{
  'azure' => {
    :mgmt_certificate => 'cert/azure.pem',
    :mgmt_endpoint => 'https://management.core.windows.net',
    :subscription_id => 'guid',
    :storage_acct_name => 'portalvhds6qmhy1bc0fqn8',    
    :private_key => 'cert/azure.pem',
    :public_cert => 'cert/azure.cer',
  },
  'azure_files' => {
    :storage_access_key => '...==',
    :storage_account => 'portal...',
  },
  'aws' => {
    :access_key_id => 'AK...',
    :secret_access_key => 'key+',
    :keypair_name => 'dicey1',
    :private_key => 'cert/dicey1.pem',
  },
  'aws_s3' => {
    :access_key_id => 'AK...',
    :secret_access_key => 'key+',
    :s3_host_base => 's3.amazonaws.com',
    :s3_host_bucket => '%(bucket)s.s3.amazonaws.com',
  },
  'digital_ocean' => {
    :token => 'toen..',
    :private_key => 'cert/digital_ocean',
    :ssh_key_name => 'Vagrant',
  },
  'google' => {
    :google_project_id => 'lucid-sol-713',
    :google_client_email  => 'id-id@developer.gserviceaccount.com',
    :google_key_location => 'cert/My First Project-fffcc674adc0.p12',
    :private_key => "cert/google_compute_engine",
  },
  'google_storage' => {
    :service_account => 'number-id@developer.gserviceaccount.com',
    :key_file  => '/tmp/cert/My First Project-fffcc674adc0.p12',
  },
  'rackspace' => {
    :username => 'clintonskitson',
    :api_key  => 'id...',
    :keypair_name => 'id_rsa',
    :private_key => 'cert/id_rsa',
  },
  'rackspace_swift' => {
    :st_user => 'clintonskitson',
    :st_key  => 'key...',
    :st_auth => 'https://auth.api.rackspacecloud.com/v1.0',
  },

  'virtualbox' => {},

  :defaults => {
    :domain => 'scaleio.local',
    :plugin_config => "
      config.hostmanager.enabled = true
      config.hostmanager.manage_host = false
      config.hostmanager.ignore_private_ip = true
      config.hostmanager.include_offline = false
    ",
    :plugin_config_vm => "
      deploy_config.hostmanager.aliases = box[:hostname] 
    ",
  }
}