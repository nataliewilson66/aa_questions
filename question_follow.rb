require_relative 'questions_database'
require_relative 'user'
require_relative 'question'
require_relative 'model_base'

class QuestionFollow < ModelBase
  attr_accessor :id, :user_id, :question_id

  def self.followers_for_question_id(question_id)
    followers = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        users.*
      FROM
        users
      JOIN
        question_follows ON question_follows.user_id = users.id
      WHERE
        question_id = ?
    SQL
    return nil unless followers.length > 0

    followers.map { |f| User.new(f) }
  end

  def self.followed_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        questions.*
      FROM
        questions
      JOIN
        question_follows ON question_follows.question_id = questions.id
      WHERE
        user_id = ?
    SQL
    return nil unless questions.length > 0

    questions.map { |q| Question.new(q) }
  end

  def self.most_followed_questions(n)
    questions = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT DISTINCT
        questions.*,
        COUNT(user_id)
      FROM
        questions
      JOIN
        question_follows ON question_follows.question_id = questions.id
      GROUP BY
        questions.id
      ORDER BY
        COUNT(user_id) DESC
      LIMIT ?
    SQL
    return nil unless questions.length > 0

    questions.map { |q| Question.new(q) }
  end

  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end

  def attrs
    { user_id: user_id, question_id: question_id }
  end
end

# Previously implemented class methods below. No longer needed with Superclass implementations.

#   def self.all
#     data = QuestionsDatabase.instance.execute('SELECT * FROM question_follows')
#     data.map { |datum| QuestionFollow.new(datum) }
#   end

#   def self.find_by_id(id)
#     qf = QuestionsDatabase.instance.execute(<<-SQL, id)
#       SELECT
#         *
#       FROM
#         question_follows
#       WHERE
#         id = ?
#     SQL
#     return nil unless qf.length > 0

#     QuestionFollow.new(qf.first)
#   end

#   def save
#     if self.id
#       update
#     else
#       create
#     end
#   end

#   def create
#     raise "#{self} already in database" if self.id
#     QuestionsDatabase.instance.execute(<<-SQL, self.user_id, self.question_id)
#       INSERT INTO
#         question_follows (user_id, question_id)
#       VALUES
#         (?, ?)
#     SQL
#     self.id = QuestionsDatabase.instance.last_insert_row_id
#   end

#   def update
#     raise "#{self} not in database" unless self.id
#     QuestionsDatabase.instance.execute(<<-SQL, self.user_id, self.question_id, self.id)
#       UPDATE
#         question_follows
#       SET
#         user_id = ?, question_id = ?
#       WHERE
#         id = ?
#     SQL
#   end