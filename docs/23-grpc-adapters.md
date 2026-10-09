# 23. Adapters in other languages (gRPC)

Write an adapter in Python, Go or any language with gRPC, run it as its own service, and add it as a `grpc` connection.

The contract is `sethucms-adapter-sdk/proto/sethucms/adapter/v1/adapter.proto` (protocol version 1). Calls are unary: Describe, Connect, Capabilities, Introspect, Find, Get, Create, Update, Delete, Disconnect, CreateCollection, FinishBulkLoad. Payloads are JSON in string fields, with the same shapes as the TypeScript `Adapter` interface. (`Disconnect` is not named `Close` because gRPC clients already have a `close()`.)

- **Auth:** `authorization: Bearer <token>` metadata. Your service must check it.
- **Errors:** return a gRPC status and put the SethuCMS error code (for example `NOT_FOUND`, `CAPABILITY_UNSUPPORTED`) in trailing metadata `sethucms-error-code`. Messages of internal errors are hidden from API callers.
- **Capabilities:** declare honestly what your database can do. If you declare no inequality filters, the gateway refuses such queries with `CAPABILITY_UNSUPPORTED` instead of sending them.

Connection config: `{ "address": "host:port", "tls": true, "caCert": "-----BEGIN…", "callTimeoutMs": 10000 }`, credentials `{ "token": "…" }`. In production plain text to a non-loopback host is refused, and the network guard checks the address like any other database.

Write a server in TypeScript with `serveAdapter()` from `@sethucms/adapter-sdk/grpc`. A complete Python server is in `sethucms-adapter-sdk/examples/python-minimal/server.py`. Check yours with the conformance suite (`defineConformanceSuite` in `@sethucms/adapter-sdk/testing`) by pointing a `GrpcAdapter` at it; `apps/api/tests/grpc-python.test.ts` shows how.

**Status:** tested in-process (TypeScript server) and against the Python example, both passing the conformance suite. TLS with a custom CA is not tested. The older Python and Go template repositories were written before this protocol and probably need updating to match the proto.
