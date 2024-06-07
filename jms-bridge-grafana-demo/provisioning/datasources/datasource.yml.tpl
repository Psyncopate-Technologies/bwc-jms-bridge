apiVersion: 1
datasources:
  - name: ksqlDB
    type: confluent-ksqlDB
    orgId: 1
    isDefault: true
    jsonData:
      applicationEndpoint: KSQL_ENDPOINT
    secureJsonData:
      apiKey: KSQL_API_KEY
      apiSecret: KSQL_API_SECRET
