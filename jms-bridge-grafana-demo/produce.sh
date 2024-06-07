#!/usr/bin/env sh

echo "[+] Producing messages to JMS Bridge every 2 seconds"
docker compose -p psyncopate-jms -f docker-compose.java.yml run --rm producer java -jar jms-mutator-1.0-SNAPSHOT.jar ./psy_travelers.txt 2000
