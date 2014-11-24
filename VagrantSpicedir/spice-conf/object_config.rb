

{
  'azure_files' => {
    'puppetmaster' => {
      'CentOS-6.5-x64' => {
        :download_commands => proc {|object_creds| "
            rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
            rpm -e npm || :
            rm -Rf /usr/lib/node_modules/npm
            rm -f /usr/bin/npm
            yum install -y yum-plugin-fastestmirror
            yum update -y nodejs
            yum install -y npm
            npm install azure-cli -g
            export AZURE_STORAGE_ACCOUNT=#{object_creds[:storage_account]}
            export AZURE_STORAGE_ACCESS_KEY=#{object_creds[:storage_access_key]}
            files=( 
                   'yourfile1'
                   )
            mkdir -p /etc/puppet/modules/scaleio/files/
            for file in ${files[@]}
            do
              echo copying $file
              azure storage blob download scaleio $file /tmp/$file
            done
            /etc/init.d/puppetmaster restart
          "
        },
      }
    }
  },
  'aws_s3' => {
    'puppetmaster' => {
      'CentOS-6.5-x64' => {
        :download_commands => proc {|object_creds| "
            yum install -y wget
            wget http://s3tools.org/repo/RHEL_6/s3tools.repo --output-document=/etc/yum.repos.d/s3tools.repo
              cat >/tmp/s3cfg <<EOM
[default]
access_key = #{object_creds[:access_key_id]}
secret_key = #{object_creds[:secret_access_key]}
host_base = #{object_creds[:s3_host_base]}
host_bucket = #{object_creds[:s3_host_bucket]}
EOM
              sudo yum install s3cmd -y
              s3cmd --config /tmp/s3cfg  get s3://yourfile* /tmp/.
              /etc/init.d/puppetmaster restart
          "
        }
      }
    }
  },
  'google_storage' => {
    'puppetmaster' => {
      'CentOS-6.5-x64' => {
        :download_commands => proc {|object_creds| "
            echo 'Authenticating and Downloading from Google Storage'
            rpm -e pyOpenSSL
            rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
            yum install -y openssl-devel python-devel python-pip libffi-devel gcc
            easy_install pyOpenSSL
            CLOUDSDK_PYTHON_SITEPACKAGES=1 /usr/local/bin/gcloud auth activate-service-account #{object_creds[:service_account]} --key-file='#{object_creds[:key_file]}'
            /usr/local/bin/gsutil cp gs://yourfile* /tmp/.
          "
        },
      }
    }
  },
  'rackspace_swift' => {
    'puppetmaster' => {
      'CentOS-6.5-x64' => {
        :download_commands => proc {|object_creds| "
            rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
            yum install -y go git
            export GOPATH=~/go
            go get github.com/fanatic/swift-cli
            go build -o swift-cli github.com/fanatic/swift-cli
            export ST_KEY=#{object_creds[:st_key]}
            export ST_USER=#{object_creds[:st_user]}
            export ST_AUTH=#{object_creds[:st_auth]}
            files=( 
                   'file1'
                   )
            mkdir -p /etc/puppet/modules/scaleio/files/
            for file in ${files[@]}
            do
              echo copying $file
              ./swift-cli get $file > /tmp/.
            done
          "
        }
      }
    }
  },
}