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

## Getting Started

### Prerequisites

To run the Threat Shield application, you will need the following installed on your system:

- [Docker](https://www.docker.com/get-started)

### Installation

Clone this repo and switch to `threat_shield`:

```bash
git clone git@github.com:inspired-consulting/ThreatShields.git

cd threat_shield
```

### Configuration

The Threat Shield application requires the environment variables that are defined in the .env file provided to you. Copy the file into the root of this application.

## Usage

### Running the application

Build and start the Docker image via docker compose:

```bash
docker compose up --build
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
