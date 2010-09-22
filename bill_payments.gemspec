# -*- encoding: utf-8 -*-
require File.expand_path("../lib/bill_payments/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "bill_payments"
  s.version     = BillPayments::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Bill Horsman"]
  s.email       = ["bill@logicalcobwebs.com"]
  s.homepage    = "http://rubygems.org/gems/bill_payments"
  s.summary     = "bill_payments"
  s.description = "Automate bill payments (e.g. bill.com)"

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "bill_payments"

  s.add_development_dependency "bundler", ">= 1.0.0"
  s.add_runtime_dependency "nokogiri", ">= 1.2.1"

  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'
end
