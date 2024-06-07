terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.76.0"
    }
  }
}

resource "random_string" "suffix" {
  length  = 4
  special = false
  numeric = false
  upper   = false
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

resource "confluent_environment" "environment" {
  display_name = var.confluent_cloud_environment_name

  stream_governance {
    package = "ESSENTIALS"
  }
}

resource "confluent_kafka_cluster" "cluster" {
  display_name = var.confluent_cloud_cluster_name
  availability = "SINGLE_ZONE"
  cloud        = var.confluent_cloud_provider
  region       = var.confluent_cloud_region


  // Dynamic block to determine what cluster config should be applied depending
  // on cluster type.
  dynamic "basic" {
    for_each = var.confluent_cloud_cluster_type == "basic" ? [1] : []

    content {}
  }

  dynamic "standard" {
    for_each = var.confluent_cloud_cluster_type == "standard" ? [1] : []

    content {}
  }

  dynamic "dedicated" {
    for_each = var.confluent_cloud_cluster_type == "dedicated" ? [1] : []

    content {
      cku = 1
    }
  }

  environment {
    id = confluent_environment.environment.id
  }
}

data "confluent_schema_registry_cluster" "pid_schema_registry" {
  environment {
    id = confluent_environment.environment.id
  }

  depends_on = [confluent_kafka_topic.cluster-topic]
}

resource "confluent_api_key" "env-manager-schema-registry-api-key" {
  display_name = "env-manager-schema-registry-api-key"
  description  = "Schema Registry API Key that is owned by 'env-manager' service account"

  owner {
    id          = confluent_service_account.app-manager.id
    api_version = confluent_service_account.app-manager.api_version
    kind        = confluent_service_account.app-manager.kind
  }

  managed_resource {
    id          = data.confluent_schema_registry_cluster.pid_schema_registry.id
    api_version = data.confluent_schema_registry_cluster.pid_schema_registry.api_version
    kind        = data.confluent_schema_registry_cluster.pid_schema_registry.kind

    environment {
      id = confluent_environment.environment.id
    }
  }
}

resource "confluent_role_binding" "subject-resource-owner" {
  principal   = "User:${confluent_service_account.app-manager.id}"
  role_name   = "ResourceOwner"
  crn_pattern = "${data.confluent_schema_registry_cluster.pid_schema_registry.resource_name}/subject=*"
}

resource "confluent_kafka_topic" "cluster-topic" {
  count = length(var.confluent_cloud_topic_names)

  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }

  topic_name       = trimspace(var.confluent_cloud_topic_names[count.index])
  partitions_count = 1
  rest_endpoint    = confluent_kafka_cluster.cluster.rest_endpoint

  config = {
    "cleanup.policy"    = "delete"
    "max.message.bytes" = "2097164"
    "retention.ms"      = "604800000"
  }

  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_service_account" "app-manager" {
  display_name = "app-manager-pid-${random_string.suffix.result}"
  description  = "Service account to manage PID Deployable Kafka cluster"
}

resource "confluent_role_binding" "app-manager-kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.app-manager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.cluster.rbac_crn
}

resource "confluent_kafka_acl" "app-manager-create-on-cluster" {
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }

  resource_type = "CLUSTER"
  resource_name = "kafka-cluster"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-manager.id}"
  host          = "*"
  operation     = "CREATE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.cluster.rest_endpoint

  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-manager-describe-on-cluster" {
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }

  resource_type = "CLUSTER"
  resource_name = "kafka-cluster"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-manager.id}"
  host          = "*"
  operation     = "DESCRIBE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.cluster.rest_endpoint

  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-manager-read-all-consumer-groups" {
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }

  resource_type = "GROUP"
  resource_name = "*"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.app-manager.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.cluster.rest_endpoint

  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_api_key" "app-manager-kafka-api-key" {
  display_name = "app-manager-pid-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-manager-pid' service account"
  owner {
    id          = confluent_service_account.app-manager.id
    api_version = confluent_service_account.app-manager.api_version
    kind        = confluent_service_account.app-manager.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.cluster.id
    api_version = confluent_kafka_cluster.cluster.api_version
    kind        = confluent_kafka_cluster.cluster.kind

    environment {
      id = confluent_environment.environment.id
    }
  }

  depends_on = [
    confluent_role_binding.app-manager-kafka-cluster-admin
  ]
}


# KSQL Service Account
resource "confluent_service_account" "app-ksql" {
  display_name = "app-ksql-${random_string.suffix.result}"
  description  = "Service account to manage ksqlDB cluster"
}

resource "confluent_role_binding" "app-ksql-kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.app-ksql.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.cluster.rbac_crn
}

resource "confluent_role_binding" "app-ksql-schema-registry-resource-owner" {
  principal   = "User:${confluent_service_account.app-ksql.id}"
  role_name   = "ResourceOwner"
  crn_pattern = format("%s/%s", data.confluent_schema_registry_cluster.pid_schema_registry.resource_name, "subject=*")
}

# ksqlDB
resource "confluent_ksql_cluster" "ksql-cluster" {
  display_name = "grafana-ksql"
  csu          = 1

  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }

  credential_identity {
    id = confluent_service_account.app-ksql.id
  }

  environment {
    id = confluent_environment.environment.id
  }
}

resource "confluent_api_key" "ksqldb-api-key" {
  display_name = "ksqldb-api-key"
  description  = "KsqlDB API Key that is owned by 'app-manager' service account"

  owner {
    id          = confluent_service_account.app-ksql.id
    api_version = confluent_service_account.app-ksql.api_version
    kind        = confluent_service_account.app-ksql.kind
  }

  managed_resource {
    id          = confluent_ksql_cluster.ksql-cluster.id
    api_version = confluent_ksql_cluster.ksql-cluster.api_version
    kind        = confluent_ksql_cluster.ksql-cluster.kind

    environment {
      id = confluent_environment.environment.id
    }
  }
}

