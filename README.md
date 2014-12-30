vagrant-customizable-php-stack
==============================

A customizable Vagrant shell provisioner to set up a PHP web stack.

Those Bash scripts install a VirtualBox virtual machine running a RedHat-like Linux (CentOS) setup with a full PHP stack which serves websites. The stack is composed of several layers in which, with the help of the scripts parameters, you can choose between different supported technologies:
* key-value cache (memcached | redis)
* opcode cache (APC | ZendOpCache)
* PHP-FPM
* HTTP server (Apache with mod_ssl + mod_fastcgi | Nginx)
* DBMS server (MySQL | MariaDB | Oracle XE)

Requirements
------------
* a Bash capable OS
* [Oracle VirtualBox](https://www.virtualbox.org/)
* [Vagrant](https://www.vagrantup.com/)
 
How to use
----------
1. Fork the repository and chmod the shell files (*.sh) to be executable
2. Edit the parameters in `install.sh` and `bootstrap.sh` to suit your needs
3. Run `install.sh`
4. Once provisioned, you can `vagrant ssh` to login to your virtual machine and then `su -` with password 'vagrant' to further tune it
