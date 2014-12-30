vagrant-customizable-php-stack
==============================

A customizable Vagrant shell provisioner to set up a PHP web stack.

Those Bash scripts install a VirtualBox virtual machine running a RedHat-like Linux (CentOS) setup with a full PHP stack which serves websites. The stack is composed of several layers in which, with the help of the scripts parameters, you can choose between different supported technologies:
* __PHP-FPM__ with XDebug and common modules (as well as OCI8<sup><a href="#oci8">1</a></sup>)
* __key-value cache__ (memcached | redis (todo))
* __opcode cache__ (APC | ZendOpCache)
* __HTTP server__ (Apache with mod_ssl + mod_fastcgi | Nginx)
* __DBMS server__ (MySQL | MariaDB | Oracle XE<sup><a href="#oracle-xe">2</a></sup>)

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

Footnotes
---------
1. <a name="oci8"></a>To install OCI 8 drivers you first need to download [Oracle Instant Client (basic and devel packages)](http://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html) in `bootstrap.d`
2. <a name="oci8"></a>To install Oracle Database Express (XE) you first need to download [Oracle Express Client](http://www.oracle.com/technetwork/database/database-technologies/express-edition/downloads/index.html) in `bootstrap.d`
