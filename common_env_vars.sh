#!/bin/bash


CHECKPOINT_SUCCESS_MSG="Checkpoint success"
CHECKPOINT_FAILED_MSG="Checkpoint failed"

CR_LOG_DIR="/opt/appcr/cr_logs"
DUMP_LOG_FILE="dump.log"
RESTORE_LOG_FILE="restore.log"

APP_DOCKER_IMAGE="ashumehra/acmeair-monolithic:latest"
APP_CR_DOCKER_IMAGE="ashumehra/acmeair-cr-monolithic:latest"

# Add application specific env variables here
DOCKER_NETWORK="acmeair-net"
MONGO_DB_IMAGE="mongo:latest"
MONGO_DB_CONTAINER="acmeair-db"
ACMEAIR_CONTAINER="acmeair-server"
