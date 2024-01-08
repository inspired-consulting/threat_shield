#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import subprocess
import argparse
import logging

from gcp import run, check

logging.basicConfig(level=logging.INFO)

ACCOUNTS = {
    "sa-cloud-run-webapp": {
        "display_name": "Cloud Run Webapp",
        "description": "Runs the webapp in Cloud Run",
        "roles": [
            "roles/secretmanager.secretAccessor",
            "roles/run.serviceAgent",
            "roles/cloudsql.client",
            "roles/storage.admin",
            "roles/secretmanager.secretAccessor",
            "roles/artifactregistry.reader"
        ]
    },
    "sa-function-runner": {
        "display_name": "Cloud Function Runner",
        "description": "Runs Cloud Functions",
        "roles": [
            "roles/secretmanager.secretAccessor",
            "roles/cloudfunctions.serviceAgent",
            "roles/cloudsql.client",
            "roles/pubsub.publisher",
            "roles/pubsub.subscriber",
            "roles/secretmanager.secretAccessor"
        ]
    },
    "sa-image-deployer": {
        "display_name": "Image deployet",
        "description": "Deploys container images to Artifactory",
        "roles": [
            "roles/artifactregistry.repoAdmin"
        ]
    },
    "sa-cloud-run-deployer": {
        "display_name": "Deplyoment pipeline",
        "description": "Deploys image to Cloud Run",
        "roles": [
            "roles/artifactregistry.repoAdmin",
            "roles/run.admin",
            "roles/iam.serviceAccountUser",
            "roles/iam.serviceAccountTokenCreator"
        ]
    }
}


def create_service_accounts(project):
    for id, sa in ACCOUNTS.items():
        create_sa(project, id, sa["display_name"], sa["description"])
        for role in sa["roles"]:
            grant_role(project, id, role)

def create_sa(project, id, display_name=id, description=0):
    if not exists_sa(project, id):
        run(f"""
            gcloud iam service-accounts create {id} \
                --description="{description}" \
                --display-name="{display_name}" \
                --project="{project}"
            """)
    else:
        logging.info(f"Service account {id} already exists")

def exists_sa(project, id, description=0):
    return check(f"gcloud iam service-accounts describe {id}@{project}.iam.gserviceaccount.com --verbosity=critical")


def grant_role(project, sa_id, role):
    run(f"""
        gcloud projects add-iam-policy-binding {project} \
            --member="serviceAccount:{sa_id}@{project}.iam.gserviceaccount.com" \
            --role="{role}"
        """)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-p', '--project', dest='project',
                        type=str, required=True, help='The GCP project')
    args = parser.parse_args()

    create_service_accounts(args.project)
