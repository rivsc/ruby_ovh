Gem::Specification.new do |s|
  s.name        = 'ruby_ovh'
  s.version     = '0.0.3'
  s.date        = '2019-06-06'
  s.summary     = "Ruby OVH client API"
  s.description = "This gem allow you to communicate with OVH API"
  s.authors     = ["Sylvain Claudel"]
  s.email       = 'claudel.sylvain@gmail.com'
  s.files       = ["lib/ruby_ovh.rb"]
  s.homepage    = 'https://rivsc.space'
  s.license     = 'MIT'
  s.add_runtime_dependency 'faraday'
end
