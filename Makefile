up:
	vagrant up

halt:
	vagrant halt

export: clean macOS.box

import: macOS.box
	vagrant box add --force macOS macOS.box

clean:
	rm -f macOS.box

macOS.box: Vagrantfile Vagrantfile.template
	vagrant package --output macOS.box --vagrantfile Vagrantfile.template

.PHONY: export import clean
