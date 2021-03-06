require "rknbody8.rb"

include Math

dt = 0.1           # time step
dt_dia = 1           # diagnostics printing interval
dt_out = 10          # output interval
dt_end = 1           # duration of the integration
init_out = false     # initial output requested ?
x_flag = true        # extra diagnostics requested ?
##method = "forward"  # integration method
##method = "leapfrog" # integration method
##method = "rk2"      # integration method
method = "rk4"       # integration method

STDERR.print "dt = ", dt, "\n",
      "dt_dia = ", dt_dia, "\n",
      "dt_out = ", dt_out, "\n",
      "dt_end = ", dt_end, "\n",
      "init_out = ", init_out, "\n",
      "x_flag = ", x_flag, "\n",
      "method = ", method, "\n"

nb = Nbody.new
nb.simple_read
nb.evolve(method, dt, dt_dia, dt_out, dt_end, init_out, x_flag)
