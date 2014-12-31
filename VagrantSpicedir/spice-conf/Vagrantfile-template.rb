
Vagrant.configure("2") do |config|
  boxes_type = boxes_config[:boxes_type]
  plugin_config = boxes_config[:plugin_config] \
    || ($consumer_config[$provider][:instances_config][boxes_type][:plugin_config] if ($consumer_config[$provider][:instances_config] and $consumer_config[$provider][:instances_config][boxes_type])) \
    || ($consumer_config[:defaults][:instances_config][boxes_type][:plugin_config] if ($consumer_config[:defaults][:instances_config] and $consumer_config[:defaults][:instances_config][boxes_type])) \
    || ($provider_config[$provider][:instances_config][boxes_type][:plugin_config] if ($provider_config[$provider][:instances_config] and $provider_config[$provider][:instances_config][boxes_type])) \
    || ($provider_config[:defaults][:instances_config][boxes_type][:plugin_config] if ($provider_config[:defaults][:instances_config] and $provider_config[:defaults][:instances_config][boxes_type])) \
    || $consumer_config[$provider][:plugin_config] \
    || $consumer_config[:defaults][:plugin_config] || '{}'
  
  eval(plugin_config)
  plugin_config_vm = $consumer_config[$provider][:plugin_config_vm] \
    || $consumer_config[:defaults][:plugin_config_vm] || '{}'

  eval($provider_config[$provider][:ip_resolver]) unless !$provider_config[$provider][:ip_resolver]

  config_str = $provider_config[$provider][:defaults][:config] || $provider_config[:defaults][:config]
  eval(config_str)
      
  boxes = boxes_config[:boxes]
  #eval(boxes_config[:boxes_pre_install])

  boxes.each do |box|      
    box_type = box[:type] || boxes_config[:boxes_type] \
      || (eval(boxes_config[:config_param])[:type] unless !boxes_config[:config_param]) \
      || (eval(boxes_config[:config_param])[:type] unless !boxes_config[:config_param]) \
      || (eval($provider_config[$provider][:defaults][:config_param])[:type] unless !$provider_config[$provider][:defaults][:config_param]) \
      || (eval($provider_config[:defaults][:config_param])[:type] unless !$provider_config[:defaults][:config_param])
    repo_url = box[:repo_url] || $provider_config[$provider][:instances_config][box_type][:repo_url] || $provider_config[$provider][:defaults][:repo_url]
    domain = box[:domain] || $consumer_config[$provider][:domain] || $consumer_config[:defaults][:domain]
    common_image_name = box[:common_image_name] || $provider_config[$provider][:instances_config][box_type][:common_image_name] || $provider_config[$provider][:defaults][:common_image_name]
    config_steps_type = box[:config_steps_type] || $provider_config[$provider][:instances_config][box_type][:config_steps_type]
    instance_image = $provider_config[$provider][:images_lookup][common_image_name]
    
    common_instance_type = box[:common_instance_type] || $provider_config[$provider][:instances_config][box_type][:common_instance_type] || $provider_config[$provider][:defaults][:common_instance_type]
    instance_type = $provider_config[$provider][:instance_type_lookup][common_instance_type]
    if instance_type[:type] == :custom
      str_instance_type = [instance_type[:memory],instance_type[:cpus]].join("\n")
    else
      str_instance_type = instance_type[:name]
    end

    location = box[:common_location_name] || $provider_config[$provider][:instances_config][box_type][:common_location_name] || $provider_config[$provider][:defaults][:common_location_name]
    str_location = $provider_config[$provider][:location_lookup][location] if $provider_config[$provider][:location_lookup]

    str_optional = box[:optional] || $provider_config[$provider][:instances_config][box_type][:optional] || $provider_config[$provider][:defaults][:optional]

    config.vm.box = $provider_config[$provider][:images_config][instance_image][:box] || $provider_config[$provider][:instances_config][box_type][:box] || $provider_config[$provider][:box]

    object_creds = box[:object_creds] || $provider_config[$provider][:instances_config][box_type][:object_creds] || $provider_config[$provider][:defaults][:object_creds]

    config.vm.define box[:hostname] do |deploy_config|
      fqdn = "#{box[:hostname]}.#{domain}"
      deploy_config.vm.hostname = fqdn
      eval(plugin_config_vm)
      eval($provider_config[$provider][:deploy_box_config])
      sync_folder = box[:sync_folder] || $provider_config[$provider][:instances_config][box_type][:sync_folder] || $provider_config[$provider][:sync_folder]
      eval(sync_folder)

      config_param_str = box[:config_param] || boxes_config[:config_param] \
        || $provider_config[$provider][:instances_config][box_type][:config_param] \
        || $provider_config[$provider][:defaults][:config_param] \
        || $consumer_config[:defaults][:instances_config][box_type][:config_param] \
        || $provider_config[:defaults][:instances_config][box_type][:config_param] \
        || $provider_config[:defaults][:config_param]
      config_param = eval(config_param_str)

      bootstrap_script = $config_steps[config_steps_type].call(box_type,config_param)
      deploy_config.vm.provision :shell, :inline => bootstrap_script
    end
  end
end

