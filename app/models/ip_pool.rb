require 'ipaddr'

class IpPool < ActiveRecord::Base

  validates_presence_of :first_ip, :last_ip
  validates_ip_address_of :first_ip, :last_ip

  attr_accessible :first_ip, :last_ip, :hardware_server_id
  belongs_to :hardware_server

  def total_ips
    from_ip = IPAddr.new(first_ip)
    to_ip = IPAddr.new(last_ip)
    to_ip.to_i - from_ip.to_i + 1
  end

  def used_ips
    list_used = VirtualServer.ip_addresses.map{ |ip| ip[:name] }
    from_ip = IPAddr.new(first_ip)
    to_ip = IPAddr.new(last_ip)
    socket_family = from_ip.ipv6? ? Socket::AF_INET6 : Socket::AF_INET
    count = 0
    (from_ip.to_i..to_ip.to_i).each do |ip_int|
      ip_addr = IPAddr.new(ip_int, socket_family)
      count +=1 if list_used.include?(ip_addr.to_s)
    end
    count
  end

  def free_ips
    total_ips - used_ips
  end

  def free_list
    list_used = VirtualServer.ip_addresses.map{ |ip| ip[:name] }
    from_ip = IPAddr.new(first_ip)
    to_ip = IPAddr.new(last_ip)
    socket_family = from_ip.ipv6? ? Socket::AF_INET6 : Socket::AF_INET
    list_free = []
    (from_ip.to_i..to_ip.to_i).each do |ip_int|
      ip_addr = IPAddr.new(ip_int, socket_family)
      list_free << ip_addr.to_s unless list_used.include?(ip_addr.to_s)
    end
    list_free
  end

  def validate
    msg = I18n.t('activerecord.errors.models.ip_pool.attributes.first_ip.bad_range')
    begin
      errors.add(:first_ip, msg) if IPAddr.new(first_ip).to_i > IPAddr.new(last_ip).to_i
    rescue
      errors.add(:first_ip, msg)
    end
  end

end
