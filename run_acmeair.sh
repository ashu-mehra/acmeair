#!/bin/bash

source ./common_env_vars.sh
source ./util.sh

function cleanup() {
	echo "INFO: Cleanup - Started"
	echo "INFO: Cleaning running containers"
	echo "CMD: docker stop ${app_container} ${MONGO_DB_CONTAINER} &> /dev/null"

	docker stop "${app_container}" "${MONGO_DB_CONTAINER}" &> /dev/null

	echo "CMD: docker rm "${app_container}" "${MONGO_DB_CONTAINER}" &> /dev/null"

	docker rm "${MONGO_DB_CONTAINER}" &> /dev/null
	docker rm "${app_container}" &> /dev/null

	echo "INFO: Cleaning running containers - Done"
	echo "INFO: Removing docker network \"${DOCKER_NETWORK}\""
	echo "CMD: docker network rm "${DOCKER_NETWORK}" &> /dev/null"

	docker network rm "${DOCKER_NETWORK}" &> /dev/null

	echo "INFO: Removing docker network - Done"

	echo "INFO: Cleanup - Done"
}

function setup_docker_network() { 
        declare network 
        network=`docker network ls | grep "${DOCKER_NETWORK}"` 
        if [ $? -eq 0 ]; then 
                # network already exists - check network type and subnet 
                declare nettype=`echo "${network}" | awk '{ print $3 }'` 
                if [[ $nettype =~ "bridge" ]]; then 
                        echo "INFO: Network \"${DOCKER_NETWORK}\" is of type \"${nettype}\"" 
                else 
                        echo "INFO: Network \"${DOCKER_NETWORK}\" is of type \"${nettype}\", expected \"bridge\" type" 
                        exit 1 
                fi 
        else 
                echo "INFO: Creating docker network \"${DOCKER_NETWORK}\" of type \"bridge\"" 
                echo "CMD: docker network create --driver bridge --subnet="172.28.0.0/16" ${DOCKER_NETWORK}" 
 
                docker network create --driver bridge --subnet='172.28.0.0/16' "${DOCKER_NETWORK}" 
 
                echo "INFO: Creating docker network \"${DOCKER_NETWORK}\" of type \"bridge\" - Done" 
        fi 
}


app_image=$1
app_container=$2

if [ -z "${app_image}" ]; then
	app_image="${APP_DOCKER_IMAGE}"
fi
if [ -z "${app_container}" ]; then
	app_container="${ACMEAIR_CONTAINER}"
fi
cleanup
setup_docker_network
if [ $? -eq 1 ]; then
	echo "Error: Failed to setup docker network"
	exit 1
fi

check_container_running "${MONGO_DB_IMAGE}" "${MONGO_DB_CONTAINER}"

if [ $? -eq 1 ]; then
	echo "INFO: Starting mongo db and acmeair server containers"
	echo "CMD: docker run --name=${MONGO_DB_CONTAINER} --network=${DOCKER_NETWORK} --ip='172.28.0.2' -d ${MONGO_DB_IMAGE}"

	mongo_db=`docker run --name="${MONGO_DB_CONTAINER}" --network="${DOCKER_NETWORK}" --ip='172.28.0.2' -d "${MONGO_DB_IMAGE}"`

	if [ $? -ne 0 ]; then
		echo "ERROR: Failed to start mongo db container"
		exit 1
	fi

	echo "INFO: Mongo db container id ${mongo_db}"
else
	echo "INFO: Mongo db container is already running"
fi

capabilities="--cap-add DAC_OVERRIDE --cap-add CHOWN --cap-add SETPCAP --cap-add SETGID --cap-add AUDIT_CONTROL --cap-add DAC_READ_SEARCH --cap-add NET_ADMIN --cap-add SYS_ADMIN --cap-add SYS_CHROOT --cap-add SYS_PTRACE --cap-add FOWNER --cap-add KILL --cap-add FSETID --cap-add SYS_RESOURCE --cap-add SETUID"
echo "CMD: docker run --name="${app_container}" "${capabilities}" --security-opt apparmor=unconfined --security-opt seccomp=unconfined -d -p 80:80 --network="${DOCKER_NETWORK}" --ip='172.28.0.3' -e MONGO_HOST="${MONGO_DB_CONTAINER}" "${app_image}""

acmeair_server=`docker run --name=${app_container} ${capabilities} --security-opt apparmor=unconfined --security-opt seccomp=unconfined -d -p 80:80 --network=${DOCKER_NETWORK} --ip='172.28.0.3' -e MONGO_HOST=${MONGO_DB_CONTAINER} ${app_image}`

if [ $? -ne 0 ]; then
	echo "ERROR: Failed to start acmeair server container"
	exit 1
fi

echo "INFO: Acmeair server container id ${acmeair_server}"
echo "INFO: Starting mongo db and acmeair server containers - Done"

