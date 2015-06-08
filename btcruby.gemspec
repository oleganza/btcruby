#encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)
require "btcruby/version"

files = `git ls-files`.split("\n")

Gem::Specification.new do |s|
  s.name          = "btcruby"
  s.email         = "oleganza+btcruby@gmail.com"
  s.version       = BTC::VERSION
  s.description   = "Ruby library for interacting with Bitcoin."
  s.summary       = "Ruby library for interacting with Bitcoin."
  s.authors       = ["Oleg Andreev", "Ryan Smith"]
  s.homepage      = "https://github.com/oleganza/btcruby"
  s.rubyforge_project = "btcruby"
  s.license       = "MIT"
  s.files         = files
  s.require_paths = ["lib"]
  s.add_runtime_dependency 'ffi', '~> 1.9', '>= 1.9.3'
end
