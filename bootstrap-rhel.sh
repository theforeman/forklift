
usage(){
  echo "Usage: <RH Portal Username> <RH Portal Password> <poolid>"
}

USERNAME=$1
PASSWORD=$2
POOLID=$3

if [ -z $USERNAME ]
then
  usage
  exit 1
fi

if [ -z $PASSWORD ]
then
  usage
  exit 2
fi

if [ -z $POOLID ]
then
  usage
  exit 3
fi


subscription-manager register --force --username=$USERNAME --password=$PASSWORD
subscription-manager subscribe --pool=$POOLID

# Do the actual install
./_repos_install.sh
