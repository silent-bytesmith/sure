---
name: running-sure-demo
description: Use when bringing up the sure application demo environment locally using docker, especially on Fedora or Linux systems with docker permission constraints
---

# Running Sure Demo Environment

## Overview
This skill provides the exact steps needed to launch the "sure" application locally in a Docker environment, seed it with realistic demo data, and handle common Linux (Fedora) Docker permission issues.

## When to Use
- When asked to "start the app", "bring up the demo", or "setup the dev environment" for the sure repository.
- When you encounter `permission denied while trying to connect to the docker API at unix:///var/run/docker.sock`.
- When Docker containers fail to find pre-built images for the `web` and `worker` services.

## Core Setup Pattern

### 1. Fix Docker Permissions on Fedora/Linux
If you get a permission denied error when running Docker commands on a Linux system (like Fedora), you must execute commands as the `docker` group.

Wrap all your docker commands in `sg docker -c "..."`:
```bash
sg docker -c "docker compose build"
```

### 2. Configure compose.yml for Local Build
If the `compose.yml` file is configured to pull images from a registry that you don't have access to, modify `compose.yml` to build locally:
1. Open `compose.yml`
2. Under both `web:` and `worker:` services, replace `image: ...` with `build: .`

### 3. Build and Start the Application
Build the containers and start them in detached mode:
```bash
sg docker -c "docker compose build"
sg docker -c "docker compose up -d"
```

### 4. Populate Demo Data
Once the web container is running and healthy, populate the database with realistic demo data so the dashboard and reports function correctly.

```bash
sg docker -c "docker compose exec -T web bin/rails demo_data:default"
```

## Quick Reference: Demo Credentials

After the demo data has finished generating, you can log in to `http://localhost:3000` with the following default credentials:

- **Email**: `user@example.com`
- **Password**: `Password1!`

## Common Mistakes
- **Running setup scripts inside the container:** The container image is pre-compiled for production. Do not run `bin/setup` or `npm install` inside the container, as `npm` is not installed in the final production stage image.
- **Forgetting `-T` in exec:** Always use `-T` (`docker compose exec -T`) when running commands in the background to prevent pseudo-TTY allocation errors.
- **Not running as docker group:** Ensure every single docker command is prefixed with `sg docker -c` if the system requires it.
