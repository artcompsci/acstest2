require "acs.rb"

class Worldpoint

  TAG = "worldpoint"

  attr_accessor :mass, :pos, :vel, :acc, :jerk, :time, :next_time, :nsteps,
                :minstep, :maxstep, :type

  def initialize
    @nsteps = 0
    @minstep = VERY_LARGE_NUMBER
    @maxstep = 0
  end

  def start_step(wl)
    wl.take_point(@next_time)
  end

  def admin(old_time)
    dt = @time - old_time
    @maxstep = dt if @maxstep < dt
    @minstep = dt if @minstep > dt
    @nsteps = @nsteps + 1
  end

  def finish_step(old_point, snapshot, dt_param, dt_max)
    set_acc_and_jerk_and_next_time(snapshot, dt_param, dt_max)
    correct(old_point)
    admin(old_point.time)
  end

  def set_next_time(snapshot, dt_param, dt_max)
    dt = collision_time_scale(snapshot) * dt_param
    dt = dt_max if dt > dt_max
    @next_time = @time + dt
  end

  def correct(old_point)
    dt = @time - old_point.time
    @vel = old_point.vel + (1/2.0)*(old_point.acc + @acc)*dt +
                           (1/12.0)*(old_point.jerk - @jerk)*dt**2
    @pos = old_point.pos + (1/2.0)*(old_point.vel + @vel)*dt +
                           (1/12.0)*(old_point.acc - @acc)*dt**2
  end

  def set_acc_and_jerk_and_next_time(snapshot, dt_param, dt_max)
    get_acc_and_jerk(snapshot)
    set_next_time(snapshot, dt_param, dt_max)
  end

  def get_acc_and_jerk(snapshot)
    @acc = @jerk = @pos*0                  # null vectors of the correct length
    snapshot.body.each do |b|
      r = b.pos - @pos
      r2 = r*r
      r3 = r2*sqrt(r2)
      v = b.vel - @vel
      @acc += b.mass*r/r3
      @jerk += b.mass*(v-3*(r*v/r2)*r)/r3
    end
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
    0.5*@mass*@vel*@vel
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

  def to_s
    "  mass = " + @mass.to_s + "\n" +
    "   pos = " + @pos.join(", ") + "\n" +
    "   vel = " + @vel.join(", ") + "\n"
  end

  def ppx(body_array)        # pretty print, with extra information (acc, jerk)
    STDERR.print to_s
    a = j = @pos*0              # this repeats the get_acc_and_jerk calculation
    body_array.each do |b|      # above; a kludge for now to get it working,
      unless b == self          # but this should be cleaned up soon.
        r = b.pos - @pos
        r2 = r*r
        r3 = r2*sqrt(r2)
        v = b.vel - @vel
        a += b.mass*r/r3
        j += b.mass*(v-3*(r*v/r2)*r)/r3
      end
    end    
    STDERR.print "   acc = " + a.join(", ") + "\n"
    STDERR.print "   jerk = " + j.join(", ") + "\n"
  end

  def read
    @mass = gets.to_f
    @pos = gets.split.map{|x| x.to_f}.to_v
    @vel = gets.split.map{|x| x.to_f}.to_v
  end

#  def write
#    printf("%24.16e\n", @mass)
#    @pos.each{|x| printf("%24.16e", x)}; print "\n"
#    @vel.each{|x| printf("%24.16e", x)}; print "\n"
#  end

  def extrapolate(t)
    if t > @next_time
      raise "t = " + t.to_s + " > @next_time = " + @next_time.to_s + "\n"
    end
    wp = Worldpoint.new
    wp.minstep = @minstep
    wp.maxstep = @maxstep
    wp.nsteps = @nsteps
    wp.mass = @mass
    wp.time = t
    dt = t - @time
    wp.pos = @pos + @vel*dt + (1/2.0)*@acc*dt**2 + (1/6.0)*@jerk*dt**3
    wp.vel = @vel + @acc*dt + (1/2.0)*@jerk*dt**2
    wp
  end

  def interpolate(other, t)
    wp = Worldpoint.new
    wp.minstep = @minstep
    wp.maxstep = @maxstep
    wp.nsteps = @nsteps
    wp.mass = @mass
    wp.time = t
    dt = other.time - @time
    snap = (-6*(@acc - other.acc) - 2*(2*@jerk + other.jerk)*dt)/dt**2
    crackle = (12*(@acc - other.acc) + 6*(@jerk + other.jerk)*dt)/dt**3
    dt = t - @time
    wp.pos = @pos + @vel*dt + (1/2.0)*@acc*dt**2 + (1/6.0)*@jerk*dt**3 +
             (1/24.0)*snap*dt**4 + (1/120.0)*crackle*dt**5
    wp.vel = @vel + @acc*dt + (1/2.0)*@jerk*dt**2 + (1/6.0)*snap*dt**3 + 
             (1/24.0)*crackle*dt**4
    wp
  end

  def to_acs(precision = 16, base_indentation = 0, additional_indentation = 2)
    subtag = if @type then " "+@type else "" end
    indent = base_indentation + additional_indentation
    return " " * base_indentation + "begin " + TAG + subtag + "\n" +
      nsteps.to_acs("nsteps", precision, indent) + "\n" +
      minstep.to_acs("min. stepsize", precision, indent) + "\n" +
      maxstep.to_acs("max. stepsize", precision, indent) + "\n" +
      mass.to_acs("mass", precision, indent) + "\n" +
      pos.to_acs("position", precision, indent) + "\n" +
      vel.to_acs("velocity", precision, indent) + "\n" +
      " " * base_indentation + "end"
  end

  def write(file = $stdout, precision = 16,
            base_indentation = 0, additional_indentation = 2)
    file.print to_acs(precision, base_indentation, additional_indentation)+"\n"
  end

end

class Worldline

  TAG = "worldline"

  attr_accessor  :worldpoint

  def initialize
    @worldpoint = []
  end

  def startup(era, dt_param, dt_max)
    wp = @worldpoint[0]
    ss = era.take_snapshot(self, wp.time)
    wp.set_acc_and_jerk_and_next_time(ss, dt_param, dt_max)
  end

  def extend(snapshot, dt_param, dt_max)
    old_point = @worldpoint.last
    new_point = old_point.start_step(self)
    new_point.finish_step(old_point, snapshot, dt_param, dt_max)
    @worldpoint.push(new_point)
  end

  def valid_extrapolation?(time)
    raise unless @worldpoint.last.time <= time and
      time <= @worldpoint.last.next_time
  end

  def valid_interpolation?(time)
    raise unless @worldpoint[0].time <= time and
      time <= @worldpoint.last.time
  end

  def valid_time?(time)
    raise unless @worldpoint[0].time <= time and
      time <= @worldpoint.last.next_time
  end

  def take_point(time)
    if time >= @worldpoint.last.time
      valid_extrapolation?(time)
      @worldpoint.last.extrapolate(time)
    else
      valid_interpolation?(time)
      @worldpoint.each_index do |i|
        if @worldpoint[i].time > time
          return @worldpoint[i-1].interpolate(@worldpoint[i], time)
        end
      end
    end
  end

  def next_worldline(time)
    valid_interpolation?(time)
    wl = Worldline.new
    @worldpoint.each_index do |i|
      if @worldpoint[i].time > time
        wl.worldpoint = @worldpoint[i-1...@worldpoint.size]
        break
      elsif @worldpoint[i].time == time
        wl.worldpoint = @worldpoint[i...@worldpoint.size]
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
    wp.acc = wp.pos*0
    wp.jerk = wp.pos*0
  end

  def to_acs
    "Worldline: to_acs not yet implemented"
  end

end

