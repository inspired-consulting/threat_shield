# ThreatShield

**Your intelligent threat-analysis and threat-modeling companion.**

ThreatShield is an open-source, AI-assisted web application for structured
threat modeling. You describe your organisation and its systems and assets,
and ThreatShield helps you identify the **threats** you face, assess the
**risks** they pose, and plan **mitigations** — with an AI assistant suggesting
relevant entries at each step so you start from a draft instead of a blank page.

Built with Elixir, the Phoenix Framework (LiveView) and PostgreSQL.

## Features

- **Guided threat-modeling workflow** — organisations → systems & assets →
  threats → risks → mitigations, all linked together.
- **AI-assisted suggestions** — generate candidate threats, assets, risks and
  mitigations from your organisation's context (powered by OpenAI), reviewed
  and accepted by a human before anything is saved.
- **Multi-tenant & role-based** — collaborate within an organisation with
  owner/editor/viewer roles; data is isolated per organisation.
- **Risk board & analytics** — visualise and prioritise risks across your model.
- **Excel export** — export your threat model for reporting and sharing.
- **Usage quotas** — per-organisation monthly limits on AI requests.

## Open Source

ThreatShield is open source under the [MIT License](LICENSE.txt).
Contributions, issues and pull requests are welcome.

## Table of Contents

- [ThreatShield](#threatshield)
  - [Features](#features)
  - [Open Source](#open-source)
  - [Development setup](#development-setup)
  - [Configuration](#configuration)
  - [Development setup with docker](#development-setup-with-docker)
    - [Prerequisites for docker](#prerequisites-for-docker)
    - [Usage with docker](#usage-with-docker)
      - [Building and running the application](#building-and-running-the-application)
      - [Accessing the containers](#accessing-the-containers)
      - [Stopping the containers/application](#stopping-the-containersapplication)
    - [Testing your application](#testing-your-application)
  - [Development setup with CLI tools](#development-setup-with-cli-tools)
    - [Prerequisites for CLI tools](#prerequisites-for-cli-tools)
    - [Usage with CLI tools](#usage-with-cli-tools)
      - [Running the application](#running-the-application)
      - [Stopping the server/application](#stopping-the-serverapplication)
  - [CI/CD Deployment](#cicd-deployment)
  - [License](#license)

## Development setup

Clone this repo and switch into the `threat_shield` directory:

```bash
git clone https://github.com/inspired-consulting/threat_shield.git
cd threat_shield
```

## Configuration

ThreatShield is configured via environment variables. Copy `.env.template`
to `.env` and fill in the values — at minimum a PostgreSQL connection and an
**OpenAI API key** for the AI suggestion features. See `config/runtime.exs`
for the full list of supported variables.

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

use the `Ctrl+C` command twice in your terminal to stop the application.

### Testing your application

To run the tests, access the app container, and use the following command:

```bash
MIX_ENV=test mix test
```

## Development setup with CLI tools

### Prerequisites for CLI tools

You will need the following installed on your system:

- Erlang/OTP 26.2.1
- Elixir 1.16.2
- Node.js 20.11

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

Use the `Ctrl+C` command twice in your terminal to stop the application.

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

## License

Released under the [MIT License](LICENSE.txt) — © 2024–2026 Inspired Consulting GmbH.
