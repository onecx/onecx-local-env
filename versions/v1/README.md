# OneCX Local Env v1

> **This document only contains information specific to v1 of the OneCX Local Env. Please make sure to also read the [top-level README](../../README.md) of this repository for general information and instructions that apply to all versions.**

v1 was the initial version of the local development environment for OneCX. While it still works and will be maintained for some time to avoid breaking existing workflows, some significant quality-of-life improvements were implemented in [OneCX Local Env v2](../v2/README.md). We therefore encourage new users to start with [OneCX Local Env v2](../v2/README.md).

## Overview

v1 contains services for Traefik, Postgres, Keycloak and all currently existing OneCX products (SVC, BFF, UI). Some of these services are started by default, while others can only be started via specific profiles. For more details on the available services, profiles, environment variables, networks and volumes, please refer to the ["Components"](#components) section of this document.

## Running OneCX Local Env v1

To start a minimal local development environment (Traefik, Postgres and Keycloak) together with OneCX Shell, OneCX Workspace and their dependencies, run one of the following commands:

- From the repository root:
  ```bash
  docker compose -f versions/v1/docker-compose.v1.yaml up -d
  ```
- From the `versions/v1` directory:
  ```bash
  docker compose up -d
  ```

To additionally start the OneCX Parameter product, use the `--profile parameter` flag:

- From the repository root:
  ```bash
  docker compose -f versions/v1/docker-compose.v1.yaml --profile parameter up -d
  ```
- From the `versions/v1` directory:
  ```bash
  docker compose --profile parameter up -d
  ```

To start all services defined in the compose file, use the `--profile all` flag:

- From the repository root:
  ```bash
  docker compose -f versions/v1/docker-compose.v1.yaml --profile all up -d
  ```
- From the `versions/v1` directory:
  ```bash
  docker compose --profile all up -d
  ```

## Stopping OneCX Local Env v1

To stop the started services, run one of the following commands:

- From the repository root:
  ```bash
  docker compose -f versions/v1/docker-compose.v1.yaml down
  ```
- Stop specific profile from the repository root:
  ```bash
  docker compose -f versions/v1/docker-compose.v1.yaml --profile <profile-name> down
  ```
- From the `versions/v1` directory:
  ```bash
  docker compose down
  ```
- Stop specific profile from the `versions/v1` directory:
  ```bash
  docker compose --profile <profile-name> down
  ```

## Importing initial data

When starting OneCX Local Env v1 for the first time, some initial data has to be imported to set up the environment correctly. To import the initial data, please follow these steps:

1. Start the environment using the `all` profile (see [Running OneCX Local Env v1](#running-onecx-local-env-v1)).
2. Wait for all services to be healthy.
3. Wait for at least 30 seconds to ensure that all services are fully initialized and operational.
4. Run the import script:
   - From the repository root:
     ```bash
     ./versions/v1/import-onecx.v1.sh
     ```
5. Ensure that status messages for each step are green and indicate success.
6. After the script has completed successfully, all initial data has been imported and the environment is ready to use.

## Components

### Services

- `traefik`
- `postgresdb`
- `pgadmin`
- `keycloak-app`
- OneCX Product Services:
  - Shell: `onecx-shell-ui`, `onecx-shell-bff`
  - Theme: `onecx-theme-svc`, `onecx-theme-bff`, `onecx-theme-ui`
  - Workspace: `onecx-workspace-svc`, `onecx-workspace-bff`, `onecx-workspace-ui`
  - Permission: `onecx-permission-svc`, `onecx-permission-bff`, `onecx-permission-ui`
  - Product Store: `onecx-product-store-svc`, `onecx-product-store-bff`, `onecx-product-store-ui`
  - User Profile: `onecx-user-profile-svc`, `onecx-user-profile-bff`, `onecx-user-profile-ui`
  - IAM: `onecx-iam-kc-svc`, `onecx-iam-bff`, `onecx-iam-ui`
  - Tenant: `onecx-tenant-svc`, `onecx-tenant-bff`, `onecx-tenant-ui`
  - Welcome: `onecx-welcome-svc`, `onecx-welcome-bff`, `onecx-welcome-ui`
  - Help: `onecx-help-svc`, `onecx-help-bff`, `onecx-help-ui`
  - Parameter: `onecx-parameter-svc`, `onecx-parameter-bff`, `onecx-parameter-ui`

### Profiles

OneCX Local Env v1 contains a few profiles that can be used to start additional services on top of the default set of services:

- `parameter` — starts the OneCX Parameter product services
- `all` — starts all services defined in the compose file

For details on how to use profiles, please refer to the ["Running OneCX Local Env v1"](#running-onecx-local-env-v1) section of this document.

### Environment variables

All services are based on images defined in the `.env` file in the `versions/v1` directory. Services might also reference additional environment variables from the `.env`, `common.env`, `svc.env` and `bff.env` files in the `versions/v1` directory.

The `.env` file is always loaded automatically, while other env files are referenced by some services via the `env_file` directive.

Some services also define additional environment variables directly in the compose file.

### Networks

- `example` — primary network used by OneCX Local Env v1. All services connect via this network.

### Volumes

OneCX Local Env v1 mounts one global volume:

- `postgres` — volume used by `postgresdb` to persist its data across container restarts.

Additionally, some services (`traefik`, `postgresdb`, `pgadmin` and `keycloak-app`) mount local directories for initialization data.

## Troubleshooting

### Keycloak reported as unhealthy

If the `keycloak-app` service is reported as unhealthy, please try to re-run the docker compose command to start the service again. In some cases, Keycloak might take a bit longer to start up, and re-running the command can help resolve the issue.
