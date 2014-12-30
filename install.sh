#!/usr/bin/env bash

## Shell script which installs $hostname dev enviroment as a vagrant/VirtualBox guest VM
## requires:
## - vagrant 1.6+
## - VirtualBox 4.3+

conf_d="./bootstrap.d"            # host configuration folder
hostname="localhost.local"				# VM hostname, must match config.vm.hostname in Vagrantfile
hostip="192.168.10.10"	  				# VM IP (private network), must match config.vm.network in Vagrantfile
localip="192.168.10.1"            # VM host IP (private network)


# adds dev server IP to host's hosts file if not yet here
if [ $(sudo egrep -i -c '^192\.168\.10\.10    localhost\.local$' /etc/hosts) -eq 0 ]; then
  echo "${hostip}    ${hostname}" | sudo tee -a /etc/hosts
fi

touch bootstrap.log

# get vagrant box
vagrant box add sinergi/centos-65-x64 --provider virtualbox
#vagrant box add fillup/centos-6.5-x86_64-minimal --provider virtualbox

# init, boots and provisions vagrant automatically with bootstrap.sh
cp -vf "${conf_d}"/Vagrantfile-pre ./Vagrantfile
vagrant up

# changes webroot ownership so HTTPD can write in it
vagrant halt
cp -vf ./bootstrap.d/Vagrantfile-post ./Vagrantfile
vagrant up

# et voila!
echo "Dev VM is ready. To log in as root, use password 'vagrant'"
