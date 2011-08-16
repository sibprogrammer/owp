require 'ipaddr'

module ActiveRecord
  module Validations
    module ClassMethods

      def validates_ip_address_of(*attr_names)
        configuration = { :on => :save, :message => 'Incorrect IP address.' }
        configuration.update(attr_names.extract_options!)

        validates_each(attr_names, configuration) do |record, attr_name, value|
          begin
            IPAddr.new(value.to_s)
          rescue
            record.errors.add(attr_name, :invalid, :default => configuration[:message], :value => value)
          end
        end
      end

    end
  end
end
