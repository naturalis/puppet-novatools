Puppet::Type.newtype(:nova_volume_create) do

  @doc = "Manage creation/deletion of cinder volumes."

  ensurable

  newparam(:name, :namevar => true) do
    desc "Name of the volume"
  end

  # newparam(:tenant) do
  #   desc "Name of tentant"
  # end
  #
  # newparam(:tenant_id) do
  #   desc "Tentant ID"
  # end
  #
  # newparam(:username) do
  #   desc "Openstack Username"
  # end
  #
  newparam(:password) do
    desc "Openstack Password"
  end
  #
  # newparam(:controller_url) do
  #   desc "URL/IP of the controller/API Endpoint"
  # end
  #
  # newparam(:api_port) do
  #   desc "Auth Portnummer of API (defautl 5000)"
  #
  #   defaultto "5000"
  # end
  #
  # newparam(:api_version) do
  #   desc "Auth API version (default to v2.0)"
  #
  #   defaultto "v2.0"
  # end
