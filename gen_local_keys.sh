#!/bin/bash
# This creates RSA 4096 (strongest supported RSA) Keypairs for Mender artifact signing
# https://www.openssl.org/docs/man1.1.1/man1/openssl-req.html

show_help(){
    printf "\n Usage:  gen_local_keys.sh [OPTIONS] \n"
    printf "\n A tool for creating local keys for installing test packages on the HCC2 \n"
    printf "\n Options: \n"
    printf " -v            Verbose output\n"
    printf " -f            Force generation of new keys if the ./menderkeys folder already exists \n"
}
while getopts "h?vf" opt; do
  case "$opt" in
    h|\?)
      show_help
      exit 0
      ;;
    v)  VERBOSE=true
      ;;
    f)  
      FORCE=true
      ;;
  esac
done
# shift $(($OPTIND - 1));



if [ ! -d menderkeys ] || [[ -n "$FORCE" ]]; then
  mkdir -pv menderkeys
  i=menderkeys/localkeys
  # Generate an RSA Key pair
  openssl genpkey -algorithm RSA -out ${i}-private.key -pkeyopt rsa_keygen_bits:4096
  openssl rsa -in ${i}-private.key -out ${i}-public.key -pubout
  # base64 -w 0 ${i}-private.key > ${i}-private-base64
  # base64 -w 0 ${i}-public.key > ${i}-public-base64
else
  printf "menderkeys folder exists, skipping.  use -f to force regeneration \n"
fi


