Puppet::Type.type(:nova_volume_mount).provide(:mount) do

  require 'fileutils'

  desc 'Manage Openstack with nova tools'

  commands nova: 'nova'
  commands mount: 'mount'
  commands umount: 'umount'
  commands mkfsext4: 'mkfs.ext4'
  commands blkid: 'blkid'
  commands lsblk: 'lsblk'
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
      mkfsext4(blk)
    end
    FileUtils::mkdir_p resource[:mountpoint]
    unless is_mounted(blk)
      mount(blk, resource[:mountpoint])
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
    idlink = "/dev/disk/by-id/virtio-#{volume_id[0..19]}"
    return File.realpath(idlink)
  end

  def has_filesystem(blk, fs)
    l =  lsblk('-f', blk)
    return l.include? fs
  end


end
