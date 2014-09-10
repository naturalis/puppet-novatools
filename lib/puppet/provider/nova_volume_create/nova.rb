Puppet::Type.type(:nova_volume_create).provide(:nova) do

  desc 'Manage Openstack with nova tools'

  commands nova: 'nova'

  def exists?
    nova('--os-auth-url', "http://#{resource[:controller_ip]}:5000/v2.0",
         '--os-tenant-name', resource[:tenant],
         '--os-username', resource[:username],
         '--os-password', resource[:password],
         'volume-list').match("#{resource[:name]}")
  end

  def create
    nova('--os-auth-url', "http://#{resource[:controller_ip]}:5000/v2.0",
         '--os-tenant-name', resource[:tenant],
         '--os-username', resource[:username],
         '--os-password', resource[:password],
         'volume-create', resource[:volume_size],
         '--display-name', resource[:name])
  end

  def destroy
    nova('--os-auth-url', "http://#{resource[:controller_ip]}:5000/v2.0",
         '--os-tenant-name', resource[:tenant],
         '--os-username',  resource[:username],
         '--os-password', resource[:password],
         'volume-delete', resource[:name])
  end

end
