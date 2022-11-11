# frozen_string_literal: true

require 'sinatra'
require 'dotenv/load'
require './lib/github'

get '/' do
  "Hello #{ENV['HELLO'] || 'world'}!"
end

post '/callback' do
  logger.info '/callback called'

  # Parse payload from Github callback
  payload = JSON.parse(request.body.read, symbolize_names: true)

  # TODO: ensure secret is correct

  repo = payload[:repository][:full_name]
  default_branch = payload[:repository][:default_branch]

  # Look for events we care about:
  #  - Repository Created
  #  - Default Branch Changed
  #  - Branch Protection Deleted
  #  - Branch Protection Edited
  #  - Branch Created (only trigger if default branch)

  if payload[:action] && payload[:action] == 'created' && payload[:repository]
    # Repository Created
    repo = payload[:repository][:full_name]
    logger.info "New Repository Created - #{repo}"
    gh_protect_branch(repo, default_branch)
  elsif payload[:changes] && payload[:changes][:default_branch]
    # Default Branch Changed
    logger.info "Default Branch on #{repo} changed to #{branch}"

    gh_protect_branch(repo, branch)
  elsif payload[:rule] && payload[:action] && payload[:action] == 'deleted'
    # Branch Protection Deleted
    logger.info "Branch Protection on #{repo} removed"
    gh_protect_branch(repo, default_branch)
  elsif payload[:rule] && payload[:action] && payload[:action] == 'edited'
    # Branch Protection Edited
    logger.info "Branch Protection on #{repo} edited"
    gh_protect_branch(repo, default_branch)
  elsif payload[:ref] && payload[:ref_type] && payload[:ref_type] == 'branch'
    # Branch Created or Edited
    branch = payload[:ref]
    logger.info "Branch #{branch} Created"
    gh_protect_branch(repo, branch) if branch == default_branch
  else
    logger.warn 'Action for callback not found'
  end
end
