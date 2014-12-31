

{
  'default_linux' => proc {|box_type,config_param| "
    #{$provider_config[$provider][:instances_config][box_type][:commands][:set_hostname].call(config_param[:hostname],config_param[:domain])}        

    #{$provider_config[$provider][:instances_config][box_type][:commands][:dns_update]}
    
    #{$provider_config[$provider][:instances_config][box_type][:commands][:pre_install]}

    #{$provider_config[$provider][:instances_config][box_type][:commands][:install].call(config_param)}
    
    #{$provider_config[$provider][:instances_config][box_type][:commands][:post_install]}

    #{$object_config[$provider_config[$provider][:instances_config][box_type][:object_source]][box_type][config_param[:common_image_name]][:download_commands].call(config_param[:object_creds]) unless !$provider_config[$provider][:instances_config][box_type][:object_source]}

  "},
  'default_coreos' => proc {|box_type,config_param| "    
    #{$provider_config[$provider][:instances_config][box_type][:commands][:pre_install]}

    #{$provider_config[$provider][:instances_config][box_type][:commands][:install].call(config_param)}
    
    #{$provider_config[$provider][:instances_config][box_type][:commands][:post_install].call(config_param)}
  "}
}