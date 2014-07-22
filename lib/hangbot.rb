require 'webrick'
require 'json'
require 'hipchat_party'
require 'uri'
require 'pp'
require 'configliere'
require 'logger'


# Set up a webhook and make sure any old leftover hooks are cleaned out
def init_hipchat_webhook hipchat, room_name, webhook_name, url
   remove_hipchat_webhooks hipchat, room_name, webhook_name

   return hipchat.create_webhook(
      room_name,
      webhook_name,
      'room_message',
      url,
      pattern:'^\/(hangman|guess).*'
   )
end

# Clean out all HipChat webhooks with webhook_name.
def remove_hipchat_webhooks hipchat, room_name, webhook_name
   hipchat.delete_webhooks_by_name room_name, webhook_name
end

# Create a web server that listens on the given address & port for HipChat message notifications. The webhook ID on the notifications will be checked against +webhook_id+.
#
# Message contents will be passed to the block, and the block's return value will be posted as a new HipChat room notification.
def respond_to_hipchat_messages port:4567, address:'0.0.0.0', room_name:nil, webhook_url:nil, api_token:nil, timeout:30, logger:nil
   webhook_name = 'hangbot'

   # Tell HipChat to let us know when there's a new message in the room
   hipchat = HipChatParty.new api_token, timeout:timeout
   logger.info "Setting up a new HipChat webhook and clearing out old ones"
   webhook_id = init_hipchat_webhook hipchat, room_name, webhook_name, webhook_url

   # Create a WEBrick server to listen for HipChat notifications.
   #
   # For better security, you could get a cert and use it to run WEBrick in HTTPS mode.
   server = WEBrick::HTTPServer.new Port:port, BindAddress:address
   server.mount_proc '/' do |req, res|
      body = JSON.parse(req.body)

      # Check to see if this is the hook that we're expecting
      unless body['event'] == 'room_message' && body['webhook_id'] == webhook_id
         logger.warn "Unexpected webhook callback from #{req.remote_ip}"
         logger.debug "#{body.inspect}"
         next
      end

      # Let the block come up with a response to the message
      sender = body['item']['message']['from']['mention_name']
      message = body['item']['message']['message']
      logger.info "message: #{sender}: #{message}"
      response_message = yield message

      # Send the block's response back to the room
      logger.info "response: #{response_message}"
      hipchat.send_room_notification room_name, response_message
   end

   # Shut down cleanly on ctrl-c
   trap 'INT' do
      # Reset the signal handler so that two SIGINTs shut things down immediately
      trap 'INT', 'DEFAULT'

      server.shutdown
   end

   # Start the server here. Any code after server.start will be executed after the server shuts down.
   logger.info "Starting web server at #{address}:#{port} (CTRL-C to stop)"
   server.start

   # Clean up the hooks, otherwise HipChat will keep trying to call us.
   logger.info "Cleaning up webhooks"
   remove_hipchat_webhooks hipchat, room_name, webhook_name
end

def main
   # Set up a logger with the same output format as WEBrick
   logger = Logger.new STDERR
   logger.formatter = proc do |severity, datetime, progname, msg|
     "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity}  #{msg}\n"
   end

   # TODO: define setting types
   Settings.read './hangbot.yaml'
   Settings.resolve!
   webhook_url = URI.join Settings['local_server']['base_url'], '/'

   respond_to_hipchat_messages(
      address:Settings['local_server']['bind_address'],
      port:Settings['local_server']['port'],
      webhook_url:webhook_url,
      room_name:Settings['hipchat']['room_name'],
      api_token:Settings['hipchat']['api_token'],
      timeout:Settings['hipchat']['timeout'],
      logger:logger
   ) do |message|
      "Herp derp"
   end
end

main
