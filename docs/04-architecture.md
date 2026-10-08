# 4. Architecture

## 4.1 System context

```mermaid
flowchart LR
    subgraph Clients
        W[Next.js / React]
        F[Flutter / Mobile]
        P[Python / FastAPI]
        O[Other languages]
    end
    ADM[Admin UI<br/>React + Refine]

    subgraph AnyDB CMS
        GW[API Gateway<br/>REST + GraphQL + OpenAPI]
        AUTH[Auth<br/>OIDC, RBAC, field/row rules]
        WK[Worker pool<br/>isolated adapter runners]
        VLT[Vault<br/>envelope encryption]
        AUD[Audit log]
        CP[(Control plane DB<br/>tenants, connections,<br/>metadata, permissions)]
    end

    subgraph Customer databases
        SQL[(Postgres / MySQL / SQL Server)]
        DOC[(MongoDB / Firestore / Cosmos)]
        KV[(DynamoDB / Redis)]
    end

    W & F & P & O --> GW
    ADM --> GW
    GW --> AUTH
    GW --> CP
    GW --> WK
    WK --> VLT
    WK --> SQL & DOC & KV
    GW --> AUD
    WK --> AUD
```

## 4.2 Layers

```mermaid
flowchart TB
    A[Clients and Admin UI] --> B[API Gateway]
    B --> C[Auth and permission checks]
    C --> D[Portable query AST]
    D --> E[Adapter protocol]
    E --> F1[postgres adapter]
    E --> F2[mongodb adapter]
    E --> F3[firestore adapter]
    E --> F4[dynamodb adapter]
    E --> F5[any-language adapter]
    F1 & F2 & F3 & F4 & F5 --> G[(Customer databases)]
```

## 4.3 Read request flow

```mermaid
sequenceDiagram
    autonumber
    participant C as Client
    participant G as Gateway
    participant A as Auth
    participant CP as Control plane
    participant W as Worker / Adapter
    participant V as Vault
    participant DB as Customer DB
    participant L as Audit

    C->>G: GET /v1/connections/{id}/collections/orders?cursor=...
    G->>A: verify token, resolve roles
    A-->>G: identity + permissions
    G->>CP: load connection + collection metadata
    G->>G: build query AST, apply field and row rules
    G->>W: find(ast) over adapter protocol
    W->>V: fetch decrypted secret (short-lived)
    V-->>W: credential or IAM token
    W->>DB: native query (parameterised)
    DB-->>W: rows / documents
    W-->>G: records + next cursor
    G->>L: append audit event
    G-->>C: JSON response
```

## 4.4 Connect-and-introspect flow

```mermaid
sequenceDiagram
    autonumber
    participant U as Admin
    participant G as Gateway
    participant NG as Network guard
    participant V as Vault
    participant W as Worker
    participant DB as Customer DB
    participant CP as Control plane

    U->>G: POST /v1/connections (type, host, secret ref)
    G->>NG: validate host (SSRF, TLS, allowlist)
    NG-->>G: ok
    G->>V: encrypt and store secret
    G->>CP: save connection (read-only by default)
    G->>W: introspect job
    W->>DB: read catalog / sample documents
    DB-->>W: schema
    W->>CP: save draft content model
    G-->>U: connection id + draft schema to review
```

## 4.5 Adapter capability handling

```mermaid
flowchart LR
    Q[Query AST] --> CAP{Adapter capabilities}
    CAP -->|supported| N[Compile to native query]
    CAP -->|not supported| R[Reject with CAPABILITY_UNSUPPORTED]
    CAP -->|emulatable| E[Gateway emulation, flagged in response]
    N --> RES[Result]
    E --> RES
```

Examples: DynamoDB has no arbitrary sort, so sorting by any column is rejected; Firestore has limited OR and inequality, so some filters are rejected or emulated and marked as such.

## 4.6 Multi-tenant bring-your-own-database

```mermaid
flowchart TB
    subgraph Control plane
        T[tenants] --> CN[connections]
        CN --> SR[secret refs]
        CN --> MD[collection metadata]
        T --> RL[roles and permissions]
    end
    subgraph Data plane
        W1[Worker: tenant A / conn 1]
        W2[Worker: tenant B / conn 2]
    end
    CN --> W1
    CN --> W2
    W1 --> DA[(Tenant A DB)]
    W2 --> DB2[(Tenant B DB)]
```

Each connection gets its own pool limits and an isolated worker so one tenant's slow query cannot starve another.

## 4.7 Deployment view

```mermaid
flowchart TB
    LB[Load balancer / WAF] --> API[API pods]
    API --> CP[(Postgres control plane)]
    API --> Q[Job queue]
    Q --> WRK[Worker pods]
    WRK --> KMS[KMS / secrets manager]
    WRK --> NAT[Static egress IPs]
    NAT --> EXT[(Customer databases)]
    ADM[Admin UI static hosting] --> LB
```

Static egress IPs let customers allowlist the platform. Private networking (PrivateLink, Private Service Connect, Private Link) and SSH tunnels are supported alongside.
