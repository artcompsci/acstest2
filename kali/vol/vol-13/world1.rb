require "acs.rb"

class Worldpoint

  attr_accessor :mass, :pos, :vel, :acc, :jerk, :time, :next_time

  def propagate(era, wl, dt_param)
    ss = era.make_snapshot(wl, @next_time)
    wp = ss.body.shift
    wp.acc, wp.jerk = wp.get_acc_and_jerk(ss)
    w = interpolate(wp, wp.time)
    w.acc, w.jerk = wp.acc, wp.jerk
    w.next_time = w.time + w.collision_time_scale(ss) * dt_param
    w
  end

  def get_acc_and_jerk(snapshot)
    a = j = @pos*0                         # null vectors of the correct length
    snapshot.body.each do |b|
      r = b.pos - @pos
      r2 = r*r
      r3 = r2*sqrt(r2)
      v = b.vel - @vel
      a += r*(b.mass/r3)
      j += (v-r*(3*(r*v)/r2))*(b.mass/r3)
    end
    [a, j]
  end    

  def collision_time_scale(snapshot)
    time_scale_sq = 1e30                         # square of time scale value
    snapshot.body.each do |b|
      r = b.pos - @pos
      v = b.vel - @vel
      r2 = r*r
      v2 = v*v
      estimate_sq = r2 / v2              # [distance]^2/[velocity]^2 = [time]^2
      if time_scale_sq > estimate_sq
        time_scale_sq = estimate_sq
      end
      a = (@mass + b.mass)/r2
      estimate_sq = sqrt(r2)/a           # [distance]/[acceleration] = [time]^2
      if time_scale_sq > estimate_sq
        time_scale_sq = estimate_sq
      end
    end
    sqrt(time_scale_sq)                  # time scale value
  end

  def ekin                               # kinetic energy
    0.5*@mass*(@vel*@vel)
  end

  def epot(body_array)                   # potential energy
    p = 0
    body_array.each do |b|
      unless b == self
        r = b.pos - @pos
        p += -@mass*b.mass/sqrt(r*r)
      end
    end
    p
  end

  def ppx                    # pretty print, with extra information (acc, jerk)
    STDERR.print to_s
    STDERR.print "   acc = " @acc.join(", ") + "\n"
    STDERR.print "   jerk = " + @jerk.join(", ") + "\n"
  end

  def read
    @mass = gets.to_f
    @pos = gets.split.map{|x| x.to_f}.to_v
    @vel = gets.split.map{|x| x.to_f}.to_v
  end

  def write
    printf("%24.16e\n", @mass)
    @pos.each{|x| printf("%24.16e", x)}; print "\n"
    @vel.each{|x| printf("%24.16e", x)}; print "\n"
  end

  def extrapolate(t)
    if t > @next_time
      raise "t = " + t.to_s + " > @next_time = " + @next_time.to_s + "\n"
    end
    wp = Worldpoint.new
    wp.mass = @mass
    wp.time = t
    dt = t - @time
    wp.pos = @pos + @vel*dt + @acc*(dt*dt/2.0) + @jerk*(dt*dt*dt/6.0)
    wp.vel = @vel + @acc*dt + @jerk*(dt*dt/2.0)
    wp
  end

  def interpolate(other, t)
    wp = Worldpoint.new
    wp.mass = @mass
    wp.time = t
    dt = other.time - @time
    snap = ((@acc - other.acc)*(-6) - (@jerk*2 + other.jerk)*2*dt)/(dt*dt)
    crackle = ((@acc - other.acc)*12 + (@jerk + other.jerk)*6*dt)/(dt*dt*dt)
    dt = t - @time
    wp.pos = @pos + @vel*dt + @acc*(dt**2/2.0) + @jerk*(dt**3/6.0) +
             snap*(dt**4/24.0) + crackle*(dt**5/120.0)
    wp.vel = @vel + @acc*dt + @jerk*(dt**2/2.0) + snap*(dt**3/6.0) + 
             crackle*(dt**4/24.0)
    wp
  end

  def clone
    c = Worldpoint.new
    c.mass = @mass
    c.pos = @pos*1             # silly, but it works ; to be cleaned up
    c.vel = @vel*1             # by overloading the = operator ; without 
    c.acc = @acc*1             # this silly trick, no deep vector copy !!
    c.jerk = @jerk*1
    c.time = @time
    c.next_time = @next_time
    c
  end

end

class Worldline

  attr_accessor  :worldpoint

  def initialize
    @worldpoint = []
  end

  def extend(era, dt_param)
    @worldpoint.push(@worldpoint.last.propagate(era, self, dt_param))
  end

  def make_snapshot(time)
    if @worldpoint.last.time <= time
      @worldpoint.last.extrapolate(time)
    else
      @worldpoint.each_index do |i|
        if @worldpoint[i].time > time
          return @worldpoint[i-1].interpolate(@worldpoint[i], time)
        end
      end
    end
  end

  def next_worldline
    wl = Worldline.new
    wl.worldpoint[0] = @worldpoint.last.clone
    wl
  end

#  def read                               # for self-documenting data
#  end

  def read_worldpoint
    @worldpoint[0] = Worldpoint.new
    @worldpoint[0].read
  end

  def write_worldpoint
    @worldpoint.last.write
  end

  def write
    print "    Begin World Line\n"               # for now; 
    @worldpoint.each do |wp|
      print "    at time ", wp.time, " :\n"
      wp.write
    end
    print "    End World Line\n"                 # for now; 
  end

