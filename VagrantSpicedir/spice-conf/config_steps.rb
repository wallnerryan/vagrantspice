

{
  'default_linux' => proc {|config_param| "
    #{$provider_config[$provider][:instances_config][config_param[:type]][:commands][:set_hostname].call(config_param[:hostname],config_param[:domain])}        

    #{$provider_config[$provider][:instances_config][config_param[:type]][:commands][:dns_update]}
    
    #{$provider_config[$provider][:instances_config][config_param[:type]][:commands][:pre_install]}

    #{$provider_config[$provider][:instances_config][config_param[:type]][:commands][:install].call(config_param)}
    
    #{$provider_config[$provider][:instances_config][config_param[:type]][:commands][:post_install]}

    #{$object_config[$provider_config[$provider][:instances_config][config_param[:type]][:object_source]][config_param[:type]][config_param[:common_image_name]][:download_commands].call(config_param[:object_creds]) unless !$provider_config[$provider][:instances_config][config_param[:type]][:object_source]}

  "}
}