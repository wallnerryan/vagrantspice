
{
  'CentOS-6.5-x64' => {
    :commands => {

      :puppetmaster_install => proc {|config_param| "
        sleep 60

        if which puppet > /dev/null 2>&1; then
          echo 'Puppet Installed.'
        else
          echo 'Installing Puppet Master.'
          rpm -Uvh http://yum.puppetlabs.com/el/6/products/x86_64/puppetlabs-release-6-10.noarch.rpm
          yum --nogpgcheck -y install puppet-server
          echo '*.#{config_param[:domain]}' > /etc/puppet/autosign.conf
          puppet module install puppetlabs-stdlib
          puppet module install puppetlabs-firewall
          puppet module install puppetlabs-java
          puppet module install dalen-dnsquery
          puppet config set --section master certname puppetmaster.#{config_param[:domain]}
          iptables -F
          iptables -A INPUT -i lo -j ACCEPT
          iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
          iptables -A INPUT -p tcp --dport ssh -j ACCEPT
          iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 8140 --tcp-flags FIN,SYN,RST,ACK SYN -j ACCEPT
          iptables -A INPUT -j DROP

          # three options for overwriting puppet config and modules
          yum install -y git
          git clone #{config_param[:repo_url]} /tmp/vagrant-puppet-scaleio
          cp -Rf /tmp/vagrant-puppet-scaleio/puppet/* /etc/puppet/.

          #rsync it to /opt and copy it from there
          cp -Rf /opt/puppet/* /etc/puppet/. &> /dev/null

          #object store transfered
          if [ -e '/tmp/puppet.tar.gz' ]; then
            tar -zxvf /tmp/puppet.tar.gz -C /etc
          fi

          cp -Rf /opt/sync/puppet /etc/puppet/.

          /usr/bin/puppet resource service puppetmaster ensure=running enable=true
        fi
      "},
      :puppetmaster_sitepp_copy => proc {|from| "
        cp -f #{from} /etc/puppet/manifests/site.pp
      " },
      :puppetagent_install => proc {|config_param| "
        sleep 60

        if which puppet > /dev/null 2>&1; then
          echo 'Puppet Installed.'
        else
          echo 'Installing Puppet Agent.'
          rpm -Uvh http://yum.puppetlabs.com/el/6/products/x86_64/puppetlabs-release-6-10.noarch.rpm
          yum --nogpgcheck -y install puppet
          puppet config set --section main server puppetmaster.#{config_param[:domain]}
          puppet agent -t --detailed-exitcodes || [ $? -eq 2 ]
        fi
      "},
      :puppetmaster_remove => "sudo rpm -e puppet-server --nodeps &> /dev/null",
      :puppetagent_remove => "sudo rpm -e puppet --nodeps &> /dev/null",
    }
  },
  'CentOS-7-x64' => {
    :commands => {
      :puppetmaster_install => proc {|config_param| "
        sleep 60
        if which puppet > /dev/null 2>&1; then
          echo 'Puppet Installed.'
        else
          yum remove -y firewalld && yum install -y iptables-services && iptables --flush

          echo 'Installing Puppet Master.'
          rpm -ivh http://yum.puppetlabs.com/el/7/products/x86_64/puppetlabs-release-7-10.noarch.rpm
          yum --nogpgcheck -y install puppet-server
          echo '*.#{config_param[:domain]}' > /etc/puppet/autosign.conf
          puppet config set --section master certname puppetmaster.#{config_param[:domain]}
          /usr/bin/puppet resource service iptables ensure=stopped enable=false
        fi

        /usr/bin/puppet resource service puppetmaster ensure=running enable=true

      "},
      :puppetmaster_install_scaleio => proc {|config_param| "
        puppet module install puppetlabs-stdlib
        puppet module install puppetlabs-firewall
        puppet module install puppetlabs-java
        puppet module install emccode-scaleio
        puppet config set --section main parser future

        cp -Rf /opt/sync/puppet/* /etc/puppet/.

        sh /opt/sync/copyrpms.sh

        systemctl restart puppetmaster
      "},
      :puppetmaster_sitepp_copy => proc {|from| "
        cp -f #{from} /etc/puppet/manifests/site.pp
      " },
      :puppetagent_install => proc {|config_param| "
        sleep 60

        if which puppet > /dev/null 2>&1; then
          echo 'Puppet Installed.'
        else
          yum remove -y firewalld && yum install -y iptables-services && iptables --flush

          echo 'Installing Puppet Agent.'
          rpm -ivh http://yum.puppetlabs.com/el/7/products/x86_64/puppetlabs-release-7-10.noarch.rpm
          yum --nogpgcheck -y install puppet
          puppet config set --section main server puppetmaster.#{config_param[:domain]}
          puppet agent -t --detailed-exitcodes || [ $? -eq 2 ]
        fi



      "},
      :puppetagent_install_docker_scaleio => proc {|config_param| "
        if which docker > /dev/null 2>&1; then
          echo 'Docker Installed.'
          systemctl stop docker
          rpm -e docker
        fi

        if which screen > /dev/null 2>&1; then
          echo 'Screen installed.'
        else
          yum install -y screen
        fi

        # Install flocker related stuff below
        echo 'Installing and Configuring Flocker Packages'

        # Flocker Ports
        iptables -A INPUT -p tcp --dport 4523 -j ACCEPT
        iptables -A INPUT -p tcp --dport 4523 -j ACCEPT

	if selinuxenabled; then setenforce 0; fi
	yum clean all
	yum install -y https://clusterhq-archive.s3.amazonaws.com/centos/clusterhq-release$(rpm -E %dist).noarch.rpm
        yum remove -y docker-engine
        yum install -y clusterhq-flocker-node

	mkdir /etc/flocker
	chmod 0700 /etc/flocker

	# TODO can we do key managment this way?
	# I think vagrant spice puts key into the nodes :)
	if [ $HOSTNAME == 'tb.vagrantspice.local' ]; then
	    printf '%s\n' 'on the tb host'
	    cd /etc/flocker/
	    flocker-ca initialize mycluster
	    flocker-ca create-control-certificate tb.vagrantspice.local
	    cp control-tb.vagrantspice.local.crt /etc/flocker/control-service.crt
	    cp controltb.vagrantspice.local.key /etc/flocker/control-service.key
	    cp cluster.crt /etc/flocker/cluster.crt
	    chmod 0600 /etc/flocker/control-service.key

	     # We have three nodes in the cluster.
	    flocker-ca create-node-certificate
	    #< COPY THIS AS THE FIRST NODE >
	    flocker-ca create-node-certificate
	    #< COPY INTO second-node/node2.crt|key>
	    flocker-ca create-node-certificate
	    #< COPY INTO second-node/node2.crt|key>

	    # Create an API certificate for the plugin
	    flocker-ca create-api-certificate plugin

	    # Create a general purpose user api cert
	    flocker-ca create-api-certificate vagrantspice
	fi

	#if [ $HOSTNAME != 'mdm1.vagrantspice.local' ]; then
	#   SCP, with pem file in sync folder?
	#fi

	# TODO Install scaleio_flocker_driver
        curl 'https://bootstrap.pypa.io/get-pip.py' -o 'get-pip.py'
        python get-pip.py
        yum -y install git
	git clone https://github.com/emccorp/scaleio-flocker-driver
	cd scaleio-flocker-driver/
	/opt/flocker/bin/python setup.py install

	# TODO edit agent.yml
	cp /etc/flocker/example_sio_agent.yml /etc/flocker/agent.yml
	sed -i -e \"s/^hostname:*/hostname: tb.vagrantspice.local/g\" /etc/flocker/agent.yml
	sed -i -e \"s/^mdm:*/mdm: mdm1.vagrantspice.local/g\" /etc/flocker/agent.yml

	yum install -y python-pip build-essential libssl-devel libffi-devel python-devel
	pip install git+https://github.com/clusterhq/flocker-docker-plugin.git


        echo 'Done installing Flocker Packages'

        systemctl stop docker
        rm -Rf /var/lib/docker

        yum install -y wget

        curl -O -sSL https://get.docker.com/rpm/1.7.0/centos-6/RPMS/x86_64/docker-engine-1.7.0-1.el6.x86_64.rpm
        sudo yum -y localinstall --nogpgcheck docker-engine-1.7.0-1.el6.x86_64.rpm
        rm -Rf /var/lib/docker

        echo 'Performing 10MB download of Docker experimental build'
        wget -nv https://github.com/emccode/dogged/releases/download/docker_1.7.0_exp/docker-1.7.0 -O /bin/docker
        chmod +x /bin/docker

        sed -i -e \"s/^other_args=/#OPTIONS=-H tcp://0.0.0.0:4243 -H unix:///var/run/docker.sock/g\" /etc/sysconfig/docker
        sed -i -e \"s/^OPTIONS=/#OPTIONS=-H tcp://0.0.0.0:4243 -H unix:///var/run/docker.sock/g\" /etc/sysconfig/docker

        systemctl start docker

        # Docker Plugin Service
	echo '[Unit]
	Description=flocker-plugin - flocker-docker-plugin job file

	[Service]
	Environment=FLOCKER_CONTROL_SERVICE_BASE_URL=tb.vagrantspice.local
	Environment=MY_NETWORK_IDENTITY=<INPUT NETWORK ID>
	ExecStart=/usr/local/bin/flocker-docker-plugin

	[Install]
	WantedBy=multi-user.target' >> /etc/systemd/system/flocker-docker-plugin.service

      "},
      :puppetmaster_remove => "sudo rpm -e puppet-server --nodeps &> /dev/null",
      :puppetagent_remove => "sudo rpm -e puppet --nodeps &> /dev/null",
    }
  },
  'default_linux' => {
    :commands => {
      :set_hostname => proc {|hostname,domain| "
              echo 'Setting Hostname'
              echo '#{hostname}.#{domain}' > /etc/hostname
              hostname `cat /etc/hostname`
      "},
      :dns_update => 'echo -e "DNS1=8.8.4.4\nDNS2=8.8.8.8" >> /etc/sysconfig/network-scripts/ifcfg-eth0',
      :curl_file => proc {|from_url,to_path| "
        yum install -y curl
        mkdir -p #{File.dirname(to_path)}
        curl #{from_url} -o #{to_path}
      "}
    },
  }
}
