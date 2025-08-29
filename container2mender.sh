#!/bin/bash
#THIS IS A AUTOMATION SCRIPT, IS IS NOT RECOMMENDED TO RUN THIS DIRECTLY UNLESS YOU ARE A MACHINE

DEVICE_TYPE="hcc2-sensia"

march_args="--platform linux/amd64"
if [ -n "${MARH_ARGS_OVERRIDE}" ]; then
    march_args="${MARH_ARGS_OVERRIDE}"
fi

# Get pigz, fallback to gzip
if [ -x /usr/bin/pigz ]; then
    COMPRESS="/usr/bin/pigz"
else
    COMPRESS="/bin/gzip"
fi

if $LOCAL_BUILD; then
    PRESERVE_IMAGES=true
fi
SAVECOMMAND=""
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
    if [[ -z "$LOCAL_BUILD" ]]; then
        docker pull ${march_args} "$CONTAINER"
    fi

    SAVECOMMAND="$SAVECOMMAND $CONTAINER"
    if [[ -z "$PRESERVE_IMAGES" ]]; then
        docker image rm ${march_args} "$CONTAINER"
    fi
    IDLIST="$IDLIST""$ID""_"
    done <<< "$CONTAINERS"
    FILELIST="$FILELIST -f $var"
done
TARGZFILENAME="combined.tar.gz"
FILELIST="$FILELIST -f $TARGZFILENAME"
echo "$SAVECOMMAND"
bash -c "docker save ${march_args} $SAVECOMMAND | $COMPRESS -9 > combined.tar.gz"

# echo "$IDLIST"
# echo "$FILELIST"
FILENAME=collection

MENDER_ARGS="-t $DEVICE_TYPE -T container-compose"
if [ -n "${MENDER_ARTIFACT_NAME}" ]; then
    MENDER_ARGS+=" -n ${MENDER_ARTIFACT_NAME}"
else
    MENDER_ARGS+=" -n ${IDLIST}"
fi
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

if [ -n "${MENDER_SOFTWARE_FILESYSTEM}" ]; then
    MENDER_ARGS+=" --software-filesystem ${MENDER_SOFTWARE_FILESYSTEM}"
fi
if [ -n "${MENDER_SOFTWARE_NAME}" ]; then
    MENDER_ARGS+=" --software-name ${MENDER_SOFTWARE_NAME}"
fi
if [ -n "${MENDER_SOFTWARE_VERSION}" ]; then
    MENDER_ARGS+=" --software-version ${MENDER_SOFTWARE_VERSION}"
fi
# The MENDER_SOFTWARE_PROVIDES will be a long string, with KEY:VALUE pairs, separated by SEMICOLON
# Idea taken from JFrog File Specs Properties approach.
# Ex. MENDER_SOFTWARE_FILESYSTEM.unity_top.version:1.5.98-dev.20240814.4;MENDER_SOFTWARE_FILESYSTEM.hcc2-ldap-base.version:2.6.6-r1169;...
if [ -n "${MENDER_SOFTWARE_PROVIDES}" ]; then
  provides=( $(echo ${MENDER_SOFTWARE_PROVIDES} | tr ';' ' ') )
  for keypair in ${provides[*]}; do
      MENDER_ARGS+=" -p ${keypair}"
  done
fi
if [ -n "${MENDER_CLEARS_PROVIDES}" ]; then
    MENDER_ARGS+=" --no-default-clears-provides"
    provides=( $(echo ${MENDER_CLEARS_PROVIDES} | tr ';' ' ') )
    for keypair in ${provides[*]}; do
        MENDER_ARGS+=" --clears-provides ${keypair}"
    done
fi
if [ -n "${MENDER_SS_PATH}" ]; then
    for SCRIPT in "$MENDER_SS_PATH"/* ; do
        MENDER_ARGS+=" --script $(readlink -f $SCRIPT)"
        echo "INCLUDED ${SCRIPT}"
    done
fi
 MENDER_ARGS+=" -o $FILENAME.mender"
[ $VERBOSE ] && printf "mender arguments: ${MENDER_ARGS}\n"
[ $VERBOSE ] && printf "mender file list: ${FILELIST}\n"
mender-artifact write module-image ${MENDER_ARGS} $FILELIST
