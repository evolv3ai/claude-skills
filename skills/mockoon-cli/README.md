# mockoon-cli

Mock REST API server for development, testing, and CI/CD.

## Keywords

mockoon, mock api, api mocking, rest api mock, openapi mock, swagger mock, fake api, test api, ci cd mock, docker mock api, faker.js, api testing, integration testing, mock server

## Triggers

- "create mock api"
- "mock rest api"
- "mockoon"
- "fake api server"
- "api mocking"
- "convert openapi to mock"
- "docker mock api"
- "ci/cd api testing"
- "generate fake data api"

## Quick Start

```bash
# Install
npm install -g @mockoon/cli

# Start mock server
mockoon-cli start --data ./api-mock.json --port 3000

# Import from OpenAPI
mockoon-cli import --input ./openapi.yaml --output ./mock-env.json
```

## Key Features

- Run mock APIs from Mockoon or OpenAPI files
- Dynamic data with Faker.js templating
- Docker support (image + Dockerfile generation)
- CI/CD integration (GitHub Actions)
- Proxy mode and response rules
- Admin API for runtime control

## Installation

```bash
npm install -g @mockoon/cli
```
