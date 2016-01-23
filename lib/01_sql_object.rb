require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    if @columns
      return @columns
    else
      db = DBConnection.execute2(<<-SQL)
        SELECT
          *
        FROM
          #{table_name}
        LIMIT
          1
      SQL
      @columns = db[0].map { |el| el.to_sym }
      return @columns
    end
  end

  def self.finalize!
    self.columns.each do |col|
      define_method(col) do
        attributes["#{col}".to_sym]
      end

      define_method("#{col}=") do |val|
        attributes["#{col}".to_sym] = val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
    SQL
    parse_all(results)
  end

  def self.parse_all(results)
    wrapped_results = []
    results.each do |row_hash|
      row_wrapper = new()
      row_hash.each do |key, val|
        row_wrapper.send("#{key}=", val)
      end
      wrapped_results << row_wrapper
    end
    wrapped_results
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      WHERE
        #{table_name}.id = #{id}
    SQL
    if results.empty?
      return nil
    else
      return parse_all(results)[0]
    end
  end

  def initialize(params = {})
    params.each do |param, attr_value|
      attr_name_sym = param.to_sym
      unless self.class.columns.include?(param)
        raise "unknown attribute '#{param}'"
      end
      send("#{param}=", attr_value)
    end
  end

  def attributes
    @attributes ||= {}
    return @attributes
  end

  def attribute_values
    @attributes.values
  end

  def insert
    cols = self.class.columns
    #cols.map! {|x| x.to_sym}
    col_names = cols[1..-1].join(", ")
    question_marks = "?, " * (cols.length - 2) + "?"
    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL
    send("id=", DBConnection.last_insert_row_id)
  end

  def update
    cols = self.class.columns
    #cols.map! {|x| x.to_sym}
    col_names = cols[1..-1].map { |el| el.to_s + " = ?"}
    col_names = col_names.join(", ")
    question_marks = "?, " * (cols.length - 2) + "?"
    DBConnection.execute(<<-SQL, *attribute_values[1..-1], attribute_values[0])
      UPDATE
        #{self.class.table_name}
      SET
        #{col_names}
      WHERE
        id = ?
    SQL
  end

  def save
    id = send("id")
    if id
      update
    else
      insert
    end
  end
end
