require "rkbody.rb"

include Math

dt = 0.00001           # time step
dt_dia = 10           # diagnostics printing interval
dt_out = 100           # output interval
dt_end = 10           # duration of the integration
#method = "forward"  # integration method
#method = "leapfrog"  # integration method
#method = "rk2"  # integration method
method = "rk4"  # integration method

STDERR.print "dt = ", dt, "\n",
      "dt_dia = ", dt_dia, "\n",
      "dt_out = ", dt_out, "\n",
      "dt_end = ", dt_end, "\n",
      "method = ", method, "\n"

b = Body.new
b.simple_read
b.evolve(method, dt, dt_dia, dt_out, dt_end)
