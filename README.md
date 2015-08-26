# vagrant-golang-postgres
Vagrant dev env for Golang and Postgres

## Requirements

* [Vagrant 1.7.1+](http://www.vagrantup.com/downloads.html)
* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

## Quickstart

* On your host machine, extract or clone the repo to your `$GOPATH` or wherever you'd like.
* To clone to an existing folder, see http://stackoverflow.com/a/18999726/2563011
* In `Vagrantfile` change `myapp` to the name of your app.
* Run `vagrant up` to provision the VM and then `vagrant ssh` to access the VM.
* The `$GOPATH` in the VM is set to `/vagrant/`.
