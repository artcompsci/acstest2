require "body.rb"

include Math

dt = 0.01           # time step
dt_dia = 1          # diagnostics printing interval
dt_out = 1          # output interval
dt_end = 1          # duration of the integration

STDERR.print "dt = ", dt, "\n",
      "dt_dia = ", dt_dia, "\n",
      "dt_out = ", dt_out, "\n",
      "dt_end = ", dt_end, "\n"

b = Body.new
b.simple_read
b.evolve(dt, dt_dia, dt_out, dt_end)
