#!/usr/bin/env bash

## Shell script which installs a full web stack (CentOS) using a Vagrant VM (Virtual Box):
# - key-value cache (memcached | redis)
# - opcode cache (APC | ZendOpCache)
# - PHP-FPM
# - HTTP server (Apache with mod_ssl + mod_fastcgi | Nginx)
# - DBMS server (MySQL | MariaDB | Oracle XE)

conf_d="/vagrant/bootstrap.d"     # absolute path to host configuration folder
webroot="/vagrant/test"     			# absolute path to VM shared folder, must match config.vm.synced_folder in Vagrantfile
hostname="localhost.local"				# VM hostname, must match config.vm.hostname in Vagrantfile
hostip="192.168.10.10"	  				# VM IP (private network), must match config.vm.network in Vagrantfile
localip="192.168.10.1"            # VM host IP (private network)

install[0]='memcached'            # key-value cache
install[1]='zendopcache'          # opcode cache
install[2]='nginx'                # HTTP server
install[3]='oraclexe'             # DBMS server


function setup_system() {
  # set colored prompt for root
  echo PS1="'\[\033[01;31m\]\u\[\033[00m\]@\[\033[01;32m\]\h\[\033[00m\]:\[\033[01;36m\]\w\[\033[00m\]\$ '" | sudo tee -a /root/.bashrc
  
  # update system packages
  #sudo yum -y update

  sudo yum -y install yum-plugin-priorities
  sudo yum -y install PackageKit-yum-plugin
  sudo yum -y install yum-plugin-security

  sudo yum -y install wget

  # add EPEL repo (required for Nginx 1.0)
  #sudo rpm --import https://fedoraproject.org/static/0608B895.txt
  #sudo rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm

  # add RPM-forge repo
  sudo wget http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm
  sudo rpm --import http://apt.sw.be/RPM-GPG-KEY.dag.txt
  sudo rpm -K rpmforge-release-0.5.3-1.el6.rf.*.rpm
  sudo rpm -Uvh rpmforge-release-0.5.3-1.el6.rf.*.rpm

  # add Remi repo (required for PHP-FPM)
  sudo wget http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
  sudo rpm --import http://rpms.famillecollet.com/RPM-GPG-KEY-remi
  sudo rpm -K remi-release-6*.rpm
  sudo rpm -Uvh remi-release-6*.rpm
  sudo yum-config-manager --enable remi

  # add Webtatic repo (required for Nginx 1.x)
  sudo rpm -Uvh https://mirror.webtatic.com/yum/el6/latest.rpm

  sudo yum -y install vim 
  sudo yum -y install lynx
  sudo yum -y install colordiff
  sudo yum -y install htop

  sudo yum -y install openssl
  #sudo /etc/ssl/certs/make-dummy-cert /etc/ssl/certs/"${hostname}".crt

  # setup system hostname and NS lookups
  echo "${hostip}   ${hostname}" | sudo tee -a /etc/hosts

  # activate SELinux (needs system to be rebooted)
  #file=/etc/selinux/config
  #sudo cp -v "${file}"{,-dist}
  #sudo sed -i 's/SELINUX=disabled/SELINUX=enforcing/' "${file}"
}


function install_stack() {
  install_php
  install_kvc_${install[0]}
  install_oc_${install[1]}
  install_http_${install[2]}
  install_dbms_${install[3]}
}


function install_php_oci8() {
  # installs Oracle client from RPM
  sudo rpm -K "${conf_d}/oracle-instantclient12.1-basic-12.1.0.1.0-1.x86_64.rpm"
  sudo rpm -Uvh "${conf_d}/oracle-instantclient12.1-basic-12.1.0.1.0-1.x86_64.rpm"
  sudo rpm -K "${conf_d}/oracle-instantclient12.1-devel-12.1.0.1.0-1.x86_64.rpm"
  sudo rpm -Uvh "${conf_d}/oracle-instantclient12.1-devel-12.1.0.1.0-1.x86_64.rpm"

  # installs PHP extension via RPM from Remi repository
  #sudo yum -y install php-oci8

  # otherwise via PECL (manual)
  #sudo pecl channel-update pecl.php.net
  #sudo pecl install oci8
  # "instantclient,/usr/lib/oracle/12.1/client64/lib"
  # add extension in php.ini or oci8.ini "oci8=/usr/lib64/php/modules/oci8.so"
  #sudo chmod 755 /usr/lib64/php/modules/oci8.so
}


function install_php_xdebug() {
  sudo yum -y install php-pecl-xdebug
  file=/etc/php.d/xdebug.ini
  sudo cp -v "${file}"{,-dist}
  sudo cp -fv "${conf_d}/xdebug.ini" "${file}"
  sudo sed -i "s/xdebug.remote_host=localhost/xdebug.remote_host=${localip}/" "${file}"
}


