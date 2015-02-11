require 'net/http'
require 'uri'
require 'json'
require 'time'
require 'pp'

puts 'got nova api'

class Rest
  def get(uri,xauth=false)
    uri = URI(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Get.new(uri.path)
    req['x-auth-token'] = xauth unless xauth == false
    req['content-type'] = 'application/json'
    req['accept'] = 'application/json'
    res = http.request(req)
    JSON.parse(res.body)
  end
  def put(uri,data,xauth=false)
    uri = URI(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Put.new(uri.path)
    req.body = data.to_json
    req['x-auth-token'] = xauth unless xauth == false
    req['content-type'] = 'application/json'
    req['accept'] = 'application/json'
    res = http.request(req)
    JSON.parse(res.body)
  end
  def post(uri,data,xauth=false)
    uri = URI(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Post.new(uri.path)
    req.body = data.to_json
    req['x-auth-token'] = xauth unless xauth == false
    req['content-type'] = 'application/json'
    req['accept'] = 'application/json'
    res = http.request(req)
    JSON.parse(res.body)
  end
  def delete(uri,xauth=false)
    uri = URI(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Delete.new(uri.path)
    req['x-auth-token'] = xauth unless xauth == false
    req['content-type'] = 'application/json'
    req['accept'] = 'application/json'
    res = http.request(req)
    JSON.parse(res.body)
  end
end

class OpenStackAPI < Rest
  def initialize(host,port,path,username,password,tenant)
    @host = host
    @port = port
    @token = false
    @u = username
    @t = tenant
    @p = password
  end

  def volume_list
    token
    ep = endpoint('volume')
    data = get("#{ep}/volumes",@token['access']['token']['id'])
    volumes = Array.new
    data['volumes'].each do |d|
      attached_to = 'none'
      attached_device = 'none'
      attached_to = d['attachments'][0]['server_id'] unless d['attachments'].empty?
      attached_device = d['attachments'][0]['device'] unless d['attachments'].empty?
      volumes << {
        'display_name' => d['display_name'],
        'id' => d['id'],
        'status' => d['status'],
        'size' => d['size'],
        'attached_to' => attached_to,
        'attached_device' => attached_device
       }
    end
    volumes
  end

  def volume_create(volume_name,volume_size=1)
    token
    ep = endpoint('volume')
    data = {
      "volume" => {
        "display_name" => volume_name,
        "display_description" => "#{volume_name} -- Created by Puppet",
        "size" => volume_size,
      }
    }
    post("#{ep}/volumes",data,@token['access']['token']['id'])
  end

  def volume_attach(volume_id,server_id)
    token
    ep = endpoint('compute')
    data = {
      'volumeAttachment' => {
        'volumeId' => volume_id
      }
    }
    post("#{ep}/servers/#{server_id}/os-volume_attachments",data,@token['access']['token']['id'])
  end

  def volume_show(volume_id)
    token
    ep = endpoint('volume')
    get("#{ep}/volumes/#{volume_id}",@token['access']['token']['id'])
  end

  def floating_ip_list
    token
    ep = endpoint('compute')
    get("#{ep}/os-floating-ips",@token['access']['token']['id'])
  end

  def floating_ip_create(pool)
    token
    ep = endpoint('compute')
    post("#{ep}/os-floating-ips",{'pool' => pool},@token['access']['token']['id'])
  end

  def list
    token
    ep = endpoint('compute')
    get("#{ep}/servers",@token['access']['token']['id'])
  end

  def endpoint(ep)
    token
    result = String.new
    @token['access']['serviceCatalog'].each do |endpoint|
      if endpoint['type'].include? ep
        result = endpoint['endpoints'][0]['publicURL']
      end
    end
    result
  end

  def token
    data = {'auth' => { 'tenantName' => @t, 'passwordCredentials' => { 'username' => @u, 'password' => @p } } }
    if @token
      if Time.now > Time.parse(@token['access']['token']['expires']) - 60
        puts '--- refreshing token'
        @token = post("http://#{@host}:#{@port}/v2.0/tokens",data)
      else
        puts '--- token is ok'
      end
    else
      puts '--- requesting new token'
      @token = post("http://#{@host}:#{@port}/v2.0/tokens",data)
    end
  end


  private :token, :endpoint

end
