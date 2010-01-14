class AddSearchDomainToVirtualServer < ActiveRecord::Migration
  def self.up
    add_column :virtual_servers, :search_domain, :string
  end

  def self.down
    remove_column :virtual_servers, :search_domain
  end
end
