VagrantSpice
============
The purpose of VagrantSpice is to simplify and standardize how the different machine providers are configured and that machines can always communicate using hostnames across Vagrant providers.

The first example is relevant to getting a Puppet Master and Agent deployed and configured across multiple providers with a CentOS image.


Summary
-------

Each provider maintains its own configuration parameters.  Some of these parameters are unique per provider but others are more generally applicable.  In addition, different providers have different default behavior for VM templates, network connectivity, storage and other configurable items.  By abstracting from the Vagrantfile, VagrantSpice allows a single configuration of boxes to work across any pre-configured provider.

This simplification requires a level of abstraction for commonality to occur.  This can limit the capabilities of certain cloud providers to only common aspects among other providers.  This is a natural by-product of making cloud provider capabilities align, but there is still the option to leverage custom provider options as well.

By default VagrantSpice makes use of the Vagrant HostManager plugin to assist with configuring the hosts files with all machines as they are built.  This ensures that all machines can communicate using host names when dynamic networking (DHCP) is used (default).

Different public cloud providers leverage different networking capabilities.  Some assign public IPs directly to interfaces of the machine, while others leverage NAT and private IP spaces.  In addition, some provide intra-VM communication between machines while others only allow communication through public IP addresses.  For this VagrantSpice also uses the HostManager plugin and different IP resolvers to ensure VMs are able to communicate with one another.  The hosts file is modified different depending on provider to include a reachable IP.

Another facet of VagrantSpice recognizes that RSYNC or NFS may not be the best methods to synchornize files to the target machine since this connectivity can be limiting and prone to inconsistent behavior.  For this we have implemented some basic examples of leveraging private object stores to synchronize files.  The objects stores are configured independently of machine providers.

The first example of VagrantSpice is to deploy a Puppet Master and Agent machines in a working fashion across cloud providers.  This kind of configuration management is software is important in this case since we are using stock images from the providers that although aligned, may still present subtle differences that something like Puppet should help overcome.  This is of course optional and can be superseded by other tools.

<br>


Configured Machine Providers
-----------------
The following providers have been configured already within VagrantSpice.  If there is a provider that is not listed, the provider_config.rb and consumer_config.rb files must be updated with relevant normalizing information.  The following represents relevant authentication parameters in the consumer_config.rb file.

AWS

	  'aws' => {
	    :access_key_id => 'AKIAJPBGSO3SZ3V4EHDA',
	    :secret_access_key => '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',
	    :keypair_name => 'dicey1',
	    :private_key => 'cert/dicey1.pem',
	  },
  
Azure  

	  'azure' => {
	    :mgmt_certificate => 'cert/azure.pem',
	    :mgmt_endpoint => 'https://management.core.windows.net',
	    :subscription_id => 'dbeb65ad-1dea-4528-ad5d-b1082da2f799',
	    :storage_acct_name => 'portalvhds6qmhy1bc0fqn8',    
	    :private_key => 'cert/azure.pem',
	    :public_cert => 'cert/azure.cer',
	  },


Digital Ocean  

	  'digital_ocean' => {
	    :token => 'be83edcfb41fd19806ed7dc034b45e60942b65ceb2c8386540017f5c7c0c83a7',
	    :private_key => 'cert/digital_ocean',
	    :ssh_key_name => 'Vagrant',
	  },

Google (GCE)  

	  'google' => {
	    :google_project_id => 'lucid-sol-713',
	    :google_client_email  => '1011620534039-bk95sa499437crqm3qtid4e0nnhn5tos@developer.gserviceaccount.com',
	    :google_key_location => 'cert/My First Project-fffcc674adc0.p12',
	    :private_key => "cert/google_compute_engine",
	  },
	  
Rackspace  

	  'rackspace' => {
	    :username => 'username',
	    :api_key  => 'df7303cdceeb40c6a0aae3b6778e8759',
	    :keypair_name => 'id_rsa',
	    :private_key => 'cert/id_rsa',
	  },
  
Virtual Box  

	N/A

Object Providers
----------------
AWS S3 
  
	'aws_s3' => {
	    :access_key_id => 'AKIAJPBGTO3TZ2V4EHDA',
	    :secret_access_key => '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',
	    :s3_host_base => 's3.amazonaws.com',
	    :s3_host_bucket => '%(bucket)s.s3.amazonaws.com',
	  },
	  
Azure Files  

	  'azure_files' => {
	    :storage_access_key => 'BvvjCdFcBFgvd+deD+NkhREOR+Tk+VmaWXwLmm7TcBOcVuDajg8wY0vOrbd1DYPisc8Xwyvm4axXqn8IfbrINA==',
	    :storage_account => 'portalvhds6qmhy1bc0fqn8',
	  },
	  
Google Storage  

	  'google_storage' => {
	    :service_account => '12123123123213-123123123asd@developer.gserviceaccount.com',
	    :key_file  => '/tmp/cert/My First Project-fffcc674adc0.p12',
	  },
	  
Rackspace Swift  

	  'rackspace_swift' => {
	    :st_user => 'clintonskitson',
	    :st_key  => '93aef92e3..',
	    :st_auth => 'https://auth.api.rackspacecloud.com/v1.0',
	  },



