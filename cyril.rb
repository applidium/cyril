require 'json'
require 'rest-client'

class User
  attr_reader :id, :name
  def initialize(id, name)
    @id, @name = [id, name]
  end

  # slack id formatting, allows highlighting users
  def to_slack
    "<@#{@id}>"
  end

  def to_s
    "#{@id} #{@name}"
  end

  def self.from_slack
    uri = URI('https://slack.com/api/rtm.start')
    uri.query = URI.encode_www_form({ :token => ENV["SLACK_TOKEN"] })

    slack_data = JSON.parse(Net::HTTP.get_response(uri).body)
    general_channel = get_general_channel(slack_data)

    return [] if general_channel.nil?

    # hash -> lookup in O(1)
    general_members = Hash[ (general_channel["members"] || []).map { |m| [m, true] } ]

    slack_members = slack_data["users"] || []

    # select users currently connected on #general channel
    slack_members.select! { |m| !m["deleted"] && m["presence"] == "active" }
    slack_members.select! { |m| !general_members[m["id"]].nil? }

    slack_members.map { |m| User.new(m["id"], m["name"]) }
  end
end

class Pair
  def initialize(users)
    @users = users
  end

  def to_s
    return "#{@users[0].to_slack} tout seul :-(" if @users.length < 2  # happens when there is only one user on #general
    "#{@users[0..-2].map(&:to_slack).join(", ")} et #{@users[-1].to_slack}"
  end
end

# search #general channel across all channels
def get_general_channel(slack_data)
  return if slack_data["channels"].nil?

  slack_data["channels"].each do |channel|
    return channel if channel["is_general"]
  end

  return nil
end

# make random pairs (and a group of three if the amount of users is odd)
def make_random_pairs(users)
  pairs = users.shuffle.each_slice(2).to_a

  # add lonely user to the soon-to-be last pair
  pairs[-2] << pairs.pop[0] if pairs.length > 1 && users.length.odd?

  pairs.map { |u| Pair.new(u) }
end

# output pairs with a custom header message
def build_text(pairs)
  message = "Et voici votre partenaire gourmand et croquant pour le déjeuner"
  "#{message}\n#{pairs.map(&:to_s).join("\n")}"
end

# post pairs to Slack via incoming webhook url
def post_pairs(pairs)
  payload = {
    "text" => build_text(pairs)
  }.to_json

  RestClient.post(ENV["WEBHOOK_URL"], payload, :content_type => 'application/json')
end

if __FILE__ == $0
  pairs = make_random_pairs(User.from_slack)
  post_pairs(pairs)
end
