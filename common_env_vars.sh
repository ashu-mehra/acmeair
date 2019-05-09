#!/bin/bash

APP_DOCKER_IMAGE="ashumehra/acmeair-monolithic:latest"
APP_CR_DOCKER_IMAGE="ashumehra/acmeair-cr-monolithic:latest"

# Add application specific env variables here
DOCKER_NETWORK="acmeair-net"
MONGO_DB_IMAGE="mongo:latest"
MONGO_DB_CONTAINER="acmeair-db"
ACMEAIR_CONTAINER="acmeair-server"

