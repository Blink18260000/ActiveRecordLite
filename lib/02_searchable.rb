require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    keys = params.keys
    keys = keys.map! { |el| el.to_s + " = ?" }
    keys = keys.join(" AND ")
    vals = params.values
    results = DBConnection.execute(<<-SQL, *vals)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{keys}
    SQL
    parse_all(results)
  end
end

class SQLObject
  extend Searchable
end
