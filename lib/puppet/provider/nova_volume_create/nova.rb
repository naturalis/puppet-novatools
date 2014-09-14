Puppet::Type.type(:nova_volume_create).provide(:nova) do

  desc 'Manage Openstack with nova tools'

  require 'net/http'
  require 'uri'
  require 'json'
  require 'time'

  commands nova: 'nova'

  $token = false

  def exists?
    # nova('--os-auth-url', "http://#{resource[:controller_ip]}:5000/v2.0",
    #      '--os-tenant-name', resource[:tenant],
    #      '--os-username', resource[:username],
    #      '--os-password', resource[:password],
    #      'volume-list').match("#{resource[:name]}")
    if find_volume(token)
      true
    else
      false
    end
  end

  def create
    # nova('--os-auth-url', "http://#{resource[:controller_ip]}:5000/v2.0",
    #      '--os-tenant-name', resource[:tenant],
    #      '--os-username', resource[:username],
    #      '--os-password', resource[:password],
    #      'volume-create', resource[:volume_size],
    #      '--display-name', resource[:name])
    create_volume(token)
  end

  def destroy
    nova('--os-auth-url', "http://#{resource[:controller_ip]}:5000/v2.0",
         '--os-tenant-name', resource[:tenant],
         '--os-username',  resource[:username],
         '--os-password', resource[:password],
         'volume-delete', resource[:name])
  end

  def find_volume(tk)
    token = update_token(tk)

    volume_endpoint = String.new
    token['access']['serviceCatalog'].each do |endpoint|
      if endpoint['type'].include? 'volume'
        volume_endpoint = endpoint['endpoints'][0]['publicURL']
      end
    end

    uri = URI("#{volume_endpoint}/volumes")

    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP.Get.new(uri.path)
    req['x-auth-token'] = token['access']['token']['id']
    req['content-type'] = 'application/json'
    req['accept'] = 'application/json'
    res = http.request(req)
    res['volumes'].each do |v|
      if v['display_name'].include? resource[:name]
        return true
      end
    end
  end

  def create_volume(tk)
    token = update_token(tk)

    volume_endpoint = String.new
    token['access']['serviceCatalog'].each do |endpoint|
      if endpoint['type'].include? 'volume'
        volume_endpoint = endpoint['endpoints'][0]['publicURL']
      end
    end

    uri = URI("#{volume_endpoint}/volumes")

    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP.Post.new(uri.path)
    volume_data = { 'volume' => {'size' => '1', 'display_name' => resource[:name] } }
    req.body = volume_data.to_json
    req['x-auth-token'] = token['access']['token']['id']
    req['content-type'] = 'application/json'
    req['accept'] = 'application/json'
    res = http.request(req)
    return JSON.parse(res.body)
  end

  def openstack_auth
    uri = URI("http://#{resource[:controller_ip]}:5000/v2.0")
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP.Post.new(uri.path)
    auth_data = { 'auth' => { 'tenantName' => resouce[:tenant], 'passwordCredentials' => { 'username' => resouce[:username], 'password' => resource[:password] } } }
    req.body = auth_data.to_json
    req['content-type'] = 'application/json'
    req['accept'] = 'application/json'
    res = http.request(req)
    return JSON.parse(res.body)
  end

  def update_token(tk)
    unless tk
      expire = Time.parse(token['access']['token']['expires']) - 60
      if Time.now > expire then
        return openstack_auth
      end
    else
      return opentstack_auth
    end
  end

end
