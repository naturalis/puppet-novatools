Puppet::Type.type(:nova_volume).provide(:nova_volume) do
  require File.join(File.dirname(__FILE__).split('/')[0..-2],'lib','novaapi.rb')
  require 'uri'


  def exists?
    ep = URI(resource[:keystone_endpoint])
    @property_hash[:nova] = OpenStackAPI.new(ep.host,ep.port,ep.path,resource[:username],resource[:password],resource[:tenant])
    check_exists
  end

  def create
    puts 'creating volume'
    @property_hash[:nova].volume_create(resource[:name],resource[:volume_size_gb])
  end

  def destroy
  end

  def check_all
  end

  def check_exists
    @property_hash[:volume_list] = @property_hash[:nova].volume_list.find { |v| v['display_name'] == resource[:name] }
    #puts @property_hash[:volume_list] if @property_hash[:volume_list].nil? ? false : true
    @property_hash[:volume_list].nil? ? false : true
  end

  def attach_volume
    @property_hash[:volume_list]['status']['in-use'].nil? ? 'false' : 'true'
  end

  def attach_volume=(value)
    puts 'puts attaching volume'
    status = volume_status
    case status
    when 'in-use'
      print 'dont do anything'
    when 'attaching'
      print 'volume is attaching'
    when 'deleting','error','error_deleting'
      print "cannot attach, current state is #{status}"
    when 'available'
      puts 'volume is avaiable going to attatch'
      @property_hash[:nova].volume_attach(@property_hash[:volume_list]['id'],Facter['uuid'].value.downcase)
      wait_for_attach(300)
    else
      fail "unknown status: #{status}"
    end
    #@property_hash[:nova].volume_attach(@property_hash[:volume_list]['id'],Facter['uuid'].value.downcase)
  end

  def create_filesystem
    return 'ext4'
  end

  def create_filesystem=(value)
  end

  def mount_volume
    return 'true'
  end

  def mount_volume=(value)
  end


  def check_mount
  end

  def volume_status
    @property_hash[:volume_list] = @property_hash[:nova].volume_list.find { |v| v['display_name'] == resource[:name] }
    @property_hash[:volume_list]['status'].downcase
  end

  def wait_for_attach(timeout=300)
    #status = volume_status.downcase
    #totaltime = 0

    # while status.include? 'attaching' and totaltime < timeout
    #   totaltime += 2
    #   puts "waiting for volume to be attached. Timeout is #{timeout}. Current time is #{totaltime}"
    #   status = volume_status.downcase
    #   sleep 2
    # end
   (0..timeout).each do |i|
      break if volume_status_downcase.include? 'in-use'
      sleep 1
      puts "Waiting for volume #{resource[:name]} to attach. Timeout is #{timeout}. Current wait time is #{i}"
    end
  end




end
