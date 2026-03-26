# sync_customers_to_crm.rb
# Syncs updated customers to HubSpot CRM.
# Usage: ruby sync_customers_to_crm.rb

require 'httparty'
require 'logger'

class CrmSync
  HUBSPOT_URL = 'https://api.hubapi.com/crm/v3/objects/contacts'

  def initialize
    @log   = Logger.new($stdout)
    @token = ENV.fetch('HUBSPOT_TOKEN')
  end

  def run
    customers = Customer.where('updated_at > ?', 24.hours.ago).to_a
    @log.info "Syncing #{customers.size} customers..."
    customers.each_slice(10) do |batch|
      upsert_batch(batch)
      sleep(0.1)
    end
    @log.info "Done."
  end

  private

  def upsert_batch(batch)
    payload = { inputs: batch.map { |c| { properties: map_fields(c) } } }
    HTTParty.post("#{HUBSPOT_URL}/batch/upsert",
      headers: { 'Authorization' => "Bearer #{@token}", 'Content-Type' => 'application/json' },
      body: payload.to_json)
  end

  def map_fields(c)
    { email: c.email, firstname: c.first_name, lastname: c.last_name }
  end
end

CrmSync.new.run
