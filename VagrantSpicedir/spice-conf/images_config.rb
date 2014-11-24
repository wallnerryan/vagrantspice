
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

          #get a differents site.pp version
          #{config_param[:curl_file]}

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