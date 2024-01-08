#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import subprocess
import argparse
import logging
import string
import secrets

from gcp import run, check

logging.basicConfig(level=logging.INFO)

SERVICE_NAME="threatshield-webapp"
REGION = "europe-west3"
NEG_NAME = "threatshield-neg"
BACKEND_SERVICE_NAME = "threatshield-lb-backend"
CERT_NAME="threatshield-cert"
CERT_DOMAINS="app.threatshield.eu"


def create_load_balancer(project):
    create_network_endpoint_group(project, NEG_NAME, SERVICE_NAME)
    create_backend(project, BACKEND_SERVICE_NAME, NEG_NAME)
    create_certificate(project, CERT_NAME, CERT_DOMAINS)

def create_backend(project, name, neg_name):
    if not exists_backend(project, name):
        run(f"""
            gcloud compute backend-services create {name} \
                --global \
                --project="{project}"
            """)

        run(f"""
            gcloud compute backend-services add-backend {name} \
                --global \
                --network-endpoint-group={neg_name} \
                --network-endpoint-group-region={REGION}
            """)
        run(f"""
            gcloud compute backend-services update {name} --enable-cdn --global
            """)

    else:
        logging.info(f"Backend service {name} already exists")


def exists_backend(project, name):
    return check(f"""
        gcloud compute backend-services describe {name} \
        --global \
        --project="{project}" \
        --quiet
        """)

def create_network_endpoint_group(project, name, service_name):
    if not exists_neg(project, name):
        run(f"""
            gcloud compute network-endpoint-groups create {name} \
                --region={REGION} \
                --network-endpoint-type=SERVERLESS \
                --cloud-run-service={service_name} \
                --project="{project}"
            """)
    else:
        logging.info(f"Network endpoint group {name} already exists")


def exists_neg(project, name):
    return check(f"""
        gcloud compute network-endpoint-groups describe {name} \
        --region={REGION} \
        --project="{project}" \
        --quiet
        """)


def create_certificate(project, name, domains):
    if not exists_certificate(project, name):
        run(f"""
            gcloud compute ssl-certificates create {name} \
                --domains={domains} \
                --global \
                --project="{project}"
            """)
    else:
        logging.info(f"Certificate {CERT_NAME} already exists")


def exists_certificate(project, name):
    return check(f"""
        gcloud compute ssl-certificates describe {name} \
        --global \
        --project="{project}" \
        --quiet
        """)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-p', '--project', dest='project', type=str, required=True, help='The GCP project')
    args = parser.parse_args()

    create_load_balancer(args.project)