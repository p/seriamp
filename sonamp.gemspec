# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "sonamp"
  spec.version       = '0.0.8'
  spec.authors       = ['Oleg Pudeyev']
  spec.email         = ['code@olegp.name']
  spec.summary       = %q{Sonance Sonamp Amplifier Serial Control Interface}
  spec.description   = %q{Library for controlling Sonance Sonamp 875D SE & 875D MkII amplifiers via the serial port}
  spec.homepage      = "https://github.com/p/sonamp-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |path| path.start_with?('docs/') }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
end
