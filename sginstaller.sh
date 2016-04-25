#!/usr/bin/env bash

DOWNLOAD_SUCCESS=false

terraFail() {
  printf "\n Terraform install failed.\n"
  printf "\n Terraform is required for this installer.\n"
  printf " Terraform can be downloaded from: https://www.terraform.io/downloads.html\n"
  printf " Terrafom can also be installed via the Homebrew, or Linux package installer.\n"
  printf " If downloading from the Hashicorp webpage, ensure the executable files are in\n your os \$PATH so the supergiant cli can find them.\n\n"
  exit 5
}

installPackage(){
  YUM_CMD=$(which yum)
  APT_GET_CMD=$(which apt-get)
  BREW_CMD=$(which brew)
  VERSION=0.6.14
  MAC_LOCATION="https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_darwin_amd64.zip"
  LINUX_LOCATION="https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_linux_amd64.zip"

  if [[ ! -z $YUM_CMD ]]; then
     yum -y install $1
     if [ $? -ne 0 ]; then
       terraFail
     fi
  elif [[ ! -z $APT_GET_CMD ]]; then
     sudo apt-get update
     sudo apt-get -y install $1
     if [ $? -ne 0 ]; then
       sudo apt-get -y install unzip
       sudo curl -L $LINUX_LOCATION --output /tmp/terraform.zip
       sudo unzip -o /tmp/terraform.zip -d /usr/local/bin
         if [ $? -ne 0 ]; then
           terraFail
         fi
     fi
  elif [[ ! -z $BREW_CMD ]]; then
     brew install $1
     if [ $? -ne 0 ]; then
       echo "You may need to enter your admin password here..."
       sudo curl -L $MAC_LOCATION --output /tmp/terraform.zip
       sudo unzip -o /tmp/terraform.zip -d /usr/local/bin
         if [ $? -ne 0 ]; then
           terraFail
         fi
     fi
  fi
}

preCheck(){
  #check for curl
  if [ "$(type -t curl)" != "file" ]; then
    printf "\n Curl is required for this installer.\n\n"
    exit 5
  fi
  #check for terraform
  if [ "$(type -t terraform)" != "file" ]; then
    #we will try to install if we can.
    echo "Terraform is not installed. We will try to install it if we can."
    echo "Installing..."
    installPackage terraform
    echo "Success..."
  fi
}
downloadBin(){
  distro=$1
  if [ "$(type -t supergiant)" != "file" ]; then
    echo "Downloading ${distro} bin..."
    ## error check and dump with exit code if fail.
    bin=$(curl -s https://api.github.com/repos/supergiant/supergiant-cli/releases/latest | grep $distro | grep 386 | grep browser_download_url | head -n 1 | cut -d '"' -f 4)
    echo $bin
      if [ $distro == linux ]; then
        sudo curl -L $bin --output /usr/local/bin/supergiant
        sudo chmod 755 /usr/local/bin/supergiant
      else
        curl -L $bin --output /usr/local/bin/supergiant
        chmod 755 /usr/local/bin/supergiant
        if [ $? -ne 0 ]; then
          echo "You may need to enter your admin password here..."
          sudo curl -L $bin --output /usr/local/bin/supergiant
          sudo chmod 755 /usr/local/bin/supergiant
        fi
      fi
    if [ "$(type -t supergiant)" != "file" ]; then
      printf "\n Supergiant CLI Install Failed.\n\n"
      exit 5
    fi
    echo "Supergiant CLI Install success..."
fi
}


## Check for requirments.
preCheck
 #Download sg-cli bin
case $( uname -s ) in
Linux) downloadBin linux;;
Darwin) downloadBin darwin ;;
*)     printf "\n Unfortunately the  supergiant quick start script is only compatible with Linux, and Mac OS.\n More to come soon! Additional executables can be found on the supergiant repo, and may be considered experimental.\n https://github.com/supergiant/supergiant-cli/releases\n\n";;
esac

printf "\n\nGreat!! Supergiant CLI is now successfully installed on your computer.\n"
printf "Before we can launch your Supergiant cluster, we need to set up a few things.\n\n"

printf "In order to connect to your servers through ssh, we will need to be sure you have a key.\n"
printf "Even if you do not plan to ssh into your servers, they key needs to exist or else the install will fail.\n"
printf "1. Open your AWS Console, and go to the EC2 service.\n"
printf "2. Under the \"NETWORK & SECURITY\" section in the left hand column, select \"Key Pairs\"\n"
printf "3. Select \"Create Key Pair\", and enter \"kube-admin\" for the keypair name.\n\n"

printf "Please type \"YES\" when You have completed these steps to continue: "
read input
if [ $input != "YES" ]; then
  printf "Quiting...\n"
  exit 0
fi
printf "\nThen your all set! Save this keypair to your ~/.ssh directory for access to your cluster over ssh.\n\n"

printf "Now we need to configure your AWS Credentials into the Supergiant providers DB\n"
printf "This info is accessed by the CLI during the Kubernetes setup.\n\n"
printf "When setting up a new provider, use the \'supergiant create spacetime provider\' command.\n"
printf "You will be asked for AWS Access Key, and your AWS Secret Key.\n"
printf "The keys will need to have access to have the \"AdministratorAccess\" access policy attached.\n"
printf "More info here: http://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSGettingStartedGuide/AWSCredentials.html\n\n"
printf "Press Enter to continue..."
read
if [ $(supergiant get spacetime provider | grep -c supergiant-demo) -eq 0 ]; then
  supergiant create spacetime provider --name supergiant-demo --provider-service aws
else
  echo "Looks like your credentials are already installed..."
fi

printf "\n\nNow we can use the credentials you just setup to launch our first cluster.\n"
printf "Launching a new cluster can be done using \'supergiant create spacetime\'\n"
printf "You will be asked to provide the Username, and Password you would like to use with your cluster.\n"
printf "This can take some time to complete. So grab a cup of coffee and watch the magic.\n\n"
printf "Press Enter to continue... (There will be a lot of output, but that's just terraform doing it's thing...)"
read
if [ $(supergiant get spacetime | grep -c supergiant-demo) -eq 0 ]; then
  supergiant create spacetime --provider supergiant-demo --name supergiant
  supergiant create core
else
  echo "Looks like your cluster is already built or is building..."
  echo "You can check the status with \'supergiant get spacetime\'"
  echo "If your cluster reports as failed, you can retry the build with \'supergiant create spacetime --name supergiant --retry"
  exit 0
fi
supergiant list spacetime supergiant

printf "\n\n\nLooks like your cluster is built.\n"
printf "For more information on your cluster run, \'supergiant get spacetime\'"
