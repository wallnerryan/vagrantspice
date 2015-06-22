
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
      :firewall => 'default',
    },
    :ip_resolver => $ip_resolver[:ssh_ip],
    :instances_config => {
      'puppetmaster' => {
        :common_instance_type => 'mini',
        :common_image_name => 'CentOS-7-x64',
        :config_steps_type => 'default_linux',
        :sync_folder => "
          deploy_config.vm.synced_folder 'sync', '/opt/sync'
          deploy_config.vm.synced_folder 'cert', '/tmp/cert'
          deploy_config.vm.synced_folder '.', '/vagrant', disabled: true
        ",
        :commands => {
          :dns_update => $images_config['default_linux'][:dns_update],
          :pre_install => $images_config['CentOS-7-x64'][:commands][:puppetmaster_remove],
          :set_hostname => proc {|hostname,domain| $images_config['default_linux'][:commands][:set_hostname].call(hostname,domain) },
          :install => proc {|config_param| $images_config['CentOS-7-x64'][:commands][:puppetmaster_install].call(config_param) },
          :post_install => proc {|config_param| $images_config['CentOS-7-x64'][:commands][:puppetmaster_install_scaleio].call(config_param) },
        }
      },
      'puppetagent' => {
        :common_instance_type => 'medium',
        :common_image_name => 'CentOS-7-x64',
        :config_steps_type => 'default_linux',
        :sync_folder => "
          deploy_config.vm.synced_folder 'sync/schelper', '/opt/schelper'
          deploy_config.vm.synced_folder '.', '/vagrant', disabled: true
        ",
        :commands => {
          :dns_update => $images_config['default_linux'][:dns_update],
          :pre_install => $images_config['CentOS-7-x64'][:commands][:puppetagent_remove],
          :set_hostname => proc {|hostname,domain| $images_config['default_linux'][:commands][:set_hostname].call(hostname,domain) },
          :install => proc {|config_param| $images_config['CentOS-7-x64'][:commands][:puppetagent_install].call(config_param) },
          :post_install => proc {|config_param| $images_config['CentOS-7-x64'][:commands][:puppetagent_install_docker_scaleio].call(config_param) },
        }
      },
      'coreos' => {
        :common_instance_type => 'micro',
        :common_image_name => 'CoreOS-stable',
        :config_steps_type => 'default_coreos',
        :commands => {
          :pre_install => '',
          :install => proc {|config_param|  },
          :post_install => proc {|config_param,box_param| },
        },
      },
      'coreos-fleet' => {
        :common_instance_type => 'micro',
        :common_image_name => 'CoreOS-stable',
        :config_steps_type => 'default_coreos',
        :commands => {
          :pre_install => '',
          :install => proc {|config_param|  },
          :post_install => proc {|config_param,box_param| "
public_ipv4=`curl -s ip.alt.io`

cat <<EOF > /usr/share/oem/cloud-config.yml
#cloud-config

coreos:
  etcd:
    discovery: #{config_param[:etcd_url]}
    addr: $public_ipv4:4001
    peer-addr: $public_ipv4:7001
    peer-election-timeout: 7500
    peer-heartbeat-interval: 1500
  fleet:
    public-ip: $public_ipv4
    metadata: region=#{box_param[:location]},provider=#{$provider},platform=cloud,instance_type=#{box_param[:common_instance_type]}
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

        eval($provider_config[$provider][:storage])

        eval($provider_config[$provider][:firewall])

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
      'centos-7-v20150226' => {
        :ssh_username => 'clintonkitson'
      },
      'coreos-stable-494-5-0-v20141215' => {
        :ssh_username => 'core'
      },
      'coreos-beta-522-3-0-v20141226' => {
        :ssh_username => 'core'
      },
      'coreos-alpha-549-0-0-v20150102' => {
        :ssh_username => 'core'
      }
    },
    :images_lookup => {
      'us_central' => {
        'CentOS-6.5-x64' => 'centos-6-v20141021',
        'CoreOS-stable' => 'coreos-stable-494-5-0-v20141215',
        'CoreOS-beta' => 'coreos-beta-522-3-0-v20141226',
        'CoreOS-alpha' => 'coreos-alpha-549-0-0-v20150102',
        'CentOS-7-x64' => 'centos-7-v20150226'
      },
      'europe_west' => {
        'CentOS-6.5-x64' => 'centos-6-v20141021',
        'CoreOS-stable' => 'coreos-stable-494-5-0-v20141215',
        'CoreOS-beta' => 'coreos-beta-522-3-0-v20141226',
        'CoreOS-alpha' => 'coreos-alpha-549-0-0-v20150102',
        'CentOS-7-x64' => 'centos-7-v20150226'
      },
      'asia_east' => {
        'CentOS-6.5-x64' => 'centos-6-v20141021',
        'CoreOS-stable' => 'coreos-stable-494-5-0-v20141215',
        'CoreOS-beta' => 'coreos-beta-522-3-0-v20141226',
        'CoreOS-alpha' => 'coreos-alpha-549-0-0-v20150102',
        'CentOS-7-x64' => 'centos-7-v20150226'
      },
    },
    :instance_type_lookup => {
      'us_central' => {
        'micro' => {
          :name => "google.machine_type = 'f1-micro'",
          :type => :alias,
        },
        'small' => {
          :name => "google.machine_type = 'n1-standard-1'",
          :type => :alias,
        },
        'medium' => {
          :name => "google.machine_type  = 'n1-standard-2'",
          :type => :alias,
        },
        'large' => {
          :name => "google.machine_type  = 'n1-standard-8'",
          :type => :alias,
        },
        'lowcpu_13mem' => {
          :name => "google.machine_type  = 'n1-highmem-2'",
          :type => :alias,
        },
        'lowcpu_26mem' => {
          :name => "google.machine_type  = 'n1-highmem-4'",
          :type => :alias,
        },
        '4cpu_lowmem' => {
          :name => "google.machine_type  = 'n1-highcpu-4'",
          :type => :alias,
        },
        '8cpu_lowmem' => {
          :name => "google.machine_type  = 'n1-highcpu-8'",
          :type => :alias,
        },
        'max_cpu' => {
          :name => "google.machine_type  = 'n1-highcpu-16'",
          :type => :alias,
        },
        'max_memory' => {
          :name => "google.machine_type  = 'n1-highmem-16'",
          :type => :alias,
        },
      },
      'europe_west' => {
        'micro' => {
          :name => "google.machine_type = 'f1-micro'",
          :type => :alias,
        },
        'small' => {
          :name => "google.machine_type = 'n1-standard-1'",
          :type => :alias,
        },
        'medium' => {
          :name => "google.machine_type  = 'n1-standard-2'",
          :type => :alias,
        },
        'large' => {
          :name => "google.machine_type  = 'n1-standard-8'",
          :type => :alias,
        },
        'lowcpu_13mem' => {
          :name => "google.machine_type  = 'n1-highmem-2'",
          :type => :alias,
        },
        'lowcpu_26mem' => {
          :name => "google.machine_type  = 'n1-highmem-4'",
          :type => :alias,
        },
        '4cpu_lowmem' => {
          :name => "google.machine_type  = 'n1-highcpu-4'",
          :type => :alias,
        },
        '8cpu_lowmem' => {
          :name => "google.machine_type  = 'n1-highcpu-8'",
          :type => :alias,
        },
        'max_cpu' => {
          :name => "google.machine_type  = 'n1-highcpu-16'",
          :type => :alias,
        },
        'max_memory' => {
          :name => "google.machine_type  = 'n1-highmem-16'",
          :type => :alias,
        },
      },
      'asia_east' => {
        'micro' => {
          :name => "google.machine_type = 'f1-micro'",
          :type => :alias,
        },
        'small' => {
          :name => "google.machine_type = 'n1-standard-1'",
          :type => :alias,
        },
        'medium' => {
          :name => "google.machine_type  = 'n1-standard-2'",
          :type => :alias,
        },
        'large' => {
          :name => "google.machine_type  = 'n1-standard-8'",
          :type => :alias,
        },
        'lowcpu_13mem' => {
          :name => "google.machine_type  = 'n1-highmem-2'",
          :type => :alias,
        },
        'lowcpu_26mem' => {
          :name => "google.machine_type  = 'n1-highmem-4'",
          :type => :alias,
        },
        '4cpu_lowmem' => {
          :name => "google.machine_type  = 'n1-highcpu-4'",
          :type => :alias,
        },
        '8cpu_lowmem' => {
          :name => "google.machine_type  = 'n1-highcpu-8'",
          :type => :alias,
        },
        'max_cpu' => {
          :name => "google.machine_type  = 'n1-highcpu-16'",
          :type => :alias,
        },
        'max_memory' => {
          :name => "google.machine_type  = 'n1-highmem-16'",
          :type => :alias,
        },
      },
    },
    :location_lookup => {
      'us_central' => "
        google.zone = 'us-central1-f'
      ",
      'europe_west' => "
        google.zone = 'europe-west1-b'
      ",
      'asia_east' => "
        google.zone = 'asia-east1-a'
      ",
    },
    :firewall => 'google.network = str_firewall',
    :storage => '
      google.disk_size = str_storage unless !str_storage
      ',
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
      :common_location_name => 'us_east',
      :common_image_name => 'CentOS-6.5-x64',
      :common_instance_type => 'small',
    },
    :ip_resolver => $ip_resolver[:ifconfig].call('eth1'),
    :instances_config => {
      'puppetmaster' => {
        :common_instance_type => 'mini',
        :common_image_name => 'CentOS-7-x64',
        :config_steps_type => 'default_linux',
        :sync_folder => "
          deploy_config.vm.synced_folder 'sync', '/opt/sync'
          deploy_config.vm.synced_folder 'cert', '/tmp/cert'
          deploy_config.vm.synced_folder '.', '/vagrant', disabled: true
        ",
        :commands => {
          :dns_update => $images_config['default_linux'][:dns_update],
          :pre_install => $images_config['CentOS-7-x64'][:commands][:puppetmaster_remove],
          :set_hostname => proc {|hostname,domain| $images_config['default_linux'][:commands][:set_hostname].call(hostname,domain) },
          :install => proc {|config_param| $images_config['CentOS-7-x64'][:commands][:puppetmaster_install].call(config_param) },
          :post_install => proc {|config_param| $images_config['CentOS-7-x64'][:commands][:puppetmaster_install_scaleio].call(config_param) },
        }
      },
      'puppetagent' => {
        :common_instance_type => 'medium',
        :common_image_name => 'CentOS-7-x64',
        :config_steps_type => 'default_linux',
        :sync_folder => "
          deploy_config.vm.synced_folder 'sync/schelper', '/opt/schelper'
          deploy_config.vm.synced_folder '.', '/vagrant', disabled: true
        ",
        :commands => {
          :dns_update => $images_config['default_linux'][:dns_update],
          :pre_install => $images_config['CentOS-7-x64'][:commands][:puppetagent_remove],
          :set_hostname => proc {|hostname,domain| $images_config['default_linux'][:commands][:set_hostname].call(hostname,domain) },
          :install => proc {|config_param| $images_config['CentOS-7-x64'][:commands][:puppetagent_install].call(config_param) },
          :post_install => proc {|config_param| $images_config['CentOS-7-x64'][:commands][:puppetagent_install_docker_scaleio].call(config_param) },
        }
      },
      'coreos' => {
        :common_instance_type => 'micro',
        :common_image_name => 'CoreOS-stable',
        :config_steps_type => 'default_coreos',
        :commands => {
          :pre_install => '',
          :install => proc {|config_param|  },
          :post_install => proc {|config_param,box_param| },
        },
      },
      'coreos-fleet' => {
        :common_instance_type => 'micro',
        :common_image_name => 'CoreOS-stable',
        :config_steps_type => 'default_coreos',
        :commands => {
          :pre_install => '',
          :install => proc {|config_param|  },
          :post_install => proc {|config_param,box_param| "
public_ipv4=`curl -s ip.alt.io`

cat <<EOF > /usr/share/oem/cloud-config.yml
#cloud-config

coreos:
  etcd:
    discovery: #{config_param[:etcd_url]}
    addr: $public_ipv4:4001
    peer-addr: $public_ipv4:7001
    peer-election-timeout: 7500
    peer-heartbeat-interval: 1500
  fleet:
    public-ip: $public_ipv4
    metadata: region=#{box_param[:location]},provider=#{$provider},platform=cloud,instance_type=#{box_param[:common_instance_type]}
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
      'CentOS 7 (PVHVM)' => {
        :ssh_username => 'root'
      },
      'CentOS 6.5 (PVHVM)' => {
        :ssh_username => 'root'
      },
      'CoreOS (Stable)' => {
        :ssh_username => 'core'
      },
      'CoreOS (Beta)' => {
        :ssh_username => 'core'
      },
      'CoreOS (Alpha)' => {
        :ssh_username => 'core'
      },
    },
    :images_lookup => {
      'us_central' => {
        'CentOS-7-x64' => 'CentOS 7 (PVHVM)',
        'CentOS-6.5-x64' => 'CentOS 6.5 (PVHVM)',
        'CoreOS-stable' => 'CoreOS (Stable)',
        'CoreOS-beta' => 'CoreOS (Beta)',
        'CoreOS-alpha' => 'CoreOS (Alpha)',
      },
      'us_east' => {
        'CentOS-7-x64' => 'CentOS 7 (PVHVM)',
        'CentOS-6.5-x64' => 'CentOS 6.5 (PVHVM)',
        'CoreOS-stable' => 'CoreOS (Stable)',
        'CoreOS-beta' => 'CoreOS (Beta)',
        'CoreOS-alpha' => 'CoreOS (Alpha)',
      },
      'asia_east' => {
        'CentOS-7-x64' => 'CentOS 7 (PVHVM)',
        'CentOS-6.5-x64' => 'CentOS 6.5 (PVHVM)',
        'CoreOS-stable' => 'CoreOS (Stable)',
        'CoreOS-beta' => 'CoreOS (Beta)',
        'CoreOS-alpha' => 'CoreOS (Alpha)',
      },
      'aus_east' => {
        'CentOS-7-x64' => 'CentOS 7 (PVHVM)',
        'CentOS-6.5-x64' => 'CentOS 6.5 (PVHVM)',
        'CoreOS-stable' => 'CoreOS (Stable)',
        'CoreOS-beta' => 'CoreOS (Beta)',
        'CoreOS-alpha' => 'CoreOS (Alpha)',
      },

    },
    :instance_type_lookup => {
      'us_central' => {
        'micro' => {
          :name => "rs.flavor = '512MB Standard Instance'",
          :type => :alias,
        },
        'small' => {
          :name => "rs.flavor = '1GB Standard Instance'",
          :type => :alias,
        },
        'medium' => {
          :name => "rs.flavor  = '2 GB General Purpose v1'",
          :type => :alias,
        },
        'large' => {
          :name => "rs.flavor = '8 GB General Purpose v1'",
          :type => :alias,
        },
        'lowcpu_13mem' => {
          :name => "rs.flavor = '15 GB Memory v1'",
          :type => :alias,
        },
        'lowcpu_26mem' => {
          :name => "rs.flavor = '30 GB Memory v1'",
          :type => :alias,
        },
        '4cpu_lowmem' => {
          :name => "rs.flavor = '7.5 GB Compute v1'",
          :type => :alias,
        },
        '8cpu_lowmem' => {
          :name => "rs.flavor = '15 GB Compute v1'",
          :type => :alias,
        },
        'max_cpu' => {
          :name => "rs.flavor = '30 GB Compute v1'",
          :type => :alias,
        },
        'max_memory' => {
          :name => "rs.flavor = '120 GB Memory v1'",
          :type => :alias,
        },
      },
      'us_east' => {
        'micro' => {
          :name => "rs.flavor = '512MB Standard Instance'",
          :type => :alias,
        },
        'small' => {
          :name => "rs.flavor = '1GB Standard Instance'",
          :type => :alias,
        },
        'medium' => {
          :name => "rs.flavor  = '2 GB General Purpose v1'",
          :type => :alias,
        },
        'large' => {
          :name => "rs.flavor = '8 GB General Purpose v1'",
          :type => :alias,
        },
        'lowcpu_13mem' => {
          :name => "rs.flavor = '15 GB Memory v1'",
          :type => :alias,
        },
        'lowcpu_26mem' => {
          :name => "rs.flavor = '30 GB Memory v1'",
          :type => :alias,
        },
        '4cpu_lowmem' => {
          :name => "rs.flavor = '7.5 GB Compute v1'",
          :type => :alias,
        },
        '8cpu_lowmem' => {
          :name => "rs.flavor = '15 GB Compute v1'",
          :type => :alias,
        },
        'max_cpu' => {
          :name => "rs.flavor = '30 GB Compute v1'",
          :type => :alias,
        },
        'max_memory' => {
          :name => "rs.flavor = '120 GB Memory v1'",
          :type => :alias,
        },
      },
      'asia_east' => {
        'micro' => {
          :name => "rs.flavor = '512MB Standard Instance'",
          :type => :alias,
        },
        'small' => {
          :name => "rs.flavor = '1GB Standard Instance'",
          :type => :alias,
        },
        'medium' => {
          :name => "rs.flavor  = '2 GB General Purpose v1'",
          :type => :alias,
        },
        'large' => {
          :name => "rs.flavor = '8 GB General Purpose v1'",
          :type => :alias,
        },
        'lowcpu_13mem' => {
          :name => "rs.flavor = '15 GB Memory v1'",
          :type => :alias,
        },
        'lowcpu_26mem' => {
          :name => "rs.flavor = '30 GB Memory v1'",
          :type => :alias,
        },
        '4cpu_lowmem' => {
          :name => "rs.flavor = '7.5 GB Compute v1'",
          :type => :alias,
        },
        '8cpu_lowmem' => {
          :name => "rs.flavor = '15 GB Compute v1'",
          :type => :alias,
        },
        'max_cpu' => {
          :name => "rs.flavor = '30 GB Compute v1'",
          :type => :alias,
        },
        'max_memory' => {
          :name => "rs.flavor = '120 GB Memory v1'",
          :type => :alias,
        },
      },
      'aus_east' => {
        'micro' => {
          :name => "rs.flavor = '512MB Standard Instance'",
          :type => :alias,
        },
        'small' => {
          :name => "rs.flavor = '1GB Standard Instance'",
          :type => :alias,
        },
        'medium' => {
          :name => "rs.flavor  = '2 GB General Purpose v1'",
          :type => :alias,
        },
        'large' => {
          :name => "rs.flavor = '8 GB General Purpose v1'",
          :type => :alias,
        },
        'lowcpu_13mem' => {
          :name => "rs.flavor = '15 GB Memory v1'",
          :type => :alias,
        },
        'lowcpu_26mem' => {
          :name => "rs.flavor = '30 GB Memory v1'",
          :type => :alias,
        },
        '4cpu_lowmem' => {
          :name => "rs.flavor = '7.5 GB Compute v1'",
          :type => :alias,
        },
        '8cpu_lowmem' => {
          :name => "rs.flavor = '15 GB Compute v1'",
          :type => :alias,
        },
        'max_cpu' => {
          :name => "rs.flavor = '30 GB Compute v1'",
          :type => :alias,
        },
        'max_memory' => {
          :name => "rs.flavor = '120 GB Memory v1'",
          :type => :alias,
        },
      },
    },
    :location_lookup => {
      'us_central' => "
        rs.rackspace_region = :dfw
      ",
      'us_east' => "
        rs.rackspace_region = :iad
      ",
      'asia_east' => "
        rs.rackspace_region = :hkg
      ",
      'aus_east' => "
        rs.rackspace_region = :syd
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
      :vm_location => 'us_west',
      :common_image_image => 'CentOS-6.5-x64',
      :common_instance_type => 'small',
    },
    :deploy_box_config => "
      deploy_config.vm.provider :azure do |azure,override|
        azure.mgmt_certificate = $consumer_config[$provider][:mgmt_certificate]
        azure.mgmt_endpoint = $consumer_config[$provider][:mgmt_endpoint]
        azure.subscription_id = $consumer_config[$provider][:subscription_id]

        azure.vm_image = instance_image
        eval(str_instance_type)
        azure.vm_user = box[:ssh_username] || $provider_config[$provider][:images_config][instance_image][:ssh_username]

        eval($provider_config[$provider][:firewall])

        azure.vm_name = box[:hostname]
        eval(str_location)
        azure.ssh_private_key_file = box[:private_key] || $provider_config[$provider][:instances_config][box_type][:private_key] || $consumer_config[$provider][:private_key]
        azure.ssh_certificate_file = box[:public_cert] || $provider_config[$provider][:instances_config][box_type][:public_cert] || $consumer_config[$provider][:private_key]
        azure.ssh_port = box[:ssh_port] || $provider_config[$provider][:instances_config][box_type][:ssh_port]
        override.ssh.private_key_path = box[:private_key] || $provider_config[$provider][:instances_config][box_type][:private_key] || $consumer_config[$provider][:private_key]
      end
      config.ssh.username = box[:ssh_username] || $provider_config[$provider][:images_config][instance_image][:ssh_username]
    ",
    :ip_resolver => $ip_resolver[:ssh_hostname],
    :instances_config => {
      'puppetmaster' => {
        :common_instance_type => 'mini',
        :common_image_name => 'CentOS-7-x64',
        :config_steps_type => 'default_linux',
        :sync_folder => "
          deploy_config.vm.synced_folder 'sync', '/opt/sync'
          deploy_config.vm.synced_folder 'cert', '/tmp/cert'
          deploy_config.vm.synced_folder '.', '/vagrant', disabled: true
        ",
        :commands => {
          :dns_update => $images_config['default_linux'][:dns_update],
          :pre_install => $images_config['CentOS-7-x64'][:commands][:puppetmaster_remove],
          :set_hostname => proc {|hostname,domain| $images_config['default_linux'][:commands][:set_hostname].call(hostname,domain) },
          :install => proc {|config_param| $images_config['CentOS-7-x64'][:commands][:puppetmaster_install].call(config_param) },
          :post_install => proc {|config_param| $images_config['CentOS-7-x64'][:commands][:puppetmaster_install_scaleio].call(config_param) },
        }
      },
      'puppetagent' => {
        :common_instance_type => 'medium',
        :common_image_name => 'CentOS-7-x64',
        :config_steps_type => 'default_linux',
        :sync_folder => "
          deploy_config.vm.synced_folder 'sync/schelper', '/opt/schelper'
          deploy_config.vm.synced_folder '.', '/vagrant', disabled: true
        ",
        :commands => {
          :dns_update => $images_config['default_linux'][:dns_update],
          :pre_install => $images_config['CentOS-7-x64'][:commands][:puppetagent_remove],
          :set_hostname => proc {|hostname,domain| $images_config['default_linux'][:commands][:set_hostname].call(hostname,domain) },
          :install => proc {|config_param| $images_config['CentOS-7-x64'][:commands][:puppetagent_install].call(config_param) },
          :post_install => proc {|config_param| $images_config['CentOS-7-x64'][:commands][:puppetagent_install_docker_scaleio].call(config_param) },
        }
      },
      'coreos' => {
        :common_instance_type => 'micro',
        :common_image_name => 'CoreOS-stable',
        :config_steps_type => 'default_coreos',
        :commands => {
          :pre_install => '',
          :install => proc {|config_param|  },
          :post_install => proc {|config_param,box_param| },
        },
      },
      'coreos-fleet' => {
        :common_instance_type => 'micro',
        :common_image_name => 'CoreOS-stable',
        :config_steps_type => 'default_coreos',
        :commands => {
          :pre_install => '',
          :install => proc {|config_param|  },
          :post_install => proc {|config_param,box_param| "
public_ipv4=`curl -s ip.alt.io`

cat <<EOF > /usr/share/oem/cloud-config.yml
#cloud-config

coreos:
  etcd:
    discovery: #{config_param[:etcd_url]}
    addr: $public_ipv4:4001
    peer-addr: $public_ipv4:7001
    peer-election-timeout: 7500
    peer-heartbeat-interval: 1500
  fleet:
    public-ip: $public_ipv4
    metadata: region=#{box_param[:location]},provider=#{$provider},platform=cloud,instance_type=#{box_param[:common_instance_type]}
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
    :images_config => {
      '0b11de9248dd4d87b18621318e037d37__RightImage-CentOS-7.0-x64-v14.2' => {
        :ssh_username => 'centos',
        :box => 'azure'
      },
      '5112500ae3b842c8b9c604889f8753c3__OpenLogic-CentOS-65-20140926' => {
        :ssh_username => 'centos',
        :box => 'azure'
      },
      '2b171e93f07c4903bcad35bda10acf22__CoreOS-Stable-494.5.0' => {
        :ssh_username => 'core',
        :box => 'azure'
      },
      '2b171e93f07c4903bcad35bda10acf22__CoreOS-Beta-522.3.0' => {
        :ssh_username => 'core',
        :box => 'azure'
      },
      '2b171e93f07c4903bcad35bda10acf22__CoreOS-Alpha-547.0.0' => {
        :ssh_username => 'core',
        :box => 'azure'
      },
    },
    :images_lookup => {
      'asia_east' => {
        'CentOS-7-x64' => '0b11de9248dd4d87b18621318e037d37__RightImage-CentOS-7.0-x64-v14.2',
        'CentOS-6.5-x64' => '5112500ae3b842c8b9c604889f8753c3__OpenLogic-CentOS-65-20140926',
        'CoreOS-stable' => '2b171e93f07c4903bcad35bda10acf22__CoreOS-Stable-494.5.0',
        'CoreOS-beta' => '2b171e93f07c4903bcad35bda10acf22__CoreOS-Beta-522.3.0',
        'CoreOS-alpha' => '2b171e93f07c4903bcad35bda10acf22__CoreOS-Alpha-522.2.0',
      },
      'aus_east' => {
        'CentOS-7-x64' => '0b11de9248dd4d87b18621318e037d37__RightImage-CentOS-7.0-x64-v14.2',
        'CentOS-6.5-x64' => '5112500ae3b842c8b9c604889f8753c3__OpenLogic-CentOS-65-20140926',
        'CoreOS-stable' => '2b171e93f07c4903bcad35bda10acf22__CoreOS-Stable-494.5.0',
        'CoreOS-beta' => '2b171e93f07c4903bcad35bda10acf22__CoreOS-Beta-522.3.0',
        'CoreOS-alpha' => '2b171e93f07c4903bcad35bda10acf22__CoreOS-Alpha-547.0.0',
      },
      'europe_north' => {
        'CentOS-7-x64' => '0b11de9248dd4d87b18621318e037d37__RightImage-CentOS-7.0-x64-v14.2',
        'CentOS-6.5-x64' => '5112500ae3b842c8b9c604889f8753c3__OpenLogic-CentOS-65-20140926',
        'CoreOS-stable' => '2b171e93f07c4903bcad35bda10acf22__CoreOS-Stable-494.5.0',
        'CoreOS-beta' => '2b171e93f07c4903bcad35bda10acf22__CoreOS-Beta-522.3.0',
        'CoreOS-alpha' => '2b171e93f07c4903bcad35bda10acf22__CoreOS-Alpha-547.0.0',
      },
      'europe_west' => {
        'CentOS-7-x64' => '0b11de9248dd4d87b18621318e037d37__RightImage-CentOS-7.0-x64-v14.2',
        'CentOS-6.5-x64' => '5112500ae3b842c8b9c604889f8753c3__OpenLogic-CentOS-65-20140926',
        'CoreOS-stable' => '2b171e93f07c4903bcad35bda10acf22__CoreOS-Stable-494.5.0',
        'CoreOS-beta' => '2b171e93f07c4903bcad35bda10acf22__CoreOS-Beta-522.3.0',
        'CoreOS-alpha' => '2b171e93f07c4903bcad35bda10acf22__CoreOS-Alpha-547.0.0',
      },
      'japan_west' => {
        'CentOS-7-x64' => '0b11de9248dd4d87b18621318e037d37__RightImage-CentOS-7.0-x64-v14.2',
        'CentOS-6.5-x64' => '5112500ae3b842c8b9c604889f8753c3__OpenLogic-CentOS-65-20140926',
        'CoreOS-stable' => '2b171e93f07c4903bcad35bda10acf22__CoreOS-Stable-494.5.0',
        'CoreOS-beta' => '2b171e93f07c4903bcad35bda10acf22__CoreOS-Beta-522.3.0',
        'CoreOS-alpha' => '2b171e93f07c4903bcad35bda10acf22__CoreOS-Alpha-547.0.0',
      },
      'us_central' => {
        'CentOS-7-x64' => '0b11de9248dd4d87b18621318e037d37__RightImage-CentOS-7.0-x64-v14.2',
        'CentOS-6.5-x64' => '5112500ae3b842c8b9c604889f8753c3__OpenLogic-CentOS-65-20140926',
        'CoreOS-stable' => '2b171e93f07c4903bcad35bda10acf22__CoreOS-Stable-494.5.0',
        'CoreOS-beta' => '2b171e93f07c4903bcad35bda10acf22__CoreOS-Beta-522.3.0',
        'CoreOS-alpha' => '2b171e93f07c4903bcad35bda10acf22__CoreOS-Alpha-547.0.0',
      },
      'us_east' => {
        'CentOS-7-x64' => '0b11de9248dd4d87b18621318e037d37__RightImage-CentOS-7.0-x64-v14.2',
        'CentOS-6.5-x64' => '5112500ae3b842c8b9c604889f8753c3__OpenLogic-CentOS-65-20140926',
        'CoreOS-stable' => '2b171e93f07c4903bcad35bda10acf22__CoreOS-Stable-494.5.0',
        'CoreOS-beta' => '2b171e93f07c4903bcad35bda10acf22__CoreOS-Beta-522.3.0',
        'CoreOS-alpha' => '2b171e93f07c4903bcad35bda10acf22__CoreOS-Alpha-547.0.0',
      },
      'us_west' => {
        'CentOS-7-x64' => '0b11de9248dd4d87b18621318e037d37__RightImage-CentOS-7.0-x64-v14.2',
        'CentOS-6.5-x64' => '5112500ae3b842c8b9c604889f8753c3__OpenLogic-CentOS-65-20140926',
        'CoreOS-stable' => '2b171e93f07c4903bcad35bda10acf22__CoreOS-Stable-494.5.0',
        'CoreOS-beta' => '2b171e93f07c4903bcad35bda10acf22__CoreOS-Beta-522.3.0',
        'CoreOS-alpha' => '2b171e93f07c4903bcad35bda10acf22__CoreOS-Alpha-547.0.0',
      },
    },
    :instance_type_lookup => {
      'asia_east' => {
        'micro' => {
          :name => "azure.vm_size = 'ExtraLarge'",
          :type => :alias,
        },
        'small' => {
          :name => "azure.vm_size = 'Small'",
          :type => :alias,
        },
        'medium' => {
          :name => "azure.vm_size = 'Medium'",
          :type => :alias,
        },
        'large' => {
          :name => "azure.vm_size = 'Large'",
          :type => :alias,
        },
        'lowcpu_13mem' => {
          :name => "azure.vm_size = 'ExtraLarge'",
          :type => :alias,
        },
        'lowcpu_26mem' => {
          :name => "azure.vm_size = 'A6'",
          :type => :alias,
        },
        '4cpu_lowmem' => {
          :name => "azure.vm_size = 'Large'",
          :type => :alias,
        },
        '8cpu_lowmem' => {
          :name => "azure.vm_size = 'ExtraLarge'",
          :type => :alias,
        },
        'max_cpu' => {
          :name => "azure.vm_size = 'ExtraLarge'",
          :type => :alias,
        },
        'max_memory' => {
          :name => "azure.vm_size = 'A7'",
          :type => :alias,
        },
      },
      'aus_east' => {
        'micro' => {
          :name => "azure.vm_size = 'ExtraSmall'",
          :type => :alias,
        },
        'small' => {
          :name => "azure.vm_size = 'Small'",
          :type => :alias,
        },
        'medium' => {
          :name => "azure.vm_size = 'Medium'",
          :type => :alias,
        },
        'large' => {
          :name => "azure.vm_size = 'Large'",
          :type => :alias,
        },
        'lowcpu_13mem' => {
          :name => "azure.vm_size = 'ExtraLarge'",
          :type => :alias,
        },
        'lowcpu_26mem' => {
          :name => "azure.vm_size = 'A6'",
          :type => :alias,
        },
        '4cpu_lowmem' => {
          :name => "azure.vm_size = 'Large'",
          :type => :alias,
        },
        '8cpu_lowmem' => {
          :name => "azure.vm_size = 'ExtraLarge'",
          :type => :alias,
        },
        'max_cpu' => {
          :name => "azure.vm_size = 'ExtraLarge'",
          :type => :alias,
        },
        'max_memory' => {
          :name => "azure.vm_size = 'A7'",
          :type => :alias,
        },
      },
      'europe_north' => {
        'micro' => {
          :name => "azure.vm_size = 'ExtraSmall'",
          :type => :alias,
        },
        'small' => {
          :name => "azure.vm_size = 'Small'",
          :type => :alias,
        },
        'medium' => {
          :name => "azure.vm_size = 'Medium'",
          :type => :alias,
        },
        'large' => {
          :name => "azure.vm_size = 'Large'",
          :type => :alias,
        },
        'lowcpu_13mem' => {
          :name => "azure.vm_size = 'ExtraLarge'",
          :type => :alias,
        },
        'lowcpu_26mem' => {
          :name => "azure.vm_size = 'A6'",
          :type => :alias,
        },
        '4cpu_lowmem' => {
          :name => "azure.vm_size = 'Large'",
          :type => :alias,
        },
        '8cpu_lowmem' => {
          :name => "azure.vm_size = 'ExtraLarge'",
          :type => :alias,
        },
        'max_cpu' => {
          :name => "azure.vm_size = 'ExtraLarge'",
          :type => :alias,
        },
        'max_memory' => {
          :name => "azure.vm_size = 'A7'",
          :type => :alias,
        },
      },
      'europe_west' => {
        'micro' => {
          :name => "azure.vm_size = 'ExtraSmall'",
          :type => :alias,
        },
        'small' => {
          :name => "azure.vm_size = 'Small'",
          :type => :alias,
        },
        'medium' => {
          :name => "azure.vm_size = 'Medium'",
          :type => :alias,
        },
        'large' => {
          :name => "azure.vm_size = 'Large'",
          :type => :alias,
        },
        'lowcpu_13mem' => {
          :name => "azure.vm_size = 'ExtraLarge'",
          :type => :alias,
        },
        'lowcpu_26mem' => {
          :name => "azure.vm_size = 'A6'",
          :type => :alias,
        },
        '4cpu_lowmem' => {
          :name => "azure.vm_size = 'Large'",
          :type => :alias,
        },
        '8cpu_lowmem' => {
          :name => "azure.vm_size = 'ExtraLarge'",
          :type => :alias,
        },
        'max_cpu' => {
          :name => "azure.vm_size = 'ExtraLarge'",
          :type => :alias,
        },
        'max_memory' => {
          :name => "azure.vm_size = 'A7'",
          :type => :alias,
        },
      },
      'japan_west' => {
        'micro' => {
          :name => "azure.vm_size = 'ExtraSmall'",
          :type => :alias,
        },
        'small' => {
          :name => "azure.vm_size = 'Small'",
          :type => :alias,
        },
        'medium' => {
          :name => "azure.vm_size = 'Medium'",
          :type => :alias,
        },
        'large' => {
          :name => "azure.vm_size = 'Large'",
          :type => :alias,
        },
        'lowcpu_13mem' => {
          :name => "azure.vm_size = 'ExtraLarge'",
          :type => :alias,
        },
        'lowcpu_26mem' => {
          :name => "azure.vm_size = 'A6'",
          :type => :alias,
        },
        '4cpu_lowmem' => {
          :name => "azure.vm_size = 'Large'",
          :type => :alias,
        },
        '8cpu_lowmem' => {
          :name => "azure.vm_size = 'ExtraLarge'",
          :type => :alias,
        },
        'max_cpu' => {
          :name => "azure.vm_size = 'ExtraLarge'",
          :type => :alias,
        },
        'max_memory' => {
          :name => "azure.vm_size = 'A7'",
          :type => :alias,
        },
      },
      'us_central' => {
        'micro' => {
          :name => "azure.vm_size = 'ExtraSmall'",
          :type => :alias,
        },
        'small' => {
          :name => "azure.vm_size = 'Small'",
          :type => :alias,
        },
        'medium' => {
          :name => "azure.vm_size = 'Medium'",
          :type => :alias,
        },
        'large' => {
          :name => "azure.vm_size = 'Large'",
          :type => :alias,
        },
        'lowcpu_13mem' => {
          :name => "azure.vm_size = 'ExtraLarge'",
          :type => :alias,
        },
        'lowcpu_26mem' => {
          :name => "azure.vm_size = 'A6'",
          :type => :alias,
        },
        '4cpu_lowmem' => {
          :name => "azure.vm_size = 'Large'",
          :type => :alias,
        },
        '8cpu_lowmem' => {
          :name => "azure.vm_size = 'ExtraLarge'",
          :type => :alias,
        },
        'max_cpu' => {
          :name => "azure.vm_size = 'ExtraLarge'",
          :type => :alias,
        },
        'max_memory' => {
          :name => "azure.vm_size = 'A7'",
          :type => :alias,
        },
      },
      'us_east' => {
        'micro' => {
          :name => "azure.vm_size = 'ExtraSmall'",
          :type => :alias,
        },
        'small' => {
          :name => "azure.vm_size = 'Small'",
          :type => :alias,
        },
        'medium' => {
          :name => "azure.vm_size = 'Medium'",
          :type => :alias,
        },
        'large' => {
          :name => "azure.vm_size = 'Large'",
          :type => :alias,
        },
        'lowcpu_13mem' => {
          :name => "azure.vm_size = 'ExtraLarge'",
          :type => :alias,
        },
        'lowcpu_26mem' => {
          :name => "azure.vm_size = 'A6'",
          :type => :alias,
        },
        '4cpu_lowmem' => {
          :name => "azure.vm_size = 'Large'",
          :type => :alias,
        },
        '8cpu_lowmem' => {
          :name => "azure.vm_size = 'ExtraLarge'",
          :type => :alias,
        },
        'max_cpu' => {
          :name => "azure.vm_size = 'ExtraLarge'",
          :type => :alias,
        },
        'max_memory' => {
          :name => "azure.vm_size = 'A7'",
          :type => :alias,
        },
      },
      'us_west' => {
        'micro' => {
          :name => "azure.vm_size = 'ExtraSmall'",
          :type => :alias,
        },
        'small' => {
          :name => "azure.vm_size = 'Small'",
          :type => :alias,
        },
        'medium' => {
          :name => "azure.vm_size = 'Medium'",
          :type => :alias,
        },
        'large' => {
          :name => "azure.vm_size = 'Large'",
          :type => :alias,
        },
        'lowcpu_13mem' => {
          :name => "azure.vm_size = 'ExtraLarge'",
          :type => :alias,
        },
        'lowcpu_26mem' => {
          :name => "azure.vm_size = 'A6'",
          :type => :alias,
        },
        '4cpu_lowmem' => {
          :name => "azure.vm_size = 'Large'",
          :type => :alias,
        },
        '8cpu_lowmem' => {
          :name => "azure.vm_size = 'ExtraLarge'",
          :type => :alias,
        },
        'max_cpu' => {
          :name => "azure.vm_size = 'ExtraLarge'",
          :type => :alias,
        },
        'max_memory' => {
          :name => "azure.vm_size = 'A7'",
          :type => :alias,
        },
      },
    },
    :location_lookup => {
      'asia_east' => "
        azure.vm_location = 'East Asia'
        azure.storage_acct_name = '#{$consumer_config['azure'][:storage_acct_name_prefix]}eastasia'
      ",
      'aus_east' => "
        azure.vm_location = 'Australia East'
        azure.storage_acct_name = '#{$consumer_config['azure'][:storage_acct_name_prefix]}australiaeast'
      ",
      'europe_north' => "
        azure.vm_location = 'North Europe'
        azure.storage_acct_name = '#{$consumer_config['azure'][:storage_acct_name_prefix]}northeurope'
      ",
      'europe_west' => "
        azure.vm_location = 'West Europe'
        azure.storage_acct_name = '#{$consumer_config['azure'][:storage_acct_name_prefix]}westeurope'
      ",
      'japan_west' => "
        azure.vm_location = 'Japan West'
        azure.storage_acct_name = '#{$consumer_config['azure'][:storage_acct_name_prefix]}japanwest'
      ",
      'us_central' => "
        azure.vm_location = 'Central US'
        azure.storage_acct_name = '#{$consumer_config['azure'][:storage_acct_name_prefix]}centralus'
      ",
      'us_west' => "
        azure.vm_location = 'West US'
        azure.storage_acct_name = '#{$consumer_config['azure'][:storage_acct_name_prefix]}westus'
      ",
      'us_east' => "
        azure.vm_location = 'East US'
        azure.storage_acct_name = '#{$consumer_config['azure'][:storage_acct_name_prefix]}eastus'
      ",
    },
    :firewall => 'azure.tcp_endpoints = str_firewall',
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
        :common_instance_type => 'mini',
        :common_image_name => 'CentOS-7-x64',
        :config_steps_type => 'default_linux',
        :sync_folder => "
          deploy_config.vm.synced_folder 'sync', '/opt/sync'
          deploy_config.vm.synced_folder 'cert', '/tmp/cert'
          deploy_config.vm.synced_folder '.', '/vagrant', disabled: true
        ",
        :commands => {
          :dns_update => $images_config['default_linux'][:dns_update],
          :pre_install => $images_config['CentOS-7-x64'][:commands][:puppetmaster_remove],
          :set_hostname => proc {|hostname,domain| $images_config['default_linux'][:commands][:set_hostname].call(hostname,domain) },
          :install => proc {|config_param| $images_config['CentOS-7-x64'][:commands][:puppetmaster_install].call(config_param) },
          :post_install => proc {|config_param| $images_config['CentOS-7-x64'][:commands][:puppetmaster_install_scaleio].call(config_param) },
        }
      },
      'puppetagent' => {
        :common_instance_type => 'medium',
        :common_image_name => 'CentOS-7-x64',
        :config_steps_type => 'default_linux',
        :sync_folder => "
          deploy_config.vm.synced_folder 'sync/schelper', '/opt/schelper'
          deploy_config.vm.synced_folder '.', '/vagrant', disabled: true
        ",
        :commands => {
          :dns_update => $images_config['default_linux'][:dns_update],
          :pre_install => $images_config['CentOS-7-x64'][:commands][:puppetagent_remove],
          :set_hostname => proc {|hostname,domain| $images_config['default_linux'][:commands][:set_hostname].call(hostname,domain) },
          :install => proc {|config_param| $images_config['CentOS-7-x64'][:commands][:puppetagent_install].call(config_param) },
          :post_install => proc {|config_param| $images_config['CentOS-7-x64'][:commands][:puppetagent_install_docker_scaleio].call(config_param) },
        }
      },
      'coreos' => {
        :common_instance_type => 'micro',
        :common_image_name => 'CoreOS-stable',
        :config_steps_type => 'default_coreos',
        :commands => {
          :pre_install => '',
          :install => proc {|config_param|  },
          :post_install => proc {|config_param,box_param| },
        },
      },
      'coreos-fleet' => {
        :common_instance_type => 'micro',
        :common_image_name => 'CoreOS-stable',
        :config_steps_type => 'default_coreos',
        :commands => {
          :pre_install => '',
          :install => proc {|config_param|  },
          :post_install => proc {|config_param,box_param| "
public_ipv4=`curl -s ip.alt.io`

cat <<EOF > /usr/share/oem/cloud-config.yml
#cloud-config

coreos:
  etcd:
    discovery: #{config_param[:etcd_url]}
    addr: $public_ipv4:4001
    peer-addr: $public_ipv4:7001
    peer-election-timeout: 7500
    peer-heartbeat-interval: 1500
  fleet:
    public-ip: $public_ipv4
    metadata: region=#{box_param[:location]},provider=#{$provider},platform=cloud,instance_type=#{box_param[:common_instance_type]}
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
      deploy_config.vm.provider :digital_ocean do |digitalocean, override|
        digitalocean.token = $consumer_config[$provider][:token]
        digitalocean.image = instance_image
        eval(str_location)
        eval(str_instance_type)
        eval(str_optional)
        digitalocean.ssh_key_name = box[:ssh_key_name] || $provider_config[$provider][:instances_config][box_type][:ssh_key_name] || $consumer_config[$provider][:ssh_key_name]
        override.ssh.private_key_path = box[:private_key] || $provider_config[$provider][:instances_config][box_type][:private_key] || $consumer_config[$provider][:private_key]

        #override.vm.box = 'digital_ocean'
        #override.vm.box_url = 'https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box'
        digitalocean.setup = false
        override.ssh.username = box[:ssh_username] || $provider_config[$provider][:images_config][instance_image][:ssh_username]
      end

    ",
    :images_config => {
      'centos-7-0-x64' => {
        :ssh_username => 'root'
      },
      'centos-6-5-x64' => {
        :ssh_username => 'root'
      },
      'coreos-stable' => {
        :ssh_username => 'core'
      },
      'coreos-beta' => {
        :ssh_username => 'core'
      },
      'coreos-alpha' => {
        :ssh_username => 'core'
      },
    },
    :images_lookup => {
      'us_west' => {
        'CentOS-7-x64' => 'centos-7-0-x64',
        'CentOS-6.5-x64' => 'centos-6-5-x64',
        'CoreOS-stable' => 'coreos-stable',
        'CoreOS-beta' => 'coreos-beta',
        'CoreOS-alpha' => 'coreos-alpha',
      },
      'us_east' => {
        'CentOS-7-x64' => 'centos-7-0-x64',
        'CentOS-6.5-x64' => 'centos-6-5-x64',
        'CoreOS-stable' => 'coreos-stable',
        'CoreOS-beta' => 'coreos-beta',
        'CoreOS-alpha' => 'coreos-alpha',
      },
      'asia_east' => {
        'CentOS-7-x64' => 'centos-7-0-x64',
        'CentOS-6.5-x64' => 'centos-6-5-x64',
        'CoreOS-stable' => 'coreos-stable',
        'CoreOS-beta' => 'coreos-beta',
        'CoreOS-alpha' => 'coreos-alpha',
      },
      'europe_west' => {
        'CentOS-7-x64' => 'centos-7-0-x64',
        'CentOS-6.5-x64' => 'centos-6-5-x64',
        'CoreOS-stable' => 'coreos-stable',
        'CoreOS-beta' => 'coreos-beta',
        'CoreOS-alpha' => 'coreos-alpha',
      },
      'uk_east' => {
        'CentOS-7-x64' => 'centos-7-0-x64',
        'CentOS-6.5-x64' => 'centos-6-5-x64',
        'CoreOS-stable' => 'coreos-stable',
        'CoreOS-beta' => 'coreos-beta',
        'CoreOS-alpha' => 'coreos-alpha',
      },
    },
    :instance_type_lookup => {
      'us_west' => {
        'micro' => {
          :name => "digitalocean.size = '512mb'",
          :type => :alias,
        },
        'small' => {
          :name => "digitalocean.size  = '1gb'",
          :type => :alias,
        },
        'medium' => {
          :name => "digitalocean.size = '2gb'",
          :type => :alias,
        },
        'large' => {
          :name => "digitalocean.size  = '8gb'",
          :type => :alias,
        },
        'lowcpu_13mem' => {
          :name => "digitalocean.size = '16gb'",
          :type => :alias,
        },
        'lowcpu_26mem' => {
          :name => "digitalocean.size = '32gb'",
          :type => :alias,
        },
        '4cpu_lowmem' => {
          :name => "digitalocean.size = '8gb'",
          :type => :alias,
        },
        '8cpu_lowmem' => {
          :name => "digitalocean.size = '16gb'",
          :type => :alias,
        },
        'max_cpu' => {
          :name => "digitalocean.size = '64gb'",
          :type => :alias,
        },
        'max_memory' => {
          :name => "digitalocean.size = '64gb'",
          :type => :alias,
        },
      },
      'us_east' => {
        'micro' => {
          :name => "digitalocean.size = '512mb'",
          :type => :alias,
        },
        'small' => {
          :name => "digitalocean.size  = '1gb'",
          :type => :alias,
        },
        'medium' => {
          :name => "digitalocean.size = '2gb'",
          :type => :alias,
        },
        'large' => {
          :name => "digitalocean.size  = '8gb'",
          :type => :alias,
        },
        'lowcpu_13mem' => {
          :name => "digitalocean.size = '16gb'",
          :type => :alias,
        },
        'lowcpu_26mem' => {
          :name => "digitalocean.size = '32gb'",
          :type => :alias,
        },
        '4cpu_lowmem' => {
          :name => "digitalocean.size = '8gb'",
          :type => :alias,
        },
        '8cpu_lowmem' => {
          :name => "digitalocean.size = '16gb'",
          :type => :alias,
        },
        'max_cpu' => {
          :name => "digitalocean.size = '64gb'",
          :type => :alias,
        },
        'max_memory' => {
          :name => "digitalocean.size = '64gb'",
          :type => :alias,
        },
      },
      'asia_east' => {
        'micro' => {
          :name => "digitalocean.size = '512mb'",
          :type => :alias,
        },
        'small' => {
          :name => "digitalocean.size  = '1gb'",
          :type => :alias,
        },
        'medium' => {
          :name => "digitalocean.size = '2gb'",
          :type => :alias,
        },
        'large' => {
          :name => "digitalocean.size  = '8gb'",
          :type => :alias,
        },
        'lowcpu_13mem' => {
          :name => "digitalocean.size = '16gb'",
          :type => :alias,
        },
        'lowcpu_26mem' => {
          :name => "digitalocean.size = '32gb'",
          :type => :alias,
        },
        '4cpu_lowmem' => {
          :name => "digitalocean.size = '8gb'",
          :type => :alias,
        },
        '8cpu_lowmem' => {
          :name => "digitalocean.size = '16gb'",
          :type => :alias,
        },
        'max_cpu' => {
          :name => "digitalocean.size = '64gb'",
          :type => :alias,
        },
        'max_memory' => {
          :name => "digitalocean.size = '64gb'",
          :type => :alias,
        },
      },
      'europe_west' => {
        'micro' => {
          :name => "digitalocean.size = '512mb'",
          :type => :alias,
        },
        'small' => {
          :name => "digitalocean.size  = '1gb'",
          :type => :alias,
        },
        'medium' => {
          :name => "digitalocean.size = '2gb'",
          :type => :alias,
        },
        'large' => {
          :name => "digitalocean.size  = '8gb'",
          :type => :alias,
        },
        'lowcpu_13mem' => {
          :name => "digitalocean.size = '16gb'",
          :type => :alias,
        },
        'lowcpu_26mem' => {
          :name => "digitalocean.size = '32gb'",
          :type => :alias,
        },
        '4cpu_lowmem' => {
          :name => "digitalocean.size = '8gb'",
          :type => :alias,
        },
        '8cpu_lowmem' => {
          :name => "digitalocean.size = '16gb'",
          :type => :alias,
        },
        'max_cpu' => {
          :name => "digitalocean.size = '64gb'",
          :type => :alias,
        },
        'max_memory' => {
          :name => "digitalocean.size = '64gb'",
          :type => :alias,
        },
      },
      'uk_east' => {
        'micro' => {
          :name => "digitalocean.size = '512mb'",
          :type => :alias,
        },
        'small' => {
          :name => "digitalocean.size  = '1gb'",
          :type => :alias,
        },
        'medium' => {
          :name => "digitalocean.size = '2gb'",
          :type => :alias,
        },
        'large' => {
          :name => "digitalocean.size  = '8gb'",
          :type => :alias,
        },
        'lowcpu_13mem' => {
          :name => "digitalocean.size = '16gb'",
          :type => :alias,
        },
        'lowcpu_26mem' => {
          :name => "digitalocean.size = '32gb'",
          :type => :alias,
        },
        '4cpu_lowmem' => {
          :name => "digitalocean.size = '8gb'",
          :type => :alias,
        },
        '8cpu_lowmem' => {
          :name => "digitalocean.size = '16gb'",
          :type => :alias,
        },
        'max_cpu' => {
          :name => "digitalocean.size = '64gb'",
          :type => :alias,
        },
        'max_memory' => {
          :name => "digitalocean.size = '64gb'",
          :type => :alias,
        },
      },

    },
    :location_lookup => {
      'us_west' => "
        digitalocean.region = 'sfo1'
      ",
      'us_east' => "
        digitalocean.region = 'nyc3'
      ",
      'asia_east' => "
        digitalocean.region = 'sgp1'
      ",
      'europe_west' => "
        digitalocean.region = 'ams3'
      ",
      'uk_east' => "
        digitalocean.region = 'lon1'
      ",
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
      :firewall => "['default']",
    },
    :ip_resolver => $ip_resolver[:ifconfig].call('eth0'),
    :instances_config => {
      'puppetmaster' => {
        :common_instance_type => 'mini',
        :common_image_name => 'CentOS-7-x64',
        :config_steps_type => 'default_linux',
        :sync_folder => "
          deploy_config.vm.synced_folder 'sync', '/opt/sync'
          deploy_config.vm.synced_folder 'cert', '/tmp/cert'
          deploy_config.vm.synced_folder '.', '/vagrant', disabled: true
        ",
        :commands => {
          :dns_update => $images_config['default_linux'][:dns_update],
          :pre_install => $images_config['CentOS-7-x64'][:commands][:puppetmaster_remove],
          :set_hostname => proc {|hostname,domain| $images_config['default_linux'][:commands][:set_hostname].call(hostname,domain) },
          :install => proc {|config_param| $images_config['CentOS-7-x64'][:commands][:puppetmaster_install].call(config_param) },
          :post_install => proc {|config_param| $images_config['CentOS-7-x64'][:commands][:puppetmaster_install_scaleio].call(config_param) },
        }
      },
      'puppetagent' => {
        :common_instance_type => 'medium',
        :common_image_name => 'CentOS-7-x64',
        :config_steps_type => 'default_linux',
        :sync_folder => "
          deploy_config.vm.synced_folder '.', '/vagrant', disabled: true
        ",
        :commands => {
          :dns_update => $images_config['default_linux'][:dns_update],
          :pre_install => $images_config['CentOS-7-x64'][:commands][:puppetagent_remove],
          :set_hostname => proc {|hostname,domain| $images_config['default_linux'][:commands][:set_hostname].call(hostname,domain) },
          :install => proc {|config_param| $images_config['CentOS-7-x64'][:commands][:puppetagent_install].call(config_param) },
          :post_install => proc {|config_param| $images_config['CentOS-7-x64'][:commands][:puppetagent_install_docker_scaleio].call(config_param) },
        }
      },
      'coreos' => {
        :common_instance_type => 'micro',
        :common_image_name => 'CoreOS-stable',
        :config_steps_type => 'default_coreos',
        :commands => {
          :pre_install => '',
          :install => proc {|config_param|  },
          :post_install => proc {|config_param,box_param| },
        },
      },
      'coreos-fleet' => {
        :common_instance_type => 'micro',
        :common_image_name => 'CoreOS-stable',
        :config_steps_type => 'default_coreos',
        :commands => {
          :pre_install => '',
          :install => proc {|config_param|  },
          :post_install => proc {|config_param,box_param| "
public_ipv4=`curl -s ip.alt.io`

cat <<EOF > /usr/share/oem/cloud-config.yml
#cloud-config

coreos:
  etcd:
    discovery: #{config_param[:etcd_url]}
    addr: $public_ipv4:4001
    peer-addr: $public_ipv4:7001
    peer-election-timeout: 7500
    peer-heartbeat-interval: 1500
  fleet:
    public-ip: $public_ipv4
    metadata: region=#{box_param[:location]},provider=#{$provider},platform=cloud,instance_type=#{box_param[:common_instance_type]}
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
      deploy_config.vm.provider :aws do |aws, override|
        aws.access_key_id = $consumer_config[$provider][:access_key_id]
        aws.secret_access_key = $consumer_config[$provider][:secret_access_key]
        aws.ami = instance_image
        eval(str_instance_type)
        aws.tags['Name'] = box[:hostname]

        eval($provider_config[$provider][:firewall])

        eval(str_location)

        eval($provider_config[$provider][:storage])

        eval($provider_config[$provider][:user_data])

        aws.keypair_name = box[:keypair_name] || $provider_config[$provider][:instances_config][box_type][:keypair_name] || $consumer_config[$provider][:keypair_name]
        override.ssh.private_key_path = box[:private_key] || $provider_config[$provider][:instances_config][box_type][:private_key] || $consumer_config[$provider][:private_key]
        override.ssh.username = box[:ssh_username] || $provider_config[$provider][:images_config][instance_image][:ssh_username]
      end
    ",
    :images_config => {
      'ami-454b5e00' => {
        :ssh_username => 'ec2-user'
      },


      'ami-6bcfc42e' => {
        :ssh_username => 'centos',
        :user_data =>  "'#!/bin/bash\nsed -i -e \"s/^Defaults.*requiretty/# Defaults requiretty/g\" /etc/sudoers'",
      },

      'ami-96a818fe' => {
        :ssh_username => 'centos',
        :user_data =>  "'#!/bin/bash\nsed -i -e \"s/^Defaults.*requiretty/# Defaults requiretty/g\" /etc/sudoers'",
      },

      'ami-aea582fc' => {
        :ssh_username => 'centos',
        :user_data =>  "'#!/bin/bash\nsed -i -e \"s/^Defaults.*requiretty/# Defaults requiretty/g\" /etc/sudoers'",
      },

      'ami-bd523087' => {
        :ssh_username => 'centos',
        :user_data =>  "'#!/bin/bash\nsed -i -e \"s/^Defaults.*requiretty/# Defaults requiretty/g\" /etc/sudoers'",
      },

      'ami-e4ff5c93' => {
        :ssh_username => 'centos',
        :user_data =>  "'#!/bin/bash\nsed -i -e \"s/^Defaults.*requiretty/# Defaults requiretty/g\" /etc/sudoers'",
      },

      'ami-bc7548a1' => {
        :ssh_username => 'centos',
        :user_data =>  "'#!/bin/bash\nsed -i -e \"s/^Defaults.*requiretty/# Defaults requiretty/g\" /etc/sudoers'",
      },

      'ami-89634988' => {
        :ssh_username => 'centos',
        :user_data =>  "'#!/bin/bash\nsed -i -e \"s/^Defaults.*requiretty/# Defaults requiretty/g\" /etc/sudoers'",
      },

      'ami-bf9520a2' => {
        :ssh_username => 'centos',
        :user_data =>  "'#!/bin/bash\nsed -i -e \"s/^Defaults.*requiretty/# Defaults requiretty/g\" /etc/sudoers'",
      },


      'ami-17fae852' => {
        :ssh_username => 'core'
      },
      'ami-019d8044' => {
        :ssh_username => 'core'
      },
      'ami-cfc5d98a' => {
        :ssh_username => 'core'
      },

      'ami-705d3d18' => {
        :ssh_username => 'core'
      },
      'ami-d8751bb0' => {
        :ssh_username => 'core'
      },
      'ami-14741e7c' => {
        :ssh_username => 'core'
      },

      'ami-cf82af9d' => {
        :ssh_username => 'core'
      },
      'ami-4f5d731d' => {
        :ssh_username => 'core'
      },
      'ami-0f86a85d' => {
        :ssh_username => 'core'
      },

      'ami-d1e981eb' => {
        :ssh_username => 'core'
      },
      'ami-6bacc751' => {
        :ssh_username => 'core'
      },
      'ami-1b3e5421' => {
        :ssh_username => 'core'
      },

      'ami-f4853883' => {
        :ssh_username => 'core'
      },
      'ami-0e73c879' => {
        :ssh_username => 'core'
      },
      'ami-a41590d3' => {
        :ssh_username => 'core'
      },


      'ami-487d4d55' => {
        :ssh_username => 'core'
      },
      'ami-5027174d' => {
        :ssh_username => 'core'
      },
      'ami-ace3d3b1' => {
        :ssh_username => 'core'
      },

      'ami-decfc0df' => {
        :ssh_username => 'core'
      },
      'ami-4af1fc4b' => {
        :ssh_username => 'core'
      },
      'ami-9a0f1b9b' => {
        :ssh_username => 'core'
      },

      'ami-cb04b4d6' => {
        :ssh_username => 'core'
      },
      'ami-dd6ddec0' => {
        :ssh_username => 'core'
      },
      'ami-ebb406f6' => {
        :ssh_username => 'core'
      },
    },
    :images_lookup => {
      'us_west' => {
        'CentOS-7-x64' => 'ami-6bcfc42e',
        'CentOS-6.5-x64' => 'ami-454b5e00',
        'CoreOS-stable' => 'ami-17fae852',
        'CoreOS-beta' => 'ami-019d8044',
        'CoreOS-alpha' => 'ami-cfc5d98a',
      },
      'us_east' => {
        'CentOS-7-x64' => 'ami-96a818fe',
        'CentOS-6.5-x64' => 'ami-454b5e00',
        'CoreOS-stable' => 'ami-705d3d18',
        'CoreOS-beta' => 'ami-d8751bb0',
        'CoreOS-alpha' => 'ami-14741e7c',
      },
      'asia_east' => {
        'CentOS-7-x64' => 'ami-aea582fc',
        'CentOS-6.5-x64' => 'ami-454b5e00',
        'CoreOS-stable' => 'ami-cf82af9d',
        'CoreOS-beta' => 'ami-4f5d731d',
        'CoreOS-alpha' => 'ami-0f86a85d',
      },
      'aus_east' => {
        'CentOS-7-x64' => 'ami-bd523087',
        'CentOS-6.5-x64' => 'ami-454b5e00',
        'CoreOS-stable' => 'ami-d1e981eb',
        'CoreOS-beta' => 'ami-6bacc751',
        'CoreOS-alpha' => 'ami-1b3e5421',
      },
      'europe_west' => {
        'CentOS-7-x64' => 'ami-e4ff5c93',
        'CentOS-6.5-x64' => 'ami-454b5e00',
        'CoreOS-stable' => 'ami-f4853883',
        'CoreOS-beta' => 'ami-0e73c879',
        'CoreOS-alpha' => 'ami-a41590d3',
      },
      'europe_central' => {
        'CentOS-7-x64' => 'ami-bc7548a1',
        'CentOS-6.5-x64' => 'ami-454b5e00',
        'CoreOS-stable' => 'ami-487d4d55',
        'CoreOS-beta' => 'ami-5027174d',
        'CoreOS-alpha' => 'ami-ace3d3b1',
      },
      'japan_west' => {
        'CentOS-7-x64' => 'ami-89634988',
        'CentOS-6.5-x64' => 'ami-454b5e00',
        'CoreOS-stable' => 'ami-decfc0df',
        'CoreOS-beta' => 'ami-4af1fc4b',
        'CoreOS-alpha' => 'ami-9a0f1b9b',
      },
      'sa_east' => {
        'CentOS-7-x64' => 'ami-bf9520a2',
        'CentOS-6.5-x64' => 'ami-454b5e00',
        'CoreOS-stable' => 'ami-cb04b4d6',
        'CoreOS-beta' => 'ami-dd6ddec0',
        'CoreOS-alpha' => 'ami-ebb406f6',
      },
    },
    :instance_type_lookup => {
      'us_west' => {
        'micro' => {
          :name => "aws.instance_type = 't2.micro'",
          :type => :alias,
        },
        'small' => {
          :name => "aws.instance_type  = 't2.small'",
          :type => :alias,
        },
        'medium' => {
          :name => "aws.instance_type = 't2.medium'",
          :type => :alias,
        },
        'large' => {
          :name => "aws.instance_type  = 'm3.large'",
          :type => :alias,
        },
        'lowcpu_13mem' => {
          :name => "aws.instance_type = 'r3.large'",
          :type => :alias,
        },
        'lowcpu_26mem' => {
          :name => "aws.instance_type = 'r3.xlarge'",
          :type => :alias,
        },
        '4cpu_lowmem' => {
          :name => "aws.instance_type = 'c3.xlarge'",
          :type => :alias,
        },
        '8cpu_lowmem' => {
          :name => "aws.instance_type = 'c3.xlarge'",
          :type => :alias,
        },
        'max_cpu' => {
          :name => "aws.instance_type = 'c3.4xlarge'",
          :type => :alias,
        },
        'max_memory' => {
          :name => "aws.instance_type = 'r3.4xlarge'",
          :type => :alias,
        },
      },
      'us_east' => {
        'micro' => {
          :name => "aws.instance_type = 't2.micro'",
          :type => :alias,
        },
        'small' => {
          :name => "aws.instance_type  = 't2.small'",
          :type => :alias,
        },
        'medium' => {
          :name => "aws.instance_type = 't2.medium'",
          :type => :alias,
        },
        'large' => {
          :name => "aws.instance_type  = 'm3.large'",
          :type => :alias,
        },
        'lowcpu_13mem' => {
          :name => "aws.instance_type = 'r3.large'",
          :type => :alias,
        },
        'lowcpu_26mem' => {
          :name => "aws.instance_type = 'r3.xlarge'",
          :type => :alias,
        },
        '4cpu_lowmem' => {
          :name => "aws.instance_type = 'c3.xlarge'",
          :type => :alias,
        },
        '8cpu_lowmem' => {
          :name => "aws.instance_type = 'c3.xlarge'",
          :type => :alias,
        },
        'max_cpu' => {
          :name => "aws.instance_type = 'c3.4xlarge'",
          :type => :alias,
        },
        'max_memory' => {
          :name => "aws.instance_type = 'r3.4xlarge'",
          :type => :alias,
        },
      },
      'asia_east' => {
        'micro' => {
          :name => "aws.instance_type = 't2.micro'",
          :type => :alias,
        },
        'small' => {
          :name => "aws.instance_type  = 't2.small'",
          :type => :alias,
        },
        'medium' => {
          :name => "aws.instance_type = 't2.medium'",
          :type => :alias,
        },
        'large' => {
          :name => "aws.instance_type  = 'm3.large'",
          :type => :alias,
        },
        'lowcpu_13mem' => {
          :name => "aws.instance_type = 'r3.large'",
          :type => :alias,
        },
        'lowcpu_26mem' => {
          :name => "aws.instance_type = 'r3.xlarge'",
          :type => :alias,
        },
        '4cpu_lowmem' => {
          :name => "aws.instance_type = 'c3.xlarge'",
          :type => :alias,
        },
        '8cpu_lowmem' => {
          :name => "aws.instance_type = 'c3.xlarge'",
          :type => :alias,
        },
        'max_cpu' => {
          :name => "aws.instance_type = 'c3.4xlarge'",
          :type => :alias,
        },
        'max_memory' => {
          :name => "aws.instance_type = 'r3.4xlarge'",
          :type => :alias,
        },
      },
      'aus_east' => {
        'micro' => {
          :name => "aws.instance_type = 't2.micro'",
          :type => :alias,
        },
        'small' => {
          :name => "aws.instance_type  = 't2.small'",
          :type => :alias,
        },
        'medium' => {
          :name => "aws.instance_type = 't2.medium'",
          :type => :alias,
        },
        'large' => {
          :name => "aws.instance_type  = 'm3.large'",
          :type => :alias,
        },
        'lowcpu_13mem' => {
          :name => "aws.instance_type = 'r3.large'",
          :type => :alias,
        },
        'lowcpu_26mem' => {
          :name => "aws.instance_type = 'r3.xlarge'",
          :type => :alias,
        },
        '4cpu_lowmem' => {
          :name => "aws.instance_type = 'c3.xlarge'",
          :type => :alias,
        },
        '8cpu_lowmem' => {
          :name => "aws.instance_type = 'c3.xlarge'",
          :type => :alias,
        },
        'max_cpu' => {
          :name => "aws.instance_type = 'c3.4xlarge'",
          :type => :alias,
        },
        'max_memory' => {
          :name => "aws.instance_type = 'r3.4xlarge'",
          :type => :alias,
        },
      },
      'europe_west' => {
        'micro' => {
          :name => "aws.instance_type = 't2.micro'",
          :type => :alias,
        },
        'small' => {
          :name => "aws.instance_type  = 't2.small'",
          :type => :alias,
        },
        'medium' => {
          :name => "aws.instance_type = 't2.medium'",
          :type => :alias,
        },
        'large' => {
          :name => "aws.instance_type  = 'm3.large'",
          :type => :alias,
        },
        'lowcpu_13mem' => {
          :name => "aws.instance_type = 'r3.large'",
          :type => :alias,
        },
        'lowcpu_26mem' => {
          :name => "aws.instance_type = 'r3.xlarge'",
          :type => :alias,
        },
        '4cpu_lowmem' => {
          :name => "aws.instance_type = 'c3.xlarge'",
          :type => :alias,
        },
        '8cpu_lowmem' => {
          :name => "aws.instance_type = 'c3.xlarge'",
          :type => :alias,
        },
        'max_cpu' => {
          :name => "aws.instance_type = 'c3.4xlarge'",
          :type => :alias,
        },
        'max_memory' => {
          :name => "aws.instance_type = 'r3.4xlarge'",
          :type => :alias,
        },
      },
      'europe_central' => {
        'micro' => {
          :name => "aws.instance_type = 't2.micro'",
          :type => :alias,
        },
        'small' => {
          :name => "aws.instance_type  = 't2.small'",
          :type => :alias,
        },
        'medium' => {
          :name => "aws.instance_type = 't2.medium'",
          :type => :alias,
        },
        'large' => {
          :name => "aws.instance_type  = 'm3.large'",
          :type => :alias,
        },
        'lowcpu_13mem' => {
          :name => "aws.instance_type = 'r3.large'",
          :type => :alias,
        },
        'lowcpu_26mem' => {
          :name => "aws.instance_type = 'r3.xlarge'",
          :type => :alias,
        },
        '4cpu_lowmem' => {
          :name => "aws.instance_type = 'c3.xlarge'",
          :type => :alias,
        },
        '8cpu_lowmem' => {
          :name => "aws.instance_type = 'c3.xlarge'",
          :type => :alias,
        },
        'max_cpu' => {
          :name => "aws.instance_type = 'c3.4xlarge'",
          :type => :alias,
        },
        'max_memory' => {
          :name => "aws.instance_type = 'r3.4xlarge'",
          :type => :alias,
        },
      },
      'japan_west' => {
        'micro' => {
          :name => "aws.instance_type = 't2.micro'",
          :type => :alias,
        },
        'small' => {
          :name => "aws.instance_type  = 't2.small'",
          :type => :alias,
        },
        'medium' => {
          :name => "aws.instance_type = 't2.medium'",
          :type => :alias,
        },
        'large' => {
          :name => "aws.instance_type  = 'm3.large'",
          :type => :alias,
        },
        'lowcpu_13mem' => {
          :name => "aws.instance_type = 'r3.large'",
          :type => :alias,
        },
        'lowcpu_26mem' => {
          :name => "aws.instance_type = 'r3.xlarge'",
          :type => :alias,
        },
        '4cpu_lowmem' => {
          :name => "aws.instance_type = 'c3.xlarge'",
          :type => :alias,
        },
        '8cpu_lowmem' => {
          :name => "aws.instance_type = 'c3.xlarge'",
          :type => :alias,
        },
        'max_cpu' => {
          :name => "aws.instance_type = 'c3.4xlarge'",
          :type => :alias,
        },
        'max_memory' => {
          :name => "aws.instance_type = 'r3.4xlarge'",
          :type => :alias,
        },
      },
      'sa_east' => {
        'micro' => {
          :name => "aws.instance_type = 't2.micro'",
          :type => :alias,
        },
        'small' => {
          :name => "aws.instance_type  = 't2.small'",
          :type => :alias,
        },
        'medium' => {
          :name => "aws.instance_type = 't2.medium'",
          :type => :alias,
        },
        'large' => {
          :name => "aws.instance_type  = 'm3.large'",
          :type => :alias,
        },
        'lowcpu_13mem' => {
          :name => "aws.instance_type = 'r3.large'",
          :type => :alias,
        },
        'lowcpu_26mem' => {
          :name => "aws.instance_type = 'r3.xlarge'",
          :type => :alias,
        },
        '4cpu_lowmem' => {
          :name => "aws.instance_type = 'c3.xlarge'",
          :type => :alias,
        },
        '8cpu_lowmem' => {
          :name => "aws.instance_type = 'c3.xlarge'",
          :type => :alias,
        },
        'max_cpu' => {
          :name => "aws.instance_type = 'c3.4xlarge'",
          :type => :alias,
        },
        'max_memory' => {
          :name => "aws.instance_type = 'r3.4xlarge'",
          :type => :alias,
        },
      },
    },
    :location_lookup => {
      'us_west' => "
        aws.region = 'us-west-1'
        aws.availability_zone = 'us-west-1b'
      ",
      'us_east' => "
        aws.region = 'us-east-1'
        aws.availability_zone = 'us-east-1a'
      ",
      'asia_east' => "
        aws.region = 'ap-southeast-1'
        aws.availability_zone = 'ap-southeast-1a'
      ",
      'aus_east' => "
        aws.region = 'ap-southeast-2'
        aws.availability_zone = 'ap-southeast-2a'
      ",
      'europe_west' => "
        aws.region = 'eu-west-1'
        aws.availability_zone = 'eu-west-1a'
      ",
      'europe_central' => "
        aws.region = 'eu-central-1'
        aws.availability_zone = 'eu-central-1a'
      ",
      'japan_west' => "
        aws.region = 'ap-northeast-1'
        aws.availability_zone = 'ap-northeast-1a'
      ",
      'sa_east' => "
        aws.region = 'sa-east-1'
        aws.availability_zone = 'sa-east-1a'
      ",
    },
    :firewall => 'aws.security_groups = (eval(str_firewall) unless !str_firewall) || []',
    :storage => 'aws.block_device_mapping = (eval(str_storage) unless !str_storage) || []',
    :user_data => 'aws.user_data = (eval(str_user_data) unless !str_user_data) || ""',
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
        :common_instance_type => 'small',
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
        :domain => 'vagrantspice.local',
        :plugin_config => "
          config.ssh.pty = true
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
        :domain => 'vagrantspice.local',
        :plugin_config => "
          config.ssh.pty = true
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
