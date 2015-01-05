VagrantSpice
============
The purpose of VagrantSpice is to simplify and standardize how the different machine providers are configured across cloud providers for Vagrant machines.

The primary example in the current version is getting a CoreOS Fleet cluster up and running across Amazon AWS, Azure, Digital Ocean, Google, and Rackspace.  The current repository has 27 Data centers among these providers working with CoreOS images.

If you take a peak at the VagrantSpicedir and the provider/consumer config files you can see pretty quickly where we are defining in a structured and consistent way what is typically defined loosely through the Vagrant DSL.

* [Summary] (#Summary)
 * [Version] (#Version)
* [Install] (#Install)
* [Usage] (#Usage)
* [Examples] (#Examples)
 * [CoreOS] (#examples_coreos)
 * [Firewall] (#examples_firewall)
 * [Cloud-Config] (#examples_cloudconfig)
 * [Fleet and Etcd] (#examples_fleet)
 * [Storage] (#examples_storage)
 * [Snake Charmer] (#examples_snake_charmer)
* [Configuration] (#Configuration)
 * [Consumer Configuration] (#consumer_configuration)
 * [Firewall] (#Firewall)
 * [Storage] (#Storage)
 * [Machine Customization] (#machine_cusotmization)
 * [Instances Config] (#instances_config)
 * [Other Defaults] (#other_defaults)
* [Cloud Normalization] (#cloud_normalization)
 * [Images] (#Images)
 * [Instances] (#Instances)
 * [Locations] (#Locations)
 * [Instance Type Lookup] (#instance_type_lookup)
 * [Images Lookup] (#images_lookup)
 * [Images Config] (#images_config)
* [Notes] (#Notes)
 * [Directory Structure] (#directory_structure)
 * [Abstracted Vagrantfile] (#abstracted_vagrantfile)
 * [Networking] (#Networking)
 * [Image Names From Providers] (#image_names_from_providers)
 * [Limitations] (#Limitations)
* [Future Statement] (#future_statement)
* [Contributing] (#contributing)
* [Licensing] (#licensing)
* [Support] (#support)

# <a name="Summary">Summary</a>


Each provider maintains its own configuration parameters.  Some of these parameters are unique per provider but others are more generally applicable.  In addition, different providers have different default behavior for VM templates, network connectivity, firewalls, storage and other configurable items.  By abstracting above the Vagrantfile, VagrantSpice allows a single configuration of boxes to work across any pre-configured provider.  It can be as easy as specifying a hostname and everything else just works regardless of which cloud.

This simplification requires a level of abstraction for commonality to occur.  This can limit the capabilities of certain cloud providers to only common aspects among other providers.  This is a natural by-product of making cloud provider capabilities align, but there is still the option to leverage custom provider options as well.

<br>

<A name="Version">Version</a>
-------
VagrantSpice is currently in early stages of development under <a href="http://emccode.github.io">EMC {code}</a> standard practices focused on open development.  The project is finishing the discovery phase with a working object model across the five clouds specified.  Cloning from the Github repo will ensure the latest versions.

<br>

# <A name="Install">Install</a>
VagrantSpice requires that providers are generally working with a normal Vagrantfile first.  The primary details here are specific to authentication.  With this you can take the configuration parameters and populate them in the spice-conf/consumer_config.rb file along with populating relavant certificate files in the provider/cert directory.


	git clone https://github.com/emccode/vagrantspice
	cd vagrant-spice/VagrantSpicedir  
	vi spice-conf/consumer_config.rb
	mkdir provider/cert
	cp yourcertdir/cert provider/cert/.





# <A name="Usage">Usage</a>
By enetering a provider directory and issuing a standard 'vagrant up' command, VagrantSpice will assist in dynamically feeding Vagrant DSL to allow Vagrant to create machines as normal.  

Prior to this ensure that
- Vagrant is installed
- Vagrant plugins are installed (vagrant plugin install vagrant-aws) or updated (vagrant plugin update)

Use these steps for general VagrantSpice.

	cd VagrantSpicedir/
	vi spice-conf/consumer_config.rb
	cd provider1
	vagrant up

Use these steps to run VagrantSpice with the CoreOS demo.

	cd VagrantSpicedir/
	curl -s https://discovery.etcd.io/new | more
	vi spice-conf/consumer_config.rb
	- find :etcd_url and replace the URL
	cd provider1
	vagrant up
	cd ../provider2
	vagrant up

	
If you choose a single vm name, you must also specify the ```--provider=name``` flag.

Following this, to delete the machines it is as simple as ```vagrant destroy -f```.  It is good practice to log into the provider from time to time to ensure the VMs running are needed and that orphan disks are not around.


# <A name="Examples">Examples</a>
See the ```spice-examples``` directory of ```boxes_config.rb``` files.

- <a name="examples_coreos">CoreOS</a> (stable, beta, alpha)
 - ```spice-examples/global-coreos-boxes_config.rb```
 - The following example will work for all providers except Google.  Change the ```us_east``` to ```us_central``` since Google does not have a data center in the ```us_east``` region.

	    	{
			  :boxes => [
			    { 
			      :hostname  =>  'coreos01',
			      :common_location_name => 'us_east',
			      :common_instance_type => 'micro',
			      :common_image_name => 'CoreOS-stable',
			      :type => 'coreos',
			    },
			  ],
			  :boxes_type => 'coreos',
			}


- CoreOS with <a name="examples_firewall">Firewalls</a>
 - Azure ```spice-examples/google-firewall-boxes_config.rb```.

		{
		  :boxes => [
		    { 
		      :hostname  =>  'coreos01',
		      :common_location_name => 'us_east',
		      :common_instance_type => 'micro',
		      :common_image_name => 'CoreOS-stable',
		      :type => 'coreos',
		      :firewall => '4001:4001,7001:7001',
		    },
		  ],
		  :boxes_type => 'coreos',
		}


 - AWS ```spice-examples/aws-firewall-boxes_config.rb```

			{
			  :boxes => [
			    { 
			      :hostname  =>  'coreos01',
			      :common_location_name => 'us_east',
			      :common_instance_type => 'micro',
			      :common_image_name => 'CoreOS-stable',
			      :type => 'coreos',
			      :firewall => "['default','standard']",
			    },
			  ],
			  :boxes_type => 'coreos',
			}


 -  Google ```spice-examples/google-firewall-boxes_config.rb```


			{
			  :boxes => [
			    { 
			      :hostname  =>  'coreos01',
			      :common_location_name => 'us_central',
			      :common_instance_type => 'micro',
			      :common_image_name => 'CoreOS-stable',
			      :type => 'coreos',
			      :firewall => "default",
			    },
			  ],
			  :boxes_type => 'coreos',
			}

-  Azure ```spice-examples/azure-firewall-boxes_config.rb```

			{
			  :boxes => [
			    { 
			      :hostname  =>  'coreos01',
			      :common_location_name => 'us_east',
			      :common_instance_type => 'micro',
			      :common_image_name => 'CoreOS-stable',
			      :type => 'coreos',
			      :firewall => '4001:4001,7001:7001',
			    },
			  ],
			  :boxes_type => 'coreos',
			}



- CoreOS additional configuration and running containers manually using <a name="examples_cloudconfig">cloud-config</a>.
 - Global across providers except firewall settings with ```spice-examples/global-cloudconfig_boxes_config.rb```.  For Google consider switching ```us_east``` to ```us_central```.

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
			          ExecStart=/usr/bin/docker run --name helloworld -p 8080:8080 emccode/helloworld
			          ExecStop=/usr/bin/docker stop helloworld

			EOF
			          /usr/bin/coreos-cloudinit --from-file /usr/share/oem/cloud-config.yml"
			      },
			    },
			  ],
			  :boxes_type => 'coreos',
			}



In order to test the configuration, you must find the public address of the VM with ```vagrant ssh-config coreos01``` and then open a web browser session to ```http://ip:4001/```.  You should see the following ```Hello World from Go in minimal Docker container```.  We are mapping TCP 8080, avaialable under our pre-created firewall policy of ```standard``` or ```default``` for AWS or other provider with firewalls (see firewall section).  

- CoreOS with <a name="examples_fleet">Fleet and Etcd</a>
 - Available from ```spice-examples/global-fleet-boxes_config.rb``` but requires that you generaete a new etcd cluster identifer from ```curl -s http://http://discovery.etcd.io/new | more``` and replace under ```:etcd_url```.

			{
			  :boxes => [
			    { 
			      :hostname  =>  'coreos01',
			      :common_location_name => 'us_east',
			      :common_instance_type => 'micro',
			      :common_image_name => 'CoreOS-stable',
			      :type => 'coreos-fleet',
			      :firewall => "['default','standard']",
			      :config_param => '{
			        :etcd_url => "https://discovery.etcd.io/5ecf49ae378548bb7af105c4d38119ae",
			      }',
			    }
			  ],
			}


- CoreOS with Fleet, and <a name="examples_storage">Additional Storage</a>
 - Available from ```aws-storage-boxes_config.rb``` or ```google-storage-boxes_config.rb```.  The Google version is slightly different since it adds storage to the ```/``` partition instead of as another drive making it not need to do units for carving out the partition and mounting it.

			{
			  :boxes => [
			    { 
			      :hostname  =>  'aws-coreos01',
			      :common_location_name => 'us_west',
			      :common_instance_type => 'micro',
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

- CoreOS with <a name="examples_snake_charmer">Snake Charmer</a>
 - Snake Charmer is a project from EMC CODE that focuses on building Docker containers to test and use object services and is available <a href="https://github.com/emccode/snake_charmer">here</a>.  Using the combination of VargrantSpice and Snake Charmer allows you to fire up Docker containers in no time that can use object services.
 - Using the simplest ```spice-examples/global-coreos-boxes_config.rb``` you can run CoreOS in a manual mode and leverage Docker from SSH to run Snake Charmer.  Google requires the ```central``` region.
 - We can leverage the EMC CODE ```s3proxycmd``` Docker container to list files.
	```docker run -e 'access_key=user055' -e 'secret_key=key' -e proxy_host=object.vipronline.com -e proxy_port=80 -ti emccode/s3proxycmd```
 - Go ahead and run the session interactively instead byu speciying ```--entrypoint=/bin/bash``` as ```docker run -e 'access_key=user055' -e 'secret_key=key' -e proxy_host=object.vipronline.com -e proxy_port=80 --entrypoint=/bin/bash -ti emccode/s3proxycmd```
 - First run ```run_s3_proxy_cmd.sh``` if you have supplied proxy information to create the ```/tmp/.s3cfg``` file.  Otherwise you can run ```s3cmd --configure``` to use ```s3cmd``` without a proxy (do not specify --config if doing this).
 - Following this commands like ```s3cmd --config /tmp/.s3cfg ls``` will work.
 - Create a file of random data ```head -c 50M < /dev/urandom > file```
 - Upload the file to an S3 provider ```s3cmd --config /tmp/.s3cfg put s3://testing/file``

 - You can also run ```s3cmd --configure``` once in the



# <A name="Configuration">Configuration</a>

<A name="consumer_configuration">Consumer Configuration</a>
-----------------
The following providers have been configured already within VagrantSpice.  If there is a provider that is not listed, the ```provider\_config.rb``` and ```consumer\_config.rb``` files must be updated with relevant normalizing information.  The following represents relevant authentication parameters in the ```consumer\_config.rb``` file.  The parameters are required only if you are leveraging the specific provider.

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
	    :storage_acct_name_prefix => 'dbeb65dd',
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
  

<br><br>
<hr>
<br><br>

<A name="Firewall">Firewall</a>
----------
Providers handle firewalls differently.  Some do not employ any firewall services while others have extensive capabilities.  The provider layer we are working with at VagrantSpice is based on Vagrant machine cloud provider plugins.  These plugins all receive the configuration or non-configuration of firewall settings differently.

There are three methods.  The *group* method allows you to specify the actual groups of firewall rules to apply.  The *rules* method allows you to specify firewall rules dynamically.  The *pre-existing* method assumes you pre-create firewall rules that are applied to all VMs that are brought up under a project or group and does not require configuration from VagrantSpice.  And *N/A* means the provider does not employ firewall services.

| Provider   |  Method  |
|:----------:|:--------:|
|AWS|Group|
|Azure|Rules|
|Digital Ocean|N/A|
|Google|Group|
|Rackspace|Pre-Existing|


For the CoreOS demo, at a minimum ```TCP 4001 and 7001``` need to be open to allow proper ```etcd``` communications.  As well, ```TCP 22``` must be open for ```SSH```.

#### Azure Example - boxes_config.rb
> :firewall => "4001:4001,7001:7001"

#### AWS Example - boxes_config.rb
These are pre-configured and must be available in each region that you are provisioning to ahead of time.

> :firewall => "['default','standard']"

#### Google Example - boxes_config.rb
The network specified must be pre-configured.

> :firewall => "default"

<A name="Storage">Storage</a>
-------
Storage can be considered another configuration parameter that differes between providers.  This is similar to networking where the exposure of the ability to modify sizes depends on whether the provider allows it and whether the Vagrant machine provider exposes this capability.  This storage is beyond what is offered from the instance types.

| Provider   |  Allowed | Vagrant  | VagrantSpice |
|:----------:|:--------:|:--------:|:--------:|
|AWS|Yes|Yes|Yes|
|Azure|Yes|No|No|
|Digital Ocean|No|No|No|
|Google|Yes|Yes|Yes|
|Rackspace|Yes|No|No|

Once storage is provisioned it must be consumed by the guest file system.  For CoreOS this can be done via a cloud config file.  

#### AWS Examples - boxes_config.rb
> :storage => "[{ 'DeviceName' => '/dev/xvdb', 'Ebs.VolumeSize' => 100 }]",

#### Google Example - boxes_config.rb
This storage does not need to be configured inside the guest since it represents the additional ```/``` partition size.
> :storage => '100'



<A name="machine_customization">Machine Customization</a>
-------------
The boxes_config.rb file specifies at a minimum the names of the machines.  There are a range of possibities other than this and chances to set these extra parameters at a more global level.  More detail to come later, but in general you can specify settings at the Box, Boxes, Instances, Instance Types, Consumer, and Provider levels.  The ```Vagrantfile-template.rb``` can provide insight to logic, priority and ordering.

	{
	  :boxes => [
	    { 
	      :hostname  =>  'google-coreos01',
	      :common_location_name => 'us_central',
	      :common_instance_type => 'micro',
	      :common_image_name => 'CoreOS-stable',
	    },
	    { 
	      :hostname  =>  'google-coreos02',
	      :common_location_name => 'europe_west',
	      :common_instance_type => 'medium',
	      :common_image_name => 'CoreOS-beta'
	    },
	    { 
	      :hostname  =>  'google-coreos03',
	      :common_location_name => 'asia_east',
	      :common_instance_type => 'large',
	      :common_image_name => 'CoreOS-alpha',
	    },
	  ],
	  :boxes_type => 'coreos',
	  :config_param => '{
	      :etcd_url => "https://discovery.etcd.io/33b91d0a7877a694de893efe48f68a10",
	    }',
	}


<A name="instances_config">Instances Config</a>
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

<A name="other_defaults">Other Defaults</a>
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




# <A name="cloud_normalization">Cloud Normalization</a>
The following section shows a peak under the hood, or a view of the alignment between providers for the characteristics of the deployed machines.  As configured right now, this also represents the limitations of what is currently configured.  Providing more images, instances, and location at each provider will expand the usefulness of this project.
<br>

<A name="Images">Images</a>
------
The following table represents the similar images among default configured providers.  This is an example of how we take a common iamge name of the left column and align them among providers.

| Image   |  AWS  |  Azure      |  Digital Ocean  |  Google  |  Rackspace  |  Virtualbox
|----------|:-------------:|------:|------:|----:|----:|----:  
|CentOS-64-x64|ami-454b5e00|5112500ae3b842c8b9c604889f8753c3__OpenLogic-CentOS-65-20140926|6.5 x64|centos-6-v20141021|CentOS 6.5 (PVHVM)|puppetlabs/centos-6.5-64-nocm (box)
|CoreOS-stable||||
|CoreOS-beta||||
|CoreOS-alpha||||


<A name="Instances">Instances</a>
----------
The following table includes instance types or sizes that are deployed to the machines at each provider.  This is an example of taking a common instance type on the left column and align them against providers.

| Instance Type   |  AWS  |  Azure      |  Digital Ocean  |  Google  |  Rackspace  |  Virtualbox
|----------|:-------------:|------:|------:|----:|----:|----:  
|micro||||||
|small||||||
|medium|t2.medium|Medium|2gb|n1-standard-2|1 GB General Purpose v2|N/A
|large||||||


<A name="Locations">Locations</a>
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
|us_east|yes|yes|yes||yes|
|us_west|yes|yes|yes|||
|uk_east|||yes|||


<br><br>
<hr>
<br><br>


<A name="instance_type_lookup">Instance Type Lookup</a>
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


<A name="images_lookup">Images Lookup</a>
--------------
This corresponds to generic names such as ```CoreOS-444.5.0-(stable)``` and referring to the actual image name of ```coreos-stable-444-5-0-v20141016``` at Google.

	 :images_lookup => {
	  'us_central' => {
	        'CentOS-6.5-x64' => 'centos-6-v20141021',
	        'CoreOS-stable' => 'coreos-stable-494-5-0-v20141215',
	        'CoreOS-beta' => 'coreos-beta-522-3-0-v20141226',
	        'CoreOS-alpha' => 'coreos-alpha-549-0-0-v20150102',
	      },
	    },
	  },
	    
<A name="images_config">Images Config</a>
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

# <A name="Notes">Notes</a>
Having the provider plugins used in standard ways demonstrates the disparity among them.  There are subtle differences in synchronous/asynchonous behaviors where up/destory commands might act differently.

<A name="directory_structure">Directory Structure</a>
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
└─── spice-examples
</pre>

<br>
	  

<A name="abstracted_vagrantfile">Abstracted Vagrantfile</a>
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


<A name="Networking">Networking</a>
----------
Different public cloud providers also leverage different networking capabilities.  Some assign public IPs directly to interfaces of the machine, while others leverage NAT and private IP spaces.  In addition, some provide intra-VM communication between machines while others only allow communication through public IP addresses.  VagrantSpice has many options here, but the default is to allow communication between VMs using the public internet routable IP address to maintain cloud interoperability.


<A name="image_names_from_providers">Image Names from Providers</a>
--------------------------
Work in progress..

Digital Ocean

```vagrant digitalocean-list images token```


<A name="Limitations">Limitations</a>
-----------
The project has built the framework to normalize for cloud providers but only works for a CentOS 6.5 x64 and a small or medium instance type.

As an abstraction above a Vagrantfile you will find a lot of the settings are done via strings and evals.  This leaves some flexibility in allowing for unplanned scenarios.


# <A name="future_statement">Future Statement</a>
The project currently is serving as Vagrantfile abstraction.  You can think of it as bringing structure to something that through a domain specific language was unstructured but very powerful.  The downside is that it is currently a layer above Vagrant which can make it difficult to troubleshoot with standard Vagrant knowledge.  Let's see where this goes!

# <A name="Contributing">Contributing</a>
Please contribute in any way to the project.  Specifically, normalizing differnet image sizes, locations, and intance types would be easy adds to enhance the usefulness of the project.


# <A name="Licensing">Licensing</a>
Licensed under the Apache License, Version 2.0 (the “License”); you may not use this file except in compliance with the License. You may obtain a copy of the License at <http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

# <A name="Support">Support</a>
Please file bugs and issues at the Github issues page. For more general discussions you can contact the EMC Code team at <a href="https://groups.google.com/forum/#!forum/emccode-users">Google Groups</a>. The code and documentation are released with no warranties or SLAs and are intended to be supported through a community driven process.
