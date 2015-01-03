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
}

