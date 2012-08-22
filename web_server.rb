require 'sinatra'
require_relative 'github_stats'

get '/home' do
  scores = GitHubScorer.get_scores
  scores.map do |score|
    "#{score.user.login}: #{score.score} <br/>"
  end
end

