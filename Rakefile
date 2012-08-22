require 'rubygems'
require 'rake'
require_relative 'github_stats'

task :score_users do
  scores = GitHubScorer.get_scores
  scores.each do |score|
    puts "#{score.user.login}: #{score.score}"
  end
end
