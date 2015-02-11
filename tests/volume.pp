nova_volume { 'test':
    ensure            => present,
    volume_size_gb    => 1,
    attach_volume     => true,
    mount_volume      => true,
    create_filesystem => 'ext4',
    mount_point       => '/data',
    mount_options     => '-o defauts',
    keystone_endpoint => 'http://10.41.1.1:5000/v2.0/tokens',
    tenant            => 'admin',
    username          => 'admin',
    password          => 'admin'
}
