{
  :boxes => [
    { 
      :hostname  =>  'rackspace-coreos01',
      :common_location_name => 'us_central',
      :common_instance_type => 'micro',
      :common_image_name => 'CoreOS-stable',
    },
    { 
      :hostname  =>  'rackspace-coreos02',
      :common_location_name => 'us_east',
      :common_instance_type => 'small',
      :common_image_name => 'CoreOS-beta'
    },
    { 
      :hostname  =>  'rackspace-coreos03',
      :common_location_name => 'asia_east',
      :common_instance_type => 'medium',
      :common_image_name => 'CoreOS-alpha',
    },
    { 
      :hostname  =>  'rackspace-coreos04',
      :common_location_name => 'aus_east',
      :common_instance_type => 'large',
      :common_image_name => 'CoreOS-alpha',
    },
  ],
  :boxes_type => 'coreos-fleet',
  :config_param => '{
      :etcd_url => "https://discovery.etcd.io/bae06c1b688e7e9d6216f92bb5805691",
    }',
}

