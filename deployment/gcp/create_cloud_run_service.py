#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import subprocess
import argparse
import logging
import string
import secrets

from gcp import run

logging.basicConfig(level=logging.INFO)

CONFIG = {
    "threatshield-prod": {
        "host-name": "app.threatshield.eu",
        "mailgun-domain": "mg.inspired.jetzt"
    }
}

SERVICE_NAME="threatshield-webapp"
DB_NAME = "threat_shield"
DB_USER_NAME = "threat_shield"
INSTANCE_NAME = "threatshield-db"
IMAGE="us-docker.pkg.dev/cloudrun/container/hello"
SECRET_DB_PASSWORD="threatshield-db-password"
SECRET_MAILGUN_API_KEY="mailgun-api-key"
SECRET_OPENAI_API_KEY="openai-api-key"
SECRET_PHX_SECRET_KEY_BASE="phx-secret-key-base"

def create_cloud_run(project):
    host_name = CONFIG[project]["host-name"]
    mailgun_domain = CONFIG[project]["mailgun-domain"]
    run(f"""
        gcloud run deploy {SERVICE_NAME} \
        --image={IMAGE} \
        --allow-unauthenticated \
        --port=4000 \
        --service-account=sa-cloud-run-webapp@{project}.iam.gserviceaccount.com \
        --max-instances=1 \
        --set-env-vars='CLOUD_SQL_CONNECTION_NAME=/cloudsql/{project}:europe-west3:{INSTANCE_NAME},PHX_HOST={host_name},MAILGUN_DOMAIN={mailgun_domain}' \
        --set-cloudsql-instances={project}:europe-west3:{INSTANCE_NAME} \
        --set-secrets=SECRET_KEY_BASE={SECRET_PHX_SECRET_KEY_BASE}:1,DB_PASSWORD={SECRET_DB_PASSWORD}:1,OPENAI_API_KEY={SECRET_OPENAI_API_KEY}:latest,MAILGUN_API_KEY={MAILGUN_API_KEY}:1 \
        --execution-environment=gen2 \
        --region=europe-west3 \
        --project="{project}"
    """)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-p', '--project', dest='project', type=str, required=True, help='The GCP project')
    args = parser.parse_args()

    create_cloud_run(args.project)