#!/bin/bash
set -e

pushd /home/vboxuser/git/diplom/diplom-tf/sa_bucket > /dev/null
ACCESS_KEY=$(terraform output -raw access_key)
SECRET_KEY=$(terraform output -raw secret_key)
popd > /dev/null

export AWS_ACCESS_KEY_ID="$ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$SECRET_KEY"

terraform init -reconfigure
terraform apply -auto-approve
