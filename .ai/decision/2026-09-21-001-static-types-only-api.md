# Decision: Static Types-Only Bundle API

- Date: 2026-09-21
- Topic: Bundle API
- Decision: Publish the current API as a static Luau contract built around `framework.manifest()`, `define()`, and `bundle.require(bundle_name, api_name)`.
- Reason: The implementation provides typed manifest and dependency API validation but no production runtime behavior. Public documentation must preserve that boundary.
- importance: 0.98
- confidence: 1.0
- createdAt: 2026-09-21T00:00:00Z
- lastUsedAt: 2026-09-21T00:00:00Z