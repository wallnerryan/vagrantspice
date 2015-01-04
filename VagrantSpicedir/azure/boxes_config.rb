{
  :boxes => [
    { 
      :hostname  =>  'azure-coreos01',
      :common_location_name => 'asia_east',
      :common_instance_type => 'micro',
      :common_image_name => 'CoreOS-stable',
    },
    { 
      :hostname  =>  'azure-coreos02',
      :common_location_name => 'europe_north',
      :common_instance_type => 'medium',
      :common_image_name => 'CoreOS-alpha',
    },
    { 
      :hostname  =>  'azure-coreos03',
      :common_location_name => 'europe_west',
      :common_instance_type => 'large',
      :common_image_name => 'CoreOS-alpha',
    },
    { 
      :hostname  =>  'azure-coreos04',
      :common_location_name => 'japan_west',
      :common_instance_type => 'micro',
      :common_image_name => 'CoreOS-alpha',
    },
    { 
      :hostname  =>  'azure-coreos05',
      :common_location_name => 'us_central',
      :common_instance_type => 'micro',
      :common_image_name => 'CoreOS-alpha',
    },
    { 
      :hostname  =>  'azure-coreos06',
      :common_location_name => 'us_west',
      :common_instance_type => 'micro',
      :common_image_name => 'CoreOS-alpha',
    },
    { 
      :hostname  =>  'azure-coreos07',
      :common_location_name => 'us_east',
      :common_instance_type => 'micro',
      :common_image_name => 'CoreOS-alpha',
    },

  ],
  :boxes_type => 'coreos',
  :config_param => '{
      :etcd_url => "https://discovery.etcd.io/da081f65e1545511a78aebdd35ea1cf1",
    }',
  :firewall => "4001:4001,7001:7001"
}

