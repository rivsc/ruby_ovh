require 'faraday'
require 'json'
require 'digest'

module RubyOvh
  class Client

    OVH_API = 'https://eu.api.ovh.com'
    VERSION = '1.0'

    attr_reader :ak, :ck, :as

    ##
    # == Usage
    #
    # # First Time :
    # client = RubyOvh::Client.new({application_key: 'XXXX', application_secret: 'YYYY' })
    # response = client.generate_consumer_key
    # puts "You need to memorize your consumer_key : #{response[:consumer_key]}"
    # puts "You need visit this address in your browser in order to activate your consumer key #{response[:validation_url]}"
    #
    # # Other times
    # client = RubyOvh::Client.new({application_key: 'XXXX', application_secret: 'YYYY', consumer_key: 'ZZZZZ' })
    #
    # client.query({ method: 'GET', url: "/me", query: {} })
    #
    def initialize(options = {})
      @ak = options[:application_key]
      @as = options[:application_secret]
      @ck = options[:consumer_key]
    end

    ##
    # Method to call one time to generate a consumer_key (https://docs.ovh.com/gb/en/customer/first-steps-with-ovh-api/#requesting-an-authentication-token-from-ovh)
    #
    # == Parameters
    #
    # params : hash with sereval keys :
    #   access_rules : Array of rules see here : https://docs.ovh.com/gb/en/customer/first-steps-with-ovh-api/#requesting-an-authentication-token-from-ovh
    #   redirection : Url to redirect after clic on validation url see here : https://docs.ovh.com/gb/en/customer/first-steps-with-ovh-api/#requesting-an-authentication-token-from-ovh
    #   debug : see response to the API.
    #
    # == Return
    #
    # Hash with validation_url and consumer_key keys
    # (Visit the validation url in your favorite browser and put your consumer_key (ck) in your scripts)
    #
    def generate_consumer_key(params = {})
      access_rules = params[:access_rules]
      url_to_redirect = params[:redirection]

      conn = Faraday.new(:url => OVH_API)
      response = conn.post do |req|
        req.url "/#{VERSION}/auth/credential"
        req.headers['Content-Type'] = 'application/json'
        req.headers['X-Ovh-Application'] = @ak
        req.body = {
            "accessRules": (access_rules || [
                {
                    "method": "GET",
                    "path": "/*"
                },{
                    "method": "POST",
                    "path": "/*"
                },{
                    "method": "PUT",
                    "path": "/*"
                }
            ]),
            "redirection": url_to_redirect
        }.to_json
      end

      if params[:debug]
        puts "*" * 200
        puts response.body
        puts "*" * 200
      end

      response = JSON.parse(response.body)

      ck = response['consumerKey']
      url = response['validationUrl']

      { validation_url: url, consumer_key: ck }
    end

    ##
    # This method allow you to call Ovh API.
    #
    # == Parameters
    #
    # params : hash with these keys :
    #   method: GET or POST or PUT or DELETE
    #   url: url's part of Ovh API (see here : https://eu.api.ovh.com/console/)
    #   query: API POST parameters
    #   debug: to debug
    #
    # == Example
    #
    # # GET query
    # client.signature_timestamp({ url: "/domain/zone/mydomain.org/record?fieldType=A" , method: "GET", query: {} })
    #
    # OR
    #
    # # POST query
    # client.signature_timestamp({ url: "/domain/zone/mydomain.org/record" , method: "POST", query: {
    #   "subDomain": "blog",
    #   "target": "XX.X.X.XXX",
    #   "fieldType": "A"
    # }})
    #
    # == Return
    #
    # Response REST API.
    #
    def query(params = {})
      json_body = params[:query].to_json
      url = params[:url]
      url = RubyOvh::Client.normalize_url(url)
      signature_et_ts = self.signature_timestamp({ url: url, query: json_body, method: params[:method].upcase })
      timestamp = signature_et_ts[:timestamp]
      signature = signature_et_ts[:signature]

      headers = {
        'X-Ovh-Application' => @ak,
        'X-Ovh-Timestamp'   => timestamp,
        'X-Ovh-Signature'   => signature,
        'X-Ovh-Consumer'    => @ck,
        'Content-Type'      => 'application/json'
      }

      conn = Faraday.new(:url => OVH_API)
      response = conn.run_request(params[:method].downcase.to_sym,"/#{VERSION}/#{url}",json_body,headers)

      if params[:debug]
        puts "*" * 200
        puts response.inspect
        puts "*" * 200
      end

      JSON.parse(response.body)
    end

    protected

    ##
    # Each Ovh API request needs a signature, this method generate the signature.
    #
    # == Parameters
    #
    # params : hash with these keys :
    #   method: GET or POST or PUT or DELETE
    #   url: url's part of Ovh API (see here : https://eu.api.ovh.com/console/)
    #   query: API POST parameters
    #   debug: to debug
    #
    # == Example
    #
    # client.signature_timestamp({ url: "/domain/zone/mydomain.org/record?fieldType=A" , method: "GET", query: {} })
    #
    # OR
    #
    # client.signature_timestamp({ url: "/domain/zone/mydomain.org/record" , method: "POST", query: {
    #       "subDomain": "blog",
    #       "target": "XX.X.X.XXX",
    #       "fieldType": "A"
    # }})
    #
    # == Return
    #
    # Hash with timestamp and signature keys
    #
    def signature_timestamp(params = {})
      conn = Faraday.new(:url => OVH_API)
      response = conn.get do |req|
        req.url "/#{VERSION}/auth/time"
      end

      timestamp = response.body
      #timestamp = Time.now.to_i
      puts "Timestamp : #{timestamp}" if params[:debug]

      pre_hash_signature = [@as, @ck, params[:method], "#{OVH_API}/#{VERSION}/#{params[:url]}", params[:query], timestamp].join("+")
      puts "Pre Hash Signature : #{pre_hash_signature}" if params[:debug]

      post_hash_signature = "$1$#{Digest::SHA1.hexdigest(pre_hash_signature)}"
      puts "Post Hash Signature : #{post_hash_signature}" if params[:debug]

      { timestamp: timestamp, signature: post_hash_signature }
    end

    def self.normalize_url(url)
      (url.start_with?('/') ? url[1..-1] : url)
    end
  end
end