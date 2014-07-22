**hangbot** is

1. a way for me to try out the HipChat v2 API & webhooks
2. a shared hangman-style game for HipChat rooms

TODO: screenshot

## Setup

Requires Ruby >= 2.0 and Bundler.

1. `git clone git@github.com:jstrater/hangbot.git`
2. `cd hangbot`
3. `bundle install`
4. `cp example.hangbot.yaml hangbot.yaml`
5. Configure `hangbot.yaml` for your HipChat environment.
   - You'll need a HipChat API token with `admin_room` and `send_notification` scopes for the selected room.
   - Pay attention to the `local_server.base_url` field -- this is the address that HipChat's webhooks will use to notify the local server about new messages, and if you're behind a firewall or router, you'll want to make sure that it's reachable from the outside world.
6. `bundle exec ruby bin/hangbot`

## How to play

Once hangbot is running, type `/hangbot` in your HipChat room to start a new game. Use `/guess L` to guess a letter (where `L` is any letter of the alphabet.)

## TODO

- Automatic router traversal
- Package as a gem
- Smooth out the install process
- Put in friendlier error messages
