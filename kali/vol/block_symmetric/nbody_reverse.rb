#!/usr/local/bin/ruby -w

require "nbody.rb"

options_text= <<-END

  Description: takes an N-body system, and reverses the sign of all velocities
  Long description:
    This program takes an N-body system, and changes the sign of
    the velocities of all particles.  This is a useful tool to test
    time symmetric codes: by reversing the velocities, and continuing
    a run for the same amount of time, a time symmetric code should
    let each particle return to the original starting point.

    (c) 2007, Piet Hut, Jun Makino; see ACS at www.artcompsi.org

    example:
    kali #{$0} < run1.out > run1.rev


  END

c = parse_command_line(options_text)

class Body
  def reverse_velocity
    @vel = -@vel
  end
end

class NBody
  def reverse_velocities
    @body.each{|x| x.reverse_velocity}
    self
  end
end

ACS_IO.acs_read(NBody).reverse_velocities.acs_write
