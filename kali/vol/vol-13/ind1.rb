require "vector.rb"
require "clop.rb"

class Body

  attr_accessor :mass, :pos, :vel, :acc, :jerk,
                :pred_pos, :pred_vel,
                :time, :next_time

  def initialize(mass = 0, pos = Vector[0,0,0], vel = Vector[0,0,0])
    @mass, @pos, @vel = mass, pos, vel
  end

  def autonomous_step(ba, dt_param)
    take_one_step(ba, @next_time, dt_param)
  end

  def forced_step(ba, t, dt_param)
    take_one_step(ba, t, dt_param)
  end

  def take_one_step(ba, t, dt_param)
    ba.each do |b|
      b.predict_step(t)
    end
    correct_step(ba, t, dt_param)
  end

  def predict_step(t)
    if t > @next_time
      STDERR.print "predict_step: t = ", t, " > @next_time = "
      STDERR.print @next_time, "\n"
      exit
    end
    dt = t - @time
    @pred_pos = @pos + @vel*dt + @acc*(dt*dt/2.0) + @jerk*(dt*dt*dt/6.0)
    @pred_vel = @vel + @acc*dt + @jerk*(dt*dt/2.0)
  end

  def correct_step(ba, t, dt_param)
    dt = t - @time
    new_acc, new_jerk = get_acc_and_jerk(ba)
    new_vel = @vel + (@acc + new_acc)*(dt/2.0) +        # first compute new_vel
                      (@jerk - new_jerk)*(dt*dt/12.0)   # since new_vel is used
    new_pos = @pos + (@vel + new_vel)*(dt/2.0) +        # to compute new_pos
                      (@acc - new_acc)*(dt*dt/12.0)
    @pos = new_pos
    @vel = new_vel
    @acc = new_acc
    @jerk = new_jerk
    @pred_pos = @pos
    @pred_vel = @vel
    @time = t
    @next_time = @time + collision_time_scale(ba) * dt_param
  end  

  def collision_time_scale(body_array)
    time_scale_sq = 1e30                 # square of time scale value
    body_array.each do |b|
      unless b == self
        r = b.pred_pos - @pred_pos    # NOTE: we use only predicted pos & vel
	v = b.pred_vel - @pred_vel
	r2 = r*r
	v2 = v*v
        estimate_sq = r2 / v2            # [distance]^2/[velocity]^2 = [time]^2
        if time_scale_sq > estimate_sq
          time_scale_sq = estimate_sq
	end
	a = (@mass + b.mass)/r2
        estimate_sq = sqrt(r2)/a         # [distance]/[acceleration] = [time]^2
	if time_scale_sq > estimate_sq
          time_scale_sq = estimate_sq
	end
      end
    end
    sqrt(time_scale_sq)                  # time scale value
  end

  def get_acc_and_jerk(body_array)
    a = j = @pos*0                         # null vectors of the correct length
    body_array.each do |b|
      unless b == self
        r = b.pred_pos - @pred_pos    # NOTE: we use only predicted pos & vel
        r2 = r*r
        r3 = r2*sqrt(r2)
        v = b.pred_vel - @pred_vel
        a += r*(b.mass/r3)
        j += (v-r*(3*(r*v)/r2))*(b.mass/r3)
      end
    end
    [a, j]
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
    STDERR.print to_s
    STDERR.print "   acc = " + acc(body_array).join(", ") + "\n"
    STDERR.print "   jerk = " + jerk(body_array).join(", ") + "\n"
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

  def initialize
    @body = []
  end

  def startup(dt_param)
    @e0 = ekin + epot                      # initial total energy
    @body.each do |b|
      b.pred_pos = b.pos             # first compute pred_pos & pred_vel
      b.pred_vel = b.vel
    end
    @body.each do |b|
      b.acc, b.jerk = b.get_acc_and_jerk(@body)   # acc & jerk use pred_pos/vel
    end
    @body.each do |b|
      b.time = @time
      b.next_time = @time + b.collision_time_scale(@body) * dt_param
    end
  end

  def evolve(c)
    nsteps = 0
    startup(c.dt_param)
    write_diagnostics(nsteps, c.x_flag)
    t_dia = @time + c.dt_dia
    t_out = @time + c.dt_out
    t_end = @time + c.dt_end
    simple_print if c.init_out
    while @time < t_end
      np = find_next_particle
      @time = np.next_time
      if (@time < t_end)
        np.autonomous_step(@body, c.dt_param)
        nsteps += 1
      end
      if @time >= t_dia
        sync(t_dia, c.dt_param)
        nsteps += @body.size
        write_diagnostics(nsteps, c.x_flag)
        t_dia += c.dt_dia
      end
      if @time >= t_out
        sync(t_out, c.dt_param)    # we are now syncing twice, if t_dia = t_out
        nsteps += @body.size
        simple_print
        t_out += c.dt_out
      end
    end
  end

  def find_next_particle
    next_time = 1e30
    next_particle = nil
    @body.each do |b|
      if next_time > b.next_time
        next_time = b.next_time
        next_particle = b
      end
    end
    next_particle
  end

  def sync(t, dt_param)
    @body.each{|b| b.forced_step(@body, t, dt_param)}
    @time = t
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

  def write_diagnostics(nsteps, x_flag)
    etot = ekin + epot
    STDERR.print <<END
