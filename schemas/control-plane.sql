-- SethuCMS control-plane schema (PostgreSQL)
-- Platform metadata only. Customer data never lives here.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE tenants (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name        text NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE users (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id     uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    email         text NOT NULL,
    oidc_subject  text NOT NULL,
    created_at    timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, email),
    UNIQUE (tenant_id, oidc_subject)
);

-- Encrypted connection secrets (envelope encryption; key reference points to KMS).
CREATE TABLE secrets (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id    uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    kms_key_ref  text NOT NULL,
    ciphertext   bytea NOT NULL,
    auth_kind    text NOT NULL CHECK (auth_kind IN
                   ('password','service_account','iam_token','assume_role','managed_identity','secret_ref')),
    key_version  integer NOT NULL DEFAULT 1,
    created_at   timestamptz NOT NULL DEFAULT now(),
    rotated_at   timestamptz
);

CREATE TABLE connections (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id     uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name          text NOT NULL,
    adapter_type  text NOT NULL,           -- postgres, mysql, mssql, mongodb, firestore, dynamodb, ...
    config        jsonb NOT NULL DEFAULT '{}'::jsonb,  -- non-secret settings: host, port, db, tls, pool caps
    secret_id     uuid REFERENCES secrets(id),
    mode          text NOT NULL DEFAULT 'read_only' CHECK (mode IN ('read_only','read_write')),
    status        text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','active','error','disabled')),
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, name)
);

CREATE TABLE collections (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    connection_id  uuid NOT NULL REFERENCES connections(id) ON DELETE CASCADE,
    native_name    text NOT NULL,
    display_name   text NOT NULL,
    exposed        boolean NOT NULL DEFAULT false,   -- nothing exposed until reviewed
    UNIQUE (connection_id, native_name)
);

CREATE TABLE fields (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    collection_id  uuid NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
    native_name    text NOT NULL,
    canonical_type text NOT NULL CHECK (canonical_type IN
                     ('string','text','integer','decimal','boolean','datetime','date',
                      'json','array','reference','binary','geopoint')),
    required       boolean NOT NULL DEFAULT false,
    is_primary_key boolean NOT NULL DEFAULT false,
    validation     jsonb NOT NULL DEFAULT '{}'::jsonb,
    ui             jsonb NOT NULL DEFAULT '{}'::jsonb,
    lossy          boolean NOT NULL DEFAULT false,   -- native type did not map cleanly
    UNIQUE (collection_id, native_name)
);

CREATE TABLE relations (
    id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    source_collection_id  uuid NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
    target_collection_id  uuid NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
    name                  text NOT NULL,
    kind                  text NOT NULL CHECK (kind IN ('one_to_one','one_to_many','many_to_one','many_to_many')),
    mapping               jsonb NOT NULL,        -- which fields join, or reference path
    UNIQUE (source_collection_id, name)
);

CREATE TABLE roles (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id  uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name       text NOT NULL,
    UNIQUE (tenant_id, name)
);

CREATE TABLE user_roles (
    user_id  uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id  uuid NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE permissions (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    role_id        uuid NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    collection_id  uuid NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
    action         text NOT NULL CHECK (action IN ('read','create','update','delete')),
    field_rules    jsonb NOT NULL DEFAULT '{}'::jsonb,  -- hide / mask / read-only per field
    row_filter     jsonb,                               -- portable filter AST applied to every query
    UNIQUE (role_id, collection_id, action)
);

-- Append-only audit log.
CREATE TABLE audit_log (
    id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id      uuid NOT NULL REFERENCES tenants(id),
    actor_id       uuid REFERENCES users(id),
    connection_id  uuid,
    collection     text,
    record_id      text,
    operation      text NOT NULL,       -- read, create, update, delete, connection.create, secret.read, permission.change, ...
    diff           jsonb,               -- redacted before/after
    ip             inet,
    request_id     text,
    at             timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX audit_log_tenant_time ON audit_log (tenant_id, at DESC);
CREATE INDEX connections_tenant ON connections (tenant_id);
CREATE INDEX collections_connection ON collections (connection_id);

-- Make the audit log append-only for the application role.
-- (Run as owner; replace app_role with the real application role.)
-- REVOKE UPDATE, DELETE, TRUNCATE ON audit_log FROM app_role;

-- Optional: row-level security so a request can only see its own tenant.
-- ALTER TABLE connections ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY tenant_isolation ON connections
--   USING (tenant_id = current_setting('app.tenant_id')::uuid);