<br><br>
<hr>
<br><br>

The following section shows a view of the alignment between providers for the characteristics of the deployed machines.  As configured right now, this also represents the limitations of what is currently configured.  Providing more images, instances, and location at each provider will expand the usefulness of this project.
<br>

Images
------
The following table represents the similar images among default configured providers.

| Image   |  AWS  |  Azure      |  Digital Ocean  |  Google  |  Rackspace  |  Virtualbox
|----------|:-------------:|------:|------:|----:|----:|----:  
|CentOS-64-x64|ami-454b5e00|5112500ae3b842c8b9c604889f8753c3__OpenLogic-CentOS-65-20140926|6.5 x64|centos-6-v20141021|CentOS 6.5 (PVHVM)|puppetlabs/centos-6.5-64-nocm (box)


Instances
----------------------
The following table includes instance types or sizes that are deployed to the machines at each provider.

| Instance Type   |  AWS  |  Azure      |  Digital Ocean  |  Google  |  Rackspace  |  Virtualbox
|----------|:-------------:|------:|------:|----:|----:|----:  
|small|t2.micro|Small|1gb|n1-standard-1|1 GB General Purpose v1|N/A
|medium|t2.medium|Medium|2gb|n1-standard-2|1 GB General Purpose v2|N/A



Locations
----------------------
The following table represents the physical location choices among providers.  

| Location   |  AWS  |  Azure      |  Digital Ocean  |  Google  |  Rackspace  |  Virtualbox
|----------|:-------------:|------:|------:|----:|----:|----:  
|us_west|us-west-1 (AZ us-west-1b)|West US|sfo1|us-central1-a|dfw|N/A


<br><br>
<hr>
<br><br>


Directory Structure
-------------------

<pre>
VagrantSpicedir/
└─── provider.../
	 └─── cert/
	 |  Vagrantfile
	 |  boxes.rb
└─── provider.../
	 └─── cert/
	 |  Vagrantfile
	 |  boxes.rb
└─── spice-conf
	 |  config_steps.rb
	 |  consumer_config.rb
	 |  images_config.rb
	 |  instances_config.rb
	 |  ip_resolver.rb
	 |  object_config.rb
	 |  provider_config.rb
	 |  Vagrantfile-template.rb
</pre>

<br>

Install
-------
VagrantSpice requires that providers are generally working with a normal Vagrantfile first.  The primary details here are specific to authenticaiton.  With this you can take the configuration parameters and populate them in the spice-conf/consumer_config.rb file along with populating relavant certificate files in the provier/cert directory.


	git clone https://github.com/emccode/vagrantspice
	cd vagrant-spice/VagrantSpicedir  
	vi spice-conf/consumer_config.rb  
	cp cert provider/cert


Machine Customization
-------------
The boxes.rb file specifies the names of the machines and the types.  These types can be defined exclusively or as shared types in the image configuration files.


	boxes = [
	  { 
	    :hostname  =>  'puppetmaster',
	    :type      =>  'puppetmaster',
	  },
	  { 
	    :hostname  =>  'puppetagent1',
	    :type      =>  'puppetagent',
	  },
	]

Usage
-------
By enetering a provider directory and issuing a standard 'vagrant up' command, VagrantSpice will assist in dynamically creating proper Vagrantfile parameters that allow Vagrant to create machines as normal. 

	cd VagrantSpicedir/aws  
	vagrant up --no-parallel


Example provider-config.rb
---------------------------
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
	        :object_source => 'rackspace_swift',
	        :repo_url => 'https://github.com/emccode/vagrant-puppet-scaleio',
	        :object_creds => {
	          :st_key => $consumer_config['rackspace_swift'][:st_key],
	          :st_user => $consumer_config['rackspace_swift'][:st_user],
	          :st_auth => $consumer_config['rackspace_swift'][:st_auth],
	        },
	        :commands => {
	          :dns_update => $images_config['default_linux'][:dns_update],
	          :pre_install => $images_config['CentOS-6.5-x64'][:commands][:puppetmaster_remove],
	          :set_hostname => proc {|hostname,domain| $images_config['default_linux'][:commands][:set_hostname].call(hostname,domain) },
	          :install => proc {|config_param| $images_config['CentOS-6.5-x64'][:commands][:puppetmaster_install].call(config_param) },
	          :sitepp_curl => $images_config['default_linux'][:commands][:curl_file].call('https://raw.githubusercontent.com/emccode/vagrant-puppet-scaleio/master/puppet/manifests/examples/site.pp-hosts_lookup','/etc/puppet/manifests/site.pp')
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
	    },
	    :deploy_box_config => "
	      deploy_config.vm.provider :rackspace do |rs,override|
	        rs.username = $consumer_config[$provider][:username]
	        rs.api_key  = $consumer_config[$provider][:api_key]
	        rs.server_name = box[:hostname]
	        eval(str_instance_type)
	        rs.image    = instance_image
	        eval(str_location)

	        rs.key_name = box[:keypair_name] || $provider_config[$provider][:instances_config][box[:type]][:keypair_name] || $consumer_config[$provider][:keypair_name]
	        override.ssh.private_key_path = box[:private_key] || $provider_config[$provider][:instances_config][box[:type]][:private_key] || $consumer_config[$provider][:private_key]
	        override.ssh.username = box[:ssh_username] || $provider_config[$provider][:images_config][instance_image][:ssh_username]
	      end
	    ",
	    :images_config => {
	      'CentOS 6.5 (PVHVM)' => {
	        :ssh_username => 'root'
	      }
	    },
	    :images_lookup => {
	      'CentOS-6.5-x64' => 'CentOS 6.5 (PVHVM)',
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
	  }
	  
