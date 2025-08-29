# Overview

This repo contains tools for building applications which run in the HCC2 environment.  Apps are loaded into the HCC2 as .mender files which are signed with a private key.  The HCC2 will automatically accept .mender files with official signatures, this repo contains tooling to allow local test signatures to be applied to mender files and accepted on a HCC2 used for testing.

# Local Build Quick Start

It is recommended to make this repo a submodule of your application.  
It should be possible to run these steps from your build location (in or out of tree)  
This process presumes you have root access to the HCC2 you are loading test containers on, this is necessary to load the key to accept your local signature.

## Initial setup 

### Prerequisites  

You must have mender-artifact 3.10.2 or later installed.  The latest will be available here: https://docs.mender.io/downloads  
The 3.10.2 version (subject to change) is here: https://downloads.mender.io/mender-artifact/3.10.2/linux/mender-artifact  
If you have a older version, you will get errors like `WriteArtifact: writer: cannot sign artifact: signer: unsupported private key type or error occured...`  

 
### Setup  
 
These steps only need to be run once when setting up your local dev environment.  A developer license from Sensia is required, which allows software signed with the developer private key to be loaded.  
- apply the 'developer license' to your HCC2 using unity  
- Optionally re-create a menderkeys subfolder in the root of your project and place the provided private key file there. NOTE that this will overwrite the supplied developer key  
- create a docker compose .yml file which conforms to the HCC2 requirements (insert reference) where the `image: ` reference points to the local container which is the output of your containerized application build process.  

#### Root user setup

This only applies to users with root access on their device, which is not needed to load applications in general.
- From the root of your repo, run `gen_local_keys.sh`  
- add the menderkeys folder to your .gitignore  
- using SFTP/scp (or the uploadkey.sh script), copy the generated file `menderkeys/localkeys-public.key` to your HCC2 in the location `/var/volatile/transient_keys/` and chagne the extension to .pem  

## Build

Follow this step each time your application container is built and ready to be deployed.  Optionally make it a final step in your build process!  
- Once your application container is built and ready to be deployed, run `package_app.sh my_app_composefile.yml` where my_app_composefile.yml is replaced with the path of your app specific .yml file.  


# Repo contents
See the readme of the individual scripts for additional details and options.  
- container2mender.sh and script2mender.sh : support scripts used for building locally or in a pipeline, not recommended to be run directly.  
- gen_local_keys.sh : tool for generating signing keys for your mender artifact.  Only required when generating a vendor key to be approved by Sensia, or when using temporary keys with root access.  
- package_app.sh : tool for taking a .yml file describing a docker container to be run in the HCC2 and creating a signed mender file  
- /test/test.yml : a example .yml file which can be passed to package_app.sh to package the docker hub hosted hello-world container to be run on your HCC2.  Useful for testing the build tools and that your key was loaded properly.  