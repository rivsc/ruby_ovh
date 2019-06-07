# RubyOvh

## Install

Add this in your Gemfile :

```ruby
gem 'ruby_ovh'
```

## Usage

The first time you need a consumer key. You can generate as follow :

```ruby
client = RubyOvh::Client.new({application_key: 'XXXX', application_secret: 'YYYY' })
response = client.generate_consumer_key
puts "You need to memorize your consumer_key : #{response[:consumer_key]}"
puts "You need visit this address in your browser in order to activate your consumer key #{response[:validation_url]}"
```

After that, thanks to your consumer key, you can call Ovh API as follow :

GET request :

```ruby
client = RubyOvh::Client.new({application_key: 'XXXX', application_secret: 'YYYY', consumer_key: 'ZZZZZ' })
puts client.query({ method: 'GET', url: "/me", query: {} })
```

Another GET request with params :

```ruby
puts client.query({ url: "/domain/zone/mydomain.org/record?fieldType=A" , method: "GET", query: {} })
```

POST request :

```ruby
client.query({ url: "/domain/zone/mydomain.org/record" , method: "POST", query: {
  "subDomain": "blog",
  "target": "XX.X.X.XXX",
  "fieldType": "A"
}})
```

List Ovh API : [https://eu.api.ovh.com/console/#/](https://eu.api.ovh.com/console/#/)


Rivsc.

