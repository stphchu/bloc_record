module BlocRecord
  def self.connect_to(filename)
    @database_filename = filename
  end

  def self.database_filename
    @database_filename
  end
end
