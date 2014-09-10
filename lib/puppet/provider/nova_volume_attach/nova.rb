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
    #volume_id = `"/usr/bin/nova --os-auth-url http://10.41.1.1:5000/v2.0 --os-tenant-name fileservers --os-username admin --os-password admin volume-list | /usr/bin/awk '{if (\$6==\"testa\") print \$2}'"`
    volume_id = `/usr/bin/nova --os-auth-url http://10.41.1.1:5000/v2.0 --os-tenant-name fileservers --os-username admin --os-password admin volume-list | grep testa`
    p volume_id

    # nova('--os-auth-url', "http://#{resource[:controller_ip]}:5000/v2.0",
    #      '--os-tenant-name', resource[:tenant],
    #      '--os-username', resource[:username],
    #      '--os-password', resource[:password],
    #      'volume-attach', resource[:instance], volume_id)

    get_volume_info
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
        r = v.split("|")
        # r.each do |r|
        #   print r.strip + "\n"
        # end
        volume_info["id"] = r[1]
        volume_info["status"] = r[2]
        volume_info["name"] = r[3]
        volume_info["attached_to"] = r[6]
        p volume_info
      end
    end
  end

end
