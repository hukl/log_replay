# encoding: utf-8

$: << File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name         = "log_replay"
  s.version      = "0.0.1"
  s.authors      = ["hukl"]
  s.email        = "contact@smyck.org"
  s.homepage     = "http://github.com/hukl/log_replay"
  s.summary      = "[summary]"
  s.description  = "[description]"

  s.files        = [
    "README",
    "lib/log_replay.rb",
    "lib/log_replay/request.rb"
  ]
  s.platform     = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.rubyforge_project = '[none]'
  s.required_rubygems_version = '>= 1.3.7'
end
