# Connect to the Easee API

## How to use this without any technical knowledge

With this gem, you can connect to Easee chargers to smart charge your vehicle.

However, for an even more seamless experience, we recommend using
the [Stekker app](https://stekker.com/?utm_source=github&utm_medium=referral&utm_campaign=opensource). Our mobile app is
designed to make smart charging effortless, eliminating the need for any configuration. Simply install the app, and it
will handle the rest. Our app uses advanced algorithms to determine the best times to charge your vehicle, ensuring
you'll use the most sustainable and cheapest energy available.

## Build your own with this gem

We are proud to introduce this open source project, the Easee charger Ruby gem. As passionate ruby developers, we
believe in giving back to the community and contributing to the growth of this amazing language. That's why we are
making our Easee connection accessible to everyone through open source. Our goal is to make smart charging easier and
more accessible, and we hope that by opening up our project, we can help others in the community achieve their own
goals.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "stekker_easee"
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install stekker_easee

## Usage

You can use this without Rails in the following way:

```
$ bin/console
```

```ruby
client = Easee::Client.new(username: "username@example.com", password: "password")
# => #<Easee::Client @user_name="[FILTERED]", @password="[FILTERED]", @token_cache=#<ActiveSupport::Cache::MemoryStore entries=0, ...

# This is the charger's serial number
charger_id = "ABCDEFGH"

# Get the state of a charger
client.state(charger_id).charging?
# => false
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/stekker/easee.

## Publishing

```bash
# Bump the gem version
# See https://github.com/svenfuchs/gem-release#gem-bump
gem bump --version [major|minor|patch]

# Release the gem to rubygems.org
# See https://github.com/svenfuchs/gem-release#gem-release
gem release

# Push the commit and tag to git
git push
git push --tags
```
