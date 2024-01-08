# GCP Operations

Tools and configuration to setup and operate the infrastructure and applications of ThreatShield platform.

Currently we plan these environments:

- PROD, project ID: threatshield-prod

All environments run in this region:

- Europe-West 3 (Frankfurt): europe-west3

## Prerequisites

Tools you need to install locally:

- gcloud: https://cloud.google.com/sdk/docs/install

## Connect to GCP

Login to youe Google account:

    gcloud auth login

Configure defaults, like project, region, etc. See: https://cloud.google.com/sdk/gcloud/reference/config/set

## Initial setup

The following resources need a one time setup. This setup _can_ be automated, but as it's only one time this can also be done manually using the web console or CLI.

### Enable APIs

- Cloud Build API
- Compute Engine API
- Compute Functions API
- Cloud SQL Admin API
- Serverless VPC Access API
- Service Networking API
- Secret Manager API
- Artifact Registry API
- Pub/Sub
- Cloud Run

```shell
infra/enable_services.py -p <project>
```

### Service Accounts

Create following service accounts.

    infra/create_service_accounts.py -p <project>

Or alternatively, using web console: https://console.cloud.google.com/iam-admin/serviceaccounts

Service account for running web application in Cloud Run:

- Name: sa-cloud-run-webapp
- Roles: Secret Accessor, Cloud Run Service Agent, Cloud SQL Client

Service account for running Cloud Functions:

- Name: sa-functions-runner
- Roles: Secret Accessor, Cloud Functions Service Agent, Cloud SQL Client

Service account for deployment of images to Container Registry:

- Name: sa-image-deployer
- Roles: Artifact Registry Repository Administrator
- See: https://cloud.google.com/container-registry/docs/access-control

You can create and download a private key (JSON format) for this service account and add the JSON to the GitLab CI pipeline.

### Secret Manager

Web-Console: https://console.cloud.google.com/security/secret-manager

We need these secrets:

* threatshield-db-password: Password for CloudSQL DB (generated)
* phx-secret-key-base: Secret key for Phoenix (generated)
* mailgun-api-key: API key for Mailgun (prepared)

The secrets can be created with:

```shell
infra/create_secrets.py -p <project>
```

Afterwards, the mailgun-api-key has to be set manually.


### Create VPC Network

Currently we don't need a VPC network.

### Cloud Storage buckets

Currently we don't need any buckets.

### Cloud SQL Postgres DB

Create the database instance.
Web console: https://console.cloud.google.com/sql/instances

- Instance name: threatshield-db
- Database name: threat_shield
- IPs: Public and Private

Create a user: threat_shield

Afterwards, connect using Cloud-SQL-Proxy create database 'threat_shield' with this user:

Start the Cloud SQL Proxy:

    cloud_sql_proxy -dir /tmp/cloudsql --projects=<project>

Create the database

    psql -h /tmp/cloudsql/<project>:europe-west3:threatshield-db -U threat_shield -c "CREATE DATABASE threat_shield"

### Pub/Sub topics

Currently we don't need Pub/Sub topics.

### Artifact Registry

We need one Artifact Repository:

- Name: threatshield-images
- Type: Docker

You can create the repo via script:

```shell
infra/create_artifact_repos.py -p <project>
```

The full qualified name will be:

    europe-west3-docker.pkg.dev/<project>/threatshield-images

You can connect to this registry via docker:

    gcloud auth configure-docker europe-west3-docker.pkg.dev

You can push images to this registry:

    docker push europe-west3-docker.pkg.dev/<project>/threatshield-images/<app-name>:<version>

E.g. to push image for webapp to dev:

    docker push europe-west3-docker.pkg.dev/threatshield-dev/threatshield-images/boqenhance:latest

### Initial Setup Cloud Run

Create a Cloud Run service:

Name: boqenhance-webapp

Env variables:

- none

Reference Secrets:

- none

The service can either be created manually or you can set it up via gcloud, e.g.

```shell
infra/create_cloud_run.py -p <project>
```

### Load Balancer

First, claim a public IP and create DNS A record:

    gcloud compute addresses create boqenhance-ip --global --project=<project>

    gcloud compute addresses list --project=<project>

Create 'Application Load Balancer (HTTP/S)'.

- Name: pat-mon-webapp-load-balancer
- Type: Classic Application Load Balancer
- Backend-Type: Serverless (CloudRun)
- Enable CDN
- Enable HTTP to HTTPS redirect
- Create Google managed certificate

After creation it takes about 30 minutes until everything is setup and the certificate is available.

Note: The type must be "Classic" because the "Global external Application Load Balancer" does not yet support web sockets.
