#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import subprocess
import argparse
import logging
import string
import secrets

from gcp import run, check, gen_secret

logging.basicConfig(level=logging.INFO)

def create_service_secrets(project):
    create_secret(project, "threatshield-db-password", gen_secret(30))
    create_secret(project, "phx-secret-key-base", gen_secret(64))
    prepare_secret(project, "mailgun-api-key")


def create_secret(project, name, secret):
    if not exists_secret(project, name):
        run(f"""
            printf {secret} | gcloud secrets create {name} \
                --data-file=- \
                --project="{project}"
            """)
    else:
        logging.info(f"Secret {name} already exists")


def prepare_secret(project, name):
    if not exists_secret(project, name):
        run(f"""
            gcloud secrets create {name} \
                --project={project}
            """)
    else:
        logging.info(f"Secret {name} already exists")


def exists_secret(project, name):
    return check(f"""
        gcloud secrets describe {name} \
            --project={project} \
            --quiet
        """)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-p', '--project', dest='project', type=str, required=True, help='The GCP project')
    args = parser.parse_args()

    create_service_secrets(args.project)