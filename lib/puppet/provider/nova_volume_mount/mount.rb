Puppet::Type.type(:nova_volume_mount).provide(:mount) do

  require 'fileutils'

  desc 'Manage Openstack with nova tools'

  commands nova: 'nova'
  commands mount: 'mount'
  commands umount: 'umount'
  commands mkfsext4: 'mkfs.ext4'
  commands lsblk: 'lsblk'
  commands udevadm: 'udevadm'
  optional_commands mkfsxfs: 'mkfs.xfs'

  def exists?
    vi = get_volume_info
    blk = blockdevice_name(vi['id'])
    if is_mounted(blk)
      true
    else
      false
    end
  end

  def create
    # first check if fs is there
    vi = get_volume_info
    blk = blockdevice_name(vi['id'])

    unless has_filesystem(blk, resource[:filesystem])
      if resource[:filesystem] == 'ext4'
        mkfsext4(blk)
      else
        raise 'Cannot create filesystem %s' % resource[:filesystem]
      end
    end

    unless is_mounted(blk)
      if has_filesystem(blk, resource[:filesystem])
        FileUtils::mkdir_p resource[:mountpoint]
        mount(blk, resource[:mountpoint])
      else
        raise 'Cannot mount block has no %s filesystem' % resource[:filesystem]
      end
    end
  end

  def destroy
    vi = get_volume_info
    blk = blockdevice_name(vi['id'])
    umount(blk, resource[:mountpoint])
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

  def is_mounted(blk)
    mnt = mount
    return mnt.include? blk
  end

  def blockdevice_name(volume_id)
    # idlink = "/dev/disk/by-id/virtio-#{volume_id[0..19]}"
    # return File.realpath(idlink)
    dev = "cannot find device"
    list = list_blocks
    if list.length == 0
      raise 'Cannot find blockdevices. Is %s really attached' % resource[:name]
    else
      list.each do |l|
        info = udevadm('info','--query=property',"--name=#{l}")
        if info.include? volume_id[0..19]
          dev = "/dev/#{l}"
        end
      end
    end
    return dev
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

end
