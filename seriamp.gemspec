Gem::Specification.new do |spec|
  spec.name          = "seriamp"
  spec.version       = '0.9.0'
  spec.authors       = ['Oleg Pudeyev']
  spec.email         = ['code@olegp.name']
  spec.summary       = %q{Serial control for amplifiers & A/V receivers}
  spec.description   = %q{Library for controlling Yamaha A/V receivers and Sonance Sonamp amplifiers via the serial port}
  spec.homepage      = "https://github.com/p/seriamp"
  spec.license       = "BSD-2-Clause"

  spec.files         = `git ls-files -z`.split("\x0").reject { |path| path.start_with?('protocol/') }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  
  #spec.add_runtime_dependency 'serialport', '~> 1.3'
  spec.add_runtime_dependency 'ruby-termios', '~> 1.0'
  
  spec.add_development_dependency 'rspec-core', '~> 3.12'
  spec.add_development_dependency 'rspec-expectations', '~> 3.12'
  spec.add_development_dependency 'rspec-mocks', '~> 3.12'
  spec.add_development_dependency 'faraday', '~> 2.7'
  spec.add_development_dependency 'sinatra', '~> 4.0'
  spec.add_development_dependency 'rack', '~> 3.0'
  spec.add_development_dependency 'rackup'
  spec.add_development_dependency 'rack-test', '~> 2.0'
  
  # Optional dependencies: sinatra for the web apps
end
