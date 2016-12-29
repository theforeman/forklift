#!/usr/bin/env ruby

require 'net/http'
require 'net/https'
require 'timeout'
require 'facter'

SETTINGS = {
  :url => ENV['FOREMAN_URL'] || 'http://0.0.0.0:3000',
  :ssl_ca => ENV['foreman_ssl_ca'],
  :ssl_cert => ENV['foreman_ssl_cert'],
  :ssl_key => ENV['foreman_ssl_key'],
}

# Default external encoding
if defined?(Encoding)
  Encoding.default_external = Encoding::UTF_8
end

def url
  SETTINGS[:url] || raise("Must provide URL in #{$settings_file}")
end

begin
  require 'json'
rescue LoadError
  # Debian packaging guidelines state to avoid needing rubygems, so
  # we only try to load it if the first require fails (for RPMs)
  begin
    require 'rubygems' rescue nil
    require 'json'
  rescue LoadError => e
    puts "You need the `json` gem to use the Foreman ENC script #{e}"
    # code 1 is already used below
    exit 2
  end
end

def build_body
  # Strip the Puppet:: ruby objects and keep the plain hash
  facts        = Facter.to_hash
  hostname     = ENV['HOST_NAME'] || facts['fqdn'] || certname

  {'facts' => facts, 'name' => hostname, 'certname' => certname}
end

def initialize_http(uri)
  res              = Net::HTTP.new(uri.host, uri.port)
  res.use_ssl      = uri.scheme == 'https'
  if res.use_ssl?
    if SETTINGS[:ssl_ca] && !SETTINGS[:ssl_ca].empty?
      res.ca_file = SETTINGS[:ssl_ca]
      res.verify_mode = OpenSSL::SSL::VERIFY_PEER
    else
      res.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    if SETTINGS[:ssl_cert] && !SETTINGS[:ssl_cert].empty? && SETTINGS[:ssl_key] && !SETTINGS[:ssl_key].empty?
      res.cert = OpenSSL::X509::Certificate.new(File.read(SETTINGS[:ssl_cert]))
      res.key  = OpenSSL::PKey::RSA.new(File.read(SETTINGS[:ssl_key]), nil)
    end
  end
  res
end

def generate_fact_request
  uri = URI.parse("#{url}/api/hosts/facts")
  req = Net::HTTP::Post.new(uri.request_uri)
  req.add_field('Accept', 'application/json,version=2' )
  req.content_type = 'application/json'
  req.body         = build_body.to_json
  req
rescue => e
  raise "Could not generate facts for Foreman: #{e}"
end

def upload_facts(certname, req)
  return nil if req.nil?
  uri = URI.parse("#{url}/api/hosts/facts")
  begin
    res = initialize_http(uri)
    res.start { |http| http.request(req) }
  rescue => e
    raise "Could not send facts to Foreman: #{e}"
  end
end

def certname
  @certname ||= `hostname`
end
# Actual code starts here

if __FILE__ == $0 then
  begin
    req = generate_fact_request
    upload_facts(certname, req)
  end
end