:deploy\_box\_config
------------------
The :deploy\_box\_config key contains a value that resembles the default configuration paramters of the provider.  Notice how the parameters are filled in with variables that reference multiple locations to possible find the values.
 
	    :deploy_box_config => "
	      deploy_config.vm.provider :rackspace do |rs,override|
	        rs.username = $consumer_config[$provider][:username]
	        rs.api_key  = $consumer_config[$provider][:api_key]
	        rs.server_name = box[:hostname]
	        eval(str_instance_type)
	        rs.image    = instance_image
	        eval(str_location)

	        rs.key_name = box[:keypair_name] || $provider_config[$provider][:instances_config][box[:type]][:keypair_name] || $consumer_config[$provider][:keypair_name]
	        override.ssh.private_key_path = box[:private_key] || $provider_config[$provider][:instances_config][box[:type]][:private_key] || $consumer_config[$provider][:private_key]
	        override.ssh.username = box[:ssh_username] || $provider_config[$provider][:images_config][instance_image][:ssh_username]
	      end
	    ",

Puppet specific Site.pp hook
----------------------------
The provider_config.rb specifies the provider configurations per instance type.  As an example, the Puppet Master includes a file (site.pp) that controls which nodes receive which configurations.   There is a hook that allows this to be downloaded from a specific URL.

	:sitepp_curl => $images_config['default_linux'][:commands][:curl_file].call('https://raw.githubusercontent.com/emccode/vagrant-puppet-scaleio/master/puppet/manifests/examples/site.pp-hosts_lookup','/etc/puppet/manifests/site.pp')


Other defaults
--------------
The consumer_config.rb file contains other defaults and plugin configurations.

Notie the default domain name configuration and HostManager enablement settings.  The :plugin_config_vm is a per machine setting which is being used to ensure the proper alias is tagged per machine.

	  :defaults => {
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
	  

Abstracted Vagrantfile
----------------------
For those interested, here is what is left of a Vagrantfile in a provider directory.  Its primary purpose is just to include and run the template Vagrantfile and configuration files.

	require 'resolv'


	config_files = [
	  '../spice-conf/consumer_config.rb',
	  '../spice-conf/ip_resolver.rb',
	  '../spice-conf/object_config.rb',
	  '../spice-conf/instances_config.rb',
	  '../spice-conf/images_config.rb',
	  '../spice-conf/config_steps.rb',
	  '../spice-conf/provider_config.rb',
	]

	working_directory = Dir.getwd

	config_files.each {|file| 
	  file_path = "#{working_directory}/#{file}" 
	  contents = File.read(file_path)
	  var_name = file.split('/')[-1].split('.')[0]
	  eval("$#{var_name} = #{contents}")
	}

	boxes = eval(File.read('./boxes.rb'))

	$provider = File.basename(Dir.getwd)
	eval($provider_config[$provider][:requires])
	ENV['VAGRANT_DEFAULT_PROVIDER'] = $provider

	eval(File.read('../spice-conf/Vagrantfile-template.rb'))




Limitations
-----------
The project has built the framework to normalize for cloud providers but only works for a CentOS 6.5 x64 and a small or medium instance type.

As an abstraction above a Vagrantfile you will find a lot of the settings are done via strings and evals.  This leaves some flexibility in allowing for unplanned scenarios.


Future Statement
----------------
The project currently is serving as Vagrantfile abstraction.  We hope that in the future Vagrant might have a framework to ensure the providers have common parameters making this kind of endeavor obsolete.  Otherwise, the focus here will be to ensure there is complete abstraction to allow for complete customization if needed.  The work here could be bundled into a Vagrant plugin as well.

Notes
-----
Having the provider plugins used in standard ways demonstrates the disparity among them.  There are subtle differences in synchronous/asynchonous behaviors where up/destory commands might act differently.

Contributing
-----------
Please contribute in any way to the project.  Specifically, normalizing differnet image sizes, locations, and intance types would be easy adds to enhance the usefulness of the project.


Licensing
---------
Licensed under the Apache License, Version 2.0 (the “License”); you may not use this file except in compliance with the License. You may obtain a copy of the License at <http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

Support
-------
Please file bugs and issues at the Github issues page. For more general discussions you can contact the EMC Code team at <a href="https://groups.google.com/forum/#!forum/emccode-users">Google Groups</a>. The code and documentation are released with no warranties or SLAs and are intended to be supported through a community driven process.