setenforce 0

if [ $1 ]
then
  cd $1
fi

./_repos_install.sh
