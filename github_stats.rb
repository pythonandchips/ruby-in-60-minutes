require 'rubygems'
require 'json'
require 'pry'

class Event
  attr_reader :user, :type
  def initialize(json)
    @created_at = json["created_at"]
    @type = json["type"]
    @user = User.find_or_create(json["actor"])
  end
end

class User
  attr_reader :login
  def initialize(json)
    @login = json["login"]
  end

  def self.find_or_create(json)
    @users ||= []
    user = @users.detect{|user| user.login == json["login"]}
    if user.nil?
      user = User.new(json)
      @users << user
    end
    user
  end
end

class RepoReader
  def initialize(file_name)
    @file_name = file_name
  end

  def load_events
    f = File.read(@file_name)
    @doc = JSON::parse(f)
    @doc.map{|event| Event.new(event)}
  end
end

class Scorer
  def initialize(events)
    @events = events
  end

  SCORECARD = {"PushEvent" => 20,
               "WatchEvent" => 1,
               "ForkEvent" => 2,
               "IssueCommentEvent" => 5,
               "PullRequestEvent" => 10,
               "CommitCommentEvent" => 5}

  def score
    user_events = @events.group_by{|event| event.user }
    scores = user_events.map do |user_event|
      user = user_event[0]
      score = 0
      user_event[1].each do |event|
        score = score + SCORECARD[event.type]
      end
      Score.new(user, score)
    end
  end
end

class Score
  attr_reader :user, :score
  def initialize(user, score)
    @user = user
    @score = score
  end
end
