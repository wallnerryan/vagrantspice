VagrantSpice
============
The purpose of VagrantSpice is to simplify and standardize how the different machine providers are configured across Vagrant cloud providers.

The primary example in the current version is getting a CoreOS Fleet cluster up and running across Amazon AWS, Azure, Digital Ocean, Google, and Rackspace.  The current repository has 27 Data centers among these providers working with CoreOS images.

If you take a peak at the VagrantspiceDir and the provider/consumer config files you can see pretty quickly where we are defining in a structured and consistent way what is typically defined loosely through the Vagrant DSL.

Summary
-------

Each provider maintains its own configuration parameters.  Some of these parameters are unique per provider but others are more generally applicable.  In addition, different providers have different default behavior for VM templates, network connectivity, storage and other configurable items.  By abstracting above the Vagrantfile, VagrantSpice allows a single configuration of boxes to work across any pre-configured provider.  It can be as easy as specifying a hostname and everything else just works regardless of which cloud.

This simplification requires a level of abstraction for commonality to occur.  This can limit the capabilities of certain cloud providers to only common aspects among other providers.  This is a natural by-product of making cloud provider capabilities align, but there is still the option to leverage custom provider options as well.

Different public cloud providers leverage different networking capabilities.  Some assign public IPs directly to interfaces of the machine, while others leverage NAT and private IP spaces.  In addition, some provide intra-VM communication between machines while others only allow communication through public IP addresses.  VagrantSpice has many options here, but the default is to allow communication between VMs using the public internet routable IP address to maintain cloud interoperability.

<br>

Version
-------
VagrantSpice is currently in early proof of concept strages on its third version.

<br>

Configured Machine Providers
-----------------
The following providers have been configured already within VagrantSpice.  If there is a provider that is not listed, the provider_config.rb and consumer_config.rb files must be updated with relevant normalizing information.  The following represents relevant authentication parameters in the consumer_config.rb file.

AWS

	  'aws' => {
	    :access_key_id => 'AKIAJPBHSO3SZ3V4EHDD',
	    :secret_access_key => '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',
	    :keypair_name => 'dicey1',
	    :private_key => 'cert/dicey1.pem',
	  },
  
Azure  

	  'azure' => {
	    :mgmt_certificate => 'cert/azure.pem',
	    :mgmt_endpoint => 'https://management.core.windows.net',
	    :subscription_id => 'dbeb65dd-1dea-4528-ae5d-b1082da2f799',
	    :storage_acct_name => 'portalvgds6qmhy1bc0fqn8',    
	    :private_key => 'cert/azure.pem',
	    :public_cert => 'cert/azure.cer',
	  },


Digital Ocean  

	  'digital_ocean' => {
	    :token => 'be83edcfb41fd19806ed7dc034b45e60042b65cdb2c8386540017f5c7c0c83a7',
	    :private_key => 'cert/digital_ocean',
	    :ssh_key_name => 'Vagrant',
	  },

Google (GCE)  

	  'google' => {
	    :google_project_id => 'lucid-sol-713',
	    :google_client_email  => '1011630534039-bk95sa499437crqm3qtid4e0nnhn6tos@developer.gserviceaccount.com',
	    :google_key_location => 'cert/My First Project-fffcc674adc0.p12',
	    :private_key => "cert/google_compute_engine",
	  },
	  
Rackspace  

	  'rackspace' => {
	    :username => 'username',
	    :api_key  => 'df7303cdceeb41d6a0aae3b6778e8759',
	    :keypair_name => 'id_rsa',
	    :private_key => 'cert/id_rsa',
	  },
  
Virtual Box  

	N/A

<br><br>
<hr>
<br><br>

The following section shows a view of the alignment between providers for the characteristics of the deployed machines.  As configured right now, this also represents the limitations of what is currently configured.  Providing more images, instances, and location at each provider will expand the usefulness of this project.
<br>

Images
------
The following table represents the similar images among default configured providers.  This is an example of how we take a common iamge name of the left column and align them among providers.

| Image   |  AWS  |  Azure      |  Digital Ocean  |  Google  |  Rackspace  |  Virtualbox
|----------|:-------------:|------:|------:|----:|----:|----:  
|CentOS-64-x64|ami-454b5e00|5112500ae3b842c8b9c604889f8753c3__OpenLogic-CentOS-65-20140926|6.5 x64|centos-6-v20141021|CentOS 6.5 (PVHVM)|puppetlabs/centos-6.5-64-nocm (box)
|CoreOS-stable||||
|CoreOS-beta||||
|CoreOS-alpha||||


Instances
----------------------
The following table includes instance types or sizes that are deployed to the machines at each provider.  This is an example of taking a common instance type on the left column and align them against providers.

| Instance Type   |  AWS  |  Azure      |  Digital Ocean  |  Google  |  Rackspace  |  Virtualbox
|----------|:-------------:|------:|------:|----:|----:|----:  
|micro||||||
|small||||||
|medium|t2.medium|Medium|2gb|n1-standard-2|1 GB General Purpose v2|N/A
|large||||||




Locations
----------------------
The following table represents the physical location choices among providers.  

| Location   |  AWS  |  Azure      |  Digital Ocean  |  Google  |  Rackspace  |  Virtualbox
|----------|:-------------:|:------:|:------:|:----:|:----:|:----:  
|asia_east|yes|yes|yes|yes|yes|
|aus_east|yes|yes|||yes|
|europe_central|yes|||||
|europe_east||||||
|europe_north||yes||||
|europe_west|yes|yes|yes|yes||
|japan_west|yes|yes||||
|sa_east|yes|||||
|us_central||yes|||yes|
|us_east|yes|yes|yes|yes|yes|
|us_west|yes|yes|yes|||
|uk_east|||yes|||


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
	 |  boxes_config.rb
