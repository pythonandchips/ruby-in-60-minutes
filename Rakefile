require 'rubygems'
require 'rake'
require_relative 'github_stats'

task :score_users do
  repo_reader = RepoReader.new('ruby_repo_events.json')
  events = repo_reader.load_events
  scorer = Scorer.new(events)
  scores = scorer.score

  scores.each do |score|
    puts "#{score.user.login}: #{score.score}"
  end
end
