{
  'azure' => {
    :mgmt_certificate => 'cert/azure.pem',
    :mgmt_endpoint => 'https://management.core.windows.net',
    :subscription_id => 'ce5684a8-xxxx-xxxx-xxxx-xxxxxxxxxxx',
    :storage_acct_name_prefix => 'ce5684a8',
    :private_key => 'cert/azure.pem',
    :public_cert => 'cert/azure.cer',
  },
  'azure_files' => {
    :storage_access_key => '',
    :storage_account => '',
  },
  'aws' => {
    :access_key_id => '',
    :secret_access_key => '',
    :keypair_name => 'id_rsa',
    :private_key => 'cert/id_rsa.pem',
  },
  'aws_s3' => {
    :access_key_id => '',
    :secret_access_key => '',
    :s3_host_base => 's3.amazonaws.com',
    :s3_host_bucket => '%(bucket)s.s3.amazonaws.com',

  },
  'digital_ocean' => {
    :token => '',
    :private_key => 'cert/digital_ocean',
    :ssh_key_name => 'Vagrant',
  },
  'google' => {
    :google_project_id => 'lucid-sol-711',
    :google_client_email  => 'blah@developer.gserviceaccount.com',
    :google_key_location => 'cert/My First Project-fffcc674adc0.p12',
    :private_key => "cert/google_compute_engine",
  },
  'google_storage' => {
    :service_account => '',
    :key_file  => '',
  },
  'rackspace' => {
    :username => 'clintonskitson',
    :api_key  => 'apikey',
    :keypair_name => 'id_rsa',
    :private_key => 'cert/id_rsa',
  },
  'rackspace_swift' => {
    :st_user => 'clintonskitson',
    :st_key  => '',
    :st_auth => 'https://auth.api.rackspacecloud.com/v1.0',
  },

  'virtualbox' => {},

  :defaults => {
    :domain => "vagrantspice.local",
    :instances_config => {
      'coreos' => {
        :config_param => '{
          :etcd_url => "https://discovery.etcd.io/5a06f86a07db91ca220545745f890a98",
        }',
      }
    },
  }
}