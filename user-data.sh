#!/bin/bash

#Install AWS_CLI
sudo apt-get update
sudo apt-get install -y awscli jq

#copy license file from S3
aws s3 cp s3://${bucket_name}/license.rli /tmp/license.rli

PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
PUBLIC_DNS=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)

cat > /tmp/tfe_settings.json <<EOF
{
   "aws_instance_profile": {
        "value": "1"
    },
    "enc_password": {
        "value": "${tfe-pwd}"
    },
    "hairpin_addressing": {
        "value": "0"
    },
    "hostname": {
        "value": "${dns_hostname}.${dns_zonename}"
    },
    "pg_dbname": {
        "value": "${db_name}"
    },
    "pg_netloc": {
        "value": "${db_address}"
    },
    "pg_password": {
        "value": "${db_password}"
    },
    "pg_user": {
        "value": "${db_user}"
    },
    "placement": {
        "value": "placement_s3"
    },
    "production_type": {
        "value": "external"
    },
    "s3_bucket": {
        "value": "${bucket_name}"
    },
    "s3_endpoint": {},
    "s3_region": {
        "value": "${region}"
    },
    "enable_active_active" : {
    "value": "1"
    },
    "redis_host" : {
    "value": "${redis}"
    },
    "redis_port" : {
    "value": "6379"
    },
    "redis_use_password_auth" : {
    "value": "1"
    },
    "redis_pass" : {
    "value": "${redis_pass}"
    },
    "redis_use_tls" : {
    "value": "1"
    }
}
EOF

json=/tmp/tfe_settings.json

jq -r . $json
if [ $? -ne 0 ] ; then
    echo ERR: $json is not a valid json
    exit 1
fi

# create replicated unattended installer config
cat > /etc/replicated.conf <<EOF
{
  "DaemonAuthenticationType": "password",
  "DaemonAuthenticationPassword": "${tfe-pwd}",
  "TlsBootstrapType": "self-signed",
  "TlsBootstrapHostname": "${dns_hostname}.${dns_zonename}",
  "LogLevel": "debug",
  "ImportSettingsFrom": "/tmp/tfe_settings.json",
  "LicenseFileLocation": "/tmp/license.rli",
  "BypassPreflightChecks": true
}
EOF

json=/etc/replicated.conf
jq -r . $json
if [ $? -ne 0 ] ; then
    echo ERR: $json is not a valid json
    exit 1
fi

# install replicated
curl -Ls -o /tmp/install.sh https://install.terraform.io/ptfe/stable
sudo bash /tmp/install.sh \
        release-sequence=${tfe_release_sequence} \
        no-proxy \
        private-address=$PRIVATE_IP \
        public-address=$PUBLIC_IP