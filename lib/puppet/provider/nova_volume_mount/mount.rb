Puppet::Type.type(:nova_volume_mount).provide(:mount) do

  desc 'Manage Openstack with nova tools'

  commands nova: 'nova'
  commands mount: 'mount'
  commands umount: 'umount'
  commands mkfsext4: 'mkfs.ext4'
  commands blkid: 'blkid'
  optional_commands mkfsxfs: 'mkfs.xfs'

  def exists?
    vi = get_volume_info
    blk = blockdevice_name(vi['id'])
    p blk
    if is_mounted(blk)
      p 'mounted'
      true
    else
      p 'not mounted'
      false
    end
  end

  def create
    p 'create to be implemented'
  end

  def destroy
    p 'destroy to be implemented'
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
    return File.readlink(idlink)
  end

  def has_filesystem(blk, fs)
    return blkid(blk).include? fs
  end


end
