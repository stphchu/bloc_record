require 'sqlite3'

module Selection

# Checks for valid/Invalid inputs
   def input_check(input)
       return true if input > 0 && input.is_a?(Integer)
       return false
   end

   def find(*ids)
     ids.each do |id|
       return "ERROR: Invalid id" unless input_check(id)
     end

     if ids.length == 1
       find_one(ids.first)
     else
       rows = connection.execute <<-SQL
       SELECT #{columns.join ","} FROM #{table}
       WHERE id IN (#{ids.join(",")});
       SQL
       rows_to_array(rows)
     end
   end

  def find_one(id)
     return "ERROR: Invalid id" unless input_check(id)
     row = connection.get_first_row <<-SQL
       SELECT #{columns.join ","} FROM #{table}
       WHERE id = #{id};
     SQL

     init_object_from_row(row)
  end

  def find_by(attribute, value)
     rows = connection.execute <<-SQL
       SELECT #{columns.join ","} FROM #{table}
       WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
     SQL
     rows_to_array(rows)
  end

# method_missing
  def method_missing(method, *args)
    find_by(extract_attribute(method), args)
  end

  def extract_attribute(method)
    method.to_s.split('_', 3)[2]
  end

# find_each
 def find_each(start, size)
   if input_check(start) && input_check(size)
      rows = connection.execute
        <<-SQL
          SELECT #{columns.join ","}
          FROM #{table}
          LIMIT #{query[:batch_size]};
        SQL
      for row in rows_to_array(rows)
        yield(row)
      end
  else
    return "Invalid start/size input"
  end
end

  def take(num=1)
     if num > 1
       rows = connection.execute <<-SQL
         SELECT #{columns.join ","} FROM #{table}
         ORDER BY random()
         LIMIT #{num};
       SQL
       rows_to_array(rows)
     else
       take_one
     end
  end

  def take_one
     row = connection.get_first_row <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        ORDER BY random()
        LIMIT 1;
     SQL
     init_object_from_row(row)
  end

  def first
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id ASC LIMIT 1;
    SQL
    init_object_from_row(row)
  end

  def last
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id DESC LIMIT 1;
    SQL
    init_object_from_row(row)
  end

  def all
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table};
    SQL
    rows_to_array(rows)
  end

private
   def init_object_from_row(row)
     if row
       data = Hash[columns.zip(row)]
       new(data)
     end
   end

   def rows_to_array(rows)
     rows.map { |row| new(Hash[columns.zip(row)]) }
   end
end
