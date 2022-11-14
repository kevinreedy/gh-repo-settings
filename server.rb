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
  payload_body = request.body.read
  payload = JSON.parse(payload_body, symbolize_names: true)

  # Ensure secret is correct
  verify_signature!(payload_body) if ENV['GITHUB_CALLBACK_SECRET']

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

# From https://docs.github.com/en/developers/webhooks-and-events/webhooks/securing-your-webhooks
def verify_signature!(payload_body)
  signature = 'sha256=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), ENV['GITHUB_CALLBACK_SECRET'],
                                                  payload_body)
  return halt 500, "Signatures didn't match!" unless Rack::Utils.secure_compare(signature,
                                                                                request.env['HTTP_X_HUB_SIGNATURE_256'])
end
