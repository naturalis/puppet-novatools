Puppet::Type.type(:nova_volume).provide(:nova_volume) do
  require File.join(File.dirname(__FILE__).split('/')[0..-2],'lib','novaapi.rb')
  require 'uri'


  def exists?
    ep = URI(resource[:keystone_endpoint])
    @property_hash[:nova] =  OpenStackAPI.new(ep.host,ep.port,ep.path,resource[:username],resource[:password],resource[:tenant])
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
    puts @property_hash[:volume_list] if @property_hash[:volume_list].nil? ? false : true
    @property_hash[:volume_list].nil? ? false : true
  end

  def attach_volume
    @property_hash[:volume_list]['status']['attached'].nil? ? false : true
  end

  def attach_volume=(value)
    puts 'puts attaching volume'
    puts Facter['hostname'].value
    #@property_hash[:list].list.find
    #@property_hash[:nova].volume_attach(@property_hash[:volume_list]['id'])
  end

  def create_filesystem
    return 'ext3'
  end

  def create_filesystem=(value)
  end

  def mount_volume
    true
  end

  def mount_volume=(value)
  end


  def check_mount
  end





end
