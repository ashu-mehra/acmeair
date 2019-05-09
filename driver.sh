#!/bin/bash

source ./util.sh
source ./common_env_vars.sh

CHECKPOINT_SUCCESS_MSG="Checkpoint success"
CR_LOG_DIR="/root/appcr/cr_logs"
DUMP_LOG_FILE="dump.log"
tmp_image_name="${APP_DOCKER_IMAGE}-tmp"
container_name="app-container-for-cr"

build_docker_image() {
	echo "CMD: docker build -q -t "${tmp_image_name}" -f Dockerfile ."
	docker build -t "${tmp_image_name}" -f Dockerfile .

	check_image_exists "${tmp_image_name}"
	if [ $? -eq 1 ]; then
		echo "ERROR: Building temporary image failed"
		exit 1
	fi
}

run_container() {
	./run_app_docker_image.sh "${tmp_image_name}" "${container_name}"

	check_container_running "${tmp_image_name}" "${container_name}"
	if [ $? -eq 1 ]; then
		echo "ERROR: Did not find container "${container_name}""
		exit 1
	fi
}

wait_for_checkpoint() {
        local retry_counter=0
        while true;
        do
                echo "INFO: Waiting for checkpoint (retry count: "${retry_counter}")"

		check_container_running "${tmp_image_name}" "${container_name}"
		if [ $? -eq 1 ]; then
			echo "ERROR: container has stopped"
			exit 1
		fi
                docker logs --tail=1 "${container_name}" | grep "${CHECKPOINT_SUCCESS_MSG}" &> /dev/null

                if [ $? -eq 0 ]; then
                        echo "INFO: Checkpoint done."
                        break
                fi
                if [ "${retry_counter}" -eq 20 ]; then
                        echo "ERROR: Checkpoint timed out"
                        exit 1
                fi
                retry_counter=$(($retry_counter+1))
                sleep 5s
        done
}

commit_container() {
	docker cp "${container_name}":"${CR_LOG_DIR}"/"${DUMP_LOG_FILE}" .

	echo "CMD: docker commit ${container_name} ${APP_CR_DOCKER_IMAGE}"

	docker commit "${container_name}" "${APP_CR_DOCKER_IMAGE}"

	echo "INFO: New docker image with checkpoint created"

	echo "INFO: Stopping the container"

	docker kill -s SIGUSR1 "${container_name}" &> /dev/null

	sleep 5s

	docker stop "${container_name}" &> /dev/null

	docker rm "${container_name}" &> /dev/null

	echo "Cleaning temporary container image"
	docker rmi "${tmp_image_name}"
}

upload_image() {
	echo "Uploading image to dockerhub..."
	echo "CMD: docker push ${APP_CR_DOCKER_IMAGE}"
	docker push ${APP_CR_DOCKER_IMAGE}
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

build_docker_image
run_container
wait_for_checkpoint
commit_container

if [ "${upload_image}" -eq 1 ]; then
	upload_image
fi
