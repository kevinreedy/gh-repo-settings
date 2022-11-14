# gh-repo-settings

It is a good practice to require code reviews using GitHub Pull Requests. This can be enforced on a repository-by-repository basis by setting up [Protected Branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/defining-the-mergeability-of-pull-requests/managing-a-branch-protection-rule). We can extend this practice even further by requiring Protected Branches on every Repository in an Organization.

This service uses [Webhooks](https://docs.github.com/en/rest/webhooks) to ensure all new repositories have their default branch protected, requiring pull requests to be reviewed by at least 1 person before being allowed to merge. Additionally if this protection is removed, the service will re-add the protection. In all cases, a GitHub Issue is opened, so changes can be easily tracked.

## How it works
GitHub Webhooks can be set up on a single repository or on an entire GitHub Organization. We will configure GitHub to reach out to this service whenever one these actions takes place on your Organization:

- Repository Created
- Default Branch Changed
- Branch Protection Deleted
- Branch Protection Edited
- Branch Created (only take action if it is the default branch)

When any of these actions are taken on any repository in the Organization, the service will use the GitHub API to ensure the default branch is protected, requiring review before any pull request can be merged.

## Installing
This service is a Ruby Application that can be run using Docker or directly on a system.

### Docker
 - Check out this repository locally and `cd` into the repository
 - Build the Docker image by running `docker build -t gh-repo-settings .` (if pushing this image to a repository, you may need to change the tag name)

### System
 - Check out this repository locally and `cd` into the repository
 - [Install Ruby](https://www.ruby-lang.org/en/documentation/installation/) 3.1.2
   - Using a Ruby version manager like [asdf](https://asdf-vm.com/) or [RVM](https://rvm.io/) is preferred
 - Run `bundle install` to install dependencies

## Configuring/Running
The service is configured using environment variables:
 - `GITHUB_ACCESS_TOKEN` - Visit [https://github.com/settings/tokens](https://github.com/settings/tokens), and generate a new token. Give it a name and expiration, select scope `repo`, and click `Generate token`.
 - `GITHUB_NOTIFY_USER` - GitHub username or group alias of who should be tagged in GitHub issues
 - `GITHUB_CALLBACK_SECRET` (optional, but highly recommended) - random string used to ensure callbacks are actually coming from GitHub

### Docker
Start the image by running `docker run -it --rm -p 4567:4567 --env GITHUB_ACCESS_TOKEN=[your github token] --env GITHUB_NOTIFY_USER=[your github user] --env GITHUB_CALLBACK_SECRET=[your random string] gh-repo-settings`

You can also run this service on any container orchestration platform, passing in these environment variables for configuration.

### System
 - Run `cp .env.example .env` to create a configuration file
 - Edit `.env` with the values described above
 - Run `bundle exec ruby server.rb -o 0.0.0.0` to start the service

### Testing locally
Note: if you are running this service locally, you will need to open up a firewall rule so that GitHub is able to access your web server. If you are testing this out in a development environment, you can use tools like [ngrok](https://ngrok.com/) to tunnel into your network without having to open any firewall rules.

## Setting up your GitHub Organization
 - Go to your organization's setting page at https://github.com/organizations/ORG_NAME/settings/profile
 - Click `Webhooks` on the left side menu
 - Click `Add webhook`
 - Enter the url that your service can be reached at, with `/callback` appended, for example `http://192.0.2.123:4567/callback`, `https://gh-repo-settings.example.com/callback`, or ` https://abcd-123-12-123-123.ngrok.io/callback`
 - Set Content type to `application/json`
 - Specifiy the secret you used to configure the service
 - Either select `Send me everything` or `Let me select individual events`:
   - Branch or tag creation
   - Branch protection rules
   - Repositories
 - Click `Add webhook`

## Presentation Slides
Additional information can be found in the [presentation for this project](https://docs.google.com/presentation/d/1AueXUuHos2ff3IdY1fT07smVJGrlsO4o5DKW2nKSCZM/edit?usp=sharing).
