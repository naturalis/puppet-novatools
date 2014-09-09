Puppet::Type.type(:nova_volume_create).provide(:nova) do

  desc "Manage Openstack with nova tools"

  commands :nova => 'nova'

  def exists?
    nova("volume-list","--os-auth-url","http://10.41.1.1:5000/v2.0","--os-tenant-name","fileservers","--os-tenant-id","cd707e8e349745bda47416179e4f537f","--os-username","admin","--os-password",resource[:password]).match(/^#{resource[:name]}$/)
  end

  def create
    nova("volume-create","1","--display-name",resource[:name],"--os-auth-url","http://10.41.1.1:5000/v2.0","--os-tenant-name","fileservers","--os-tenant-id","cd707e8e349745bda47416179e4f537f","--os-username","admin","--os-password",resource[:password])
  end

  def destory
    nova("volume-delete",resource[:name],"--os-auth-url","http://10.41.1.1:5000/v2.0","--os-tenant-name","fileservers","--os-tenant-id","cd707e8e349745bda47416179e4f537f","--os-username","admin","--os-password",resource[:password])
  end

end
