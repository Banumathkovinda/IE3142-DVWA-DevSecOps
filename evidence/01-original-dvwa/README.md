# Evidence 01 - Original DVWA Environment Setup

## Objective
Demonstrate that the DVWA multi-container architecture is running locally using Docker Compose, container health checks are passing, and the application is fully functional.

## Docker Containers Status
Run command:
```bash
docker compose ps
```

Actual output:
```text
NAME       IMAGE                      COMMAND                  SERVICE   STATUS                    PORTS
dvwa-db    mariadb:10.11              "docker-entrypoint.s…"   db        Up 20 seconds (healthy)   3306/tcp
dvwa-web   dvwa-devsecops-web:local   "docker-php-entrypoi…"   web       Up 15 seconds (healthy)   127.0.0.1:4280->80/tcp
```

## Health Verification
- **Web Service Endpoint**: `http://127.0.0.1:4280/login.php` (Returns HTTP 200 OK)
- **Database Engine**: MariaDB 10.11 listening on internal port 3306
- **Inter-Container Communication**: Web container resolves database host `db:3306` over Docker bridge network `dvwa-internal`.
- **Database Initialization**: Automated via `setup.php` inserting schema and seed users (`admin`, `gordonb`, `1337`, `pablo`, `smithy`).

## Manual Screenshot Checklist for Academic Report
The student should capture and save the following screenshots in this directory:
1. `01-docker-compose-ps.png`: Terminal output showing `docker compose ps` with both `dvwa-web` and `dvwa-db` in `(healthy)` state.
2. `02-dvwa-setup-page.png`: Browser view of `http://127.0.0.1:4280/setup.php` showing green checkmarks for PHP, Apache, and MySQL/MariaDB modules.
3. `03-dvwa-logged-in-index.png`: Browser view of `http://127.0.0.1:4280/index.php` showing "Logged in as 'admin'" and "Security Level: low".