end

class Worldera

  attr_accessor  :start_time, :end_time  # end of container, not necessarily of
                                         # of the contents, i.e. the worldlines
  def initialize
    @worldline = []
  end

  def find_next_worldline
  end

  def evolve(c)
    nsteps = 0
    @end_time = @start_time + c.dt_era
    time = @start_time
    while time < @end_time
      nwl = find_next_worldline
      time = nwl.worldpoint.last.next_time
      nwl.extend(self, c.dt_param)
      nsteps += 1
    end
    [next_era, nsteps]
  end

  def next_era
    e = Worldera.new
    e.start_time = @end_time
    @wordline.each do |wl|
      e.worldline.push(wl.next_worldline)
    end
  end

  def make_snapshot(wl, time)
    ws = Worldsnapshot.new
    @worldline.each do |w|
      s = w.make_snapshot(time)
      if w == wl
        ws.body.unshift(s)
      else
        ws.body.push(s)
      end
    end
  end

  def write_diagnostics(t, nsteps, initial_energy, x_flag)
    STDERR.print "at time t = #{sprintf("%g", t)} "
    STDERR.print "(from interpolation after #{nsteps} steps "
    STDERR.print "to time #{sprintf("%g", @end_time)}):"
    make_snapshot(nil, t).write_diagnostics(initial_energy, x_flag)
  end

#  def read          # for self-documenting data, either Worldera or Snapshot
#  end

  def read_snapshot
    n = gets.to_i
    @start_time = gets.to_f
    for i in 0...n
      @worldline[i] = Worldline.new
      @worldline[i].read_worldpoint         # for now; "read" w. self-doc. data
      @worldline[i].worldpoint[0].time = @start_time
    end
  end

  def write_snapshot(t)
    print @worldline.size, "\n"
    printf("%24.16e\n", t)
    make_snapshot(nil, t).write
  end

  def write
    print "  Begin Era\n"               # for now; 
    @worldline.each do |wl|
      wl.write
    end
    print "  End Era\n"                 # for now; 
  end

end

class World

  def startup(dt_param)
    @era.wordline.each do |wl|
      wp = wl.worldpoint[0]
      ss = era.make_snapshot(wl, wp.time)
      ss.body.shift
      wp.acc, wp.jerk = wp.get_acc_and_jerk(ss)
      wp.next_time = wp.time + wp.collision_time_scale(ss) * dt_param
    end
    ss = era.make_snapshot(nil, @era.start_time)
    ss.ekin + ss.epot
  end

  def evolve(c)
    initial_energy = startup(c.dt_param)
    time = @era.start_time
    nsteps = 0
    @era.write_diagnostics(time, nsteps, initial_energy, c.x_flag)
    t_dia = time + c.dt_dia
    t_out = time + c.dt_out
    t_end = time + c.dt_end
    @era.write_snapshot(time) if c.init_out
    while @era.start_time < t_end
      @new_era, dn = @era.evolve(c)
      nsteps += dn
      @old_era = @era
      @era = @new_era
      time = @old_era.end_time
      while time >= t_dia
        @old_era.write_diagnostics(t_dia, nsteps, initial_energy, c.x_flag)
        t_dia += c.dt_dia
      end
      if time >= t_out
        @old_era.write_snapshot(t_out)
        t_out += c.dt_out
      end
    end

  def read_snapshot
    @era = Worldera.new
    @era.read_snapshot
  end

  def write_snapshot(time)
    @era.write_snapshot(time)
  end

  def write
    print "Begin World\n"               # for now; 
    @era.write
    print "End World\n"               # for now; 
  end

end

class Worldsnapshot

  attr_accessor :body

  def initialize
    @body = []
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

  def write_diagnostics(initial_energy, x_flag)
    e0 = initial_energy
    STDERR.print <<END
  E_kin = #{sprintf("%.3g", ekin)} ,\
 E_pot =  #{sprintf("%.3g", epot)} ,\
 E_tot = #{sprintf("%.3g", etot)}
             E_tot - E_init = #{sprintf("%.3g", etot - e0)}
  (E_tot - E_init) / E_init = #{sprintf("%.3g", (etot - e0)/e0 )}
END
    if x_flag
      STDERR.print "  for debugging purposes, here is the internal data ",
                   "representation:\n"
      ppx
    end
  end

  def ppx                          # pretty print, with extra information (acc)
    print "     N = ", @body.size, "\n"
    @body.each{|b| b.ppx(@body)}
  end

  def write
    @body.each do |b|
      b.write
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
    ruby mkplummer3.rb -n 5 | ruby #{$0} -t 1


  Short name: 		-s
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
  Long name:		--era_length
  Value type:		float
  Default value:	0.01
  Variable name:	dt_era
  Description:		Interval between diagnostics output
  Long description:
    This option sets the time interval between diagnostics output,
    which will appear on the standard error channel.


  Short name: 		-d
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
  Long name:		--time_period
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

w = World.new
w.read_snapshot                            # for now; "read" w. self-doc. data
w.write_snapshot(0)
#w.write
w.evolve(clop)
