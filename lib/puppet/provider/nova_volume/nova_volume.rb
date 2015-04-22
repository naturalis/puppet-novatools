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
    result = is_volume_formatted unless resource[:create_filesystem] == 'false'
    result
  end

  def create
    if !check_volume_exists
      notice("Creating volume #{resource[:name]}")
      @property_hash[:nova].volume_create(resource[:name],resource[:volume_size_gb])
      wait_for_create
    end
    if !is_volume_attached and resource[:attach_volume]
      notice("Attaching volume #{resource[:name]}")
      attach_volume
    end
    if !is_volume_formatted and resource[:create_filesystem] != 'false'
      notice("Volume /dev/#{block_device[:dev]} needs to be formatted")
      create_filesystem
    end
  end

  def destroy
    notice("Deleting of volume is not implemented.")
  end

  def check_volume_exists
    @property_hash[:volume_list] = @property_hash[:nova].volume_list.find { |v| v['display_name'] == resource[:name] }
    @property_hash[:volume_list].nil? ? false : true
  end

  def is_volume_attached
    volume_status == 'in-use' ? true : false
  end

  def is_volume_formatted
    #puts 'check for format'
    #puts block_device[:fs] == '' ? false : true
    #puts     block_device
    block_device[:fs].nil? ? false : true
  end

  def attach_volume
    status = volume_status
    case status
    when 'in-use'
      fail 'status is "in-use" . Function should not end up here'
    when 'attaching'
      fail "Volume #{resource[:name]} is currently attaching"
    when 'deleting','error','error_deleting','non-exsistent'
      fail "cannot attach, current state is #{status}"
    when 'available'
      #puts 'volume is avaiable going to attatch'
      @property_hash[:nova].volume_attach(@property_hash[:volume_list]['id'],Facter['uuid'].value.downcase)
      wait_for_attach(300)
    else
      fail "unknown status: #{status}"
    end
  end

  def create_filesystem
    #puts 'trying to create fs'
    case resource[:create_filesystem]
    when 'ext4'
      mkfsext4("/dev/#{block_device[:dev]}",'-U',@property_hash[:volume_list]['id'])
      notice("#{resource[:create_filesystem]} created on /dev/#{block_device[:dev]}")
    else
      fail "unable to create #{resource[:create_filesystem]}"
    end
  end

  def mount_volume
    return 'true'
  end

  def check_mount
  end

  def volume_status
    @property_hash[:volume_list] = @property_hash[:nova].volume_list.find { |v| v['display_name'] == resource[:name] }
    begin
      @property_hash[:volume_list]['status'].downcase
    rescue
      'non-existent'
    end
  end

  def wait_for_attach(timeout=300,sleep_time=2)
    sleep_time.step(timeout,sleep_time).each do |i|
       notice("Waiting for volume #{resource[:name]} to attach. Timeout is #{timeout}. Current wait time is #{i}")
       sleep sleep_time
       s =  @property_hash[:nova].volume_list.find { |v| v['display_name'] == resource[:name] }
       break if s['status'].downcase.include? 'in-use'
    end
  end

  def wait_for_create(timeout=300,sleep_time=2)
    sleep_time.step(timeout,sleep_time).each do |i|
       notice("Waiting for volume #{resource[:name]} to be created. Timeout is #{timeout}. Current wait time is #{i}")
       sleep sleep_time
       s =  @property_hash[:nova].volume_list.find { |v| v['display_name'] == resource[:name] }
       break if s['status'].downcase.include? 'available'
    end
  end

  def block_device
    dev = Hash.new
    list_devices.each do |d|
      begin
        dev = d if d[:serial] == @property_hash[:volume_list]['id'][0..19]
      rescue
        dev = {
          :dev    => nil,
          :fs     => nil,
          :mount  => nil,
          :uuid   => nil,
          :serial => nil
        }
      end
    end
    #fail("Cannot find block device with serial: #{@property_hash[:volume_list]['id'][0..19]}")  if dev.empty?
    dev
  end

  def list_devices
    list = lsblk('-P','-n','-o','NAME,FSTYPE,MOUNTPOINT,UUID').split("\n")
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
    end
    devices
  end



end
