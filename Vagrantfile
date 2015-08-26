# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|
  # Base box to build off, and download URL for when it doesn't exist on the user's system already
  config.vm.box = "ubuntu/trusty64"

  # Forward a port from the guest to the host, which allows for outside
  # computers to access the VM, whereas host only networking does not.
  config.vm.forward_port 8000, 8000
  
  # PostgreSQL Server port forwarding
  config.vm.forward_port 5432, 15432

  # Enable provisioning with a shell script.
  config.vm.provision :shell, :path => "etc/install/install.sh", :args => "myapp", privileged: false
end