└─── provider.../
	 └─── cert/
	 |  Vagrantfile
	 |  boxes_config.rb
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
VagrantSpice requires that providers are generally working with a normal Vagrantfile first.  The primary details here are specific to authentication.  With this you can take the configuration parameters and populate them in the spice-conf/consumer_config.rb file along with populating relavant certificate files in the provider/cert directory.


	git clone https://github.com/emccode/vagrantspice
	cd vagrant-spice/VagrantSpicedir  
	vi spice-conf/consumer_config.rb
	mkdir provider/cert
	cp yourcertdir/cert provider/cert/.

Networking
----------
Different providers deal with networking in different ways.  Most providers have default firewall settings in place to protect intra-vm communication.  In order to get a default multi-machine setup working, you likely need to enable firewall setings to allow communication inbound to the VM.  This is something that should be tested with the native Vagrant provider before using VagrantSpice.  

For the CoreOS demo, at a minimum ```TCP 4001 and 7001``` need to be open to allow proper ```etcd``` communications.  As well, ```TCP 22``` must be open for ```SSH```.


Machine Customization
-------------
The boxes_config.rb file specifies the names of the machines and the types.  There are a range of possibities as far as where to declare the different variables.  More detail to come later, but in general you can specify settings at the Box, Boxes, Instances, Instance Types, Consumer, and Provider levels.  The ```Vagrantfile-template.rb``` is very rough currently, but can provide insight to priority and ordering.

	{
	  :boxes => [
	    { 
	      :hostname  =>  'google-coreos01',
	    },
	    { 
	      :hostname  =>  'google-coreos02',
	    },
	  ],
	  :boxes_type => 'coreos',
	}



Usage
-------
By enetering a provider directory and issuing a standard 'vagrant up' command, VagrantSpice will assist in dynamically creating proper Vagrantfile parameters that allow Vagrant to create machines as normal.

	cd VagrantSpicedir/
	curl -s https://discovery.etcd.io/new | more
	vi spice-conf/consumer_config.rb
	- find :etcd_url and replace the URL
	cd provider1
	vagrant up
	cd ../provider2
	vagrant up

	
If you choose a single vm name, you must also specify the ```--provider=name``` flag.

:instance\_type\_lookup
-----------------------
This is a peak at the abstraction for the instance type.  Here you can see a call to small refers to the ```google.machine_type``` parameter and ```n1-standard-1```.

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
      },


:images\_lookup
--------------
This corresponds to generic names such as ```CoreOS-444.5.0-(stable)``` and referring to the actual image name of ```coreos-stable-444-5-0-v20141016``` at Google.

	  'us_central' => {
	        'CentOS-6.5-x64' => 'centos-6-v20141021',
	        'CoreOS-stable' => 'coreos-stable-494-5-0-v20141215',
	        'CoreOS-beta' => 'coreos-beta-522-3-0-v20141226',
	        'CoreOS-alpha' => 'coreos-alpha-549-0-0-v20150102',
	      },
	    
:images\_config
--------------
Here we specify the image name at the provider followed by which ssh username must be used for that image.  In the case of the CentOS image, the name on the certificate supplied is used.  But in the case of CoreOS the default ```core``` username is used.

    :images_config => {
      'centos-6-v20141021' => {
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

:instances\_config
-----------------
This area allows us to configure the custom ```cloud-config``` file.  As part of the CoreOS process we are actually creating a new file and running the standard ```coreos-cloudinit``` command against this new file.

Another interesting part is the ```public_ipv4=`curl -s ip.alt.io``` command.  This does a ```whoami``` request to ```ip.alt.io``` which returns the IP that the machine is known as publicly.  This is what we use as the public address.

	       'coreos' => {
	        :common_instance_type => 'small',
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

Other defaults
--------------
The consumer_config.rb file contains other defaults and plugin configurations.

Notice the ```core``` default parameter for ```etcd_url```.  This must be updated by issuing a  ```https://discovery.etcd.io/new``` command and retrieving the URL shown.

	  :defaults => {
	    :domain => "vagrantspice.local",
	    :instances_config => {
	      'coreos' => {
	        :config_param => '{
	          :etcd_url => "https://discovery.etcd.io/5a06f86a07db91ca220545745f890a98",
	        }',
	      }
	    },
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

	boxes = eval(File.read('./boxes_config.rb'))

	$provider = File.basename(Dir.getwd)
	eval($provider_config[$provider][:requires])
	ENV['VAGRANT_DEFAULT_PROVIDER'] = $provider

	eval(File.read('../spice-conf/Vagrantfile-template.rb'))


Image Names from Providers
--------------------------

Digital Ocean

	curl -X GET -H 'Content-Type: application/json' -H 'Authorization: Bearer yourtoken' "https://api.digitalocean.com/v2/images?page=1&per_page=999" | python -m json.tool 


Limitations
-----------
The project has built the framework to normalize for cloud providers but only works for a CentOS 6.5 x64 and a small or medium instance type.

As an abstraction above a Vagrantfile you will find a lot of the settings are done via strings and evals.  This leaves some flexibility in allowing for unplanned scenarios.


Future Statement
----------------
The project currently is serving as Vagrantfile abstraction.  You can think of it as bringing structure to something that through a domain specific language was unstructured but very powerful.  The downside is that it is currently a layer above Vagrant which can make it difficult to troubleshoot with standard Vagrant knowledge.  Let's see where this goes!

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
