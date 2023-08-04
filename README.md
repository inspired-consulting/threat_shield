# ThreatShield

## Safeguarding Your Digital Realm

ThreatShield is an AI-powered web application built with Elixir and Phoenix Framework designed to perform threat analysis and threat modeling.

In short, ThreatShield is your Intelligent Threat Analysis Companion.

## Table of Contents

- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Configuration](#configuration)
- [Usage](#usage)
  - [Running the application](#running-the-application)
  - [Stopping the application](#stopping-the-application)
  - [Access the app container](#access-the-app-container)
  - [Access the database container](#access-the-database-container)

## Local development setup

Clone this repo and switch to `threat_shield`:

```bash
git clone git@github.com:inspired-consulting/ThreatShields.git
```

## Configuration

The Threat Shield application requires the environment variables that are defined in the `.env` file provided to you. Copy the file into the root of this application.

## Local development setup with docker

### Prerequisites

To run the Threat Shield application, you will need the following installed on your system:

- [Docker](https://www.docker.com/get-started)

## Usage

Build and start the Docker image:

```bash
cd threat_shield

docker compose up --build
```

Navigate to [localhost:4000](http://localhost:4000) in your browser, you're set to go.

## Local development setup with CLI tools

### Prerequisites

You will need the following installed on your system:

- Erlang/OTP >= 26
- Elixir >= 1.15
- Node.js >= 18.17

If you use asdf, you can install these dependencies with `asdf install`.

You also need to setup a PostgreSQL database. For local development, you can use Docker, e.g.:

```bash
docker run -e POSTGRES_USER=threat_shield -e POSTGRES_PASSWORD=secret -e POSTGRES_DB=threat_shield -p 5432:5432 --name threat-shield-db -d postgres:14
```

For local testing a separate DB is necessary. You can create this besides the dev database in the same docker instance:

```bash
docker exec -it threat-shield-db psql -h localhost -U threat_shield -c "CREATE DATABASE threat_shield_test;"
```

### Configuration

The Threat Shield application requires the environment variables that are defined in the .env file provided to you. Copy the file into the root of this application.

## Usage

### Running the application

Build and start the Docker image via docker compose:

```bash
cd threat_shield
mix setup
mix phx.server
```

Navigate to [localhost:4000](http://localhost:4000) in your browser, you're set to go.

### Stopping the application

Run the following command in your terminal to stop the Docker container via docker compose:

```bash
docker compose down
```

### Access the app container

Run the following command in your terminal to access the app container:

```bash
docker exec -it ThreatShield-server /bin/sh
```

### Access the database container

Run the following command in your terminal to access the database container:

```bash
docker exec -it ThreatShield-db /bin/sh
```
