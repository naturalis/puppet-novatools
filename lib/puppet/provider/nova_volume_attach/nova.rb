Puppet::Type.type(:nova_volume_attach).provide(:nova) do

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
    volume_id = `"/usr/bin/nova --os-auth-url http://10.41.1.1:5000/v2.0 --os-tenant-name fileservers --os-username admin --os-password admin volume-list | awk '{if ($6==\"testa\") print $2}'"`
    nova('--os-auth-url', "http://#{resource[:controller_ip]}:5000/v2.0",
         '--os-tenant-name', resource[:tenant],
         '--os-username', resource[:username],
         '--os-password', resource[:password],
         'volume-attach', resource[:instance], volume_id)
  end

  # def destroy
  #   nova('--os-auth-url', "http://#{resource[:controller_ip]}:5000/v2.0",
  #        '--os-tenant-name', resource[:tenant],
  #        '--os-username',  resource[:username],
  #        '--os-password', resource[:password],
  #        'volume-delete', resource[:name])
  # end

end
