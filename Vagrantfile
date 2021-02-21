# -*- mode: ruby -*-
# vi: set ft=ruby :

# Customize behavior via environment variables, or by updating the defaults specified below.

# Currently support only a single Step-CA Server. Set to zero to not build any.
#step_ca_server_count   = ENV['step_ca_server_count'].to_i || 1
step_ca_ip_start        = ENV['step_ca_ip_start']          || '192.168.100.20'

step_ca_hostname_prefix = ENV['step_ca_hostname_prefix']   || 'ca'
step_ca_hostname_suffix = ENV['step_ca_hostname_suffix']   || '.local'

step_ca_version         = ENV['step_ca_version']           || '0.15.8'
step_version            = ENV['step_version']              || '0.15.7'

bootstrap_dir           = '/tmp/bootstrap'
bootstrap_script        = bootstrap_dir + '/bootstrap.sh'

step_ca_box             = ENV['step_ca_box']               || 'ubuntu/bionic64'
step_ca_box_version     = ENV['step_ca_box_version']       || '20210218.0.0'

Vagrant.configure("2") do |config|
  config.vm.box         = step_ca_box
  config.vm.box_version = step_ca_box_version
  config.vm.hostname    = step_ca_hostname_prefix + step_ca_hostname_suffix
  config.vm.network     :private_network, ip: step_ca_ip_start
  
  config.vm.provision "shell" do |bootstrap|
    bootstrap.env = {
      'step_ca_version' => step_ca_version,
      'step_version'    => step_version,
      'ip'              => step_ca_ip_start
    }
    bootstrap.path      = 'files/step-bootstrap.sh'
  end
end