class Worldera

  TAG = "worldera"

  attr_accessor  :start_time, :end_time, # end of container, not necessarily of
                 :worldline, :snap_time  # of the contents, i.e. the worldlines

  def initialize
    @worldline = []
  end

  def startup(dt_param, dt_max)
    worldline.each do |wl|
      wl.startup(self, dt_param, dt_max)
    end
    ss = take_snapshot(nil, @start_time)
    ss.ekin + ss.epot
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

  def evolve(dt_era, dt_param, dt_max, shared_flag)
    nsteps = 0
    @end_time = @start_time + dt_era
    while shortest_interpolated_worldline.worldpoint.last.time < @end_time
      wl = shortest_extrapolated_worldline
      wp = wl.worldpoint.last
      unless shared_flag
        ss = take_snapshot(wl, wp.next_time)
        wl.extend(ss, dt_param, dt_max)
        nsteps += 1
      else
        t = wp.next_time
        @worldline.each do |w|
          w.worldpoint.last.next_time = t
          ss = take_snapshot(w, t)
          w.extend(ss, dt_param, dt_era)
          nsteps += 1
        end
      end
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
        ws.camera_body = s
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

  def write_diagnostics(t, nsteps, initial_energy, x_flag, init_flag = false)
    STDERR.print "at time t = #{sprintf("%g", t)} "
    STDERR.print "(from interpolation after #{nsteps} steps "
    if init_flag
      STDERR.print "to time #{sprintf("%g", @start_time)}):\n"
    else
      STDERR.print "to time #{sprintf("%g", @end_time)}):\n"
    end
    take_snapshot(nil, t).write_diagnostics(initial_energy, x_flag)
  end

#  def read          # for self-documenting data, either Worldera or Snapshot
#  end

  def read_initial_snapshot(dt_era)
    n = gets.to_i
    @start_time = gets.to_f
    @end_time = @start_time + dt_era
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

  def to_acs(precision = 16, base_indentation = 0, add_indentation = 2)
    raise if not valid_time?(@snap_time)
    subtag = if @type then " "+@type else "" end
    indent = base_indentation + add_indentation
    return " " * base_indentation + "begin " + TAG + subtag + "\n" +
      @start_time.to_acs("t_start", precision, indent) + "\n" +
      @end_time.to_acs("t_end", precision, indent) + "\n" +
      @snap_time.to_acs("t", precision, indent) + "\n" +
      take_snapshot(nil, @snap_time).to_acs(precision,indent,add_indentation) +
      "\n"+ " " * base_indentation + "end"
  end

  def write(time, file = $stdout, precision = 16, additional_indentation = 2)
    ACS_Wrapper.new("ACS", ACS_Wrapper.new("DSS",
                  to_acs(time))).write(file, precision, additional_indentation)
  end

end

class World

  TAG = "world"

  def evolve(c)
    dt_max = c.dt_era * c.dt_max_param
    initial_energy = @era.startup(c.dt_param, dt_max)
    time = @era.start_time
    nsteps = 0
    @era.write_diagnostics(time, nsteps, initial_energy, c.x_flag, true)
    t_dia = time + c.dt_dia
    t_out = time + c.dt_out
    t_end = time + c.dt_end
    @era.write_snapshot(time) if c.init_out
    while @era.start_time < t_end
      @new_era, dn = @era.evolve(c.dt_era, c.dt_param, dt_max,
                                 c.shared_flag)
      nsteps += dn
      while t_dia <= @era.end_time and t_dia <= t_end
        @era.write_diagnostics(t_dia, nsteps, initial_energy, c.x_flag)
        t_dia += c.dt_dia
      end
      while t_out <= @era.end_time and t_out <= t_end
