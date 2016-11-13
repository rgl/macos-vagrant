This is a macOS Base Box Vagrant Environment.

Before using this environment you have to create the base box as described bellow.

To keep the base box up to date, launch a new environment with:

```bash
vagrant up
```

Do the updates manually inside the VM and finish it with:

```bash
sudo dd if=/dev/zero of=/EMPTY bs=1m || true; sudo rm -f /EMPTY; sudo poweroff
```

Export to a box file:

```bash
make export
```

Replace the base box with the exported box file:

```bash
make import
```

NB you should also manually delete the existing "`linked_clone`" environments from VirtualBox (the VMs with a `(base)` name suffix).


# How to create the base box

Download the `macOS 10.12 Sierra Final by TechReviews.rar` file from:

* [How to Install macOS Sierra 10.12 on VirtualBox](http://www.wikigain.com/install-macos-sierra-10-12-virtualbox/)


Extract the `.vmdk` to your disk.


Create a VirtualBox VM with these settings:

| Setting    | Value |
|------------|-------|
| Name       | macOS |
| Type       | Mac OS X |
| Version    | Mac OS X 10.11 El Capitan (64-bit) |
| Processors | 2 |
| Memory     | 4 GB |
| Hard Disk  | Use an existing virtual disk file (and point it to the downloaded `.vmdk` file) |
| Boot order | Optical, Hard Disk |


Then, run the following commands to configure the VM:

```batch
VBoxManage modifyvm macOS --cpuidset 00000001 000306a9 04100800 7fbae3ff bfebfbff
VBoxManage setextradata macOS VBoxInternal/Devices/efi/0/Config/DmiSystemProduct "MacBookPro11,3"
VBoxManage setextradata macOS VBoxInternal/Devices/efi/0/Config/DmiSystemVersion "1.0"
VBoxManage setextradata macOS VBoxInternal/Devices/efi/0/Config/DmiBoardProduct "Iloveapple"
VBoxManage setextradata macOS VBoxInternal/Devices/smc/0/Config/DeviceKey "ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc"
VBoxManage setextradata macOS VBoxInternal/Devices/smc/0/Config/GetKeyFromRealSMC 1
```

Launch the VM and follow the install steps.

NB make sure you create the default account with the username and password `vagrant`.


Enter the VM and manually enable SSH:

1. Open the Preferences.
1. Search for `Remove Login`.
1. Click the `Remote Login` checkbox to turn it on.

Or use a command:

```bash
sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist
```


Create the `vagrant` group (some vagrant commands, e.g. `rsync`, expect to find it):

```bash
VAGRANT_GID=$(id -u vagrant)
sudo dscl . -create /Groups/vagrant
sudo dscl . -create /Groups/vagrant PrimaryGroupID $VAGRANT_GID
sudo dscl . -create /Users/vagrant PrimaryGroupID $VAGRANT_GID
```


Configure SSH to accept the unsecure vagrant SSH public key:

NB vagrant will replace the insecure key on the first run.

```bash
install -d -m 700 ~/.ssh
pushd ~/.ssh
curl -o authorized_keys https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub
chmod 600 authorized_keys
popd
```


Configure sudo for not asking for the user password when the user belongs to the admin group:

```bash
sudo su -l
chmod +w /etc/sudoers
sed -i.orig -E 's,^%admin.+,%admin ALL=(ALL) NOPASSWD:ALL,g' /etc/sudoers
rm -f /etc/sudoers.orig
chmod -w /etc/sudoers
```


Install all the Updates that might be available at the App Store.


Zero the free disk space -- for better compression of the box file:

```bash
sudo dd if=/dev/zero of=/EMPTY bs=1m || true; sudo sync; sudo rm -f /EMPTY; sudo sync
```


Shutdown the machine.


Create the vagrant box template file:

```bash
cat >Vagrantfile.template <<'EOF'
Vagrant.configure("2") do |config|
  config.vm.synced_folder ".", "/vagrant", type: "rsync", rsync__exclude: [".vagrant/", ".git/", "*.box"]
  config.vm.provider "virtualbox" do |vb|
    vb.check_guest_additions = false
    vb.functional_vboxsf = false
    vb.customize ["modifyvm", :id, "--cpuidset", "00000001", "000306a9", "04100800", "7fbae3ff", "bfebfbff"]
    vb.customize ["setextradata", :id, "VBoxInternal/Devices/efi/0/Config/DmiSystemProduct", "MacBookPro11,3"]
    vb.customize ["setextradata", :id, "VBoxInternal/Devices/efi/0/Config/DmiSystemVersion", "1.0"]
    vb.customize ["setextradata", :id, "VBoxInternal/Devices/efi/0/Config/DmiBoardProduct", "Iloveapple"]
    vb.customize ["setextradata", :id, "VBoxInternal/Devices/smc/0/Config/DeviceKey", "ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc"]
    vb.customize ["setextradata", :id, "VBoxInternal/Devices/smc/0/Config/GetKeyFromRealSMC", "1"]
  end
end
EOF
```


Create the vagrant box file:

```bash
vagrant package --output macOS.box --vagrantfile Vagrantfile.template --base macOS
```


Add it to your vagrant installation:

```bash
vagrant box add --name macOS macOS.box
```


And test it by launching a simple vagrant environment that dumps the OS version to stdout:

```bash
cat >Vagrantfile <<'EOF'
Vagrant.configure("2") do |config|
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
EOF
```


And launch it:

```bash
vagrant up
```
