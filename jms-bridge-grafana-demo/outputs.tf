output "kafka_bootstrap_servers" {
  value = confluent_kafka_cluster.cluster.bootstrap_endpoint
}

output "kafka_api_key" {
  value = confluent_api_key.app-manager-kafka-api-key.id
  sensitive = true
}

output "kafka_api_secret" {
  value     = confluent_api_key.app-manager-kafka-api-key.secret
  sensitive = true
}

output "sr_url" {
  value = data.confluent_schema_registry_cluster.pid_schema_registry.rest_endpoint
  sensitive = true
}

output "sr_api_key" {
  value     = confluent_api_key.env-manager-schema-registry-api-key.id
  sensitive = true
}

output "sr_api_secret" {
  value     = confluent_api_key.env-manager-schema-registry-api-key.secret
  sensitive = true
}

output "ksql_api_key" {
  value = confluent_api_key.ksqldb-api-key.id
  sensitive = true
}

output "ksql_api_secret" {
  value = confluent_api_key.ksqldb-api-key.secret
  sensitive = true
}

output "ksql_endpoint" {
  value = confluent_ksql_cluster.ksql-cluster.rest_endpoint
}

# output "connection_details" {
#   value = {
#     bootstrap_servers : confluent_kafka_cluster.cluster.bootstrap_endpoint,
#     kafka_api_key : confluent_api_key.app-manager-kafka-api-key.id,
#     kafka_api_secret : confluent_api_key.app-manager-kafka-api-key.secret,
#     confluent_cloud_environment_id : confluent_environment.environment.id,
#     confluent_cloud_cluster_id : confluent_kafka_cluster.cluster.id,
#     confluent_cloud_cluster_bootstrap_server : confluent_kafka_cluster.cluster.bootstrap_endpoint
#   }
#   sensitive = true
# }
#
#
# output "schema_registry_details" {
#   value = {
#     schema_registry_url : data.confluent_schema_registry_cluster.pid_schema_registry.rest_endpoint,
#     schema_registry_api_id : confluent_api_key.env-manager-schema-registry-api-key.id,
#     schema_registry_api_secret : confluent_api_key.env-manager-schema-registry-api-key.secret
#   }
#   sensitive = true
# }
#
#
# output "stream_details" {
#   value = {
#     confluent_cloud_cluster_rbac_crn : confluent_kafka_cluster.cluster.rbac_crn,
#     confluent_cloud_cluster_rest_endpoint : confluent_kafka_cluster.cluster.rest_endpoint,
#     confluent_cloud_service_account_id : confluent_service_account.app-manager.id,
#     confluent_cloud_service_account_api_version : confluent_service_account.app-manager.api_version,
#     confluent_cloud_service_account_kind : confluent_service_account.app-manager.kind,
#     confluent_cloud_schema_registry_cluster_name : data.confluent_schema_registry_cluster.pid_schema_registry.resource_name,
#     confluent_cloud_provider : confluent_kafka_cluster.cluster.cloud,
#     confluent_cloud_region : confluent_kafka_cluster.cluster.region,
#     confluent_cloud_environment_name : confluent_environment.environment.display_name,
#     confluent_cloud_cluster_name : confluent_kafka_cluster.cluster.display_name,
#     confluent_cloud_environment_resource_name : confluent_environment.environment.resource_name
#   }
#   sensitive = true
# }
