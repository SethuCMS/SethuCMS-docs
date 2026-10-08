# 6. Data model and schemas

Two models exist. Do not mix them.

1. **Control plane**: the platform's own database (tenants, connections, metadata, permissions, audit). Always Postgres.
2. **Canonical content model**: the platform's description of a customer's data, stored in the control plane but never inside the customer's database.

## 6.1 Control-plane ER diagram

```mermaid
erDiagram
    TENANTS ||--o{ USERS : has
    TENANTS ||--o{ CONNECTIONS : owns
    TENANTS ||--o{ ROLES : defines
    USERS }o--o{ ROLES : assigned
    CONNECTIONS ||--o{ COLLECTIONS : exposes
    COLLECTIONS ||--o{ FIELDS : contains
    COLLECTIONS ||--o{ RELATIONS : "source of"
    ROLES ||--o{ PERMISSIONS : grants
    COLLECTIONS ||--o{ PERMISSIONS : "scoped to"
    CONNECTIONS ||--o{ SECRETS : "uses"
    TENANTS ||--o{ AUDIT_LOG : records
    USERS ||--o{ AUDIT_LOG : acts

    TENANTS {
        uuid id PK
        text name
        timestamptz created_at
    }
    USERS {
        uuid id PK
        uuid tenant_id FK
        text email
        text oidc_subject
        timestamptz created_at
    }
    CONNECTIONS {
        uuid id PK
        uuid tenant_id FK
        text name
        text adapter_type
        jsonb config
        uuid secret_id FK
        text mode
        text status
    }
    SECRETS {
        uuid id PK
        text kms_key_ref
        bytea ciphertext
        text auth_kind
        int key_version
    }
    COLLECTIONS {
        uuid id PK
        uuid connection_id FK
        text native_name
        text display_name
        boolean exposed
    }
    FIELDS {
        uuid id PK
        uuid collection_id FK
        text native_name
        text canonical_type
        boolean required
        jsonb validation
        jsonb ui
    }
    RELATIONS {
        uuid id PK
        uuid source_collection_id FK
        uuid target_collection_id FK
        text kind
        jsonb mapping
    }
    ROLES {
        uuid id PK
        uuid tenant_id FK
        text name
    }
    PERMISSIONS {
        uuid id PK
        uuid role_id FK
        uuid collection_id FK
        text action
        jsonb field_rules
        jsonb row_filter
    }
    AUDIT_LOG {
        bigint id PK
        uuid tenant_id FK
        uuid actor_id FK
        uuid connection_id
        text collection
        text record_id
        text operation
        jsonb diff
        inet ip
        timestamptz at
    }
```

The full DDL is in [`schemas/control-plane.sql`](../schemas/control-plane.sql).

## 6.2 Canonical content model

```mermaid
classDiagram
    class Collection {
        +string name
        +string nativeName
        +Field[] fields
        +Relation[] relations
        +Capabilities capabilities
    }
    class Field {
        +string name
        +CanonicalType type
        +bool required
        +bool unique
        +Validation validation
        +UiHints ui
    }
    class Relation {
        +string name
        +RelationKind kind
        +string target
        +Mapping mapping
    }
    class CanonicalType {
        <<enumeration>>
        string
        text
        integer
        decimal
        boolean
        datetime
        date
        json
        array
        reference
        binary
        geopoint
    }
    Collection "1" --> "*" Field
    Collection "1" --> "*" Relation
    Field --> CanonicalType
```

## 6.3 Type mapping (canonical to native)

| Canonical | Postgres | MySQL | MongoDB | Firestore | DynamoDB |
|---|---|---|---|---|---|
| string | varchar/text | varchar | string | string | S |
| integer | int/bigint | int/bigint | int32/int64 | integer | N |
| decimal | numeric | decimal | decimal128 | double | N |
| boolean | boolean | tinyint(1) | bool | boolean | BOOL |
| datetime | timestamptz | datetime | date | timestamp | S (ISO) or N |
| json | jsonb | json | object | map | M |
| array | array / jsonb | json | array | array | L |
| reference | FK | FK | ObjectId | document ref | key string |
| geopoint | geometry/point | point | GeoJSON | geopoint | M |

Adapters own the exact conversion in `type-map.ts`. Lossy conversions must be flagged in introspection.

## 6.4 Portable query AST

```mermaid
flowchart TD
    Q[Query] --> C[collection]
    Q --> F[filter]
    Q --> S[sort]
    Q --> P[projection]
    Q --> PG[page: cursor + limit]
    F --> AND[and / or / not]
    AND --> CMP[comparison: field, op, value]
    CMP --> OPS["ops: eq, ne, lt, lte, gt, gte, in, nin, contains, startsWith, exists"]
```

Example:

```json
{
  "collection": "orders",
  "filter": { "and": [
    { "field": "status", "op": "eq", "value": "paid" },
    { "field": "total", "op": "gte", "value": 100 }
  ]},
  "sort": [{ "field": "created_at", "dir": "desc" }],
  "projection": ["id", "status", "total", "created_at"],
  "page": { "limit": 50, "cursor": null }
}
```

The JSON Schema is in [`schemas/query-ast.schema.json`](../schemas/query-ast.schema.json). Field names are always validated against introspected metadata before compilation; they are never interpolated into native queries.

## 6.5 Rules

1. Metadata lives in the control plane, never in the customer's database.
2. Cursor pagination is the default everywhere.
3. Cross-source relations resolve at the gateway with batching, not inside any database.
4. Validation happens in the CMS layer for schemaless stores.
