Vagrant.configure("2") do |config|

  config.vm.provider "virtualbox" do |v, override|
    v.cpus = 2
    v.memory = 2048

    override.vm.provision "shell", path: "../provision/linux_setHosnameIp.sh", privileged: false
    if ENV.has_key? "WORKSPACE"
      override.vm.synced_folder ENV['WORKSPACE'], "/mnt/workspace", type: "virtualbox"
    end
    override.vm.synced_folder "/home/tester/vm-shared", "/mnt/shared", mount_options: ["ro"], type: "virtualbox"
  end

  config.vm.provider "libvirt" do |libvirt, override|
    if ENV.has_key? "VM_CPUS"
      libvirt.cpus = ENV['VM_CPUS']
    else
      libvirt.cpus = 4
    end
    if ENV.has_key? "VM_MEMORY"
        libvirt.memory = ENV['VM_MEMORY']
    else
        libvirt.memory = 8192
    end
    if VM.end_with? "x64"
        libvirt.sound_type = "ich6"
    end
    if File.exist?("/home/tester/vm-shared")
      override.vm.synced_folder "/home/tester/vm-shared", "/mnt/shared", type: "sshfs", ssh_username: "tester", sshfs_opts_append: "-o ro"
    else
      # empty ssh_password is workaround to prevent promting for pw
      # https://github.com/dustymabe/vagrant-sshfs/blob/9fcb721bf7b406d27273f44cba7924c22de9e7fd/lib/vagrant-sshfs/synced_folder/sshfs_forward_mount.rb#L93
      override.vm.synced_folder "/home/tester/vm-shared", "/mnt/shared", ssh_host: "hydra.brq.redhat.com", type: "sshfs", ssh_username: "tester", sshfs_opts_append: "-o ro -o IdentityFile=/home/tester/.ssh/id_rsa", ssh_password: "", prompt_for_password: false
    end
    if ENV.has_key? "WORKSPACE"
      override.vm.synced_folder ENV['WORKSPACE'], "/mnt/workspace", type: "sshfs", ssh_username: "tester", sshfs_opts_append: "-o rw"
    end
  end
end
