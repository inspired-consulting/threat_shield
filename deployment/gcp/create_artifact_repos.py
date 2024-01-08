#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import subprocess
import argparse
import logging
import string
import secrets

from gcp import run, check

logging.basicConfig(level=logging.INFO)

def create_repos(project):
     run(f"""
        gcloud artifacts repositories create threatshield-images \
            --repository-format=docker \
            --location=europe-west3 \
            --description="Docker repository for ThreatShield images" \
            --project="{project}"
    """)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-p', '--project', dest='project', type=str, required=True, help='The GCP project')
    args = parser.parse_args()

    create_repos(args.project)
