Puppet::Type.type(:nova_volume_attach).provide(:nova) do

  desc 'Manage Openstack with nova tools'

  commands nova: 'nova'

  @token = false

  def exists?
    # JOBS
    # Check if volume exists
    # Check if voume is attached to something

    # vi = get_volume_info
    # id = get_instance_id
    # if id == "not found"
    #   raise "Instance %s is not found" % resource[:instance]
    # end
    # if vi["attached_to"] == id
    #   true
    # elsif vi["attached_to"] == ""
    #   false
    # else
    #   raise "Volume %s is attached to different instance" % resource[:name]
    # end
    find_volume
    attach_info
  end

  def create
    # vi = get_volume_info
    # nova('--os-auth-url', "http://#{resource[:controller_ip]}:5000/v2.0",
    #      '--os-tenant-name', resource[:tenant],
    #      '--os-username', resource[:username],
    #      '--os-password', resource[:password],
    #      'volume-attach', resource[:instance], vi['id'])
    puts 'create to be implemented'
  end

  def destroy
    # vi = get_volume_info
    # nova('--os-auth-url', "http://#{resource[:controller_ip]}:5000/v2.0",
    #      '--os-tenant-name', resource[:tenant],
    #      '--os-username', resource[:username],
    #      '--os-password', resource[:password],
    #      'volume-detach', resource[:instance], vi['id'])
    puts 'destroy to be implemented'
  end

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

  def get_instance_id
    instance_id = "not found"
    vid = nova('--os-auth-url', "http://#{resource[:controller_ip]}:5000/v2.0",
               '--os-tenant-name', resource[:tenant],
               '--os-username', resource[:username],
               '--os-password', resource[:password],
               'list')
    vid = vid.split("\n")
    vid.each do |v|
      if v.include? resource[:instance]
        r = v.split('|')
        instance_id = r[1].strip
      end
    end
    return instance_id
  end

  def volume_info
    update_token
    volume_endpoint = String.new
    @token['access']['serviceCatalog'].each do |endpoint|
      volume_endpoint = endpoint['endpoints'][0]['publicURL'] if endpoint['type'].include? 'volume'
    end

    uri = URI("#{volume_endpoint}/volumes")
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Get.new(uri.path)
    req['x-auth-token'] = @token['access']['token']['id']
    req['content-type'] = 'application/json'
    req['accept'] = 'application/json'
    res = http.request(req)
    JSON.parse(res.body)
  end

  def instances_info
    update_token
    compute_endpoint = String.new
    @token['access']['serviceCatalog'].each do |endpoint|
      compute_endpoint = endpoint['endpoints'][0]['publicURL'] if endpoint['type'].include? 'compute'
    end

    uri = URI("#{compute_endpoint}/servers")
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Get.new(uri.path)
    req['x-auth-token'] = @token['access']['token']['id']
    req['content-type'] = 'application/json'
    req['accept'] = 'application/json'
    res = http.request(req)
    JSON.parse(res.body)
  end

  def instance_id
    info = instances_info
    id = 'none'
    puts info
    fail 'could not retrieve instances list' if info['servers'].empty?
    info['servers'].each do |i|
      puts i['name']
      id = i['id'] if i['name'].include? resource[:instance]
    end
    fail 'could not find instance with name %s' % resource[:instance] if id.include? 'none'
    id
  end

  def attach_info
    id = instance_id
    info = volume_info
    if info['volumes'].empty?
      # fail 'Volume with displayname %s cannot be found' % resource[:name]
      fail 'No volumes found'
    else
      info['volumes'].each do |v|
        if v['display_name'].include? resource[:name]
           if v['attachments'].include? id
             return true
           else
             if v['status'].include? 'available'
               return false
             else
               fail 'volume is not available. It could be in error or attached to different instance. Status of volume is %s' % v['status']
             end
           end
        else
          fail 'No volume found with display_name %s' % resource[:name]
        end
      end
    end
  end

  def find_volume
    update_token
    volume_endpoint = String.new
    @token['access']['serviceCatalog'].each do |endpoint|
      if endpoint['type'].include? 'volume'
        volume_endpoint = endpoint['endpoints'][0]['publicURL']
      end
    end

    uri = URI("#{volume_endpoint}/volumes")

    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Get.new(uri.path)
    req['x-auth-token'] = @token['access']['token']['id']
    req['content-type'] = 'application/json'
    req['accept'] = 'application/json'
    res = http.request(req)
    res = JSON.parse(res.body)
    if res['volumes'].empty?
      return false
    else
      res['volumes'].each do |v|
        if v['display_name'].include? resource[:name]
          puts 'volume found'
          return true
        else
          puts 'volume not found'
          return false
        end
      end
    end
  end

  def create_volume
    update_token

    volume_endpoint = String.new
    @token['access']['serviceCatalog'].each do |endpoint|
      if endpoint['type'].include? 'volume'
        volume_endpoint = endpoint['endpoints'][0]['publicURL']
      end
    end

    uri = URI("#{volume_endpoint}/volumes")

    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Post.new(uri.path)
    volume_data = { 'volume' => {'size' => '1', 'display_name' => resource[:name] } }
    req.body = volume_data.to_json
    req['x-auth-token'] = @token['access']['token']['id']
    req['content-type'] = 'application/json'
    req['accept'] = 'application/json'
    res = http.request(req)

    JSON.parse(res.body)
  end

  def openstack_auth
    uri = URI("http://#{resource[:controller_ip]}:5000/v2.0/tokens")
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Post.new(uri.path)
    auth_data = { 'auth' => { 'tenantName' => resource[:tenant], 'passwordCredentials' => { 'username' => resource[:username], 'password' => resource[:password] } } }
    req.body = auth_data.to_json
    req['content-type'] = 'application/json'
    req['accept'] = 'application/json'
    res = http.request(req)

    JSON.parse(res.body)
  end

  def update_token
    if @token
      puts 'token exists'
      expire = Time.parse(@token['access']['token']['expires']) - 60
      # if Time.now > expire then
      #   token = openstack_auth
      # end
      puts 'token expired, requesting new' if Time.now > expire
      @token = openstack_auth if Time.now > expire
    else
      puts 'token created'
      @token = openstack_auth
    end
  end


end
