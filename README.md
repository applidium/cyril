# Cyril Slack bot

This is Cyril, a bot pairing Slack users connected to our general channel.

We use him to make pairs of people that will have lunch together on fridays.

## Installation

Execute:

	$ bundle install

## Usage

You will need 2 environment variables:

* WEBHOOK\_URL: The Slack [Incoming Webhook](https://api.slack.com/incoming-webhooks) url
* SLACK\_TOKEN: The Slack [Token](https://api.slack.com/web) of an user having access to
the general channel, in order to be able to get the list of currently connected users.

Example:

	$ WEBHOOK_URL=https://hooks.slack.com/services/XXXX/XXXXX SLACK_TOKEN=xoxp-XXXXXXX ruby cyril.rb

