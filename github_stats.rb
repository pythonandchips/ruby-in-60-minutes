require 'rubygems'
require 'json'
require 'pry'
require 'active_support/inflector'

module ObjectSerializer
  def deserialize(json)
    json.each do |key, value|
      if self.respond_to?(key)
        if value.kind_of?(Hash)
          klass_name = key.to_s.classify.to_sym
          if Object.const_defined?(klass_name)
            klass = Object.const_get(klass_name)
            self.instance_variable_set("@#{key}", klass.new(value))
          end
        else
          self.instance_variable_set("@#{key}", value)
        end
      end
    end
  end
end

class Event
  include ObjectSerializer
  attr_reader :actor, :type

  def initialize(json)
    deserialize(json)
  end
end

class Actor
  include ObjectSerializer
  attr_reader :login
  def initialize(json)
    deserialize(json)
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
    user_events = @events.group_by{|event| event.actor.login }
    scores = user_events.map do |user_event|
      actor = user_event[0]
      score = 0
      user_event[1].each do |event|
        score = score + SCORECARD[event.type]
      end
      Score.new(actor, score)
    end
  end
end

class Score
  attr_reader :actor, :score
  def initialize(actor, score)
    @actor = actor
    @score = score
  end
end

class GitHubScorer
  def self.get_scores
    repo_reader = RepoReader.new('ruby_repo_events.json')
    events = repo_reader.load_events
    scorer = Scorer.new(events)
    scorer.score
  end
end
