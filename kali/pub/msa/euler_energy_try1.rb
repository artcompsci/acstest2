require "vector.rb"
include Math

def energies(r,v)                     #1
  ekin = 0.5*v*v                      #1
  epot = -1/sqrt(r*r)                 #1
  [ekin, epot, ekin+epot]             #1
end                                   #1

def print_pos_vel(r,v)
  r.each{|x| print(x, "  ")}
  v.each{|x| print(x, "  ")}
  print "\n"
end

def print_diagnostics(r,v,e0)
  ekin, epot, etot = energies(r,v)
  STDERR.print "  E_kin = ", sprintf("%.3g, ", ekin)
  STDERR.print "E_pot = ", sprintf("%.3g; ", epot)
  STDERR.print "E_tot = ", sprintf("%.3g\n", etot)
  STDERR.print "            E_tot - E_init = ", sprintf("%.3g, ", etot-e0)
  STDERR.print "(E_tot - E_init) / E_init = ", sprintf("%.3g\n", (etot-e0)/e0)
end

r = [1, 0, 0].to_v
v = [0, 0.5, 0].to_v
dt = 0.01
e0 = energies(r,v).last               #2

print_pos_vel(r,v)
print_diagnostics(r,v,e0)
1000.times{
  r2 = r*r
  r3 = r2 * sqrt(r2)
  a = -r/r3
  r += v*dt
  v += a*dt
  print_pos_vel(r,v)
}
print_diagnostics(r,v,e0)
