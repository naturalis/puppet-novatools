Puppet::Type.type(:nova_volume).provide(:nova_volume) do
  require File.join(File.dirname(__FILE__).split('/')[0..-2],'lib','novaapi.rb')
  require 'uri'

  commands mount: 'mount'
  commands umount: 'umount'
  commands mkfsext4: 'mkfs.ext4'
  commands lsblk: 'lsblk'

  def exists?
    ep = URI(resource[:keystone_endpoint])
    @property_hash[:nova] = OpenStackAPI.new(ep.host,ep.port,ep.path,resource[:username],resource[:password],resource[:tenant])
    result = check_volume_exists
    result = is_volume_attached if resource[:attach_volume]
    #result = is_volume_formatted unless resource[:create_filesystem] == 'false'
    result
  end

  def create
    puts 'creating volume'
    if !check_volume_exists
      @property_hash[:nova].volume_create(resource[:name],resource[:volume_size_gb])
    elsif !is_voume_attached
      attach_volume
    end
  end

  def destroy
  end

  def check_volume_exists
    @property_hash[:volume_list] = @property_hash[:nova].volume_list.find { |v| v['display_name'] == resource[:name] }
    @property_hash[:volume_list].nil? ? false : true
  end

  def is_volume_attached
    @property_hash[:volume_list]['status']['in-use'].nil? ? 'false' : 'true'
  end

  def is_volume_formatted
    result = false
    list_devices.each do |d|
      result = true if d[:uuid] == @property_hash[:volume_list]['id']
    end
    result
  end

  def attach_volume
    puts 'puts attaching volume'
    status = volume_status
    case status
    when 'in-use'
      fail 'status is "in-use" . Function should not end up here'
    when 'attaching'
      fail "Volume #{resource[:name]} is currently attaching"
    when 'deleting','error','error_deleting'
      print "cannot attach, current state is #{status}"
    when 'available'
      #puts 'volume is avaiable going to attatch'
      @property_hash[:nova].volume_attach(@property_hash[:volume_list]['id'],Facter['uuid'].value.downcase)
      wait_for_attach(300)
    else
      fail "unknown status: #{status}"
    end
  end

  def create_filesystem
    result = nil
    list_devices.each do |dev|
      result = dev[:fs] if dev[:uuid] == @property_hash[:volume_list]['id']
    end
    result
  end

  def mount_volume
    return 'true'
  end

  def check_mount
  end

  def volume_status
    @property_hash[:volume_list] = @property_hash[:nova].volume_list.find { |v| v['display_name'] == resource[:name] }
    @property_hash[:volume_list]['status'].downcase
  end

  def wait_for_attach(timeout=300,sleep_time=5)
    sleep_time.step(timeout,sleep_time).each do |i|
       puts "Waiting for volume #{resource[:name]} to attach. Timeout is #{timeout}. Current wait time is #{i}"
       sleep sleep_time
       s =  @property_hash[:nova].volume_list.find { |v| v['display_name'] == resource[:name] }
       break if s['status'].downcase.include? 'in-use'
    end
  end

  def list_devices
    list = lsblk('-P','-n','-o','NAME,FSTYPE,MOUNTPOINT,UUID').split("\n")
    #until list.index{|s| s.include?(filter)}.nil?
    #  list.delete_at(list.index{|s| s.include?(filter)})
    #end
    devices = Array.new
    list.each do |l|
      dev = l.split[0].split("=")[1].split("\"")[1]
      serial = ''
      serial = File.read("/sys/class/block/#{dev}/serial") if File.exists?("/sys/class/block/#{dev}/serial")
      hash = {
        :dev    => dev,
        :fs     => l.split[1].split("=")[1].split("\"")[1],
        :mount  => l.split[2].split("=")[1].split("\"")[1],
        :uuid   => l.split[3].split("=")[1].split("\"")[1],
        :serial => serial
      }
      devices << hash
      puts hash
    end
    devices
  end



end
