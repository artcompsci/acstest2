= Testing Forward Euler

== Starting Again

*Bob*: Time to run the driver for our new integrator, which will give
us the energy conservation diagnostics we have been talking about for
so long now!  Let us start with the same variables we used for our
very first forward Euler run:

 :inccode: .euler0a.rb-barebones

We concluded that the position was probably right to within a percent
or so, from comparing it with a more accurate integration.  I'm
curious whether the energy check gives us a similar answer.

 :command: cp -f euler0a.rb test.rb
 :commandoutput: ruby test.rb < euler.in
 :command: rm -f test.rb

*Alice*: Did you set this up?  A relative energy accuracy of
<tex>$0.94\%$</tex>, very close!

*Bob*: That was just pure luck, my argument was only an order of
magnitude estimate.

== Linear Scaling

*Alice*: As we argued, a first-order method like the forward Euler
should converge linearly: making the step size ten times smaller
should decrease the error size also by roughly a factor of ten.
Shall we try?

 :inccode: .euler0b.rb-barebones

*Bob*: So we expect an error of <tex>$0.1\%$</tex> now.  Let's see.

 :command: cp -f euler0b.rb test.rb
 :commandoutput: ruby test.rb < euler.in
 :command: rm -f test.rb

*Alice*: Almost too good: the relative error is now <tex>$0.094\%$</tex>.
It has decreased by the predicted factor ten.  Let's do this:

 :inccode: .euler0c.rb-barebones

making the time step smaller by a jump of a factor a hundred.

 :command: cp -f euler0c.rb test.rb
 :commandoutput: ruby test.rb < euler.in
 :command: rm -f test.rb

*Bob*: And the error comes down by yet another factor ten.  Note that the
integrator halts after exactly 100,000 steps, not one more and not one
less.  Yesterday evening, when I tried it out, it kept overshooting to
100,001 steps, so that was why I added that extra half step in the halting
criteria.

== A Full Orbit

*Alice*: Let's follow your earlier suggestion to do a longer integration,
for ten time units.  And let's use your flexible output options.  I would
like to see four energy diagnostics, but only one final position and
velocity output, so that we don't get too distracted.

*Bob*: That means:

 :inccode: .euler0d.rb-barebones

I have given +dt_out+ a value larger than the total run time +dt_end+,
so we won't get the regular particle poutput, only the diagnostics.

 :command: cp -f euler0d.rb test.rb
 :commandoutput: ruby test.rb < euler.in
 :command: rm -f test.rb

*Alice*: That's funny, a large energy error right away and then the energy
seems to be frozen in.

*Bob*: Ah yes, this was the run where the system exploded, with the
relative distance increasing to a value of about ten.

== Zooming In

*Alice*: And look, the velocity vector is almost parallel to the position
vector, and pointing in the same direction.  Clearly, the two bodies are
escaping from each other.

*Bob*: And that explains why the energy error is frozen: there is no longer
much interaction going on between the particles.  The numerical explosion
must have happened at pericenter, as we deduced earlier.  Let's have a
closer look at what happens in the first part:

 :inccode: .euler0e.rb-barebones

A five times shorter run, with five times more frequent diagnostics.

 :command: cp -f euler0e.rb test.rb
 :commandoutput: ruby test.rb < euler.in
 :command: rm -f test.rb

*Alice*: So the disaster happened between a time of 1 and 1.5.  That must
have been when the first periastron occurred.

== Pericenter Passage

*Bob*: Let's check:

 :inccode: .euler0f.rb-barebones

I'll ask only for particle output, once every quarter time unit:

 :command: cp -f euler0f.rb test.rb
 :commandoutput: ruby test.rb < euler.in
 :command: rm -f test.rb

*Alice*: This is sure hard to read.  It is definitely time to get some form
of graphics going.  This must be how people analyzed the first N-body
calculations, in the sixties!

*Bob*: Yes, we'll get to graphics soon.  But let's do some real lab bench
work here.  Ah!  You see, at time 1.25 the separation of the particles is
clearly smaller than at other times.  That must have been the periastron
passage, roughly.  So the period of the orbit must be 2.5, give or take.

== Apocenter  Passage

*Alice*: Let's check!

*Bob*: We can only check when we use smaller stepsizes, since this one
here is numerically exploding.  Let's try this:

 :inccode: .euler0g.rb-barebones

A ten times smaller step size, and both types of output at time 2.5:

 :command: cp -f euler0g.rb test.rb
 :commandoutput: ruby test.rb < euler.in
 :command: rm -f test.rb

*Alice*: You were right, close to apocenter, the place we started from.
Let's print out the initial conditions for comparison:

 :inccode: euler.in

*Bob*: Close indeed.  But still a larger energy error.  Let's try a ten
times smaller time step.

 :inccode: .euler0h.rb-barebones

 :command: cp -f euler0h.rb test.rb
 :commandoutput: ruby test.rb < euler.in
 :command: rm -f test.rb

*Alice*: Better!  And a linear behavior, with the energy errors getting
ten times smaller.  Let's shrink the time step by one more factor of ten:

 :inccode: .euler0i.rb-barebones

 :command: cp -f euler0i.rb test.rb
 :commandoutput: ruby test.rb < euler.in
 :command: rm -f test.rb

*Bob*: Good.  Another factor ten more accurate.  It is converging slowly
but surely.  And we remain close to apocenter.  I think we have the
situation under control.
