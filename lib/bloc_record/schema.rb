require 'sqlite3'
require_relative 'utility'

module Schema

#TABLE
  def table
    BlocRecord::Utility.underscore(name)
  end

#SCHEMA
  def schema
    unless @schema
      @schema = {}
      connection.table_info(table) do |col|
        @schema[col["name"]] = col["type"]
      end
    end
    @schema
  end

#COLUMNS
  def columns
    schema.keys
  end

#ATTRIBUTES
  def attributes
    columns - ["id"]
  end

#COUNT
  def count
    connection.execute(<<-SQL)[0][0]
      SELECT COUNT(*) FROM #{table}
    SQL
  end

end
