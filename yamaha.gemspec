# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "yamaha"
  spec.version       = '0.0.4'
  spec.authors       = ['Oleg Pudeyev']
  spec.email         = ['code@olegp.name']
  spec.summary       = %q{Yamaha Receiver Serial Control Interface}
  spec.description   = %q{Library for controlling Yamaha amplifiers via the serial port}
  spec.homepage      = "https://github.com/p/yamaha-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
end
