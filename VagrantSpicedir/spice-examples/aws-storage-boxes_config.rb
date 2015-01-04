{
  :boxes => [
    { 
      :hostname  =>  'aws-coreos01',
      :common_location_name => 'us_west',
      :common_instance_type => 'micro',
      :common_image_name => 'CoreOS-beta',
    },
    { 
      :hostname  =>  'aws-coreos02',
      :common_location_name => 'us_east',
      :common_instance_type => 'small',
      :common_image_name => 'CoreOS-beta'
    },
    { 
      :hostname  =>  'aws-coreos03',
      :common_location_name => 'asia_east',
      :common_instance_type => 'medium',
      :common_image_name => 'CoreOS-beta',
    },
    { 
      :hostname  =>  'aws-coreos04',
      :common_location_name => 'aus_east',
      :common_instance_type => 'large',
      :common_image_name => 'CoreOS-beta',
    },
    { 
      :hostname  =>  'aws-coreos05',
      :common_location_name => 'europe_west',
      :common_instance_type => 'micro',
      :common_image_name => 'CoreOS-beta',
    },
    { 
      :hostname  =>  'aws-coreos06',
      :common_location_name => 'europe_central',
      :common_instance_type => 'large',
      :common_image_name => 'CoreOS-beta',
    },
    { 
      :hostname  =>  'aws-coreos07',
      :common_location_name => 'japan_west',
      :common_instance_type => 'medium',
      :common_image_name => 'CoreOS-beta',
    },
    { 
      :hostname  =>  'aws-coreos08',
      :common_location_name => 'sa_east',
      :common_instance_type => 'small',
      :common_image_name => 'CoreOS-beta',
    },

  ],
  :boxes_type => 'coreos',
  :config_param => '{
      :etcd_url => "https://discovery.etcd.io/18179f2ce7a9bddc11463ff157907af8",
    }',
  :firewall => "['default','standard']",
  :storage => "[{ 'DeviceName' => '/dev/xvdb', 'Ebs.VolumeSize' => 100 }]",
  :config_steps => proc {|config_param,box_param| " 
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
      - name: format-ephemeral.service
        command: start
        content: |
          [Unit]
          Description=Formats the ephemeral drive
          [Service]
          Type=oneshot
          RemainAfterExit=yes
          ExecStart=/usr/sbin/wipefs -f /dev/xvdb
          ExecStart=/usr/sbin/mkfs.btrfs -L root -f /dev/xvdb
      - name: var-lib-docker.mount
        command: start
        content: |
          [Unit]
          Description=Mount ephemeral to /var/lib/docker
          Requires=format-ephemeral.service
          After=format-ephemeral.service
          Before=docker.service
          [Mount]
          What=/dev/xvdb
          Where=/var/lib/docker
          Type=btrfs
EOF
          /usr/bin/coreos-cloudinit --from-file /usr/share/oem/cloud-config.yml"
          },
}

