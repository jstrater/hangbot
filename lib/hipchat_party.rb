require 'httparty'
require 'json'


# Thin abstraction layer for the HipChat v2 API.
#
# The official API's module name is "hipchat", hence the disambiguating "party" suffix.
#
# TODO: error handling for requests
class HipChatParty
   include HTTParty
   base_uri 'https://api.hipchat.com/v2/'
   headers 'Content-Type' => "application/json"
   format :json
   debug_output $stderr

   # +api_token+ must have admin_room and send_notification scopes.
   #
   # +timeout+ is specified in seconds.
   def initialize api_token, timeout:30
      self.class.headers 'Authorization' => "Bearer #{api_token.strip}"
   end

   # Delete all webhooks with the specified name in a room
   def delete_webhooks_by_name room_name, hook_name
      # We can't delete webhooks by name; we have to use IDs. First we look up
      # the IDs, then we use them to delete the hooks.
      webhooks_response = self.get_webhooks room_name
      webhooks = webhooks_response.parsed_response['items']
      webhooks_to_delete = webhooks.find_all { |wh| wh['name'] == hook_name }
      webhooks_to_delete.each do |webhook|
         self.delete_webhook_by_id room_name, webhook['id']
      end
   end

   # https://www.hipchat.com/docs/apiv2/method/delete_webhook
   def delete_webhook_by_id room_name, hook_id
      self.class.delete "/room/#{room_name}/webhook/#{hook_id}"
   end

   # List all webhooks for the room
   #
   # https://www.hipchat.com/docs/apiv2/method/get_all_webhooks
   def get_webhooks room_name
      self.class.get "/room/#{room_name}/webhook"
   end

   # Sets a webhook to call back to +url+ whenever +event+ occurs in
   # +room_name+. If +pattern+ is set, and the event type is "room_message",
   # only matching messages will trigger a callback.
   #
   # https://www.hipchat.com/docs/apiv2/method/create_webhook
   def create_webhook room_name, hook_name, event, url, pattern:nil
      post_body = {
         url: url,
         event: event,
         name: hook_name
      }

      if event == 'room_message' && pattern
         post_body['pattern'] = pattern
      end

      response = self.class.post "/room/#{room_name}/webhook", body: post_body.to_json
      response.parsed_response['id']
   end

   # https://www.hipchat.com/docs/apiv2/method/send_room_notification
   def send_room_notification room_name, message, color:'yellow', notify:false, format:'text'
      self.class.post "/room/#{room_name}/notification", body: {
         color: color,
         message: message,
         notify: notify,
         message_format: format
      }.to_json
   end
end
