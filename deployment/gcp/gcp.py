import secrets
import string
import subprocess

def run(cmd, desc="<unknown>"):
    rc = subprocess.call(cmd, shell=True)
    if rc != 0:
        raise Exception(f"Command '{desc}' failed with code: {rc}")

def check(cmd, desc="<unknown>", show_output=False):
    if show_output:
        rc = subprocess.call(cmd, shell=True)
    else:
        rc = subprocess.call(cmd, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return rc == 0

def gen_secret(length):
    alphabet = string.ascii_letters + string.digits + '._-+'
    return ''.join(secrets.choice(alphabet) for i in range(length))
