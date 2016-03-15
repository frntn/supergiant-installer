#!/usr/bin/env bash


downloadBin(){
  distro = $1
  echo "Downloading ${distro} bin.."
  ## error check and dump with exit code if fail.
}


## Check for cloud creds (prob will do aws by default)

if [[ -z "$AWS_SECRET" ] && [ -z "$AWS_KEY"]; then
  echo -n "Enter your aws secret key [ENTER]: "
  read -n 1 AWS_SECRET
  echo

  echo -n "Enter your aws user key [ENTER]: "
  read -n 1 AWS_KEY
  echo
fi

## Download sg-cli bin
case $( uname -s ) in
linux) downloadBin linux;;
darwin) downloadBin darwin ;;
*)     echo "OS not supported";;
esac

## supergiant == the name of the cluster we will spin up.
## use sg spacetime to create new kube record
#sg spacetime expand supergiant

## commit record to production.
#sg spacetime commit -y

## sg will return kubernetes information
## Now we deploy the supergiant core to our cluster.
# sg core install supergiant

## sg will return information about the supergiant installation including URL to UI and API info.
## Based on this info we can open a browser or whatevr we want. 
