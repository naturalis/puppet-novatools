# Class design
# nova_tools { volume_name:
#   ensure            => present,
#   volume_size_gb    => 1,
#   attach_volume     => true,
#   mount_volume      => true,
#   create_filesystem => 'ext4',
#   mount_point       => '/data'
#   mount_options     => '-o defauts',
#   keystone_endpoint => 'http://openstack:5000/v2.0/tokens',
#   tenant            => 'tenant',
#   username          => 'username',
#   password          => 'password',
# }

Puppet::Type.newtype(:nova_volume) do

  @doc = 'Openstack Volume managment for Puppet'

  ensurable

  newparam(:name) do
    desc 'Name of the volume'
    isnamevar
  end

  newparam(:volume_size_gb) do
    desc 'Size of volume in GB'
    validate do |v|
      fail "#{v} is not a integer" unless v.to_i.is_a? Integer
    end
    munge do |v|
      v.to_i
    end
    defaultto 1
  end

  newproperty(:attach_volume) do
    desc 'Attach the volume (or not)'
    defaultto true
    newvalues(true,false)
    munge do |v|
      v.to_s
    end
  end

  newproperty(:mount_volume) do
    desc 'Mount the volume (or not)'
    defaultto true
    newvalues(true,false)
    munge do |v|
      v.to_s
    end
  end

  newproperty(:create_filesystem) do
    desc 'Create a filesystem'
    defaultto 'ext4'
    newvalues(false,'ext4')
    munge do |v|
      v.to_s
    end
  end

  newparam(:mount_options) do
    desc 'add special mountpoints'
    defaultto('defaults')
  end

  newparam(:mount_point) do
    desc 'where to mount the volume'
    defaultto('/data')
  end


  newparam(:keystone_endpoint) do
    desc 'web uri where the keystone endpoint is found'
  end

  newparam(:tenant) do
    desc 'openstack tenant where the volume is created'
  end

  newparam(:username) do
    desc 'openstack username'
  end

  newparam(:password) do
    desc 'openstack password'
  end

end
