Puppet::Type.type(:nova_volume_mount).provide(:mount) do

  require 'fileutils'
  require 'net/http'
  require 'uri'
  require 'json'
  require 'time'

  desc 'Manage Openstack with nova tools'

  # Workflow
  # Firsttime volume is attached devicemapping is correct
  # write label/uuid to disk which is the volume id
  # When checking, first check on uuid/label if unable to
  # find that check device mappinng from api and set filesystem to it.

  commands nova: 'nova'
  commands mount: 'mount'
  commands umount: 'umount'
  commands mkfsext4: 'mkfs.ext4'
  commands lsblk: 'lsblk'
  commands udevadm: 'udevadm'
  commands blkid: 'blkid'
  optional_commands mkfsxfs: 'mkfs.xfs'

  def exists?
    # vi = get_volume_info
    # blk = blockdevice_name(volume_id)
    # puts "in exists #{blk}"
    # if is_mounted(blk)
    #   true
    # else
    #   false
    # end
    find_uuid
    is_mounted
  end

  def create
    # first check if fs is there
    # vi = get_volume_info
    # blk = blockdevice_name(volume_id)
    #
    # unless has_filesystem(blk, resource[:filesystem])
    #   if resource[:filesystem] == 'ext4'
    #     mkfsext4(blk)
    #   else
    #     fail 'Cannot create filesystem %s' % resource[:filesystem]
    #   end
    # end
    #
    # unless is_mounted(blk)
    #   if has_filesystem(blk, resource[:filesystem])
    #     FileUtils::mkdir_p resource[:mountpoint]
    #     mount(blk, resource[:mountpoint])
    #   else
    #     fail 'Cannot mount block has no %s filesystem' % resource[:filesystem]
    #   end
    # end
    puts'Create to be implemented'
  end

  def destroy
    # vi = get_volume_info
    # blk = blockdevice_name(vi['id'])
    # umount(blk, resource[:mountpoint])
    puts 'Destroy (unmount) of volume to be implemented'
  end



  def is_mounted
    list = lsblk('-l', '-n', '-o', 'UUID,MOUNTPOINT')
    list = list.split("\n")
    list.each do |l|
      if l.include? volume_id
        a = l.split(' ')
        puts a.length
      end
    end
  end

  def has_filesystem(blk, fs)
    l =  lsblk('-f', blk)
    return l.include? fs
  end

  def list_blocks
    list = Array.new
    ls = lsblk('-l', '-n', '-o', 'NAME')
    ls = ls.split("\n")
    ls.each do |l|
      unless l.include? "vda"
        list.push l
      end
    end
    return list
  end

  def find_uuid
    uuid = lsblk('-l','-n','-o','UUID')
    uuid = uuid.split("\n")
    found = Array.new
    uuid.each do |u|
      found.push(uuid) if uuid.include? volume_id
    end
    if found.empty?
      puts 'uuid not found'
      return false
    else
      puts 'uuid found'
      return true
    end
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

  def volume_id
    info = volume_info
    info['volumes'].each do |v|
      return v['id'] if v['display_name'].include? resource[:name]
    end
  end

  def volume_dev
    info = volume_info
    info['volumes'].each do |v|
      return v['attachments'][0]['device'] if v['display_name'].include? resource[:name]
    end
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

  # def get_volume_info
  #   volume_info = Hash.new
  #   vid = nova('--os-auth-url', "http://#{resource[:controller_ip]}:5000/v2.0",
  #              '--os-tenant-name', resource[:tenant],
  #              '--os-username', resource[:username],
  #              '--os-password', resource[:password],
  #              'volume-list')
  #   vid = vid.split("\n")
  #   vid.each do |v|
  #     if v.include? resource[:name]
  #       r = v.split('|')
  #       volume_info['id'] = r[1].strip
  #       volume_info['status'] = r[2].strip
  #       volume_info['name'] = r[3].strip
  #       volume_info['attached_to'] = r[6].strip
  #     end
  #   end
  #   return volume_info
  # end
  #
  # def get_instance_id
  #   instance_id = "not found"
  #   vid = nova('--os-auth-url', "http://#{resource[:controller_ip]}:5000/v2.0",
  #              '--os-tenant-name', resource[:tenant],
  #              '--os-username', resource[:username],
  #              '--os-password', resource[:password],
  #              'list')
  #   vid = vid.split("\n")
  #   vid.each do |v|
  #     if v.include? resource[:instance]
  #       r = v.split('|')
  #       instance_id = r[1].strip
  #     end
  #   end
  #   return instance_id
  # end

  # def blockdevice_name(volume_id)
  #   # idlink = "/dev/disk/by-id/virtio-#{volume_id[0..19]}"
  #   # return File.realpath(idlink)
  #   dev = String.new
  #   list = list_blocks
  #   puts list
  #   if list.length == 0
  #     fail 'cannot find blockdevices. Is %s really attached' % resource[:name]
  #   else
  #     list.each do |l|
  #       info = udevadm('info', '--query=property',"--name=#{l}")
  #       dev = "/dev/#{l}" if info.include? volume_id[0..19]
  #     end
  #   end
  #   dev
  # end

end
