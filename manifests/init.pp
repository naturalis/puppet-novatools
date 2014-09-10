# == Class: novatools
#
# Full description of class novatools here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { novatools:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2014 Your name here, unless otherwise noted.
#
class novatools (
  $password,
  ){

  nova_volume_create { ['testa','testb']:
    ensure         => present,
    password       => $password,
    username       => 'admin',
    tenant         => 'fileservers',
    controller_ip  => '10.41.1.1',
    volume_size    => '10',
  }

  nova_volume_attach { ['testa','testb'] :
    ensure         => present,
    password       => $password,
    username       => 'admin',
    tenant         => 'fileservers',
    controller_ip  => '10.41.1.1',
    instance       => $::fqdn,
    require        => [Nova_volume_create['testb'],Nova_volume_create['testb']],
  }

  nova_volume_mount { 'testa':
    ensure         => present,
    password       => $password,
    username       => 'admin',
    tenant         => 'fileservers',
    controller_ip  => '10.41.1.1',
    instance       => $::fqdn,
    mountpoint     => '/data',
    filesystem     => 'ext4',
    require        => Nova_volume_attach['testa'],
  }

  nova_volume_mount { 'testb':
    ensure         => present,
    password       => $password,
    username       => 'admin',
    tenant         => 'fileservers',
    controller_ip  => '10.41.1.1',
    instance       => $::fqdn,
    mountpoint     => '/piet',
    filesystem     => 'ext4',
    require        => Nova_volume_attach['testb'],
  }

}
