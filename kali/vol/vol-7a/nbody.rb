require "acs.rb"

class Body

  ACS_OUTPUT_NAME = self.to_s

  attr_accessor :mass, :pos, :vel

  def initialize
    @mass = 0.0
    @pos = Vector.new
    @vel = Vector.new
  end

end

class Nbody

  ACS_OUTPUT_NAME = self.to_s

  attr_accessor :time, :body

  def initialize
    @body = []
    @time = 0.0
  end

end
