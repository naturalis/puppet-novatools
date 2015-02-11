class novatools::volume
(
    $volume_name,
    $volume_size       = 1,
    $attach_volume     = true,
    $mount_volume      = true,
    $create_filesystem = 'ext4',
    $mount_point       = '/data',
    $mount_options     = '-o defaults',
    $keystone_endpoint = 'http://your.ip.to.keystone:5000/v2.0/tokens',
    $tenant,
    $username,
    $password
){

  nova_volume { $volume_name:
      ensure            => present,
      volume_size_gb    => $volume_size,
      attach_volume     => $attach_volume,
      mount_volume      => $mount_volume,
      create_filesystem => $create_filesystem,
      mount_point       => $mount_point,
      mount_options     => $mount_options,
      keystone_endpoint => $keystone_endpoint,
      tenant            => $tenant,
      username          => $username,
      password          => $password,
  }

}
