#!/usr/bin/env ruby

require 'gmp'

a = GMP::F.new 1,4000000
a = a.asin
a = a*a*a*a*a*a*a*a*a*a*a*a
p a.to_s[0..1000]

