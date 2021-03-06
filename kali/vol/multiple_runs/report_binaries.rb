#!/usr/local/bin/ruby -w

require "binary.rb"

class NBody

  def report_binaries(max_semi_major_axis, v)
    print_time_flag = true
    @body.each_index do |i|
      @body.each_index do |j|
        if j > i
          b = Binary.new(@body[i], @body[j])
          if b.rel_energy < 0 and b.semi_major_axis <= max_semi_major_axis
            if @time
              if print_time_flag
                STDERR.printf("  time = %8.3f :", @time)   # to be improved <==
                print_time_flag = false
              else
                STDERR.print "                   "
              end
            end
            acs_log(v, "  [#{i},#{j}] :  ")
            acs_log(v, "a = #{sprintf("%g", b.semi_major_axis)} ; ")
            acs_log(v, "e = #{sprintf("%g", b.eccentricity)} ; ")
            acs_log(v, "T = #{sprintf("%g", b.period)}\n")
          end
        end
      end
    end
  end

end

options_text= <<-END

  Description: Find and report gravitationally bound pairs of stars
  Long description:
    This program accepts Nbody snapshots, and returns information about the
    binaries stars (gravitationally bound pairs of stars) on the stderr output
    channel.  It also echoes each original snapshot on the stdout output
    channel, so that it will be available for another diagnostics program.

    (c) 2004, Piet Hut, Jun Makino; see ACS at www.artcompsi.org

    example:
               kali mkplummer.rb -n 3 | kali #{$0}


  Short name: 		-x
  Long name:            --max_semi_major_axis
  Value type:           float
  Default value:        #{VERY_LARGE_NUMBER}
  Description:          Maximum value of semi major axis
  Variable name:        max_semi_major_axis
  Long description:
    This option allows the user to limit the number of binaries detected
    by discarding binaries with a semi-major axis larger than the specified
    number.  This is useful in situation such as the initial state for a cold
    collapse situation, where every star is formally bound to every other star.


  END

clop = parse_command_line(options_text)

nb = ACS_IO.acs_read
while nb
  raise "class #{nb.class} is not NBody" unless nb.class == NBody
  nb.report_binaries(clop.max_semi_major_axis, clop.verbosity)
  nb.acs_write
  nb = ACS_IO.acs_read
end
