# mbody_driver.rb: driver for mbody.rb, which is a
# message passing toy model extension of rkbody.rb
# Douglas and Piet, 2004/4/8-9.

require "mbody.rb"

include Math

eta = 0.1            # accuracy parameter
#dt_dia = 1           # diagnostics printing interval
#dt_out = 1           # output interval
t_end = 1            # time of termination of the integration
#method = "forward"   # integration method
#method = "leapfrog"  # integration method
method = "rk2"       # integration method
#method = "rk4"       # integration method

STDERR.print "eta = ", eta, "\n",
      "dt_end = ", t_end, "\n",
      "method = ", method, "\n"

b = Body.new                  # for now, we assume a new body is born at time 0
b.simple_read
b.propagator(method, eta, t_end)