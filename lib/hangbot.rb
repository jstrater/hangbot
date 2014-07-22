require 'webrick'
require 'json'
require 'hipchat_party'
require 'uri'
require 'pp'
require 'configliere'
require 'logger'
require 'hangman_game'
require 'hangman_wordlist'


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

# Create a web server that listens on the given address & port for HipChat
# message notifications. The webhook ID on the notifications will be checked
# against +webhook_id+.
#
# Message contents will be passed to the block, and the block's return value
# will be posted as a new HipChat room notification.
def respond_to_hipchat_messages port:4567, address:'0.0.0.0', room_name:nil,
   webhook_url:nil, api_token:nil, timeout:30, logger:nil
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
      if response_message
         logger.info "response: #{response_message}"
         hipchat.send_room_notification room_name, response_message
      else
         logger.info "no response"
      end
   end

   # Shut down cleanly on ctrl-c
   trap 'INT' do
      # Reset the signal handler so that two SIGINTs shut things down immediately
      trap 'INT', 'DEFAULT'

      server.shutdown
   end

   # Start the server here. Any code after server.start will be executed after
   # the server shuts down.
   logger.info "Starting web server at #{address}:#{port} (CTRL-C to stop)"
   server.start

   # Clean up the hooks, otherwise HipChat will keep trying to call us.
   logger.info "Cleaning up webhooks"
   remove_hipchat_webhooks hipchat, room_name, webhook_name
end

def load_settings!
   config_file_argument = ARGV[0] ? File.absolute_path(ARGV[0]) : nil
   config_file = config_file_argument || './hangbot.yaml'
   default_word_list = File.expand_path(
      File.join(File.dirname(__FILE__), '../bandnames.txt')
   )

   # Use Configliere to define and read in our settings from hangbot.yaml
   Settings.define 'word_list',
      description:"Word list file"
   Settings.define 'local_server.base_url', required:true,
      description:"URL for your local server, as you would access it from the outside world (accounting for NAT, port forwarding, etc.)"
   Settings.define 'local_server.bind_address',
      description:"Address for the local server to bind to"
   Settings.define 'local_server.port',
      description:"Port to listen on"
   Settings.define 'hipchat.room_name', required:true,
      description:"HipChat room to join"
   Settings.define 'hipchat.api_token', required:true,
      description:"OAuth bearer token. Must have admin_room and send_notification scopes for the room."
   Settings.define 'hipchat.timeout',
      description:"Seconds before a HipChat API request times out."
   Settings({ # defaults
      'word_list' => default_word_list,
      'local_server' => {
         'bind_address' => '0.0.0.0',
         'port' => 4567
      },
      'hipchat' => {
         'timeout' => 30
      }
   })
   Settings.read config_file
   Settings.resolve!

   # The word_list's path is relative to the config file. Expand it so that we
   # have the right path later on.
   Settings['word_list_full_path'] =
      File.expand_path(Settings['word_list'], File.dirname(config_file))
end


def partial_solution_string game 
   game.partial_solution.map{ |char| char || '_' }.join(' ')
end

def game_status game
   misses_list = game.incorrect_guesses.empty? ? "" : ": #{game.incorrect_guesses.to_a.join(', ')}"
   misses_message = "[#{game.incorrect_guesses.size}/#{game.guess_limit} misses#{misses_list}]"

   "#{partial_solution_string game}  #{misses_message}"
end

def main
   # Set up a logger with the same output format as WEBrick
   logger = Logger.new STDERR
   logger.formatter = proc do |severity, datetime, progname, msg|
     "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity}  #{msg}\n"
   end

   load_settings!
   webhook_url = URI.join Settings['local_server']['base_url'], '/'
   wordlist = HangmanWordlist.new Settings['word_list_full_path']
   game = nil

   respond_to_hipchat_messages(
      address:Settings['local_server']['bind_address'],
      port:Settings['local_server']['port'],
      webhook_url:webhook_url,
      room_name:Settings['hipchat']['room_name'],
      api_token:Settings['hipchat']['api_token'],
      timeout:Settings['hipchat']['timeout'],
      logger:logger
   ) do |message|
      # Split up a "/command [args...]" message into its parts
      message_parts = /^\/(?<command>\w+)(\s+(?<args>.*))?$/.match message
      if message_parts
         command = message_parts['command']
         args = message_parts['args']

         case command
         # New game command
         when 'hangman'
            game = HangmanGame.new wordlist.random_word
            "Starting a new game. Fill in the blanks: #{partial_solution_string game}\nMake guesses with \"/guess LETTER\". #{game.remaining_misses} mistakes and you're toast."

         # Command to guess a letter
         when 'guess'
            unless game
               next "No game in progress. Use /hangman to start a new one."
            end

            if game.finished?
               next "Game's over! Use /hangman to start a new one."
            end

            # See if the command included a valid guess
            guess = args.strip.upcase
            unless HangmanGame.acceptable_guess? guess
               next "The /guess command takes a single letter of the alphabet."
            end

            if game.guessed? guess
               next "#{guess} has already been guessed."
            end

            # Make the guess and let the user know how it turned out
            game.guess! guess
            if game.won?
               "You got it! The answer was #{game.word}. (success)"
            elsif game.lost?
               "(sadpanda) Aww, you lost. The correct answer was #{game.word}."
            else
               # No win or loss yet -- just print out the game state.
               game_status game
            end
         end
      end
   end
end

main
