#!/usr/bin/env sh

echo "[+] Deploying to Confluent Cloud"

# Check if terraform is installed
if ! [ -x "$(command -v terraform)" ]; then
  echo "[-] Error: terraform is not installed." >&2
  exit 1
fi

#Check if docker is installed
if ! [ -x "$(command -v docker)" ]; then
  echo "[-] Error: docker is not installed." >&2
  exit 1
fi

# Check if python3 is installed
if ! [ -x "$(command -v python3)" ]; then
  echo "[-] Error: python3 is not installed." >&2
  exit 1
fi

#Check if jq is installed
if ! [ -x "$(command -v jq)" ]; then
  echo "[-] Error: jq is not installed." >&2
  exit 1
fi

#Check if terraform is initialized
if [ ! -d ".terraform" ]; then
  echo "[+] Initializing terraform"
  terraform init
  if [ $? -ne 0 ]; then
    echo "[-] Failed to initialize terraform"
    exit 1
  fi
fi

echo "[+] Applying terraform"
terraform apply -auto-approve -var-file=values.tfvars
if [ $? -ne 0 ]; then
  echo "[-] Failed to apply terraform"
  exit 1
fi

# Set output variables as environment variables
export KAFKA_BOOTSTRAP_SERVERS=$(terraform output -raw kafka_bootstrap_servers)
export SCHEMA_REGISTRY_URL=$(terraform output -raw sr_url)
export KAFKA_API_KEY=$(terraform output -raw kafka_api_key)
export KAFKA_API_SECRET=$(terraform output -raw kafka_api_secret)
export SCHEMA_REGISTRY_API_ID=$(terraform output -raw sr_api_key)
export SCHEMA_REGISTRY_API_SECRET=$(terraform output -raw sr_api_secret)
export KSQL_API_KEY=$(terraform output -raw ksql_api_key)
export KSQL_API_SECRET=$(terraform output -raw ksql_api_secret)
export KSQL_ENDPOINT=$(terraform output -raw ksql_endpoint)

# Create Grafana data source
echo "[+] Creating Grafana data source"
python3 build_datasource.py ./provisioning/datasources/datasource.yml.tpl > ./provisioning/datasources/datasource.yaml
if [ $? -ne 0 ]; then
  echo "[-] Failed to create Grafana data source"
  exit 1
fi

# Create docker jms-bridge image
echo "[+] Building docker image"
docker build -t jms-bridge .
if [ $? -ne 0 ]; then
  echo "[-] Failed to build docker image"
  exit 1
fi

# Create KSQL Query
echo "[+] Creating KSQL Query"
docker build -t execute_ksql_image -f Dockerfile-ksql .
if [ $? -ne 0 ]; then
  echo "[-] Failed to build docker image"
  exit 1
fi

# Launch KSQL Query Creation
docker run -e KSQL_ENDPOINT -e KSQL_API_KEY -e KSQL_API_SECRET execute_ksql_image
if [ $? -ne 0 ]; then
  echo "[-] Failed to create KSQL Query"
  exit 1
fi
docker rmi execute_ksql_image

# Run docker image
echo "[+] Running docker image"
docker-compose -p psyncopate-jms up -d
if [ $? -ne 0 ]; then
  echo "[-] Failed to run docker image"
  exit 1
fi