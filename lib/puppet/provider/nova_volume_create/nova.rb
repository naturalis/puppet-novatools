Puppet::Type.type(:nova_volume_create).provide(:nova) do

  desc 'Manage Openstack with nova tools'

  commands nova: 'nova'

  def exists?
    nova('--os-auth-url', 'http://10.41.1.1:5000/v2.0',
         '--os-tenant-name', 'fileservers',
         '--os-username', 'admin',
         '--os-password', resource[:password],
         'volume-list').match("#{resource[:name]}")
  end

  def create
    nova('--os-auth-url', 'http://10.41.1.1:5000/v2.0',
         '--os-tenant-name', 'fileservers',
         '--os-username', 'admin',
         '--os-password', resource[:password],
         'volume-create', '1',
         '--display-name', resource[:name])
  end

  def destroy
    nova('--os-auth-url', 'http://10.41.1.1:5000/v2.0',
         '--os-tenant-name', 'fileservers',
         '--os-username', 'admin',
         '--os-password', resource[:password],
         'volume-delete', resource[:name])
  end

end
