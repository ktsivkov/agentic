.DEFAULT_GOAL := help

.PHONY: help test test/unit test/integration lint format sqlc mockery swag cli

help:
	@printf '%s\n' \
		'test              Run unit and integration tests' \
		'test/unit         Run tests outside integration' \
		'test/integration  Run integration tests (requires Docker/Testcontainers)' \
		'lint              Lint handwritten backend code with golangci-lint (generated files/frontend excluded)' \
		'format            Apply configured golangci-lint formatters' \
		'sqlc              Generate database code with sqlc in Docker' \
		'mockery           Generate interface mocks' \
		'swag              Generate Swagger docs in swagger/ with swag in Docker' \
		'cli               Run the full pipeline in order: sqlc, mockery, swag, format, lint, test'

test: test/unit test/integration

test/unit:
	cd app && go test $$(go list ./... | grep -v '/integration') -count=1

test/integration:
	cd app && go test ./integration/... -count=1

lint:
	docker run --rm -v "$(CURDIR):/app" -w /app golangci/golangci-lint:v2.14.0 golangci-lint run ./...

format:
	docker run --rm -v "$(CURDIR):/app" -w /app golangci/golangci-lint:v2.14.0 golangci-lint fmt ./...

sqlc:
	docker run --rm -v "$(CURDIR):/app" -w /app sqlc/sqlc:1.31.1 generate

mockery:
	cd app && go run github.com/vektra/mockery/v3@v3.8.1

swag:
	docker run --rm -v "$(CURDIR):/app" -v "$(CURDIR)/swagger:/app/swagger" -w /app ghcr.io/swaggo/swag:v1.16.6 init --generalInfo main.go --dir cmd/http --parseInternal --output swagger

cli: sqlc mockery swag format lint test
