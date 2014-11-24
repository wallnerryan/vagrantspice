
{
  :ssh_hostname => "
    config.hostmanager.ip_resolver = proc do |machine|
      ip = if machine.ssh_info && machine.ssh_info[:host]
        Resolv::DNS.new.getaddress(machine.ssh_info[:host]).to_s
      end
      machine.communicate.execute('echo '+ip+' | sudo tee /etc/ssh_ip') do ||
      end
      ip
    end  
  ",
  :ssh_ip => "
    config.hostmanager.ip_resolver = proc do |machine|
      ip = if machine.ssh_info && machine.ssh_info[:host]
        machine.ssh_info[:host]
      end
      machine.communicate.execute('echo '+ip+' | sudo tee /etc/ssh_ip') do ||
      end
      ip
    end  
  ",
  :ifconfig => proc do |eth| '
      config.hostmanager.ip_resolver = proc do |machine|
      result = ""
      machine.communicate.execute("ifconfig '+eth+'") do |type, data|
        result << data if type == :stdout
      end
      result
      (ip = /^\s*inet .*?(\d+\.\d+\.\d+\.\d+)\s+/.match(result)) && ip[1]
    end
    '
  end,
}