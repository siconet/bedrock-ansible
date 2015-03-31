# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

ANSIBLE_PATH = '.' # path targeting Ansible directory (relative to Vagrantfile)

config_file = File.join(ANSIBLE_PATH, 'group_vars/development')

if File.exists?(config_file)
  wordpress_sites = YAML.load_file(config_file)['wordpress_sites']
else
  raise 'group_vars/development file not found. Please set `ANSIBLE_PATH` in Vagrantfile'
end

Vagrant.require_version '>= 1.5.1'

Vagrant.configure('2') do |config|
  config.vm.box = 'roots/bedrock'

  # Required for NFS to work, pick any local IP
  config.vm.network :private_network, ip: '192.168.50.5'

  main_site, *other_sites = wordpress_sites

  config.vm.hostname = main_site['site_hosts'].first

  if Vagrant.has_plugin? 'vagrant-hostsupdater'
    host_aliases = other_sites.flat_map { |site| site['site_hosts'] }
    config.hostsupdater.aliases = host_aliases - [config.vm.hostname]
  else
    puts 'vagrant-hostsupdater missing, please install the plugin:'
    puts 'vagrant plugin install vagrant-hostsupdater'
  end

  if Vagrant::Util::Platform.windows?
    wordpress_sites.each do |site|
      config.vm.synced_folder site['local_path'], remote_site_path(site), id: 'current', owner: 'vagrant', group: 'www-data', mount_options: ['dmode=776', 'fmode=775']
    end
  else
    if !Vagrant.has_plugin? 'vagrant-bindfs'
      raise Vagrant::Errors::VagrantError.new,
        "vagrant-bindfs missing, please install the plugin:\nvagrant plugin install vagrant-bindfs"
    else
      wordpress_sites.each do |site|
        config.vm.synced_folder site['local_path'], nfs_path(site), type: 'nfs'
        config.bindfs.bind_folder nfs_path(site), remote_site_path(site), u: 'vagrant', g: 'www-data'
      end
    end
  end
   
  # Check if we are on Windows using rbconfig
  # windows shell script: https://gist.github.com/starise/e90d981b5f9e1e39f632
  require 'rbconfig'
  is_windows = (RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/)
  if is_windows
    # Provisioning configuration for shell script (Windows host)
    config.vm.provision :shell,
	                    :keep_color => true,
						:inline => "export PYTHONUNBUFFERED=1 && export ANSIBLE_FORCE_COLOR=1 && cd /vagrant/windows-provisioning && ./windows.sh"
  
    config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"
    
    #config.vm.provision "shell" do |sh|
    #  sh.path = "windows.sh"
    #  sh.args = "site.yml hosts/development"
    #end
  else
    # Standard bedrock configuration for Ansible (Mac/Linux host).
    config.vm.provision :ansible do |ansible|
      # adjust paths relative to Vagrantfile
      ansible.playbook = './site.yml'
      ansible.groups = {
        'web' => ['default'],
        'development' => ['default']
      }
      ansible.extra_vars = {
        ansible_ssh_user: 'vagrant',
        user: 'vagrant'
      }
      ansible.sudo = true
    end
  end
  
  config.vm.provider 'virtualbox' do |vb|
    # Give VM access to all cpu cores on the host
    cpus = case RbConfig::CONFIG['host_os']
      when /darwin/ then `sysctl -n hw.ncpu`.to_i
      when /linux/ then `nproc`.to_i
      else 2
    end

    # Customize memory in MB
    vb.customize ['modifyvm', :id, '--memory', 1024]
    vb.customize ['modifyvm', :id, '--cpus', cpus]

    # Fix for slow external network connections
    vb.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
    vb.customize ['modifyvm', :id, '--natdnsproxy1', 'on']
    
    # adjust paths relative to Vagrantfile
    vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant", "1"]
    vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/current", "1"]
    vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/v-root", "1"]
    vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant-root", "1"]
  end
end

def nfs_path(site)
  "/vagrant-nfs-#{site['site_name']}"
end

def remote_site_path(site)
  File.join('/srv/www/', site['site_name'], 'current')
end
