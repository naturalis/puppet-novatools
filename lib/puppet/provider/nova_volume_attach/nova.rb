Puppet::Type.type(:nova_volume_attach).provide(:nova) do

  desc 'Manage Openstack with nova tools'

  commands nova: 'nova'

  def exists?
    # nova('--os-auth-url', "http://#{resource[:controller_ip]}:5000/v2.0",
    #      '--os-tenant-name', resource[:tenant],
    #      '--os-username', resource[:username],
    #      '--os-password', resource[:password],
    #      'volume-list').match("#{resource[:name]}")
    false
  end

  def create
    vi = get_volume_info
    nova('--os-auth-url', "http://#{resource[:controller_ip]}:5000/v2.0",
         '--os-tenant-name', resource[:tenant],
         '--os-username', resource[:username],
         '--os-password', resource[:password],
         'volume-attach', resource[:instance], vi['id'])
  end

  # def destroy
  #   nova('--os-auth-url', "http://#{resource[:controller_ip]}:5000/v2.0",
  #        '--os-tenant-name', resource[:tenant],
  #        '--os-username',  resource[:username],
  #        '--os-password', resource[:password],
  #        'volume-delete', resource[:name])
  # end

  def get_volume_info
    volume_info = Hash.new
    vid = nova('--os-auth-url', "http://#{resource[:controller_ip]}:5000/v2.0",
               '--os-tenant-name', resource[:tenant],
               '--os-username', resource[:username],
               '--os-password', resource[:password],
               'volume-list')
    vid = vid.split("\n")
    vid.each do |v|
      if v.include? resource[:name]
        r = v.split('|')
        volume_info['id'] = r[1].strip
        volume_info['status'] = r[2].strip
        volume_info['name'] = r[3].strip
        volume_info['attached_to'] = r[6].strip
      end
    end
    return volume_info
  end

end
