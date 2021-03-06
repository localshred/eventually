# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "eventually/version"

Gem::Specification.new do |s|
  s.name        = "eventually"
  s.version     = Eventually::VERSION
  s.authors     = ["BJ Neilsen"]
  s.email       = ["bj.neilsen@gmail.com"]
  s.homepage    = "http://www.rand9.com"
  s.summary     = %q{Eventually is an event library built to loosely mirror the NodeJS EventEmitter API.}
  s.description = s.summary

  s.rubyforge_project = "eventually"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency 'rspec', '>= 2.8'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'redcarpet'
  s.add_development_dependency 'github-markup'
  s.add_development_dependency 'simplecov'
end
