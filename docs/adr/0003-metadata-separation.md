# ADR 0003: CMS metadata lives in the control plane

- Status: Proposed
- Date: 2026-10-08

## Context

The CMS needs display names, validation, relations, permissions and audit data. Writing these into a customer's database would require write access, create schema drift, and leak platform concerns into data we do not own.

## Decision

Store all CMS metadata in a separate control-plane Postgres database. Customer databases hold only customer data. Connections are read-only by default.

## Consequences

Positive:
- Least-privilege access to customer databases.
- Customer schemas stay untouched.
- Audit logs cannot be altered by tenants.

Negative:
- Schema changes in the customer database must be detected by re-introspection and reconciled with stored metadata.

## Mitigations

Introspection jobs diff the live schema against stored metadata and flag breaking changes for review.
