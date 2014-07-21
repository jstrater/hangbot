require 'webrick'
require 'json'
require 'hipchat_party'
require 'uri'
require 'pp'
require 'configliere'


# TODO: define setting types
Settings.read './hangbot.yaml'
Settings.resolve!

WEBHOOK_PATH = '/'
WEBHOOK_URI = URI.join Settings['local_server']['base_url'], WEBHOOK_PATH
WEBHOOK_NAME = 'hangbot'
ROOM_NAME = Settings['hipchat']['room_name']
LOCAL_PORT = Settings['local_server']['port']
LOCAL_ADDRESS = Settings['local_server']['bind_address']
API_TOKEN = Settings['hipchat']['api_token']
TIMEOUT = Settings['hipchat']['timeout']

hipchat = HipChatParty.new API_TOKEN, timeout:TIMEOUT

# Clear out any old webhooks
hipchat.delete_webhooks_by_name ROOM_NAME, WEBHOOK_NAME
hook_id = hipchat.create_webhook ROOM_NAME, WEBHOOK_NAME, 'room_message', WEBHOOK_URI, pattern:'^\/(hangman|guess).*'

# For better security, you could get a cert and use it to run WEBrick in HTTPS mode.
server = WEBrick::HTTPServer.new Port:LOCAL_PORT, BindAddress:LOCAL_ADDRESS
server.mount_proc '/' do |req, res|
   pp JSON.parse(req.body)
end

# Shut down cleanly on ctrl-c
trap 'INT' do
   # Reset the signal handler so that two SIGINTs shut things down immediately
   trap 'INT', 'DEFAULT'

   server.shutdown

   # Get rid of the HipChat webhooks
   hipchat.delete_webhooks_by_name ROOM_NAME, WEBHOOK_NAME
end

server.start
