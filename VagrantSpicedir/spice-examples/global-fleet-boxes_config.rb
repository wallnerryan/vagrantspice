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

