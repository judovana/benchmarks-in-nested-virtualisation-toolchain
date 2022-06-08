$repository_url = "http://hydra.brq.redhat.com:8083"

if OS
  load File.expand_path("../RootVagrantfile" + OS + ".rb", __FILE__)
end

Vagrant.configure("2") do |config|
  #config.vm.define VM, primary: true
  if ENV.has_key? "VM_BOX_OVERRIDE"
    config.vm.box = ENV['VM_BOX_OVERRIDE']
  else
    config.vm.box = VM
  end
  config.vm.box_url = $repository_url + "/" + config.vm.box
  config.vm.box_download_insecure = true
  config.vm.boot_timeout = 1200
  config.vm.box_download_options = {"limit-rate": "80M"}

  config.ssh.username = "tester"
  config.ssh.private_key_path = "~/.ssh/tester_rsa"
  config.vm.synced_folder ".", "/vagrant", disabled: true

  if ENV.has_key? "OTOOL_JOB_NAME_SHORTENED"
	  config.vm.define ENV['OTOOL_JOB_NAME_SHORTENED'] do |foo|
	  #
	  end
  end

  config.vm.provider "libvirt" do |libvirt|
    libvirt.qemu_use_session = false
    libvirt.channel :type => 'unix', :target_name => 'org.qemu.guest_agent.0', :target_type => 'virtio'
    libvirt.random :model => 'random'
    # Enable KVM nested virtualization, ALSO should TEST different CPU mode to see which is better
    libvirt.nested = true
    libvirt.cpu_mode = "host-model"
    if VM.end_with? "aarch64"
        libvirt.features = []
        # uncomment following to emulate aarch on x86_64
        # libvirt.machine_type = "virt"
        # libvirt.machine_arch = "aarch64"
        # libvirt.driver = "qemu"
        # libvirt.cpu_mode = "custom"
        # libvirt.cpu_model = "cortex-a57"
        libvirt.cpu_mode = "host-passthrough"
        libvirt.loader = "/usr/share/edk2/aarch64/QEMU_EFI-pflash.raw"
        libvirt.video_type = "virtio"
        libvirt.input :type => "tablet", :bus => "virtio"
        libvirt.input :type => "keyboard", :bus => "virtio"
    elsif VM.end_with? "s390x"
        libvirt.cpu_mode = "host-passthrough"
        libvirt.video_type = "virtio"
        libvirt.input :type => "tablet", :bus => "virtio"
        libvirt.input :type => "keyboard", :bus => "virtio"
    else
        if ENV.has_key? "VM_CPU_MODE"
            libvirt.cpu_mode = ENV['VM_CPU_MODE']
        end
        if ENV.has_key? "VM_CPU_MODEL"
            libvirt.cpu_model = ENV['VM_CPU_MODEL']
        end
        libvirt.graphics_type = "spice"
        libvirt.video_type = "qxl"
        libvirt.channel :type => 'spicevmc', :target_name => 'com.redhat.spice.0', :target_type => 'virtio'
    end
    if ENV.has_key? "OTOOL_JOB_NAME_SHORTENED"
        libvirt.default_prefix = ''
    elsif ENV.has_key? "JOB_NAME"
        libvirt.default_prefix = ENV['JOB_NAME']
    end
  end

  config.vm.provider "virtualbox" do |v, override|
    v.linked_clone = true

    v.customize ["modifyvm", :id, "--nic2", "hostonly", "--hostonlyadapter2", "vboxnet0", "--nicpromisc2", "allow-all"]
    v.customize ["modifyvm", :id, "--vrde", "on", "--vrdeport", "50100-50150", "--vrdeaddress", "0.0.0.0"]

    if ENV.has_key? "JOB_NAME"
      v.name = ENV['JOB_NAME']
    end
  end

end
