package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/joho/godotenv"
)

type ksqlPayload struct {
	KSQL              string                 `json:"ksql"`
	StreamsProperties map[string]interface{} `json:"streamsProperties"`
}

// Struct returning the cause of a failed statement execution.
type ksqlErrorResponse struct {
	Message string `json:"message"`
}

func main() {
	err := godotenv.Load()

	ksqlEndpoint := os.Getenv("KSQL_ENDPOINT")
	ksqlKey := os.Getenv("KSQL_API_KEY")
	ksqlSecret := os.Getenv("KSQL_API_SECRET")

	// Need to unmarshal the KSQL statement list to a slice before we can execute them.
	var ksqlStatements []string
	fmt.Printf("KSQL_STATEMENTS: %s", os.Getenv("KSQL_STATEMENTS"))
	err = json.Unmarshal([]byte(os.Getenv("KSQL_STATEMENTS")), &ksqlStatements)
	if err != nil {
		log.Fatalf("Error parsing KSQL statements: %s", err)
	}

	for statement := range ksqlStatements {
		err = executeKSQL(ksqlEndpoint, ksqlKey, ksqlSecret, ksqlStatements[statement])

		if err != nil {
			log.Fatalf("Error executing KSQL statement: %s \n\nKSQL Statement: %s", err, ksqlStatements[statement])
		}
	}

	fmt.Printf("Executed %d KSQL statements succesfully", len(ksqlStatements))
}


func executeKSQL(endpoint string, key string, secret string, statement string) error {
	payload := ksqlPayload{
		KSQL:              statement,
		StreamsProperties: map[string]interface{}{},
	}

	payloadBytes, err := json.Marshal(payload)
	if err != nil {
		return err
	}

	req, err := http.NewRequest("POST", endpoint + "/ksql", bytes.NewBuffer(payloadBytes))
	if err != nil {
		return err
	}

	req.Header.Set("Content-Type", "application/vnd.ksql.v1+json; charset=utf-8")
	req.SetBasicAuth(key, secret)

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	// Return the exact cause of the failed KSQL statement.
	if (resp.StatusCode != http.StatusOK) {
		bodyBytes, err := io.ReadAll(resp.Body)
		if err != nil {
			return err
		}

		var errorMsg ksqlErrorResponse
		err = json.Unmarshal(bodyBytes, &errorMsg)
		if err != nil {
			return err
		}

		if (strings.Contains(errorMsg.Message, "same name already exists")) {
			fmt.Println("The stream/table already exists. Skipping KSQL statement.")
			return nil
		} else {
			return fmt.Errorf(errorMsg.Message)
		}
	}

	return nil
}
