#<i>Demo for +to_s+ method in Body class</i>

require "body.rb"

#:segment start: demo
b = Body.new(3, [0.1, 0.2, 0.3], [4, 5, 6])
p b
print b.to_s
#:segment end:
