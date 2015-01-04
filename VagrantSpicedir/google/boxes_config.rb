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
  :firewall => 'default'
}

