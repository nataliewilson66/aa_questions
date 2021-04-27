require_relative 'questions_database'
require_relative 'question'
require_relative 'reply'
require_relative 'question_follow'
require_relative 'question_like'

class User
  attr_accessor :id, :fname, :lname

  def self.all
    data = QuestionsDatabase.instance.execute('SELECT * FROM users')
    data.map { |datum| User.new(datum) }
  end

  def self.find_by_id(id)
    user = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL
    return nil unless user.length > 0

    User.new(user.first)
  end

  def self.find_by_name(fname, lname)
    user = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
        fname = ? AND lname = ?
    SQL
    return nil unless user.length > 0

    User.new(user.first)
  end

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def save
    if self.id
      update
    else
      create
    end
  end

  def authored_questions
    raise "#{self} not in database" unless self.id
    Question.find_by_author_id(self.id)
  end

  def authored_replies
    raise "#{self} not in database" unless self.id
    Reply.find_by_user_id(self.id)
  end

  def followed_questions
    raise "#{self} not in database" unless self.id
    QuestionFollow.followed_questions_for_user_id(self.id)
  end

  def liked_questions
    raise "#{self} not in database" unless self.id
    QuestionLike.liked_questions_for_user_id(self.id)
  end

  def average_karma
    avg_vals = QuestionsDatabase.instance.execute(<<-SQL, self.id)
      SELECT
        COUNT(DISTINCT(questions.id)) AS "num questions",
        CAST(COUNT(question_likes.user_id) AS FLOAT) AS "num likes"
      FROM
        questions
      LEFT OUTER JOIN
        question_likes ON question_likes.question_id = questions.id
      WHERE
        questions.author_id = ?

    SQL

    avg_vals.first['num likes'] / avg_vals.first['num questions']
  end

  private
  def create
    raise "#{self} already in database" if self.id
    QuestionsDatabase.instance.execute(<<-SQL, self.fname, self.lname)
      INSERT INTO
        users (fname, lname)
      VALUES
        (?, ?)
    SQL
    self.id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    raise "#{self} not in database" unless self.id
    QuestionsDatabase.instance.execute(<<-SQL, self.fname, self.lname, self.id)
      UPDATE
        users
      SET
        fname = ?, lname = ?
      WHERE
        id = ?
    SQL
  end
end