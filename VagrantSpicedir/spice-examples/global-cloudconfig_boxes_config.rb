{
  :boxes => [
    { 
      :hostname  =>  'coreos01',
      :common_location_name => 'us_east',
      :common_instance_type => 'micro',
      :common_image_name => 'CoreOS-stable',
      :type => 'coreos',
      :firewall => "['default','standard']",
      :config_steps => proc {|config_param,box_param| " 
public_ipv4=`curl -s ip.alt.io`

cat <<EOF > /usr/share/oem/cloud-config.yml
#cloud-config

coreos:
  units:
      - name: helloworld.service
        command: start
        content: |
          [Unit]
          Description=EMC CODE HelloWorld Container
          After=docker.service

          [Service]
          TimeoutStartSec=0
          KillMode=none
          EnvironmentFile=/etc/environment
          ExecStartPre=-/usr/bin/docker kill helloworld
          ExecStartPre=-/usr/bin/docker rm helloworld
          ExecStartPre=/usr/bin/docker pull emccode/helloworld
          ExecStart=/usr/bin/docker run --name helloworld -p 4001:8080 emccode/helloworld
          ExecStop=/usr/bin/docker stop helloworld

EOF
          /usr/bin/coreos-cloudinit --from-file /usr/share/oem/cloud-config.yml"
      },
    },
  ],
  :boxes_type => 'coreos',
}

