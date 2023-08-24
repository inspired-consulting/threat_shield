# ThreatShield

## Safeguarding Your Digital Realm

ThreatShield is an AI-powered web application built with Elixir and Phoenix Framework designed to perform threat analysis and threat modeling.

In short, ThreatShield is your Intelligent Threat Analysis Companion.

## Table of Contents

- [ThreatShield](#threatshield)
  - [Development setup](#development-setup)
  - [Configuration](#configuration)
  - [Development setup with docker](#development-setup-with-docker)
    - [Prerequisites for docker](#prerequisites-for-docker)
    - [Usage with docker](#usage-with-docker)
      - [Building and running the application](#building-and-running-the-application)
      - [Accessing the containers](#accessing-the-containers)
      - [Stopping the containers/application](#stopping-the-containersapplication)
  - [Development setup with CLI tools](#development-setup-with-cli-tools)
    - [Prerequisites for CLI tools](#prerequisites-for-cli-tools)
    - [Usage with CLI tools](#usage-with-cli-tools)
      - [Running the application](#running-the-application)
      - [Stopping the server/application](#stopping-the-serverapplication)
  - [CI/CD Deployment](#cicd-deployment)

## Development setup

Clone this repo and switch to `threat_shield`:

```bash
git clone git@github.com:inspired-consulting/ThreatShields.git
```

## Configuration

The Threat Shield application requires the environment variables that are defined in the `.env` file provided to you. Copy the file into the root of this application.

## Development setup with docker

### Prerequisites for docker

To run the Threat Shield application, you will need the following installed on your system:

- [Docker](https://www.docker.com/get-started)

### Usage with docker

#### Building and running the application

Build and start the app:

```bash
cd threat_shield

docker compose up --build
```

Start the app:

```bash
cd threat_shield

docker compose up
```

Navigate to [localhost:4000](http://localhost:4000) in your browser, you're set to go.

#### Accessing the containers

To access the app container, you can use the following command:

```bash
docker exec -it ThreatShield-server /bin/sh
```

To access the database container, you can use the following command:

```bash
docker exec -it ThreatShield-db /bin/sh
```

#### Stopping the containers/application

Run the following command in your terminal to stop the Docker container via docker compose:

```bash
docker compose down
```

or

Use the `CMD+D`, or `Ctrl+D` respectively, command in your terminal to stop the application.

## Development setup with CLI tools

### Prerequisites for CLI tools

You will need the following installed on your system:

- Erlang/OTP >= 26
- Elixir >= 1.15
- Node.js >= 18.17

If you use asdf, you can install these dependencies with `asdf install`.

You also need to set up a PostgreSQL database. For local development, you can use Docker, e.g.:

```bash
docker run -e POSTGRES_USER=threat_shield -e POSTGRES_PASSWORD=secret -e POSTGRES_DB=threat_shield -p 5432:5432 --name threat-shield-db -d postgres:14
```

For local testing a separate DB is necessary. You can create this besides the dev database in the same docker instance:

```bash
docker exec -it threat-shield-db psql -h localhost -U threat_shield -c "CREATE DATABASE threat_shield_test;"
```

### Usage with CLI tools

#### Running the application

To start your Phoenix server:

```bash
cd threat_shield
mix setup
mix phx.server
```

Navigate to [localhost:4000](http://localhost:4000) in your browser, you're set to go.

#### Stopping the server/application

Use the `CMD+C`, or `Ctrl+C` respectively, command twice in your terminal to stop the application.`

## CI/CD Deployment

To create a secret for the GitHub Container Registry to pull the image from, run the following command:

```bash
kubectl create secret docker-registry github-container-registry \
  --namespace=threatshield \
  --docker-server=ghcr.io \
  --docker-username=<github-username> \
  --docker-password=<token>
```

For more context: [Set up Kubernetes secret](https://nicwortel.nl/blog/2022/continuous-deployment-to-kubernetes-with-github-actions#creating-the-image-pull-secret).
