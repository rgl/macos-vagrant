Vagrant.configure("2") do |config|
  config.ssh.insert_key = false
  config.vm.synced_folder ".", "/vagrant", :disabled => true
  config.vm.box = "macOS"
  config.vm.provider :virtualbox do |vb|
    vb.linked_clone = true
    vb.gui = true
    vb.cpus = 4
    vb.memory = 4096
  end
  config.vm.provision "shell", inline: <<-SHELL
    set -eux
    cat /System/Library/CoreServices/SystemVersion.plist
    system_profiler SPSoftwareDataType
    sw_vers
    uname -a
  SHELL
end
