Puppet::Type.type(:nova_volume_attach).provide(:nova) do

  desc 'Manage Openstack with nova tools'

  commands nova: 'nova'

  require 'net/http'
  require 'uri'
  require 'json'
  require 'time'

  @token = false

  def exists?
    find_volume
    attach_info
  end

  def create
    attach_volume
  end

  def destroy
    puts 'destroy to be implemented'
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
    fail 'could not retrieve instances list' if info['servers'].empty?
    info['servers'].each do |i|
      id = i['id'] if i['name'].include? resource[:instance]
    end
    fail 'could not find instance with name %s' % resource[:instance] if id.include? 'none'
    id
  end

  def attach_info
    id = instance_id
    info = volume_info
    if info['volumes'].empty?
      fail 'No volumes found'
    else
      info['volumes'].each do |v|
        if v['display_name'].include? resource[:name]
          puts v['attachents']
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
    res = volume_info
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

  def volume_id
    info = volume_info
    info['volumes'].each do |v|
      if v['display_name'].include? resource[:name]
        return v['id']
      end
    end
  end

  def attach_volume
    t_id = tenant_id
    i_id = instance_id
    v_id = volume_id
    update_token
    compute_endpoint = String.new
    @token['access']['serviceCatalog'].each do |endpoint|
      compute_endpoint = endpoint['endpoints'][0]['publicURL'] if endpoint['type'].include? 'compute'
    end

    uri = URI("#{compute_endpoint}/servers/#{i_id}/os-volume_attachments")
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Post.new(uri.path)
    volume_data = { 'volumeAttachment' => {'volumeId' => v_id, 'attachment' => 'auto' } }
    req.body = volume_data.to_json
    req['x-auth-token'] = @token['access']['token']['id']
    req['content-type'] = 'application/json'
    req['accept'] = 'application/json'
    res = http.request(req)
  end

  def tenant_id
    @token['access']['token']['tenant']['id']
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
