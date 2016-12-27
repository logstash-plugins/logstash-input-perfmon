Gem::Specification.new do |s|
  s.name = 'logstash-input-perfmon'
  s.version = '0.1.6'
  s.licenses = ['Apache License (2.0)']
  s.summary = "Logstash input for Windows Performance Monitor"
  s.description = "This gem is a logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/plugin install gemname. This gem is not a stand-alone program. Logstash input for Windows Performance Monitor metrics."
  s.authors = ["Nick Ramirez"]
  s.email = 'nickram44@hotmail.com'
  s.homepage = "https://github.com/NickMRamirez/logstash-input-perfmon"
  s.require_paths = ["lib"]

  # Files
  s.files = `git ls-files`.split($\)
  
  # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "input" }

  # Gem dependencies
  s.add_runtime_dependency 'logstash-core', '~> 2.1'
  s.add_runtime_dependency 'logstash-codec-plain', '~> 2.0'

  s.add_development_dependency 'logstash-devutils', '~> 0'
end