#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import subprocess
import argparse
import logging
import string
import secrets

from gcp import run

logging.basicConfig(level=logging.INFO)

def enable_services(project):
    enable("secretmanager.googleapis.com", project)
    enable("containerregistry.googleapis.com", project)
    enable("compute.googleapis.com", project)
    enable("vpcaccess.googleapis.com", project)
    enable("artifactregistry.googleapis.com", project)
    enable("sqladmin.googleapis.com", project)
    enable("sql-component.googleapis.com", project)
    enable("cloudbuild.googleapis.com", project)
    enable("cloudfunctions.googleapis.com", project)
    enable("certificatemanager.googleapis.com", project)
    enable("pubsub.googleapis.com", project)
    enable("run.googleapis.com", project)

def enable(service, project):
    logging.info(f"Enabling service: {service}")
    run(f"""gcloud services enable {service} \
        --project="{project}" 
    """)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-p', '--project', dest='project', type=str, required=True, help='The GCP project')
    args = parser.parse_args()

    enable_services(args.project)
