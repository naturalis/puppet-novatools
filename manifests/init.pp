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
  $controller_ip,
  $openstack_username,
  $openstack_tentant,
  $password,
  $volume_name,
  $volume_size,
  $mount_point = '/data',
  ){

  nova_volume_create { $volume_name :
    ensure         => present,
    password       => $password,
    username       => $openstack_username,
    tenant         => $openstack_tentant,
    controller_ip  => $controller_ip,
    volume_size    => $volume_size,
  }

  nova_volume_attach { $volume_name :
    ensure         => present,
    password       => $password,
    username       => $openstack_username,
    tenant         => $openstack_tentant,
    controller_ip  => $controller_ip,
    instance       => $::fqdn,
    require        => Nova_volume_create[$volume_name],
  }

  nova_volume_mount { $volume_name :
    ensure         => present,
    password       => $password,
    username       => $openstack_username,
    tenant         => $openstack_tentant,
    controller_ip  => $controller_ip,
    instance       => $::fqdn,
    mountpoint     => $mount_point,
    filesystem     => 'ext4',
    require        => Nova_volume_attach[$volume_name],
  }
}
