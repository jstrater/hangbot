**hangbot** is

1. a way for me to try out the HipChat v2 API & webhooks
2. a shared hangman-style game for HipChat rooms

## Setup

### From Rubygems

Requires Ruby >= 2.0.

1. `$ gem install hangbot`

### From GitHub

Requires Ruby >= 2.0 and Bundler.

1. `$ git clone git@github.com:jstrater/hangbot.git`
2. `$ cd hangbot`
3. `$ bundle install`

## Configuration

hangbot's configuration lives in a YAML file. You can use `example.hangbot.yaml` as a template for your config. Fill in the appropriate values for your environment, including your HipChat API key, room name, and externally visible server URL.

### Tips

   - You'll need a HipChat API token with `admin_room` and `send_notification` scopes for the selected room.
   - Pay attention to the `local_server.base_url` field -- this is the address that HipChat's webhooks will use to notify the local server about new messages, and if you're behind a firewall or router, you'll want to make sure that it's reachable from the outside world.

## How to play

Start the server by running `$ hangbot hangbot.yaml` (assuming that you put your configuration in `hangbot.yaml`.)

Once hangbot is running, type `/hangbot` in your HipChat room to start a new game. Use `/guess L` to guess a letter (where `L` is any letter of the alphabet.)

## TODO

- Automatic router traversal
- Put in friendlier error messages
