{
  :boxes => [
    { 
      :hostname  =>  'digitalocean-coreos01',
      :common_location_name => 'us_west',
      :common_instance_type => 'micro',
      :common_image_name => 'CoreOS-stable',
    },
    { 
      :hostname  =>  'digitalocean-coreos02',
      :common_location_name => 'us_east',
      :common_instance_type => 'small',
      :common_image_name => 'CoreOS-beta'
    },
    { 
      :hostname  =>  'digitalocean-coreos03',
      :common_location_name => 'asia_east',
      :common_instance_type => 'medium',
      :common_image_name => 'CoreOS-alpha',
    },
    { 
      :hostname  =>  'digitalocean-coreos04',
      :common_location_name => 'europe_west',
      :common_instance_type => 'large',
      :common_image_name => 'CoreOS-alpha',
    },
    { 
      :hostname  =>  'digitalocean-coreos05',
      :common_location_name => 'uk_east',
      :common_instance_type => 'micro',
      :common_image_name => 'CoreOS-alpha',
    },
  ],
  :boxes_type => 'coreos-fleet',
  :config_param => '{
      :etcd_url => "https://discovery.etcd.io/56960ade2f50cd06d89284657f87c0db",
    }',
}

