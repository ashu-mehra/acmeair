#!/bin/bash

source ./util.sh
source ./common_env_vars.sh

ACMEAIR_ROOT_DIR=`pwd`

function create_acmeair_server_image() {
	echo "INFO: Building acmeair"
	./gradlew build
	if [ $? -eq 0 ]; then
		echo "INFO: Building acmeair - Done"
	else
		echo "ERROR: Buildling acmeair - Failed"
		exit 1
	fi

	echo "INFO: Building acmeair docker image"
	pushd "${ACMEAIR_ROOT_DIR}"/acmeair-webapp &> /dev/null
	echo "CMD: docker build -t "${APP_DOCKER_IMAGE}" -f "${ACMEAIR_ROOT_DIR}"/acmeair-webapp/Dockerfile ."

	docker build -t "${APP_DOCKER_IMAGE}" -f "${ACMEAIR_ROOT_DIR}"/acmeair-webapp/Dockerfile .

	popd &> /dev/null
	if [ $? -eq 0 ]; then
		# Verify the image is created

		check_image_exists "${APP_DOCKER_IMAGE}"

		if [ $? -eq 0 ]; then
			echo "INFO: Building acmeair docker image - Done"
		else
			echo "ERROR: Building acmeair docker image completed but failed to find the docker image"
			exit 1;
		fi
	else
		echo "ERROR: Building acmeair docker image - Failed"
		exit 1
	fi
}

upload_image() {
	echo "Uploading image to dockerhub..."
	echo "CMD: docker push ${APP_DOCKER_IMAGE}"
	docker push ${APP_DOCKER_IMAGE}
	echo "Uploading done"
}

upload_image=0
for i in "$@"; do
        case $i in
		-u )
			upload_image=1
			;;
	esac
done

create_acmeair_server_image
if [ "${upload_image}" -eq 1 ]; then
	upload_image
fi
