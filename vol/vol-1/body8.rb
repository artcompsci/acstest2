class Body

  attr_accessor :mass, :pos, :vel

  def initialize(mass = 0, pos = [0,0,0], vel = [0,0,0])
    @mass, @pos, @vel = mass, pos, vel
  end

  def to_s
    "  mass = " + @mass.to_s + "\n" +
    "   pos = " + @pos.join(", ") + "\n" +
    "   vel = " + @vel.join(", ") + "\n"
  end

  def pp               # pretty print
    print to_s
  end

  def simple_print
    [[@mass], @pos, @vel].each { |x| x.each { |y| printf("%24.16e", y) } ; print "\n" }
  end

  def simple_read
    (@mass,),@pos,@vel = (1..3).collect { |i|  i = gets.split.collect { |x| x.to_f } }
  end

end
