require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    class_name.constantize.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    unless options[:primary_key].nil?
      @primary_key = options[:primary_key].to_s.singularize.underscore.to_sym
    else
      @primary_key = :id
    end

    unless options[:foreign_key].nil?
      foreign_key = options[:foreign_key]
    else
      foreign_key = name.to_s.singularize.underscore + "_id"
    end
    @foreign_key = foreign_key.to_sym

    unless options[:class_name].nil?
      @class_name = options[:class_name].to_s.singularize.underscore.camelcase
    else
      @class_name = name.to_s.singularize.underscore.camelcase
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    unless options[:primary_key].nil?
      @primary_key = options[:primary_key].to_s.singularize.underscore.to_sym
    else
      @primary_key = :id
    end

    unless options[:foreign_key].nil?
      @foreign_key = options[:foreign_key]
    else
      @foreign_key = (self_class_name.to_s.singularize.underscore + "_id").to_sym
    end

    unless options[:class_name].nil?
      @class_name = options[:class_name].to_s.singularize.underscore.camelcase
    else
      @class_name = name.to_s.singularize.underscore.camelcase
    end
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options
    define_method(name.to_s) do
      fk_val = send(options.foreign_key)
      m_class = options.model_class
      table = options.table_name
      results = DBConnection.execute(<<-SQL, fk_val)
        SELECT
          *
        FROM
          #{table}
        WHERE
          #{options.primary_key} = ?
      SQL
      m_class.parse_all(results)[0]
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.name, options)
    define_method(name.to_s) do
      pk_val = send(options.primary_key)
      m_class = options.model_class
      table = options.table_name
      results = DBConnection.execute(<<-SQL, pk_val)
        SELECT
          *
        FROM
          #{table}
        WHERE
          #{options.foreign_key} = ?
      SQL
      m_class.parse_all(results)
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
