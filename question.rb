require_relative 'questions_database'
require_relative 'user'
require_relative 'reply'
require_relative 'question_follow'
require_relative 'question_like'
require_relative 'model_base'

class Question < ModelBase
  attr_accessor :id, :title, :body, :author_id

  def self.find_by_author_id(author_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        author_id = ?
    SQL
    return nil unless questions.length > 0

    questions.map { |q| Question.new(q) }
  end

  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end

  def attrs
    { title: title, body: body, author_id: author_id }
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

  def replies
    Reply.find_by_question_id(self.id)
  end

  def followers
    QuestionFollow.followers_for_question_id(self.id)
  end

  def likers
    QuestionLike.likers_for_question_id(self.id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(self.id)
  end
end

# Previously implemented class methods below. No longer needed with Superclass implementations.

#   def self.all
#     data = QuestionsDatabase.instance.execute('SELECT * FROM questions')
#     data.map { |datum| Question.new(datum) }
#   end

#   def self.find_by_id(id)
#     question = QuestionsDatabase.instance.execute(<<-SQL, id)
#       SELECT
#         *
#       FROM
#         questions
#       WHERE
#         id = ?
#     SQL
#     return nil unless question.length > 0

#     Question.new(question.first)
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
#     QuestionsDatabase.instance.execute(<<-SQL, self.title, self.body, self.author_id)
#       INSERT INTO
#         questions (title, body, author_id)
#       VALUES
#         (?, ?, ?)
#     SQL
#     self.id = QuestionsDatabase.instance.last_insert_row_id
#   end

#   def update
#     raise "#{self} not in database" unless self.id
#     QuestionsDatabase.instance.execute(<<-SQL, self.title, self.body, self.author_id, self.id)
#       UPDATE
#         questions
#       SET
#         title = ?, body = ?, author_id =  ?
#       WHERE
#         id = ?
#     SQL
#   end