Puppet::Type.newtype(:nova_volume_attach) do

  @doc = 'Attach/Detach volumes from instances'

  ensurable

  newparam(:name) do
    desc 'Name of the volume'

    isnamevar

  end

  newparam(:tenant) do
    desc 'Name of tentant'

  end

  newparam(:username) do
    desc 'Openstack Username'

  end

  newparam(:password) do
    desc 'Openstack Password'

  end

  newparam(:controller_ip) do
    desc 'DNS/IP of the controller/API Endpoint'

  end

  newparam(:instance) do
    desc 'Name/ID of instance to attach to'
  end

  newparam(:api_port) do
    desc 'Auth Portnummer of API (defautl 5000)'

    defaultto '5000'

  end

  newparam(:api_version) do
    desc 'Auth API version (default to v2.0)'

    defaultto 'v2.0'

  end

end
