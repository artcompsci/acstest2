#:segment start: classes
require "acs"

class Body

  attr_accessor :mass, :pos, :vel

  def initialize(mass = 0, pos = Vector[0,0,0], vel = Vector[0,0,0])
    @mass, @pos, @vel = mass, pos, vel
  end

end

class NBody

  attr_accessor :time, :body

  def initialize(n = 0)
    @body = []
    for i in 0...n
      @body[i] = Body.new
    end
  end

end
#:segment end:

#:segment start: worker
include Math

def frand(low, high)
  low + rand * (high - low)
end

def mkplummer(n, seed)
  if seed == 0
    srand
  else
    srand seed
  end
  nb = NBody.new(n)
  nb.body.each do |b|
    b.mass = 1.0/n                                                       #3
    radius = 1.0 / sqrt( rand ** (-2.0/3.0) - 1.0)                       #4
    theta = acos(frand(-1, 1))                                           #5
    phi = frand(0, 2*PI)                                                 #6
    b.pos[0] = radius * sin( theta ) * cos( phi )                        #7
    b.pos[1] = radius * sin( theta ) * sin( phi )                        #7
    b.pos[2] = radius * cos( theta )                                     #7
    x = 0.0                                                              #8
    y = 0.1                                                              #8
    while y > x*x*(1.0-x*x)**3.5                                         #8
      x = frand(0,1)                                                     #8
      y = frand(0,0.1)                                                   #8
    end                                                                  #8
    velocity = x * sqrt(2.0) * ( 1.0 + radius*radius)**(-0.25)           #8
    theta = acos(frand(-1, 1))                                           #9
    phi = frand(0, 2*PI)                                                 #9
    b.vel[0] = velocity * sin( theta ) * cos( phi )                      #9
    b.vel[1] = velocity * sin( theta ) * sin( phi )                      #9
    b.vel[2] = velocity * cos( theta )                                   #9
  end
  STDERR.print "             actual seed used\t: ", srand, "\n"
  nb.acs_write
end
#:segment end:

#:segment start: driver
options_text= <<-END

  Description: Plummer's Model Builder
  Long description:
    This program creates an N-body realization of Plummer's Model.
    (c) 2004, Piet Hut and Jun Makino; see ACS at www.artcompsi.org

    The algorithm used is described in Aarseth, S., Henon, M., & Wielen, R.,
    Astron. Astroph. 37, 183 (1974).


  Short name:		-n
  Long name:            --n_particles
  Value type:           int
  Default value:        1
  Variable name:        n
  Print name:           N
  Description:          Number of particles
  Long description:
    Number of particles in a realization of Plummer's Model.

    Each particles is drawn at random from the Plummer distribution,
    and therefore there are no correlations between the particles.

    Physical Units are used in which G = M = a = 1, where
      G is the gravitational constant
      M is the total mass of the N-body system
      a is the structural length, with potential U(r) = GM/(r^2 + a^2)^{1/2}


  Short name:           -s
  Long name:            --seed
  Value type:           int
  Default value:        0
  Description:          pseudorandom number seed given
  Print name:           
  Variable name:      seed
  Long description:
    Seed for the pseudorandom number generator.  If a seed is given with
    value zero, a preudorandom number is chosen as the value of the seed.
    The seed value used is echoed separately from the seed value given,
    to allow the possibility to repeat the creation of an N-body realization.

      Example:

        |gravity> ruby mkplummer1.rb -n 42 -s 0
        . . .
        pseudorandom number seed given	: 0
                     actual seed used	: 1087616341
        . . .
        |gravity> ruby mkplummer1.rb -n 42 -s 1087616341
        . . .
        pseudorandom number seed given	: 1087616341
                     actual seed used	: 1087616341
        . . .


  END

c = parse_command_line(options_text, true)

mkplummer(c.n, c.seed)
#:segment end:
