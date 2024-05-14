#!/bin/bash

show_help(){
    printf "\n Usage:  packageApp.sh [OPTIONS] filename \n"
    printf "\n A tool for packaging applications for use in the hcc2 \n"
    printf " If building with a pipeline and locally, it is recommended to have a version of the .yml file for each case. \n"
    printf " A signing key will automatically be applied if found in the subfolder menderkeys of the calling directory. \n"
    printf " Keys can also be applied using the options below which take precedence over the menderkeys folder\n"
    printf "\n filename - a docker compose .yml file appropriately formatted for use in the HCC2.\n"
    printf "\n Options: \n"
    printf " -v            Verbose output\n"
    printf " -k key.pem    Path to private key to sign the artifact with (see gen_local_keys.sh tool for more details)\n"
    printf " -b string     Base64 encoded private key to sign the artifact with (see gen_local_keys.sh tool for more details)\n"
}
while getopts "h?vk:b:" opt; do
  case "$opt" in
    h|\?)
      show_help
      exit 0
      ;;
    v)  VERBOSE=true
      ;;
    k)  export PRIVATE_LOCAL_KEY_PATH=$OPTARG
      ;;
    b)  export PRIVATE_LOCAL_KEY_BASE64=$OPTARG
      ;;
  esac
done
shift $(($OPTIND - 1));
YMLFILE=$1
if [[ -e "$YMLFILE" ]]; then
    [ $VERBOSE ] && printf "input file: $YMLFILE\n"
else
    printf "YML file not found, aborting\n"
    exit 0
fi

if [[ -z "$PRIVATE_LOCAL_KEY_PATH" ]] && [[ -z "$PRIVATE_LOCAL_KEY_BASE64" ]]; then
    if [[ -e "./menderkeys/localkeys-private.key" ]]; then
        export PRIVATE_LOCAL_KEY_PATH="./menderkeys/localkeys-private.key"
        [ $VERBOSE ] && printf "using private key found in ./menderkeys/localkeys-private.key\n"
    fi
fi

if hash mender-artifact 2>/dev/null; then
  [ $VERBOSE ] && printf "mender-artifact found\n"
else
  printf "mender-artifact not found, aborting.  Install from https://docs.mender.io/downloads\n"
  exit
fi
if hash docker 2>/dev/null; then
  [ $VERBOSE ] && printf "docker found\n"
else
  printf "docker not found, aborting.  Install from your package manager.\n"
  exit
fi

script_full_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
export LOCAL_BUILD=true
[ $VERBOSE ] && export VERBOSE
echo $script_full_path
$script_full_path/container2mender.sh "$YMLFILE"