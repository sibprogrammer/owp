module Marshal

  def self.safe_dump(params)
    is_sqlite = 'SQLite3::Database' == ActiveRecord::Base.connection.instance_variable_get(:@connection).class.to_s
    is_sqlite ? Marshal.dump(params) : ActiveSupport::Base64.encode64(Marshal.dump(params)).chop
  end

  def self.safe_load(string)
    is_sqlite = 'SQLite3::Database' == ActiveRecord::Base.connection.instance_variable_get(:@connection).class.to_s
    is_sqlite ? Marshal.load(string) : Marshal.load(ActiveSupport::Base64.decode64(string))
  end

end
