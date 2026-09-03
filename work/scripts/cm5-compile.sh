#!/bin/bash

export MACHINE=raspberrypi5

RECIPE_NAME=core-image-minimal

OUTPUT_FILE=./tmp/deploy/images/raspberrypi5/core-image-minimal-raspberrypi5.rootfs.rpi-sdimg
DEPLOY_DIR=/tmp/deploy

DATE_SUFFIX=$(date +%Y%m%d-%H%M%S)
DEPLOY_FILENAME=${MACHINE}_${DATE_SUFFIX}.img
DEPLOY_FILE=${DEPLOY_DIR}/${DEPLOY_FILENAME}
DEPLOY_GENERIC_FILE=${DEPLOY_DIR}/last.img


if ! bitbake -c cleansstate "$RECIPE_NAME"; then
  echo "ERROR: Unable to clear sstate of ${RECIPE_NAME}. See above."
  exit 1
fi

if bitbake "$RECIPE_NAME"; then
  cp "${OUTPUT_FILE}" "${DEPLOY_FILE}"
  cp "${OUTPUT_FILE}" "${DEPLOY_GENERIC_FILE}"
  echo "==============================================================================================================="
  echo -e "\t\033[1m▶️ Generated image:           ${DEPLOY_FILE}\033[0m"
  echo -e "\t\033[1m▶️ Generated image (generic): ${DEPLOY_GENERIC_FILE}\033[0m"
  echo "==============================================================================================================="
else
  echo "ERROR : Unable to compile yocto project. See above."
  exit 2
fi