function install_php() {
  sudo yum -y install php-fpm php-devel

  # install PHP extensions commonly required
  sudo yum -y install php-gd php-intl php-mcrypt php-mbstring php-mysql php-pdo php-pear php-process
  # should also be installed by default PHP install
  sudo yum -y install php-xml

  # fixes mcrypt.ini which raises error "Startup: Unable to load dynamic library '/usr/lib/php/modules/module.so'"
  file=/etc/php.d/mcrypt.ini
  sudo cp -v "${file}"{,-dist}
  sudo sed -i 's/extension=module.so/extension=mcrypt.so/' "${file}"

  # PEAR colored console
  sudo yum -y install php-pear-Console-Color php-pear-Console-Table

  # php-uploadprogress
  #sudo yum -y install ftp://linuxsoft.cern.ch/cern/updates/slc6X/x86_64/RPMS/php-pecl-uploadprogress-1.0.1-1.slc6.x86_64.rpm

  # setup PHP
  file=/etc/php.ini
  sudo cp -v "${file}"{,-dist}
  sudo sed -i 's/max_execution_time = 30/max_execution_time = 60/' "${file}"
  sudo sed -i 's/memory_limit = 128M/memory_limit = 512M/' "${file}"
  sudo sed -i 's/display_errors = Off/display_errors = On/' "${file}"
  sudo sed -i 's/display_startup_errors = Off/display_startup_errors = On/' "${file}"
  sudo sed -i 's/html_errors = Off/html_errors = On/' "${file}"
  sudo sed -i 's/;cgi\.fix_pathinfo=1/cgi\.fix_pathinfo=0/' "${file}"
  sudo sed -i 's/;date\.timezone =/date.timezone = America\/Montreal/' "${file}"
  #sudo sed -i 's/;error_log = php_errors.log/error_log = php_errors.log/' "${file}"

  # setup PHP-FPM to listen to socket
  file=/etc/php-fpm.d/www.conf
  sudo cp -v "${file}"{,-dist}
  #sudo sed -i 's/listen = 127\.0\.0\.1:9000/listen = \/var\/run\/php-fpm\/php-fpm.sock/' "${file}"
  sudo sed -i 's/group = apache/group = vagrant/' "${file}"

  sudo pecl install channel://pecl.php.net/libevent-0.1.0

  install_php_oci8
  install_php_xdebug

  sudo chkconfig --level 2345 php-fpm on
  sudo service php-fpm start
}


function install_phpmyadmin() {
  sudo yum -y install phpMyAdmin

  # allow external connexion to phpMyAdmin
  file=/etc/httpd/conf.d/phpMyAdmin.conf
  sudo cp -v "${file}"{,-dist}
  sudo sed -i 's/     Order Deny,Allow/     Order Allow,Deny/' "${file}"
  sudo sed -i 's/     Deny from All/     Allow from All/' "${file}"
}


function install_drupal() {
  # drush (Drupal)
  sudo yum -y install php-drush-drush
}


function install_kvc_memcached() {
  sudo yum -y install memcached
  sudo yum -y install telnet nc
  sudo yum -y install php-pecl-memcache php-pecl-memcached

  sudo chkconfig --level 2345 memcached on
  sudo service memcached start
}

#function install_kvc_redis() {
#}


function install_oc_apc() {
  sudo yum -y install php-pecl-apc
  file="/etc/php.d/apc.ini"
  sudo cp -v "${file}"{,-dist}
  sudo sed -i 's/apc.shm_size=32M/apc.sh_size=128M/' "${file}"
  sudo sed -i 's/apc.rfc1867=0/apc.rfc1867=1/' "${file}"
  sudo cp -v /usr/share/php-pecl-apc/apc.php "${webroot}"
}

# requires PHP 5.4+
function install_oc_zendopcache() {
  sudo yum -y install php-pecl-zendopcache
}


