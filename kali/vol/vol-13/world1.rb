require "acs.rb"

class Worldpoint

  attr_accessor :mass, :pos, :vel, :acc, :jerk, :time, :next_time

  def propagate(era, wl, dt_param, init_flag = false)
    ss = era.take_snapshot(wl, @next_time)
    wp = ss.body.shift
    wp = self if init_flag
    wp.acc, wp.jerk = wp.get_acc_and_jerk(ss)
    wp.correct(self)
    wp.next_time = wp.time + wp.collision_time_scale(ss) * dt_param
    wp
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
    time_scale_sq = VERY_LARGE_NUMBER              # square of time scale value
    snapshot.body.each do |b|
      r = b.pos - @pos
      v = b.vel - @vel
      r2 = r*r
      v2 = v*v + 1.0/VERY_LARGE_NUMBER          # always non-zero, for division
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
    STDERR.print "   acc = " + @acc.join(", ") + "\n"
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

  def correct(old)
    dt = @time - old.time
    @vel = old.vel + (old.acc + @acc)*(dt/2.0) +           # first compute @vel
                      (old.jerk - @jerk)*(dt*dt/12.0)      # since @vel is used
    @pos = old.pos + (old.vel + @vel)*(dt/2.0) +           # to compute @pos
                      (old.acc - @acc)*(dt*dt/12.0)
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

  def valid_extrapolation?(time)
    if @worldpoint.last.time <= time and time <= @worldpoint.last.next_time
      true
    else
      false
    end
  end

  def valid_interpolation?(time)
    if @worldpoint[0].time <= time and time <= @worldpoint.last.time
      true
    else
      false
    end
  end

  def valid_time?(time)
    if @worldpoint[0].time <= time and time <= @worldpoint.last.next_time
      true
    else
      false
    end
  end

  def take_point(time)
    if time >= @worldpoint.last.time
      raise if not valid_extrapolation?(time)
      @worldpoint.last.extrapolate(time)
    else
      raise if not valid_interpolation?(time)
      @worldpoint.each_index do |i|
        if @worldpoint[i].time > time
          return @worldpoint[i-1].interpolate(@worldpoint[i], time)
        end
      end
    end
  end

  def next_worldline(time)
    raise if not valid_interpolation?(time)
    wl = Worldline.new
    @worldpoint.each_index do |i|
      if @worldpoint[i].time > time
        wl.worldpoint = @worldpoint[i-1...@worldpoint.size]
        break
      end
    end
    wl
  end

#  def read                               # for self-documenting data
#  end

  def read_initial_worldpoint(time)
    wp = @worldpoint[0] = Worldpoint.new
    wp.read
    wp.time = wp.next_time = time
    wp.acc = wp.jerk = wp.pos*0
  end

end

class Worldera

  attr_accessor  :start_time, :end_time, # end of container, not necessarily of
                 :worldline              # of the contents, i.e. the worldlines

  def initialize
    @worldline = []
  end

  def shortest_extrapolated_worldline
    t = VERY_LARGE_NUMBER
    wl = nil
    @worldline.each do |w|
      if t > w.worldpoint.last.next_time
        t = w.worldpoint.last.next_time
        wl = w
      end
    end
    wl
  end

  def shortest_interpolated_worldline
    t = VERY_LARGE_NUMBER
    wl = nil
    @worldline.each do |w|
      if t > w.worldpoint.last.time
        t = w.worldpoint.last.time
        wl = w
      end
    end
    wl
  end

  def evolve(dt_era, dt_param)
    nsteps = 0
    @end_time = @start_time + dt_era
    while shortest_interpolated_worldline.worldpoint.last.time < @end_time
      shortest_extrapolated_worldline.extend(self, dt_param)
      nsteps += 1
    end
    [next_era, nsteps]
  end

  def next_era
    e = Worldera.new
    e.start_time = @end_time
    @worldline.each do |wl|
      e.worldline.push(wl.next_worldline(e.start_time))
    end
    e
  end

  def take_snapshot(wl, time)
    ws = Worldsnapshot.new
    @worldline.each do |w|
      s = w.take_point(time)
      if w == wl
        ws.body.unshift(s)
      else
        ws.body.push(s)
      end
    end
    ws
  end

  def valid_time?(time)
    return true if @start_time <= time and time <= @end_time
    false
  end

  def write_diagnostics(t, nsteps, initial_energy, x_flag)
    STDERR.print "at time t = #{sprintf("%g", t)} "
    STDERR.print "(from interpolation after #{nsteps} steps "
    STDERR.print "to time #{sprintf("%g", @end_time)}):\n"
    take_snapshot(nil, t).write_diagnostics(initial_energy, x_flag)
  end

#  def read          # for self-documenting data, either Worldera or Snapshot
#  end

  def read_initial_snapshot
    n = gets.to_i
    @start_time = gets.to_f
    @end_time = @start_time      # for now, to allow initial diagnostics output
    for i in 0...n
      @worldline[i] = Worldline.new
      @worldline[i].read_initial_worldpoint(@start_time)
    end
  end

  def write_snapshot(t)
    raise if not valid_time?(t)
    print @worldline.size, "\n"
    printf("%24.16e\n", t)
    take_snapshot(nil, t).write
  end

end

class World

  def startup(dt_param)
    @era.worldline.each do |wl|
      wl.worldpoint[0].propagate(@era, wl, dt_param, true)
    end
    ss = @era.take_snapshot(nil, @era.start_time)
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
      @new_era, dn = @era.evolve(c.dt_era, c.dt_param)
      nsteps += dn
      while t_dia <= @era.end_time and t_dia <= t_end
        @era.write_diagnostics(t_dia, nsteps, initial_energy, c.x_flag)
        t_dia += c.dt_dia
      end
      while t_out <= @era.end_time and t_out <= t_end
        @era.write_snapshot(t_out)
        t_out += c.dt_out
      end
      @old_era = @era
      @era = @new_era
    end
  end

  def read_initial_snapshot
    @era = Worldera.new
    @era.read_initial_snapshot
  end

  def write_snapshot(time)
    @era.write_snapshot(time)
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
    ek = ekin
    ep = epot
    etot = ek + ep
    STDERR.print <<-END
    E_kin = #{sprintf("%.3g", ek)} ,\
     E_pot =  #{sprintf("%.3g", ep)} ,\
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
  Description:		Duration of an era
  Long description:
    This option sets the time interval between begin and end of an era,
    which is the period in time that contains a bundle of world lines,
    all of which are guaranteed to extend beyond the era boundaries with
    by at least one world point in either direction.  In other words, each
    world line has an earliest world point before the beginning of the era,
    and a latest world point past the end of the era.  This guarantees
    accurate interpolation at each time within an era.


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
w.read_initial_snapshot                     # for now; "read" w. self-doc. data
#w.write_snapshot(0)
#w.write
w.evolve(clop)
