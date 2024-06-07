# ksqlDB Data Source Plugin for Grafana

A data source plugin for streaming data from ksqlDB to Grafana

![Grafanaksqldbplugin](https://user-images.githubusercontent.com/40263561/161767246-0009d098-91bf-4019-93b9-1bc9bef638dd.gif)

## Getting Started

Make sure you have the necessary prerequisites installed:

* [docker](https://docs.docker.com/get-docker/)
* [docker-compose](https://docs.docker.com/compose/install/)
* [Go](https://go.dev/doc/install)
* [mage](https://magefile.org/)
* [NodeJS](https://nodejs.org/en/)
* [yarn](https://classic.yarnpkg.com/lang/en/docs/install/)

Please note you need to use one of the following versions for node:
* `````>18.14.1`````

### Building the plugin

To use the plugin you'll first have to build it. From the root folder of the project run the following commands

```
npx @grafana/toolkit before yarn install
yarn install
yarn build
go get -u github.com/grafana/grafana-plugin-sdk-go
go mod tidy
mage -v
```

### Running the Plugin Demo

Before you can run the demo you'll need a Confluent Cloud instance, a Schema Registry instance and a ksqlDB Application up and running.

Follow these steps to setup the required Confluent Cloud and ksqlDB artifacts.

* Create a topic called "trades"
* Create a Datagen Source connector
  * Choose the "Stock Trades" template
  * Select Avro as the "Output Kafka record value format"
* Run the following in the ksqlDB App Editor

```
CREATE STREAM IF NOT EXISTS trades WITH (KAFKA_TOPIC='trades', VALUE_FORMAT='AVRO');

CREATE TABLE IF NOT EXISTS trades_tbl_last_5mins WITH (KAFKA_TOPIC='trades_tbl', VALUE_FORMAT='AVRO') AS
    SELECT
        side,
        MIN(QUANTITY*PRICE) AS MIN_TRADE_VALUE,
        MAX(QUANTITY*PRICE) AS MAX_TRADE_VALUE,
        AVG(QUANTITY*PRICE) AS AVG_TRADE_VALUE
    FROM trades
    WINDOW TUMBLING (SIZE 30 SECONDS)
    GROUP BY side;
```

* Rename  the following file from `./docker/provisioning/datasources/datasource.yaml.example` to `./docker/provisioning/datasources/datasource.yaml`

* Edit `./docker/provisioning/datasources/datasource.yaml` and update the following values:
  * ksqlDB Application endpoint
  * API Key
  * API Secret

* Start the docker container
```
cd docker
docker-compose up
```
* Navigate to [http://localhost:3000](http://localhost:3000) in your browser
* Click the search icon in the left hand navigation bar
* Click the "Confluent" Folder
* Click the "TRADES" Dashboard
* You should now see data streaming in from ksqlDB