function install_http_apache() {
  #sudo yum -y install mod_evasive
  #sudo yum -y install mod_security

  # setup mod_ssl (and by dependency, apache httpd)
  #sudo yum -y install mod_ssl
  #file=/etc/httpd/conf.d/ssl.conf
  #sudo cp -v "${file}"{,-dist}
  #sed -i 's/#ServerName www\.example\.com:443/ServerName localhost:443/' "${file}"
  #sudo cp -v "${conf_d}"/$hostname.crt /etc/pki/tls/certs
  #sudo cp -v "${conf_d}"/$hostname.key /etc/pki/tls/private/$hostname.key
  #sudo cp -v "${conf_d}"/$hostname.csr /etc/pki/tls/private/$hostname.csr

  # setup Apache 2.2
  # https://docs.vagrantup.com/v2/synced-folders/virtualbox.html
  #file=/etc/httpd/conf/httpd.conf
  #sudo cp -v "${file}"{,-dist}
  #sudo cp -fv "${conf_d}"/httpd.conf "${file}"

  # EnableSendfile off

  # setup Apache virtual hosts (main and site)
  #file=/etc/httpd/conf.d/vhosts.conf
  #sudo cp -fv "${conf_d}/httpd-vhosts.conf" "${file}"
  #sudo chown -v root:root "${file}"

  # setup fastcgi Apache module
  #sudo yum -y erase mod_php # in case it's here for whatever reason
  sudo yum -y install mod_fastcgi
  file=/etc/httpd/conf.d/fastcgi.conf
  sudo cp -v "${file}"{,-dist}
  sudo cp -fv "${conf_d}/fastcgi.conf" "${file}"

  # disable php module
  file=/etc/httpd/conf.d/php.conf
  sudo mv -v "${file}"{,-disabled}

  sudo chkconfig --level 2345 httpd on
  sudo service httpd start
}

function install_http_nginx() {
  sudo yum -y install nginx

  # turn sendfile off (Nginx has it on by default) to fix issues between web server and VirtualBox shared folders
  # https://docs.vagrantup.com/v2/synced-folders/virtualbox.html
  file=/etc/nginx/nginx.conf
  sudo cp -v "${file}"{,-dist}
  sudo sed -i 's/    sendfile        on;/    sendfile        off;/' "${file}"

  # setup virtual host
  #file=/etc/nginx/conf.d/virtual.conf
  #sudo cp -v "${file}"{,-dist}
  #sudo cp -fv "${conf_d}/nginx-virtual.conf" "${file}"

  sudo chkconfig --level 2345 nginx on
  sudo service nginx start
}


# install MariaDB and import site DB, setting admin user as 'admin@localhost', pass 'drupal'
function install_dbms_mariadb() {
  # add MariaDb repository for yum
  file=/etc/yum.repos.d/MariaDB.repo
  sudo cp -v "${conf_d}/MariaDB.repo" "${file}"

  # install MariaDB package
  sudo yum -y install MariaDB-server MariaDB-client

  # optimize MariaDB server
  file=/etc/my.cnf.d/server.cnf
  sudo cp -v "${file}"{,-dist}
  #sudo cp "${conf_d}/server.cnf" "${file}"
  if [ $(egrep -i -c '^thread_cache_size.*$' "${file}") -eq 0 ]; then
    sed -i 's/\[server\]/\[server\]\nthread_cache_size = 4/' "${file}"
  fi
  if [ $(egrep -i -c '^query_cache_size.*$' "${file}") -eq 0 ]; then
    sed -i 's/\[server\]/\[server\]\nquery_cache_size = 16M/' "${file}"
  fi
  if [ $(egrep -i -c '^skip-innodb$' $file) -eq 0 ]; then
    sed -i 's/\[server\]/\[server\]\nskip-innodb/' "${file}"
  fi
  if [ $(egrep -i -c '^skip-federated$' "${file}") -eq 0 ]; then
    sed -i 's/\[server\]/\[server\]\nskip-federate/' "${file}"
  fi
  if [ $(egrep -i -c '^skip-archive$' "${file}") -eq 0 ]; then
    sed -i 's/\[server\]/\[server\]\nskip-archive/' "${file}"
  fi
  if [ $(egrep -i -c '^max_allowed_packet.*$' "${file}") -eq 0 ]; then
    sed -i 's/\[server\]/\[server\]\nmax_allowed_packet = 16M/' "${file}"
  fi
  if [ $(egrep -i -c '^default_storage_engine.*$' "${file}") -eq 0 ]; then
    sed -i 's/\[server\]/\[server\]\ndefault_storage_engine = aria/' "${file}"
  fi

  sudo chkconfig --level 2345 mysql on
  sudo service mysql start
}

function install_swap_file() {
	file=/file.swap
	# preallocate a space for the swap file
	sudo fallocate -l 4G "${file}"
	# readable by the system only
	sudo chmod 600 "${file}"
	# set the file as a swap space
	sudo mkswap $file
	# activate the swap "${file}"
	sudo swapon $file
}

function install_dbms_oraclexe() {
  install_swap_file

	sudo rpm -Uvh "${conf_d}/oracle-xe-11.2.0-1.0.x86_64.rpm"
	sudo /etc/init.d/oracle-xe configure responseFile="${conf_d}/xe.rsp"
}


# main
setup_system 2>&1 | tee bootstrap.log
install_stack 2>&1 | tee -a bootstrap.log
