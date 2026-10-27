# Code Style

## General
- Follow the [uber-go/guide](https://github.com/uber-go/guide).
- No named returns. No `else` / `else if`; use early returns.
- Handwritten receiver names are one or two letters (leave generated names unchanged).
- No comments unless needed for clarification, required Swagger annotations, or compiler/tool directives. Preserve generated comments.
- Libraries: `uber-go/fx` (DI), `uber-go/zap` (logging), `go-playground/validator` (validation), `go-chi/chi` (HTTP), `spf13/viper` (config).

## Errors
- Declare `Err`-prefixed sentinels in the package that returns them.
- Wrap dependency errors with local errors, preserving the cause.
- Constructor argument failures wrap the local `ErrInvalidArgument` with an explanation. Dependency and initialization failures wrap an appropriate local error, not `ErrInvalidArgument`.

## Interfaces and DI
- Inject service dependencies as interfaces; config and value arguments may be concrete.
- Implementation-independent interfaces live in the consuming package's `interfaces.go`.
- `Logger` interfaces take `ctx context.Context` first.

## Domain objects
- Immutable, built via constructors, accessed via getters; copy slices defensively.
- Implement `zap.ObjectMarshaler`, omitting secrets.
- Distinct request/response/resource types per operation; no aliases.

## Linting and formatting
- `.golangci.yml` must not be modified; never disable linters with inline comments.
- Notable limits: `funlen` <= 60 lines, plus `wsl`, `mnd`, `err113`, `lll`, `funcorder`, `golines`.
- Fix the code, not the linter. Lint must report 0 issues.

## Tests
- Use `stretchr/testify`; cover all scenarios and edge cases via public APIs only.
- Unit tests sit beside the source in package `{CURRENT_PACKAGE}_test`.
- Integration tests use `testcontainers-go` under `integration`, mirroring adapter paths; shared setup in `integration/testutil`.
- For each public function (outside domain objects) write one test with named `t.Run("success", ...)` and `t.Run("fail", ...)` cases, with independent setup and assertions.
- No loops that generate test cases (loops processing test data are fine).
- No direct tests of domain objects; exercise them through business and adapter tests.
- Use Mockery-generated mocks (`make mockery`) for interface arguments, collected in one `mocks_test.go` per package beside the interfaces (package `{CURRENT_PACKAGE}_test`). Third-party interface mocks live beside the consumer tests.
- Mock `Logger` with one matcher per variadic field; use `logger.NopContext()` when logging is not asserted.

## Workflow
- Run `make help` to discover targets.
- Before finishing: `make cli` (sqlc, mockery, swag, format, lint, test).
- `make test`, `make test/unit`, `make test/integration` run tests.
- Never commit secrets or configuration credentials.
