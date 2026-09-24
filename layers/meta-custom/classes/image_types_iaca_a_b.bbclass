# Custom image type: iaca_a_b
#
# Purpose : Create IACA image with partition A/B support
# See : https://gitlab.iaca-electronique.com/linux/iaca-image-format-specifications
# Supported version : 2.x.x

IMAGE_CMD:iaca_a_b() {
  install -d ${WORKDIR}/iaca-assets

  IMAGE_DIR_FORMAT_PATH=${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.dir

  BOOT_TAR_GZ=${IMAGE_DIR_FORMAT_PATH}/boot.tar.gz
  ROOTFS_TAR_GZ=${IMAGE_DIR_FORMAT_PATH}/rootfs.tar.gz

  WORK_OUTPUT_DIR=${TMPDIR}/${IMAGE_NAME}_a_b.tmp

  FINAL_IMAGE_PATH=${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}_a_b.iaca

  mkdir "$WORK_OUTPUT_DIR"

  cp "$BOOT_TAR_GZ" "${WORK_OUTPUT_DIR}/0" || { echo "ERROR : Unable to copy boot."; exit 1; }
  cp "$ROOTFS_TAR_GZ" "${WORK_OUTPUT_DIR}/1" || { echo "ERROR : Unable to copy rootfs."; exit 2; }
  cp "${DEPLOY_DIR_IMAGE}/16GB_a_b.json" "${WORK_OUTPUT_DIR}/ifd.json" || { echo "ERROR : Unable to create ifd."; exit 3; }

  cd "${WORK_OUTPUT_DIR}"
  tar -cvf "${FINAL_IMAGE_PATH}" *  || { echo "ERROR : Unable to create archive."; exit 4; }

  ln -s "${FINAL_IMAGE_PATH}" "${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}_a_b.iaca"

  # Clear
  rm -fr "$WORK_OUTPUT_DIR"
}

IMAGE_TYPEDEP:iaca_a_b = "dir"

do_image_iaca[depends] += "iaca-assets:do_deploy"