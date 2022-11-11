# frozen_string_literal: true

require 'octokit'

@client = nil

def gh_client
  # Attempt to re-use connection when possible
  @client ||= Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
end

def gh_default_branch(repo)
  gh_client.repository(repo)[:default_branch]
end

def gh_protect_branch(repo, branch)
  # Take no action if default branch doesn't exist
  # This happens on new repositories with no commits
  unless gh_branch_exists?(repo, branch)
    logger.warn "Branch #{branch} on repo #{repo} does not exist"
    return
  end

  # Take no action if branch already protected. This prevents potential inifinite loops
  return if gh_branch_protected?(repo, branch)

  # Additional options can be found at
  # https://docs.github.com/en/rest/branches/branch-protection
  # If changing, be sure to update `gh_branch_protected?` as well
  gh_client.protect_branch(repo, branch,
                           required_pull_request_reviews: {
                             required_approving_review_count: 1 # Require 1 approval before merging
                           },
                           enforce_admins: true) # Require these reules for repo admins as well

  gh_create_issue(repo, branch)
end

def gh_branch_protected?(repo, branch)
  br_protection = gh_client.branch_protection(repo, branch)
  return false unless br_protection
  return false unless br_protection[:required_pull_request_reviews]
  return false unless br_protection[:required_pull_request_reviews][:required_approving_review_count]
  return false unless br_protection[:required_pull_request_reviews][:required_approving_review_count] >= 1

  true
end

def gh_branch_exists?(repo, branch)
  begin
    gh_client.branch(repo, branch)
  rescue Octokit::NotFound
    return false
  end

  true
end

def gh_notify_user
  # Default to kevinreedy if not configured
  ENV['GITHUB_NOTIFY_USER'] || 'kevinreedy'
end

def gh_default_issue_body(repo, branch = nil)
  'Branch Protection has automatically been added to the default branch of this repository' +
    (branch ? ", #{branch}" : '') +
    '. ' \
    "Details can be found at https://github.com/#{repo}/settings/branches. " \
    "For more details, contact @#{gh_notify_user}."
end

def gh_create_issue(repo, branch = nil, body = gh_default_issue_body(repo, branch))
  gh_client.create_issue(repo, 'Branch Protection Enabled', body)
end
