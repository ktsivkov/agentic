# Architecture

## Principles
- Hexagonal Architecture (ports and adapters) with CQRS: state-changing commands and read-only queries use distinct business handlers and interfaces.
- Business rules, validation, and permissions live in `business`, independently of transport validation.

## Layout
| Path | Purpose |
|------|---------|
| `business/services` | Command and query handlers (business logic) |
| `business/domain` | Domain models, in operation-specific subfolders |
| `cmd` | Entry points and application composition (Fx wiring, server lifecycle) |
| `app/inbound` | Inbound adapters (HTTP) |
| `app/outbound` | Outbound adapters (PostgreSQL, S3 object storage, logger) |
| `integration` | Integration tests (testcontainers) mirroring adapter paths; shared setup in `integration/testutil` |
| `migrations` | `golang-migrate` database migrations |
| `config` | Generic config loader and `config.yml` |
| `swagger` | Generated API docs (`make swag`) |

Inbound adapters call business handlers in `business`, never outbound adapters directly.
Interfaces that are implementation-independent are declared in the consuming package's `interfaces.go`.

## Domain objects
- Distinct command requests, command responses and query resources, each in separate `business/domain` subfolders, even if fields match. No shared entity types or aliases across roles.
- Every command with input takes a domain request object, even for a single value. Inbound adapters construct it, handlers validate it via getters, repositories accept it, and outbound adapters unpack it.
- Objects are immutable, constructor-built, expose values via getters, and defensively copy slices.
- Implement `zap.ObjectMarshaler` (not `json.Marshaler`); never include secrets (tokens, hashes, OAuth state).

## HTTP
- Router: `go-chi/chi`. Organized by audience (`public`, `protected`, `admin`), then one package per handler. Never group CRUD handlers in one package.
- Handler request/response types, interfaces, and unit tests live in the handler package.
- Audience routers register endpoints and middleware; the root router only mounts them. Wired through Fx.
- Middleware lives in `app/inbound/http/middleware`, grouped by purpose.
- Access: public needs no auth; protected needs authentication; Ownership and domain permissions are enforced in `business`.
- Every endpoint is documented with `swaggo/swag`; run `make swag` after changes.
- Share business logic across audiences; use distinct handlers/commands/queries when behavior or response shapes differ.

## Database
- Repositories and config in `app/outbound/postgres`. Each repository owns `queries.sql`; sqlc output goes to `gen` (`make sqlc`).
- Migrations: `make db/migrate/up` / `make db/migrate/down`.

## Configuration
- `config.LoadFor[T]()` reads fixed `config/config.yml` using `spf13/viper`; environment overrides files. No `os.Getenv`.
- Config structs and validation live beside their consumers (HTTP, PostgreSQL, logger); components receive their own config, not the whole app config.
- Env names are uppercase YAML paths joined by `_` (e.g. `HTTP_READ_TIMEOUT`), derived from structs. Durations use Go strings; lists are comma-separated.
- Omitted fields keep zero values. Validation via struct tags, then `T.Validate()`.
- A missing file is allowed (env-only deployment); malformed files, unknown keys, invalid values, and missing DB config fail startup.

## Logging
- `uber-go/zap` only via context-aware `Logger` interfaces (`Info(ctx, msg, fields...)`).
- `request_id` and `user_id` are added by `logger.ContextLogger` through `logger.Decorator`s in the Fx group `log_decorators`; never add them manually. Request IDs are server-generated UUIDs.
- Handlers and middleware log request outcomes; services do not log. Repositories log unexpected DB failures at `Error` (with `zap.Error`) and expected outcomes at `Debug`.
- Log domain data with `zap.Object("request", ...)`, `zap.Object("response", ...)` and `operation`. Never log hashes, tokens, or OAuth state.

## Dependency injection
`uber-go/fx`. Service dependencies are injected as interfaces; configuration and value arguments may be concrete.
