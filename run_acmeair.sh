#!/bin/bash

source ./common_env_vars.sh
source ./util.sh

cleanup() {
	echo "INFO: Cleanup - Started"
	echo "INFO: Cleaning running containers"

	cmd="docker stop "${app_container}""
	echo "CMD: ${cmd}"
	${cmd} &> /dev/null

	cmd="docker rm "${app_container}""
	echo "CMD: ${cmd}"
	${cmd} &> /dev/null

	echo "INFO: Cleanup - Done"
}

app_image=$1
app_container=$2

if [ -z "${app_image}" ]; then
	app_image="${APP_DOCKER_IMAGE}"
fi
if [ -z "${app_container}" ]; then
	app_container="${ACMEAIR_CONTAINER}"
fi

# remove existing containers and images if any
cleanup

# This is the list of additional capabilities required for using criu
capabilities="--cap-add AUDIT_CONTROL --cap-add DAC_READ_SEARCH --cap-add NET_ADMIN --cap-add SYS_ADMIN --cap-add SYS_PTRACE --cap-add SYS_RESOURCE"

cmd="docker run --name="${app_container}" "${capabilities}" --security-opt apparmor=unconfined --security-opt seccomp=unconfined -d -p 8080:8080 "${app_image}""
echo "CMD: ${cmd}"

acmeair_server=`${cmd}`

if [ $? -ne 0 ]; then
	echo "ERROR: Failed to start acmeair server container"
	exit 1
fi

echo "INFO: Acmeair server container id ${acmeair_server}"
echo "INFO: Starting acmeair server container - Done"

