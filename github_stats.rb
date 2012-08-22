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

  def initialize(json)
    deserialize(json)
  end
end

class Event
  include ObjectSerializer
  attr_reader :actor, :type
end

class Actor
  include ObjectSerializer
  attr_reader :login
end

class JsonReader
  def initialize(file_name)
    @file_name = file_name
  end

  def load(klass)
    f = File.read(@file_name)
    @doc = JSON::parse(f)
    @doc.map{|event| klass.new(event)}
  end
end

class Score
  attr_reader :actor, :score
  SCORECARD = {"PushEvent" => 20,
               "WatchEvent" => 1,
               "ForkEvent" => 2,
               "IssueCommentEvent" => 5,
               "PullRequestEvent" => 10,
               "CommitCommentEvent" => 5}

  def initialize(actor, events)
    @actor = actor
    @events = events
  end

  def self.generate_scores(events)
    user_events = events.group_by{|event| event.actor.login }
    scores = user_events.map do |user_event|
      actor = user_event[0]
      Score.new(actor, user_event[1])
    end
  end

  def score
    @events.inject(0) do |result, event|
      result + SCORECARD[event.type]
    end
  end
end

class GitHubScorer
  def self.get_scores
    json_reader = JsonReader.new('ruby_repo_events.json')
    events = json_reader.load(Event)
    Score.generate_scores(events)
  end
end