#        @era.write_snapshot(t_out)
        @snap_time = @era.snap_time = t_out               # KLUDGE !!!
        write($stdout, c.precision, c.add_indent)
        t_out += c.dt_out
      end
      @old_era = @era
      @era = @new_era
    end
  end

  def read_initial_snapshot(c)
    @era = Worldera.new
    @era.read_initial_snapshot(c.dt_era)
  end

  def write_snapshot(time)
    @era.write_snapshot(time)
  end

  def to_acs(precision = 16, base_indentation = 0, add_indentation = 2)
    subtag = if @type then " "+@type else "" end
    indent = base_indentation + add_indentation
    return " " * base_indentation + "begin " + TAG + subtag + "\n" +
      @era.to_acs(precision,indent,add_indentation) +
      "\n"+ " " * base_indentation + "end"
  end

  def write(file = $stdout, precision = 16, additional_indentation = 2)
    ACS_Wrapper.new("ACS", ACS_Wrapper.new("DSS",
                    self)).write(file, precision, 0, additional_indentation)
  end

end

class Worldsnapshot

  TAG = "worldsnapshot"

  attr_accessor :camera_body, :body, :type

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

#  def write
#    @body.each do |b|
#      b.write
#    end
#  end

  def to_acs(precision = 16, base_indentation = 0, add_indentation = 2)
    nsteps = 0
    @body.each{|b| nsteps += b.nsteps}
    subtag = if @type then " "+@type else "" end
    indent = base_indentation + add_indentation
    return " " * base_indentation + "begin " + TAG + subtag + "\n" +
      @body.size.to_acs("N", precision, indent) + "\n" +
      nsteps.to_acs("nsteps", precision, indent) + "\n" +
      @body.map{|b| b.to_acs(precision,indent,add_indentation)}.join("\n") +
      "\n"+ " " * base_indentation + "end"
  end

  def write(file = $stdout, precision = 16,
            base_indentation = 0, additional_indentation = 2)
    file.print to_acs(precision, base_indentation, additional_indentation)+"\n"
  end

end

options_text= <<-END

  Description: Individual Time Step Hermite Code
  Long description:
    This program evolves an N-body code with a fourth-order Hermite Scheme,
    using individual time steps.  Note that the program can be forced to let
    all particles share the same (variable) time step with the option -a.

    This is a test version, for the ACS data format

    (c) 2004, Piet Hut, Jun Makino, Murat Kaplan; see ACS at www.artcompsi.org

    example:
    ruby mkplummer3.rb -n 5 | ruby #{$0} -t 1


  Short name: 		-c
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


  Short name: 		-m
  Long name:		--max_timestep_param
  Value type:		float
  Default value:	1
  Variable name:	dt_max_param
  Description:		Maximum time step in units of dt_era
  Long description:
    This option sets an upper limit to the size dt of a time step,
    as the product of the duration of an era and this parameter:
    dt <= dt_max = dt_era * dt_max_param .


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


  Short name:		-a
  Long name:  		--shared_timesteps
  Value type:  		bool
  Variable name:	shared_flag
  Description:		All particles share the same time step
  Long description:
    If this flag is set to true, all particles will march in lock step,
    all sharing the same time step.


  Short name:           -p
  Long name:            --precision
  Value type:           int
  Default value:        16
  Description:          Floating point precision
  Variable name:        precision
  Long description:
    The precision with which floating point numbers are printed in the output.
    The default precision is comparable to double precision accuracy.


  Short name:           -n
  Long name:            --indentation
  Value type:           int
  Default value:        2
  Description:          Incremental indentation
  Variable name:        add_indent
  Long description:
    This option allows the user to set the incremental indentation, i.e.
    the number of white spaces added in front of the output of data, for
    each level that the data are removed from the top level.

    Starting at zero indentation at the level of the top ACS structure,
    one set of incremental indentation is added for each level down,
    from ACS to DSS, from DSS to World, and so on.


  END

clop = parse_command_line(options_text, true)

w = World.new
w.read_initial_snapshot(clop)               # for now; "read" w. self-doc. data
#w.write_snapshot(0)
#w.write
w.evolve(clop)
