#!/bin/bash
#THIS IS A AUTOMATION SCRIPT, IS IS NOT RECOMMENDED TO RUN THIS DIRECTLY UNLESS YOU ARE A MACHINE

DEVICE_TYPE="hcc2-sensia"

# Get pigz, fallback to gzip
if [ -x /usr/bin/pigz ]; then
    COMPRESS="/usr/bin/pigz"
else
    COMPRESS="/bin/gzip"
fi

if $LOCAL_BUILD; then
    PRESERVE_IMAGES=true
fi

#supports a list of containers as the parameters
for var in "$@"; do
    #remove comments, then select what is after 'image:'
    CONTAINERS=$(sed -n '{s/#.*//};/image:/{s/.*image: *//;p}' "$var") 
    echo "$CONTAINERS"
    while IFS= read -r CONTAINER; do
    REPOSITORY="$(echo ${CONTAINER#sensia-} | cut -d\. -f1)"
    IMAGETAG="$(echo $CONTAINER | cut -d\/ -f 2-)"
    if [[ -z "$OVERRIDE_ID" ]]; then
        ID="$(echo $CONTAINER | sed -n --expression='{s/^[^\/]*//; {s#/##}; {s#/#_#g}; {s#:#_#g}; {s#\.#_#g} ;p}')"
    else
        ID="$OVERRIDE_ID"
    fi
    if [[ -z "$ID" ]]; then
        ID="Default"
    fi
    TARGZFILENAME="$ID".tar.gz
    echo "$TARGZFILENAME"
    if [[ -z "$LOCAL_BUILD" ]]; then
        docker pull "$CONTAINER"
    fi
    docker save "$CONTAINER" | $COMPRESS -9 > "$TARGZFILENAME"
    if [[ -z "$PRESERVE_IMAGES" ]]; then
        docker image rm "$CONTAINER"
    fi
    IDLIST="$IDLIST""$ID""_"
    FILELIST="$FILELIST -f $TARGZFILENAME"
    done <<< "$CONTAINERS"
    FILELIST="$FILELIST -f $var"
done
# echo "$IDLIST"
# echo "$FILELIST"
FILENAME=collection

MENDER_ARGS="-t $DEVICE_TYPE -T container-compose -n $IDLIST"
if [ -n "${PRIVATE_LOCAL_KEY_PATH}" ]; then
    MENDER_ARGS+=" -k ${PRIVATE_LOCAL_KEY_PATH}"
    FILENAME+="-signed-private"
# else
#     if [ -n "${PRIVATE_LOCAL_KEY_BASE64}" ]; then
#         MENDER_ARGS+=' -k <(printf ''%s\n'' "$PRIVATE_LOCAL_KEY_BASE64" | base64 -d)'
#         echo $KEYLOAD
#         FILENAME+="-signed-private"
#     fi
fi
if [ -n "${MENDER_SOFTWARE_NAME}" ]; then
    MENDER_ARGS+=" --software-name ${MENDER_SOFTWARE_NAME}"
fi
if [ -n "${MENDER_SOFTWARE_VERSION}" ]; then
    MENDER_ARGS+=" --software-version ${MENDER_SOFTWARE_VERSION}"
fi
 MENDER_ARGS+=" -o $FILENAME.mender"
[ $VERBOSE ] && printf "mender arguments: ${MENDER_ARGS}\n"
[ $VERBOSE ] && printf "mender file list: ${FILELIST}\n"
mender-artifact write module-image ${MENDER_ARGS} $FILELIST
