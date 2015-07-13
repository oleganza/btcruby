#encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)
require "btcruby/version"

Gem::Specification.new do |s|
  s.name              = "btcruby"
  s.email             = "oleganza+btcruby@gmail.com"
  s.version           = BTC::VERSION
  s.description       = "Bitcoin toolkit for Ruby"
  s.summary           = "Rich library for building awesome Bitcoin apps."
  s.authors           = ["Oleg Andreev", "Ryan Smith"]
  s.homepage          = "https://github.com/oleganza/btcruby"
  s.rubyforge_project = "btcruby"
  s.license           = "MIT"
  s.require_paths     = ["lib"]
  s.add_runtime_dependency 'ffi', '~> 1.9', '>= 1.9.3'

  s.files = []
  s.files << "README.md"
  s.files << "RELEASE_NOTES.md"
  s.files << "LICENSE"
  s.files << Dir["{documentation}/**/*.md"]
  s.files << Dir["{lib,spec}/**/*.rb"]
  s.test_files = s.files.select {|path| path =~ /^spec\/.*_spec.rb/}
end
