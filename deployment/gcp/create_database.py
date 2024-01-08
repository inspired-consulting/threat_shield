#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import subprocess
import argparse
import logging
import string
import secrets

from gcp import run

logging.basicConfig(level=logging.INFO)

DB_NAME = "threat_shield"
DB_USER_NAME = "threat_shield"
INSTANCE_NAME = "threatshield-db"
MACHINE_TYPE = "db-f1-micro"
SECRET_DB_PASSWORD="threatshield-db-password"

def setup_database(project):
    create_db_instance(project)
    set_root_password(project)
    add_db_user(project)
    create_database(project)


def create_db_instance(project):
    run(f"""
        gcloud sql instances create {INSTANCE_NAME} \
        --database-version=POSTGRES_15 \
        --tier={MACHINE_TYPE} \
        --region=europe-west3 \
        --project="{project}"
    """)


def set_root_password(project):
    run(f"""
        gcloud sql users set-password postgres \
        --instance={INSTANCE_NAME} \
        --password="$(gcloud secrets versions access latest --secret='{SECRET_DB_PASSWORD}' --project='{project}')" \
        --project="{project}"
    """)

def add_db_user(project):
    run(f"""
        gcloud sql users create {DB_USER_NAME} \
        --instance={INSTANCE_NAME} \
        --password="$(gcloud secrets versions access latest --secret='{SECRET_DB_PASSWORD}' --project='{project}')" \
        --type=BUILT_IN \
        --project="{project}"
    """)

def create_database(project):
    run(f"""
        gcloud sql databases create {DB_NAME} \
        --instance={INSTANCE_NAME} \
        --charset=UTF8 \
        --collation=en_US.UTF8 \
        --project="{project}"
    """)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-p', '--project', dest='project', type=str, required=True, help='The GCP project')
    args = parser.parse_args()

    setup_database(args.project)