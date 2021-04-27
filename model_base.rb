require 'active_support/inflector'
require_relative 'questions_database'

class ModelBase

  def self.table
    self.to_s.tableize
  end

  def self.all
    data = QuestionsDatabase.instance.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table}
    SQL
    data.map { |datum| self.new(datum) }
  end

  def self.find_by_id(id)
    data = QuestionsDatabase.instance.execute(<<-SQL, id: id)
      SELECT
        *
      FROM
        #{table}
      WHERE
        id = :id
    SQL

    data.nil? ? nil : self.new(data.first)
  end

  def save
    self.id ? update : create
  end

  private
  def create
    columns = self.attrs.keys.join(", ")
    values = self.attrs.values
    question_marks = (["?"] * values.length).join(", ")
    QuestionsDatabase.instance.execute(<<-SQL, *values)
      INSERT INTO
        #{self.class.table} (#{columns})
      VALUES
        (#{question_marks})
    SQL
    self.id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    set_line = self.attrs.keys.map { |attr| "#{attr} = ?" }.join(", ")
    values = self.attrs.values
    where_line = "id = #{self.id}"
    QuestionsDatabase.instance.execute(<<-SQL, *values)
      UPDATE
        #{self.class.table}
      SET
        #{set_line}
      WHERE
        #{where_line}
    SQL
  end
end