at time t = #{sprintf("%g", time)}, after #{nsteps} steps :
  E_kin = #{sprintf("%.3g", ekin)} ,\
 E_pot =  #{sprintf("%.3g", epot)} ,\
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

options_text= <<-END

  Description: Individual Time Step Hermite Code
  Long description:
    This program evolves an N-body code with a fourth-order Hermite Scheme,
    using individual time steps.
    (c) 2004, Piet Hut, Jun Makino, Murat Kaplan; see ACS at www.artcompsi.org

    example:
    ruby mkplummer3.rb -n 5 | ruby sh1.rb -t 1


  Short name: 		-d
  Long name:		--step_size_control
  Value type:		float
  Default value:	0.01
  Variable name:	dt_param
  Description:		Parameter to determine time step size
  Long description:
    This option sets the step size control parameter dt_param << 1.  Before
    each new time step, we first calculate the time scale t_scale on which
    changes are expected to happen, such as close encounters or significant
    changes in velocity.  The new shared time step is then given as the
    product t_scale * dt_param << t_scale.


  Short name: 		-e
  Long name:		--diagnostics_interval
  Value type:		float
  Default value:	1
  Variable name:	dt_dia
  Description:		Interval between diagnostics output
  Long description:
    This option sets the time interval between diagnostics output,
    which will appear on the standard error channel.


  Short name: 		-o
  Long name:		--output_interval
  Value type:		float
  Default value:	1
  Variable name:	dt_out
  Description:		Time interval between snapshot output
  Long description:
    This option sets the time interval between output of a snapshot
    of the whole N-body system, which which will appear on the
    standard output channel.

    The snapshot contains the mass, position, and velocity values
    for all particles in an N-body system.

    The program expects input of a single snapshot of an N-body
    system, in the following format: the number of particles in the
    snapshot n; the time t; mass mi, position ri and velocity vi for
    each particle i, with position and velocity given through their
    three Cartesian coordinates, divided over separate lines as
    follows:

                  n
                  t
                  m1 r1_x r1_y r1_z v1_x v1_y v1_z
                  m2 r2_x r2_y r2_z v2_x v2_y v2_z
                  ...
                  mn rn_x rn_y rn_z vn_x vn_y vn_z

    Output of each snapshot is written according to the same format.


  Short name: 		-t
  Long name:		--duration
  Value type:		float
  Default value:	10
  Variable name:	dt_end
  Print name:		t
  Description:		Duration of the integration
  Long description:
    This option sets the duration t of the integration, the time period
    after which the integration will halt.  If the initial snapshot is
    marked to be at time t_init, the integration will halt at time
    t_final = t_init + t.


  Short name:		-i
  Long name:  		--init_out
  Value type:  		bool
  Variable name:	init_out
  Description:		Output the initial snapshot
  Long description:
    If this flag is set to true, the initial snapshot will be output
    on the standard output channel, before integration is started.


  Short name:		-x
  Long name:  		--extra_diagnostics
  Value type:  		bool
  Variable name:	x_flag
  Description:		Extra diagnostics
  Long description:
    If this flag is set to true, the following extra diagnostics
    will be printed: 

      acceleration (for all integrators)
      jerk (for the Hermite integrator)


  END

clop = parse_command_line(options_text, true)

nb = Nbody.new
nb.simple_read
nb.evolve(clop)
