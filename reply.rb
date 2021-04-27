require_relative 'questions_database'
require_relative 'user'
require_relative 'question'
require_relative 'model_base'

class Reply < ModelBase
  attr_accessor :id, :subj_question_id, :parent_reply_id, :author_id, :body

  def self.find_by_user_id(user_id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        replies
      WHERE
        author_id = ?
    SQL
    return nil unless replies.length > 0

    replies.map { |reply| Reply.new(reply) }
  end

  def self.find_by_question_id(question_id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
        subj_question_id = ?
    SQL
    return nil unless replies.length > 0

    replies.map { |reply| Reply.new(reply) }
  end

  def initialize(options)
    @id = options['id']
    @subj_question_id = options['subj_question_id']
    @parent_reply_id =  options['parent_reply_id']
    @author_id = options['author_id']
    @body = options['body']
  end

  def attrs
    { subj_question_id: subj_question_id, parent_reply_id: parent_reply_id, author_id: author_id, body: body }
  end

  def author
    user = QuestionsDatabase.instance.execute(<<-SQL, self.author_id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL

    User.new(user.first)
  end

  def question
    q = QuestionsDatabase.instance.execute(<<-SQL, self.subj_question_id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
    SQL

    Question.new(q.first)
  end

  def parent_reply
    pr = QuestionsDatabase.instance.execute(<<-SQL, self.parent_reply_id)
      SELECT
        *
      FROM
        replies
      WHERE
        id = ?
    SQL
    return nil unless pr.length > 0

    Reply.new(pr.first)
  end

  def child_replies
    children = QuestionsDatabase.instance.execute(<<-SQL, self.id)
      SELECT
        *
      FROM
        replies
      WHERE
        parent_reply_id = ?
    SQL
    return nil unless children.length > 0

    children.map { |child| Reply.new(child) }
  end
end

# Previously implemented class methods below. No longer needed with Superclass implementations.

#   def self.all
#     data = QuestionsDatabase.instance.execute('SELECT * FROM replies')
#     data.map { |datum| Reply.new(datum) }
#   end

#   def self.find_by_id(id)
#     reply = QuestionsDatabase.instance.execute(<<-SQL, id)
#       SELECT
#         *
#       FROM
#         replies
#       WHERE
#         id = ?
#     SQL
#     return nil unless reply.length > 0

#     Reply.new(reply.first)
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
#     QuestionsDatabase.instance.execute(<<-SQL, self.subj_question_id, self.parent_reply_id, self.author_id, self.body)
#       INSERT INTO
#         replies (subj_question_id, parent_reply_id, author_id, body)
#       VALUES
#         (?, ?, ?, ?)
#     SQL
#     self.id = QuestionsDatabase.instance.last_insert_row_id
#   end

#   def update
#     raise "#{self} not in database" unless self.id
#     QuestionsDatabase.instance.execute(<<-SQL, self.subj_question_id, self.parent_reply_id, self.author_id, self.body, self.id)
#       UPDATE
#         replies
#       SET
#         subj_question_id = ?, 
#         parent_reply_id = ?,
#         author_id = ?,
#         body = ?
#       WHERE
#         id = ?
#     SQL
#   end