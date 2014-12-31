
{
  'google' => {
    :requires => "
      require 'vagrant-google'
      require 'vagrant-hostmanager'
      require 'fog/version'
    ",
    :use_bucket => true,
    :sync_folder => "
      deploy_config.vm.synced_folder '.', '/vagrant', disabled: true
    ",
    :box => 'gce',
    :defaults => {
      :common_location_name => 'us_west',
      :common_image_name => 'CentOS-6.5-x64',
      :common_instance_type => 'small',
    },
    :ip_resolver => $ip_resolver[:ssh_ip],
    :instances_config => {
      'puppetmaster' => {
        :common_instance_type => 'small',
        :common_image_name => 'CentOS-6.5-x64',
        :config_steps_type => 'default_linux',
        #:object_source => 'google_storage',
        #:repo_url => 'https://github.com/emccode/vagrant-puppet-scaleio',
        :sync_folder => "
          deploy_config.vm.synced_folder 'cert', '/tmp/cert'
          deploy_config.vm.synced_folder '.', '/vagrant', disabled: true
        ",
        :object_creds => {
          :service_account => $consumer_config['google_storage'][:service_account],
          :key_file => $consumer_config['google_storage'][:key_file],
        },
        :commands => {
          :dns_update => $images_config['default_linux'][:dns_update],
          :pre_install => $images_config['CentOS-6.5-x64'][:commands][:puppetmaster_remove],
          :set_hostname => proc {|hostname,domain| $images_config['default_linux'][:commands][:set_hostname].call(hostname,domain) },
          :install => proc {|config_param| $images_config['CentOS-6.5-x64'][:commands][:puppetmaster_install].call(config_param) },
          #:sitepp_curl => $images_config['default_linux'][:commands][:curl_file].call('https://raw.githubusercontent.com/emccode/vagrant-puppet-scaleio/master/puppet/manifests/examples/site.pp-hosts_lookup','/etc/puppet/manifests/site.pp')
        }
      },
      'puppetagent' => {
        :common_instance_type => 'medium',
        :common_image_name => 'CentOS-6.5-x64',
        :config_steps_type => 'default_linux',
        #:disk_size => 110,
        :commands => {
          :dns_update => $images_config['default_linux'][:dns_update],
          :pre_install => $images_config['CentOS-6.5-x64'][:commands][:puppetagent_remove],
          :set_hostname => proc {|hostname,domain| $images_config['default_linux'][:commands][:set_hostname].call(hostname,domain) },
          :install => proc {|config_param| $images_config['CentOS-6.5-x64'][:commands][:puppetagent_install].call(config_param) }
        }        
      },
      'coreos' => {
        :common_instance_type => 'small',
        :common_image_name => 'CoreOS-444.5.0-(stable)',
        :config_steps_type => 'default_coreos',
        :commands => {
          :pre_install => '',
          :install => proc {|config_param|  },
          :post_install => proc {|config_param| " 
public_ipv4=`curl -s ip.alt.io`

cat <<EOF > /usr/share/oem/cloud-config.yml
#cloud-config

coreos:
  etcd:
    discovery: #{config_param[:etcd_url]}
    addr: $public_ipv4:4001
    peer-addr: $public_ipv4:7001
    peer-election-timeout: 500
    peer-heartbeat-interval: 100
  fleet:
    public-ip: $public_ipv4
    metadata: region=us_west,provider=google,platform=cloud,instance_type=small
  units:
      - name: etcd.service
        command: start
      - name: fleet.service
        command: start
EOF
        /usr/bin/coreos-cloudinit --from-file /usr/share/oem/cloud-config.yml
"
        } }        
      },
    },
    :deploy_box_config => "
      deploy_config.vm.provider :google do |google, override|
        google.google_project_id = $consumer_config[$provider][:google_project_id]
        google.google_client_email = $consumer_config[$provider][:google_client_email]
        google.google_key_location = $consumer_config[$provider][:google_key_location]
        google.image = instance_image
        eval(str_instance_type)
        disk_size = box[:disk_size] || $provider_config[$provider][:instances_config][box_type][:disk_size] 
        google.disk_size = disk_size unless !disk_size


        eval(str_location)
        google.name = box[:hostname]
        override.ssh.private_key_path = box[:private_key] || $provider_config[$provider][:instances_config][box_type][:private_key] || $consumer_config[$provider][:private_key]
        override.ssh.username = box[:ssh_username] || $provider_config[$provider][:images_config][instance_image][:ssh_username]
      end
    ",
    :images_config => {
      'centos-6-v20141021' => {
        :ssh_username => 'clintonkitson'
      },
      'coreos-stable-444-5-0-v20141016' => {
        :ssh_username => 'core'
      }
    },
    :images_lookup => {
      'CentOS-6.5-x64' => 'centos-6-v20141021',
      'CoreOS-444.5.0-(stable)' => 'coreos-stable-444-5-0-v20141016',
    },
    :instance_type_lookup => {
      'small' => {
        :name => "google.machine_type = 'n1-standard-1'",
        :type => :alias,
      },
      'medium' => {
        :name => "google.machine_type  = 'n1-standard-2'",
        :type => :alias,
      },
    },
    :location_lookup => {
      'us_west' => "
        google.zone = 'us-central1-a'
      "
    },
  },
  'rackspace' => {
    :requires => "
      require 'vagrant-rackspace'
      require 'vagrant-hostmanager'
    ",
    :use_bucket => true,
    :sync_folder => "
      deploy_config.vm.synced_folder '.', '/vagrant', disabled: true
    ",
    :box => 'dummy',
    :defaults => {
      :common_location_name => 'us_west',
      :common_image_name => 'CentOS-6.5-x64',
      :common_instance_type => 'small',
    },
    :ip_resolver => $ip_resolver[:ifconfig].call('eth1'),
    :instances_config => {
      'puppetmaster' => {
        :common_instance_type => 'small',
        :common_image_name => 'CentOS-6.5-x64',
        :config_steps_type => 'default_linux',
        #:object_source => 'rackspace_swift',
        #:repo_url => 'https://github.com/emccode/vagrant-puppet-scaleio',
        #:object_creds => {
        #  :st_key => $consumer_config['rackspace_swift'][:st_key],
        #  :st_user => $consumer_config['rackspace_swift'][:st_user],
        #  :st_auth => $consumer_config['rackspace_swift'][:st_auth],
        #},
        :commands => {
          :dns_update => $images_config['default_linux'][:dns_update],
          :pre_install => $images_config['CentOS-6.5-x64'][:commands][:puppetmaster_remove],
          :set_hostname => proc {|hostname,domain| $images_config['default_linux'][:commands][:set_hostname].call(hostname,domain) },
          :install => proc {|config_param| $images_config['CentOS-6.5-x64'][:commands][:puppetmaster_install].call(config_param) },
          #:sitepp_curl => $images_config['default_linux'][:commands][:curl_file].call('https://raw.githubusercontent.com/emccode/vagrant-puppet-scaleio/master/puppet/manifests/examples/site.pp-hosts_lookup','/etc/puppet/manifests/site.pp')
        }
      },
      'puppetagent' => {
        :common_instance_type => 'medium',
        :common_image_name => 'CentOS-6.5-x64',
        :config_steps_type => 'default_linux',
        :commands => {
          :dns_update => $images_config['default_linux'][:dns_update],
          :pre_install => $images_config['CentOS-6.5-x64'][:commands][:puppetagent_remove],
          :set_hostname => proc {|hostname,domain| $images_config['default_linux'][:commands][:set_hostname].call(hostname,domain) },
          :install => proc {|config_param| $images_config['CentOS-6.5-x64'][:commands][:puppetagent_install].call(config_param) },
        }        
      },
      'coreos' => {
        :common_instance_type => 'small',
        :common_image_name => 'CoreOS-444.5.0-(stable)',
        :config_steps_type => 'default_coreos',
        :commands => {
          :pre_install => '',
          :install => proc {|config_param|  },
          :post_install => proc {|config_param| " 
public_ipv4=`curl -s ip.alt.io`

cat <<EOF > /usr/share/oem/cloud-config.yml
#cloud-config

coreos:
  etcd:
    discovery: #{config_param[:etcd_url]}
    addr: $public_ipv4:4001
    peer-addr: $public_ipv4:7001
    peer-election-timeout: 500
    peer-heartbeat-interval: 100
  fleet:
    public-ip: $public_ipv4
    metadata: region=us_west,provider=rackspace,platform=cloud,instance_type=small
  units:
      - name: etcd.service
        command: start
      - name: fleet.service
        command: start

EOF
        /usr/bin/coreos-cloudinit --from-file /usr/share/oem/cloud-config.yml
"
        } }        
      },
    },
    :deploy_box_config => "
      deploy_config.vm.provider :rackspace do |rs,override|
        rs.username = $consumer_config[$provider][:username]
        rs.api_key  = $consumer_config[$provider][:api_key]
        rs.server_name = box[:hostname]
        eval(str_instance_type)
        rs.image    = instance_image
        eval(str_location)

        rs.key_name = box[:keypair_name] || $provider_config[$provider][:instances_config][box_type][:keypair_name] || $consumer_config[$provider][:keypair_name]
        override.ssh.private_key_path = box[:private_key] || $provider_config[$provider][:instances_config][box_type][:private_key] || $consumer_config[$provider][:private_key]
        override.ssh.username = box[:ssh_username] || $provider_config[$provider][:images_config][instance_image][:ssh_username]
      end
    ",
    :images_config => {
      'CentOS 6.5 (PVHVM)' => {
        :ssh_username => 'root'
      },
      'CoreOS (Stable)' => {
        :ssh_username => 'core'
      }
    },
    :images_lookup => {
      'CentOS-6.5-x64' => 'CentOS 6.5 (PVHVM)',
      'CoreOS-444.5.0-(stable)' => 'CoreOS (Stable)',
    },
    :instance_type_lookup => {
      'small' => {
        :name => "rs.flavor = '1 GB General Purpose v1'",
        :type => :alias,
      },
      'medium' => {
        :name => "rs.flavor  = '2 GB General Purpose v1'",
        :type => :alias,
      },
    },
    :location_lookup => {
      'us_west' => "
        rs.rackspace_region = :dfw
      "
    },
  },

  'azure' => {
    :requires => "
      require 'vagrant-azure'
      require 'vagrant-hostmanager'
    ",
    :use_bucket => true,
    :sync_folder => "
      deploy_config.vm.synced_folder '.', '/vagrant', disabled: true
    ",
    :box => 'azure',
    :defaults => {
      :vm_location => 'West US',
      :common_image_image => 'CentOS-6.5-x64',
      :common_instance_type => 'small',
    },
    :deploy_box_config => "
      deploy_config.vm.provider :azure do |azure,override|
        azure.mgmt_certificate = $consumer_config[$provider][:mgmt_certificate]
        azure.mgmt_endpoint = $consumer_config[$provider][:mgmt_endpoint]
        azure.subscription_id = $consumer_config[$provider][:subscription_id]
        azure.storage_acct_name = $consumer_config[$provider][:storage_acct_name]
        
        azure.vm_image = instance_image
        eval(str_instance_type)
        azure.vm_user = box[:ssh_username] || $provider_config[$provider][:images_config][instance_image][:ssh_username]

        azure.vm_name = box[:hostname]
        azure.vm_location = box[:vm_location] || $provider_config[$provider][:instances_config][box_type][:vm_location] || $provider_config[$provider][:defaults][:vm_location]
        azure.ssh_private_key_file = box[:private_key] || $provider_config[$provider][:instances_config][box_type][:private_key] || $consumer_config[$provider][:private_key]
        azure.ssh_certificate_file = box[:public_cert] || $provider_config[$provider][:instances_config][box_type][:public_cert] || $consumer_config[$provider][:private_key]
        azure.ssh_port = box[:ssh_port] || $provider_config[$provider][:instances_config][box_type][:ssh_port]
        azure.tcp_endpoints = box[:firewall_settings] || $provider_config[$provider][:instances_config][box_type][:firewall_settings] || $instances_config[box_type][:firewall_settings]
        override.ssh.private_key_path = box[:private_key] || $provider_config[$provider][:instances_config][box_type][:private_key] || $consumer_config[$provider][:private_key]
      end
      config.ssh.username = box[:ssh_username] || $provider_config[$provider][:images_config][instance_image][:ssh_username]
    ",
    :ip_resolver => $ip_resolver[:ssh_hostname],
    :instances_config => {
      'puppetmaster' => {
        :instance_type => 'Small',
        :common_image_name => 'CentOS-6.5-x64',
        :config_steps_type => 'default_linux',
        :ssh_port => 22,
        :commands => {
          :dns_update => $images_config['default_linux'][:dns_update],
          :pre_install => $images_config['CentOS-6.5-x64'][:commands][:puppetmaster_remove],
          :set_hostname => proc {|hostname,domain| $images_config['default_linux'][:commands][:set_hostname].call(hostname,domain) },
          :install => proc {|config_param| $images_config['CentOS-6.5-x64'][:commands][:puppetmaster_install].call(config_param) },
        }
      },
      'puppetagent' => {
        :instance_type => 'Medium',
        :common_image_name => 'CentOS-6.5-x64',
        :config_steps_type => 'default_linux',
        :ssh_port => 22,
        :commands => {
          :dns_update => $images_config['default_linux'][:dns_update],
          :pre_install => $images_config['CentOS-6.5-x64'][:commands][:puppetagent_remove],
          :set_hostname => proc {|hostname,domain| $images_config['default_linux'][:commands][:set_hostname].call(hostname,domain) },
          :install => proc {|config_param| $images_config['CentOS-6.5-x64'][:commands][:puppetagent_install].call(config_param) }
        }        
      },
      'coreos' => {
        :common_instance_type => 'small',
        :common_image_name => 'CoreOS-509.1.0-(alpha)',
        :config_steps_type => 'default_coreos',
        :firewall_settings => '4001:4001,7001:7001',
        :commands => {
          :pre_install => '',
          :install => proc {|config_param|  },
          :post_install => proc {|config_param| " 
public_ipv4=`curl -s ip.alt.io`

echo \"#cloud-config

coreos:
  etcd:
    discovery: #{config_param[:etcd_url]}
    addr: $public_ipv4:4001
    peer-addr: $public_ipv4:7001
    peer-election-timeout: 500
    peer-heartbeat-interval: 100
  fleet:
    public-ip: $public_ipv4
    metadata: region=us_west,provider=azure,platform=cloud,instance_type=small
  units:
      - name: etcd.service
        command: start
      - name: fleet.service
        command: start
\" > /usr/share/oem/cloud-config.yml
        /usr/bin/coreos-cloudinit --from-file /usr/share/oem/cloud-config.yml
"
        } }        
      },
    },
    :images_config => {
      '5112500ae3b842c8b9c604889f8753c3__OpenLogic-CentOS-65-20140926' => {
        :ssh_username => 'centos',
        :box => 'azure'
      },
      '2b171e93f07c4903bcad35bda10acf22__CoreOS-Alpha-509.1.0' => {
        :ssh_username => 'core',
        :box => 'azure'
      }
    },
    :images_lookup => {
      'CentOS-6.5-x64' => '5112500ae3b842c8b9c604889f8753c3__OpenLogic-CentOS-65-20140926',
      'CoreOS-509.1.0-(alpha)' => '2b171e93f07c4903bcad35bda10acf22__CoreOS-Alpha-509.1.0',
    },
    :instance_type_lookup => {
      'small' => {
        :name => "azure.vm_size = 'Small'",
        :type => :alias,
      },
      'medium' => {
        :name => "azure.vm_size = 'Medium'",
        :type => :alias,
      },
    },
    :location_lookup => {
      'us_west' => "
        azure.vm_location = 'West US'
      "
    }, 
  },
  'digital_ocean' => {  
    :requires => "
      require 'vagrant-digitalocean'
      require 'vagrant-hostmanager'
    ",
    :use_bucket => true,
    :sync_folder => "
      deploy_config.vm.synced_folder '.', '/vagrant', disabled: true
    ",
    :box => 'digital_ocean',
    :defaults => {
      :common_location_name => 'us_west',
      :common_image_name => 'CentOS-6.5-x64',
      :common_instance_type => 'small',
      :optional => '',
    },
    :ip_resolver => $ip_resolver[:ssh_ip],
    :instances_config => {
      'puppetmaster' => {
        :common_instance_type => 'small',
        :common_image_name => 'CentOS-6.5-x64',
        :config_steps_type => 'default_linux',
        :commands => {
          :dns_update => $images_config['default_linux'][:dns_update],
          :pre_install => $images_config['CentOS-6.5-x64'][:commands][:puppetmaster_remove],
          :set_hostname => proc {|hostname,domain| $images_config['default_linux'][:commands][:set_hostname].call(hostname,domain) },
          :install => proc {|config_param| $images_config['CentOS-6.5-x64'][:commands][:puppetmaster_install].call(config_param) },
        }
      },
      'puppetagent' => {
        :common_instance_type => 'medium',
        :common_image_name => 'CentOS-6.5-x64',
        :config_steps_type => 'default_linux',
        :commands => {
          :dns_update => $images_config['default_linux'][:dns_update],
          :pre_install => $images_config['CentOS-6.5-x64'][:commands][:puppetagent_remove],
          :set_hostname => proc {|hostname,domain| $images_config['default_linux'][:commands][:set_hostname].call(hostname,domain) },
          :install => proc {|config_param| $images_config['CentOS-6.5-x64'][:commands][:puppetagent_install].call(config_param) }
        }        
      },
      'coreos' => {
        :common_instance_type => 'small',
        :common_image_name => 'CoreOS-444.5.0-(stable)',
        :config_steps_type => 'default_coreos',
        :commands => {
          :pre_install => '',
          :install => proc {|config_param|  },
          :post_install => proc {|config_param| " 
public_ipv4=`echo $SSH_CONNECTION | awk '{print $3}'`

echo \"#cloud-config

coreos:
  etcd:
    discovery: #{config_param[:etcd_url]}
    addr: $public_ipv4:4001
    peer-addr: $public_ipv4:7001
    peer-election-timeout: 500
    peer-heartbeat-interval: 100
  fleet:
    public-ip: $public_ipv4
    metadata: region=us_west,provider=digital_ocean,platform=cloud,instance_type=small
  units:
      - name: etcd.service
        command: start
      - name: fleet.service
        command: start
\" > /usr/share/oem/cloud-config.yml
        /usr/bin/coreos-cloudinit --from-file /usr/share/oem/cloud-config.yml
"
        } }        
      },
    },
    :deploy_box_config => "
      deploy_config.vm.provider :digital_ocean do |digitalocean, override|
        digitalocean.token = $consumer_config[$provider][:token]
        digitalocean.image = instance_image
        eval(str_location)
        eval(str_instance_type)
        eval(str_optional)
        digitalocean.ssh_key_name = box[:ssh_key_name] || $provider_config[$provider][:instances_config][box_type][:ssh_key_name] || $consumer_config[$provider][:ssh_key_name]        
        override.ssh.private_key_path = box[:private_key] || $provider_config[$provider][:instances_config][box_type][:private_key] || $consumer_config[$provider][:private_key]
        #override.vm.box = 'digital_ocean'
        #{}override.vm.box_url = 'https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box'
        digitalocean.setup = false
        override.ssh.username = box[:ssh_username] || $provider_config[$provider][:images_config][instance_image][:ssh_username]
      end
      
    ",
    :images_config => {
      '6.5 x64' => {
        :ssh_username => 'root'
      },
      '494.5.0 (stable)' => {
        :ssh_username => 'core'
      },
    },
    :images_lookup => {
      'CentOS-6.5-x64' => '6.5 x64',
      'CoreOS-444.5.0-(stable)' => '494.5.0 (stable)',
    },
    :instance_type_lookup => {
      'small' => {
        :name => "digitalocean.size = '1gb'",
        :type => :alias,
      },
      'medium' => {
        :name => "digitalocean.size  = '2gb'",
        :type => :alias,
      },
    },
    :location_lookup => {
      'us_west' => "
        digitalocean.region = 'sfo1'
      "
    },
  },
  'aws' => {  
    :requires => "
      require 'vagrant-aws'
      require 'vagrant-hostmanager'
    ",
    :use_bucket => true,
    :sync_folder => "
      deploy_config.vm.synced_folder '.', '/vagrant', disabled: true
    ",
    :box => 'dummy',
    :defaults => {
      :common_location_name => 'us_west',
      :common_image_name => 'CentOS-6.5-x64',
      :common_instance_type => 'small',
      :security_groups => ['default','standard']
    },
    :ip_resolver => $ip_resolver[:ifconfig].call('eth0'),
    :instances_config => {
      'puppetmaster' => {
        :common_instance_type => 'small',
        :common_image_name => 'CentOS-6.5-x64',
        :config_steps_type => 'default_linux',
        :commands => {
          :dns_update => $images_config['default_linux'][:dns_update],
          :pre_install => $images_config['CentOS-6.5-x64'][:commands][:puppetmaster_remove],
          :set_hostname => proc {|hostname,domain| $images_config['default_linux'][:commands][:set_hostname].call(hostname,domain) },
          :install => proc {|config_param| $images_config['CentOS-6.5-x64'][:commands][:puppetmaster_install].call(config_param) },
        }
      },
      'puppetagent' => {
        :common_instance_type => 'medium',
        :common_image_name => 'CentOS-6.5-x64',
        :config_steps_type => 'default_linux',
        :commands => {
          :dns_update => $images_config['default_linux'][:dns_update],
          :pre_install => $images_config['CentOS-6.5-x64'][:commands][:puppetagent_remove],
          :set_hostname => proc {|hostname,domain| $images_config['default_linux'][:commands][:set_hostname].call(hostname,domain) },
          :install => proc {|config_param| $images_config['CentOS-6.5-x64'][:commands][:puppetagent_install].call(config_param) }
        }        
      },
      'coreos' => {
        :common_instance_type => 'small',
        :common_image_name => 'CoreOS-444.5.0-(stable)',
        :config_steps_type => 'default_coreos',
        :commands => {
          :pre_install => '',
          :install => proc {|config_param|  },
          :post_install => proc {|config_param| " 
public_ipv4=`curl -s ip.alt.io`

echo \"#cloud-config

coreos:
  etcd:
    discovery: #{config_param[:etcd_url]}
    addr: $public_ipv4:4001
    peer-addr: $public_ipv4:7001
    peer-election-timeout: 500
    peer-heartbeat-interval: 100
  fleet:
    public-ip: $public_ipv4
    metadata: region=us_west,provider=aws,platform=cloud,instance_type=small
  units:
      - name: etcd.service
        command: start
      - name: fleet.service
        command: start
\" > /usr/share/oem/cloud-config.yml
        /usr/bin/coreos-cloudinit --from-file /usr/share/oem/cloud-config.yml
"
        } }        
      },
    },
    :deploy_box_config => "
      deploy_config.vm.provider :aws do |aws, override|
        aws.access_key_id = $consumer_config[$provider][:access_key_id]
        aws.secret_access_key = $consumer_config[$provider][:secret_access_key]
        aws.ami = instance_image
        eval(str_instance_type)
        aws.tags['Name'] = box[:hostname]
        aws.security_groups = box[:security_groups] || $provider_config[$provider][:instances_config][box_type][:security_groups] || $provider_config[$provider][:defaults][:security_groups] || []
        
        eval(str_location)

        aws.block_device_mapping = box[:block_device_mapping] || $provider_config[$provider][:instances_config][box_type][:block_device_mapping] || []

        aws.keypair_name = box[:keypair_name] || $provider_config[$provider][:instances_config][box_type][:keypair_name] || $consumer_config[$provider][:keypair_name]
        override.ssh.private_key_path = box[:private_key] || $provider_config[$provider][:instances_config][box_type][:private_key] || $consumer_config[$provider][:private_key]
        override.ssh.username = box[:ssh_username] || $provider_config[$provider][:images_config][instance_image][:ssh_username]
      end
    ",
    :images_config => {
      'ami-454b5e00' => {
        :ssh_username => 'ec2-user'
      },
      'ami-856772c0' => {
        :ssh_username => 'core'
      },
    },
    :images_lookup => {
      'CentOS-6.5-x64' => 'ami-454b5e00',
      'CoreOS-444.5.0-(stable)' => 'ami-856772c0',
    },
    :instance_type_lookup => {
      'small' => {
        :name => "aws.instance_type = 't2.micro'",
        :type => :alias,
      },
      'medium' => {
        :name => "aws.instance_type  = 't2.medium'",
        :type => :alias,
      },
    },
    :location_lookup => {
      'us_west' => "
        aws.region = 'us-west-1'
        aws.availability_zone = 'us-west-1b'
      "
    },
  },
  'virtualbox' => {
    :requires => "
      require 'vagrant-hostmanager'
    ",
    :use_bucket => true,
    :sync_folder => "
      deploy_config.vm.synced_folder 'puppet/', '/opt/puppet'
      deploy_config.vm.synced_folder '.', '/vagrant', disabled: true
    ",
    :defaults => {
      :common_image_image => 'CentOS-6.5-x64',
      :common_instance_type => 'small',
    },
    :deploy_box_config => "
      deploy_config.vm.provider :virtualbox do |virtualbox,override|
        eval(str_instance_type)
      end
      deploy_config.vm.network 'private_network', type: 'dhcp'
      config.ssh.username = box[:ssh_username] || $provider_config[$provider][:images_config][instance_image][:ssh_username]
    ",
    :ip_resolver => $ip_resolver[:ifconfig].call('eth1'),
    :instances_config => {
      'puppetmaster' => {
        :common_instance_type => 'small',
        :common_image_name => 'CentOS-6.5-x64',
        :config_steps_type => 'default_linux',
        #:repo_url => 'https://github.com/emccode/vagrant-puppet-scaleio',
        :commands => {
          :dns_update => $images_config['default_linux'][:dns_update],
          :pre_install => $images_config['CentOS-6.5-x64'][:commands][:puppetmaster_remove],
          :set_hostname => proc {|hostname,domain| $images_config['default_linux'][:commands][:set_hostname].call(hostname,domain) },
          :install => proc {|config_param| $images_config['CentOS-6.5-x64'][:commands][:puppetmaster_install].call(config_param) },
          #:sitepp_curl => $images_config['default_linux'][:commands][:curl_file].call('https://raw.githubusercontent.com/emccode/vagrant-puppet-scaleio/master/puppet/manifests/examples/site.pp-hosts_lookup','/etc/puppet/manifests/site.pp')
        }
      },
      'puppetagent' => {
        :common_instance_type => 'medium',
        :common_image_name => 'CentOS-6.5-x64',
        :config_steps_type => 'default_linux',
        :commands => {
          :dns_update => $images_config['default_linux'][:dns_update],
          :pre_install => $images_config['CentOS-6.5-x64'][:commands][:puppetagent_remove],
          :set_hostname => proc {|hostname,domain| $images_config['default_linux'][:commands][:set_hostname].call(hostname,domain) },
          :install => proc {|config_param| $images_config['CentOS-6.5-x64'][:commands][:puppetagent_install].call(config_param) }
        }        
      },
    },
    :images_config => {
      'CentOS-6.5-x64' => {
        :ssh_username => 'vagrant',
        :box => 'puppetlabs/centos-6.5-64-nocm'
      }
    },
    :images_lookup => {
      'CentOS-6.5-x64' => 'CentOS-6.5-x64',
    },
    :instance_type_lookup => {
      'small' => {
        :memory => "virtualbox.memory = 512",
        :cpus => "virtualbox.cpus = 1",
        :type => :custom,
      },
      'medium' => {
        :memory => "virtualbox.memory = 1024",
        :cpus => "virtualbox.cpus = 1",
        :type => :custom,
      },
    }, 
  },
  :defaults => {
    :config => '
      config.ssh.pty = true
      config.nfs.functional = false
    ',
    :config_param => '{
      :type => box_type,
      :hostname => box[:hostname],
      :common_image_name => common_image_name,
      :domain => domain,
      :object_creds => object_creds,
      #:repo_url => repo_url,
      #:curl_file => $provider_config[$provider][:instances_config][box_type][:commands][:sitepp_curl],
    }',
    :instances_config => {
      'puppetmaster' => {
        :domain => 'scaleio.local',
        :plugin_config => "
          config.hostmanager.enabled = true
          config.hostmanager.manage_host = false
          config.hostmanager.ignore_private_ip = true
          config.hostmanager.include_offline = false
        ",
        :plugin_config_vm => "
          deploy_config.hostmanager.aliases = box[:hostname] 
        ",
      },
      'puppetagent' => {
        :domain => 'scaleio.local',
        :plugin_config => "
          config.hostmanager.enabled = true
          config.hostmanager.manage_host = false
          config.hostmanager.ignore_private_ip = true
          config.hostmanager.include_offline = false
        ",
        :plugin_config_vm => "
          deploy_config.hostmanager.aliases = box[:hostname] 
        ",
      }
    }
  },
}