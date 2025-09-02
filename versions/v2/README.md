# OneCX Local Env v2

> **This document only contains information specific to v2 of the OneCX Local Env. Please make sure to also read the [top-level README](../../README.md) of this repository for general information and instructions that apply to all versions.**

v2 is the current latest version of the local development environment for OneCX.

## Overview

v2 contains services for Traefik, Postgres, Keycloak and all currently existing OneCX products (SVC, BFF, UI). To ensure memory-efficiency and allow developers to only start the services they need, all services are grouped into profiles that can be started individually. **No services are started by default and at least one profile must be specified when starting the environment.** For more details on the available services, profiles, environment variables, networks and volumes, please refer to the ["Components"](#components) section of this document.

## Running OneCX Local Env v2

>Since the [root compose file of the repository](../../docker-compose.yaml) always points to the current latest version of the OneCX Local Env, developers can run commands against v2 without needing to specify the versioned compose file explicitly.

To start a minimal local development environment (Traefik, Postgres and Keycloak) together with the most commonly used OneCX products (Shell, Workspace, Theme, Permission, Product Store, User Profile and Welcome) and their dependencies, developers can use the `base` profile. This profile is recommended for most users and should be viewed as the default. To start the environment with the `base` profile, run the following command:

- From the repository root:
  ```bash
  docker compose --profile base up -d
  ```

To give developers more flexibility and full control over which services/products to start, several additional profiles are available. Please refer to the ["Components > Profiles"](#profiles) section of this document for a list of all available profiles.

## Stopping OneCX Local Env v2

To stop a started profile, run the following command, replacing `<profile-name>` with the name of the profile to stop (e.g. `base`):

- From the repository root:
  ```bash
  docker compose --profile <profile-name> down
  ```

## Importing initial data

>Since the [root import script of the repository](../../import-onecx.sh) always points to the current latest version of the OneCX Local Env, developers can execute the root import script to import initial data into their v2 environment without needing to specify the versioned import script explicitly.

When starting OneCX Local Env v2 for the first time, some initial data has to be imported to set up the environment correctly. To import the initial data, please follow these steps:

1. Run the automated import script:
   - From the repository root:
     ```bash
     ./import-onecx.sh
     ```
2. Wait for the script to finish and ensure that status messages for each step are green and indicate success.
3. After the script has completed successfully, all initial data has been imported and the environment is ready to use.

If you want to integrate the import script into your own scripts and want to only perform the actual import operations instead of also starting and stopping all necessary services, you can set the `SKIP_CONTAINER_MANAGEMENT` environment variable to `1` or `true` before executing the script:
- From the repository root:
    ```bash
    SKIP_CONTAINER_MANAGEMENT=true ./import-onecx.sh
    ```

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

To give developers more flexibility and ensure the highest possible memory-efficiency, OneCX Local Env v2 exposes all services via a variety of profiles that can be started individually. At least one profile must be specified when starting the environment. The following profiles are available:

- `minimal`
    - starts only a minimal local development environment (Traefik, Postgres and Keycloak) together with OneCX Shell and its dependencies
    - useful as a basis if developers only want to test one or very few applications/products inside the Shell
    - keeps memory usage as low as possible
- `data-import`
    - not recommended for regular use
    - is used internally by `import-onecx.v2.sh` to start only the services required for the import of initial data (Traefik, Postgres, Keycloak and all OneCX product SVCs)
- `base`
    - the recommended default profile for most users
    - starts a minimal local development environment (Traefik, Postgres and Keycloak) together with the most commonly used OneCX products (Shell, Workspace, Theme, Permission, Product Store, User Profile and Welcome) and their dependencies
- `pgadmin`
    - starts PGAdmin alongside Traefik and Postgres (if not already started via another profile)
    - useful if developers want to use PGAdmin to inspect or manage the Postgres database
- `all`
    - starts all available services
    - might be useful in certain testing scenarios, but is generally not recommended due to high memory usage
- `<PRODUCT-NAME>`
    - starts all services for a specific OneCX product (SVC, BFF, UI)
    - must be combined with at least the `minimal` profile to also start the required dependencies (Traefik, Postgres, Keycloak and Shell)
    - e.g. to start only the Workspace product alongside its dependencies, run:
      ```bash
      docker compose --profile minimal --profile workspace up -d
      ```
- `<PRODUCT-NAME>-ui`
    - starts only the UI stack of a specific OneCX product (UI, BFF)
    - only works if all dependencies (e.g. `minimal` profile and related product SVC) are already started
    - useful if developers need to constantly run a certain product SVC (e.g. Workspace) and want to occasionally start and stop the related UI stack
    - e.g. to start only the Workspace UI alongside an already running Workspace SVC, run:
      ```bash
      docker compose --profile workspace-ui up -d
      ```

For details on how to run profiles, please refer to the ["Running OneCX Local Env v2"](#running-onecx-local-env-v2) section of this document.

### Environment variables

All services are based on images defined in the `.env` file in the `versions/v2` directory. Services might also reference additional environment variables from the `.env`, `common.env`, `svc.env` and `bff.env` files in the `versions/v2` directory.

The `.env` file is always loaded automatically, while other env files are referenced by some services via the `env_file` directive.

Some services also define additional environment variables directly in the compose file.

### Networks

- `default` — primary network used by OneCX Local Env v2. All services connect via this network.

### Volumes

OneCX Local Env v2 mounts one global volume:

- `postgres` — volume used by `postgresdb` to persist its data across container restarts.

Additionally, some services (`traefik`, `postgresdb`, `pgadmin` and `keycloak-app`) mount local directories for initialization data.
