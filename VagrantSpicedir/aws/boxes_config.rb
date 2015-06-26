
{
  :boxes => [
    {
      :hostname  =>  'puppetmaster',
      :common_location_name => 'us_west',
      :common_instance_type => 'micro',
      :common_image_name => 'CentOS-7-x64',
      :type => 'puppetmaster',
    },
    {
      :hostname  =>  'mdm1',
      :common_location_name => 'us_west',
      :common_instance_type => 'lowcpu_13mem',
      :common_image_name => 'CentOS-7-x64',
      :type => 'puppetagent',
      :storage => "[{ 'DeviceName' => '/dev/xvdb', 'Ebs.VolumeSize' => 110, 'Ebs.VolumeType' =>'io1','Ebs.Iops' =>'300' }]",
    },
    {
      :hostname  =>  'tb',
      :common_location_name => 'us_west',
      :common_instance_type => 'lowcpu_13mem',
      :common_image_name => 'CentOS-7-x64',
      :type => 'puppetagent',
      :storage => "[{ 'DeviceName' => '/dev/xvdb', 'Ebs.VolumeSize' => 110, 'Ebs.VolumeType' =>'io1','Ebs.Iops' =>'300' }]",
    },
    {
      :hostname  =>  'mdm2',
      :common_location_name => 'us_west',
      :common_instance_type => 'lowcpu_13mem',
      :common_image_name => 'CentOS-7-x64',
      :type => 'puppetagent',
      :storage => "[{ 'DeviceName' => '/dev/xvdb', 'Ebs.VolumeSize' => 110, 'Ebs.VolumeType' =>'io1','Ebs.Iops' =>'300' }]",
    },
  ],
  :boxes_type => 'puppetagent',
  :firewall => "['default', 'CentOS 7 -x86_64- with Updates HVM-7 2014-09-29-AutogenByAWSMP-']",
}
