
Vagrant.configure("2") do |config|
  plugin_config = $consumer_config[$provider][:plugin_config] || $consumer_config[:defaults][:plugin_config]
  eval(plugin_config)
  plugin_config_vm = $consumer_config[$provider][:plugin_config_vm] || $consumer_config[:defaults][:plugin_config_vm]

  eval($provider_config[$provider][:ip_resolver]) unless !$provider_config[$provider][:ip_resolver]

  config_str = $provider_config[$provider][:defaults][:config] || $provider_config[:defaults][:config]
  eval(config_str)
      

  boxes.each do |box|
    repo_url = box[:repo_url] || $provider_config[$provider][:instances_config][box[:type]][:repo_url] || $provider_config[$provider][:defaults][:repo_url]
    domain = box[:domain] || $consumer_config[$provider][:domain] || $consumer_config[:defaults][:domain]
    common_image_name = box[:common_image_name] || $provider_config[$provider][:instances_config][box[:type]][:common_image_name] || $provider_config[$provider][:defaults][:common_image_name]
    config_steps_type = box[:config_steps_type] || $provider_config[$provider][:instances_config][box[:type]][:config_steps_type]
    instance_image = $provider_config[$provider][:images_lookup][common_image_name]
    
    common_instance_type = box[:common_instance_type] || $provider_config[$provider][:instances_config][box[:type]][:common_instance_type] || $provider_config[$provider][:defaults][:common_instance_type]
    instance_type = $provider_config[$provider][:instance_type_lookup][common_instance_type]
    if instance_type[:type] == :custom
      str_instance_type = [instance_type[:memory],instance_type[:cpus]].join("\n")
    else
      str_instance_type = instance_type[:name]
    end

    location = box[:common_location_name] || $provider_config[$provider][:instances_config][box[:type]][:common_location_name] || $provider_config[$provider][:defaults][:common_location_name]
    str_location = $provider_config[$provider][:location_lookup][location] if $provider_config[$provider][:location_lookup]

    str_optional = box[:optional] || $provider_config[$provider][:instances_config][box[:type]][:optional] || $provider_config[$provider][:defaults][:optional]

    config.vm.box = $provider_config[$provider][:images_config][instance_image][:box] || $provider_config[$provider][:instances_config][box[:type]][:box] || $provider_config[$provider][:box]

    object_creds = box[:object_creds] || $provider_config[$provider][:instances_config][box[:type]][:object_creds] || $provider_config[$provider][:defaults][:object_creds]

    config.vm.define box[:hostname] do |deploy_config|
      fqdn = "#{box[:hostname]}.#{domain}"
      deploy_config.vm.hostname = fqdn
      eval(plugin_config_vm)
      eval($provider_config[$provider][:deploy_box_config])
      sync_folder = box[:sync_folder] || $provider_config[$provider][:instances_config][box[:type]][:sync_folder] || $provider_config[$provider][:sync_folder]
      eval(sync_folder)

      config_param_str = box[:config_param] || $provider_config[$provider][:instances_config][box[:type]][:config_param] || $provider_config[$provider][:defaults][:config_param] || $provider_config[:defaults][:config_param]
      config_param = eval(config_param_str)      
      bootstrap_script = $config_steps[config_steps_type].call(config_param)
      deploy_config.vm.provision :shell, :inline => bootstrap_script
    end
  end
end