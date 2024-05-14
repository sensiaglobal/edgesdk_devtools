#!/bin/bash
#THIS IS A AUTOMATION SCRIPT, IS IS NOT RECOMMENDED TO RUN THIS DIRECTLY UNLESS YOU ARE A MACHINE

DEVICE_TYPE="hcc2-sensia"
#$1 is the tarball of the files (DO NOT INCLUDE FULL path), $2 is the path, $3 is a optional identifier, otherwise it will be the script name minus extension
#create with tar -cf my_directory.tar -C my_directory .

if [ -z "$3" ]; then
    ID="${1%%.*}"
else
    ID="$3"
fi

echo "$2" > ./dest_dir
cp "$1" ./update.tar

MENDERFILENAME="$ID".mender

MENDER_ARGS="--compression lzma -t $DEVICE_TYPE -o $MENDERFILENAME -T directory -n $ID"
if [ -n "${PRIVATE_LOCAL_KEY_PATH}" ]; then
    MENDER_ARGS+=" --key ${PRIVATE_LOCAL_KEY_PATH}"
# else
#     if [ -n "${PRIVATE_LOCAL_KEY_BASE64}" ]; then
#         MENDER_ARGS+=" --key <(printf ''%s\n'' "$PRIVATE_LOCAL_KEY_BASE64" | base64 -d)"
#     fi
fi
if [ -n "${MENDER_SOFTWARE_NAME}" ]; then
    MENDER_ARGS+=" --software-name ${MENDER_SOFTWARE_NAME}"
fi
if [ -n "${MENDER_SOFTWARE_VERSION}" ]; then
    MENDER_ARGS+=" --software-version ${MENDER_SOFTWARE_VERSION}"
fi
mender-artifact write module-image ${MENDER_ARGS} -f "update.tar" -f "dest_dir"

rm ./dest_dir
rm ./update.tar