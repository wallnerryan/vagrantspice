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

