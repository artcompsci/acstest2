require "vector.rb"

class Body

  attr_accessor :mass, :pos, :vel

  def initialize(mass = 0, pos = Vector[0,0,0], vel = Vector[0,0,0])
    @mass, @pos, @vel = mass, pos, vel
  end

  def calc(body_array, time_step, s)
    ba  = body_array
    dt = time_step
    eval(s)
  end

  def acc(body_array)
    a = @pos*0                              # null vector of the correct length
    body_array.each do |b|
      unless b == self
        r = b.pos - @pos
        r2 = r*r
        r3 = r2*sqrt(r2)
        a += r*(b.mass/r3)
      end
    end
    a
  end    

  def ekin                         # kinetic energy
    0.5*@mass*(@vel*@vel)
  end

  def epot(body_array)             # potential energy
    p = 0
    body_array.each do |b|
      unless b == self
        r = b.pos - @pos
        p += -@mass*b.mass/sqrt(r*r)
      end
    end
    p
  end

  def to_s
    "  mass = " + @mass.to_s + "\n" +
    "   pos = " + @pos.join(", ") + "\n" +
    "   vel = " + @vel.join(", ") + "\n"
  end

  def pp                           # pretty print
    print to_s
  end

  def ppx(body_array)              # pretty print, with extra information (acc)
    print to_s + "   acc = " + acc(body_array).join(", ") + "\n"
  end

  def simple_print
    printf("%24.16e\n", @mass)
    @pos.each{|x| printf("%24.16e", x)}; print "\n"
    @vel.each{|x| printf("%24.16e", x)}; print "\n"
  end

  def simple_read
    @mass = gets.to_f
    @pos = gets.split.map{|x| x.to_f}.to_v
    @vel = gets.split.map{|x| x.to_f}.to_v
  end

end

class Nbody

  attr_accessor :time, :body

  def initialize(n=0, time = 0)
    @time = time
    @body = []
    for i in 0...n
      @body[i] = Body.new
    end
  end

  def evolve(integration_method, dt, dt_dia, dt_out, dt_end, init_out, x_flag)
    nsteps = 0
    e_init
    write_diagnostics(nsteps, x_flag)
    @dt = dt
    t_dia = dt_dia - 0.5*dt
    t_out = dt_out - 0.5*dt
    t_end = dt_end - 0.5*dt

    simple_print if init_out

    while @time < t_end
      send(integration_method)
      @time += dt
      nsteps += 1
      if @time >= t_dia
        write_diagnostics(nsteps, x_flag)
        t_dia += dt_dia
      end
      if @time >= t_out
        simple_print
        t_out += dt_out
      end
    end
  end

  def calc(s)
    @body.each{|b| b.calc(@body, @dt, s)}
  end

  def forward
    calc(" @old_acc = acc(ba) ")
    calc(" @pos += @vel*dt ")
    calc(" @vel += @old_acc*dt ")
  end

  def leapfrog
    calc(" @vel += acc(ba)*0.5*dt ")
    calc(" @pos += @vel*dt ")
    calc(" @vel += acc(ba)*0.5*dt ")
  end

  def rk2
    calc(" @old_pos = @pos ")
    calc(" @half_vel = @vel + acc(ba)*0.5*dt ")
    calc(" @pos += @vel*0.5*dt ")
    calc(" @vel += acc(ba)*dt ")
    calc(" @pos = @old_pos + @half_vel*dt ")
  end

  def rk4
    calc(" @old_pos = @pos ")
    calc(" @a0 = acc(ba) ")
    calc(" @pos = @old_pos + @vel*0.5*dt + @a0*0.125*dt*dt ")
    calc(" @a1 = acc(ba) ")
    calc(" @pos = @old_pos + @vel*dt + @a1*0.5*dt*dt ")
    calc(" @a2 = acc(ba) ")
    calc(" @pos = @old_pos + @vel*dt + (@a0+@a1*2)*(1/6.0)*dt*dt ")
    calc(" @vel += (@a0+@a1*4+@a2)*(1/6.0)*dt ")
  end

  def ekin                        # kinetic energy
    e = 0
    @body.each{|b| e += b.ekin}
    e
  end

  def epot                        # potential energy
    e = 0
    @body.each{|b| e += b.epot(@body)}
    e/2                           # pairwise potentials were counted twice
  end

  def e_init                      # initial total energy
    @e0 = ekin + epot
  end

  def write_diagnostics(nsteps, x_flag)
    etot = ekin + epot
    STDERR.print <<END
at time t = #{sprintf("%g", time)}, after #{nsteps} steps :
  E_kin = #{sprintf("%.3g", ekin)} ,\
 E_pot =  #{sprintf("%.3g", epot)},\
 E_tot = #{sprintf("%.3g", etot)}
             E_tot - E_init = #{sprintf("%.3g", etot - @e0)}
  (E_tot - E_init) / E_init = #{sprintf("%.3g", (etot - @e0)/@e0 )}
END
    if x_flag
      STDERR.print "  for debugging purposes, here is the internal data ",
                   "representation:\n"
      ppx
    end
  end

  def pp                           # pretty print
    print "     N = ", @body.size, "\n"
    print "  time = ", @time, "\n"
    @body.each{|b| b.pp}
  end

  def ppx                          # pretty print, with extra information (acc)
    print "     N = ", @body.size, "\n"
    print "  time = ", @time, "\n"
    @body.each{|b| b.ppx(@body)}
  end

  def simple_print
    print @body.size, "\n"
    printf("%24.16e\n", @time)
    @body.each{|b| b.simple_print}
  end

  def simple_read
    n = gets.to_i
    @time = gets.to_f
    for i in 0...n
      @body[i] = Body.new
      @body[i].simple_read
    end
  end

end
