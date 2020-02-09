require 'sqlite3'

module Selection

# Checks for valid/invalid inputs
  def input_check(input)
    return true if input > 0 && input.is_a?(Integer)
    return false
  end

# find
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

# find_one
  def find_one(id)
    return "ERROR: Invalid id" unless input_check(id)
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE id = #{id};
      SQL
    init_object_from_row(row)
  end

# find_by
  def find_by(attribute, value)
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
      SQL
    rows_to_array(rows)
  end

## method_missing
  def method_missing(method, *args)
    find_by(extract_attribute(method), *args)
  end

  def extract_attribute(method)
    method_name = method.to_s.split('_', 3)[2]
  end
##

# find_each
  def find_each(start, batch_size)
    if input_check(start) && input_check(batch_size)
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","}
        FROM #{table}
        LIMIT #{batch_size};
        SQL
      for row in rows_to_array(rows)
        yield(row)
      end
    else
      return "Invalid start/size input"
    end
  end

# find_in_batches
  def find_in_batches(start, batch_size)
    if input_check(start) && input_check(batch_size)
      rows = execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        LIMIT #{batch_size};
        SQL
        batch = rows_to_array(rows)
        yield(batch)
    else
      return "Invalid start/size input"
    end
  end

# take
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

# take_one
  def take_one
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY random()
      LIMIT 1;
      SQL
    init_object_from_row(row)
  end

# first
  def first
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id ASC LIMIT 1;
      SQL
    init_object_from_row(row)
  end

# last
  def last
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id DESC LIMIT 1;
      SQL
    init_object_from_row(row)
  end

# all
  def all
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table};
      SQL
    rows_to_array(rows)
  end

# where
  def where(*args)
    if args.count > 1
      expression = args.shift
      params = args
    else
      case args.first
      when String
        expression = args.first
      when Hash
        expression_hash = BlocRecord::Utility.convert_keys(args.first)
        expression = expression_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
      end
    end

    sql = <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{expression};
      SQL

    rows = connection.execute(sql, params)
    rows_to_array(rows)
  end

# order
  def order(*args)
    case args.first
      when String
        if args.count > 1
          order = args.join(",")
        end
      when Symbol
        order = args.first.to_s
      when Hash
        hash = BlocRecord::Utility.convert_keys(args.first)
        order = hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
    end

    rows = connection.execute <<-SQL
      SELECT * FROM #{table}
      ORDER BY #{order};
      SQL
    rows_to_array(rows)
  end

# join
  def join(*args)
    if args.count > 1
      joins = args.map { |arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"}.join(" ")
      rows = connection.execute <<-SQL
        SELECT * FROM #{table} #{joins}
        SQL
    else
      case args.first
        when String
          rows = connection.execute <<-SQL
            SELECT * FROM #{table} #{BlocRecord::Utility.sql_strings(args.first)};
            SQL
        when Symbol
          rows = connection.execute <<-SQL
            SELECT * FROM #{table}
            INNER JOIN #{args.first} ON #{args.first}.#{table}_id = #{table}.id
            SQL
        when Hash
          key = args.first.keys.first
          value = args.first(key)
          rows = connection.execute <<-SQL
            SELECT * FROM #{table}
            INNER JOIN #{key} ON #{key}.#{table}_id = #{table}.id
            INNER JOIN #{value} ON #{value}.#{key}_id = #{key}.id
            SQL
        end
      end
      rows_to_array(rows)
    end

# PRIVATE
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
