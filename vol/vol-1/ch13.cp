= Leapfrog

== The Basic Equations

*Alice*: Hi, Bob!  Any luck in getting a second order integrator to work?

*Bob*: No problem, it was easy!  Actually, I got two different ones to
work, and a fourth order integrator as well.

*Alice*: Wow, that was more than I expected!

*Bob*: Let's start with the second order leapfrog integrator.

*Alice*: Wait, I know what a leapfrog is, but we'd better makes some
notes about how to present to idea to your students.  How can we do
that quickly.

*Bob*: Let me give it a try.  The name <i>leapfrog</i> comes from one
of the ways to write this algorithm, where positions and velocities
`leap over' each other.  Positions are defined at times
<tex>$t_i, t_{i+1}, t_{i+2}, \dots $</tex>, spaced at constant intervals
<tex>$dt$</tex>, while the velocities are defined at times halfway in
between, indicated by <tex>$t_{i-1/2}, t_{i+1/2}, t_{i+3/2}, \dots $</tex>,
where <tex>$t_{i+1} - t_{i + 1/2} = t_{i + 1/2} - t_i = dt / 2$</tex>.
The leapfrog integration scheme then reads:

<tex>\begin{eqnarray}
{\bf r}_{i} & = & {\bf r}_{i-1} + {\bf v}_{i-1/2} dt \nonumber \\
{\bf v}_{i+1/2} & = & {\bf v}_{i-1/2} + {\bf a}_i dt \nonumber
\end{eqnarray}</tex>

Note that the accelerations <tex>${\bf a}$</tex> are defined only on integer
times, just like the positions, while the velocities are defined only on
half-integer times.  This makes sense, given that
<tex>${\bf a}({\bf r}, {\bf v}) = {\bf a}({\bf r})$</tex>:
the acceleration on one particle depends only on its position with respect
to all other particles, and not on its or their velocities.  Only at
the beginning of the integration do we have to set up the velocity at
its first half-integer time step.  Starting with initial conditions
<tex>${\bf r}_0$</tex> and  <tex>${\bf v}_0$</tex>,
we take the first term in the Taylor series expansion to compute the
first leap value for <tex>${\bf v}$</tex>:

<tex>$$
{\bf v}_{i+1/2} = {\bf v}_i + {\bf a}_i dt / 2.
$$</tex>

We are then ready to apply the first equation above to compute
the new position <tex>${\bf r}_1$</tex>, using the first leap value for
<tex>${\bf v}_{1/2}$</tex>.
Next we compute the acceleration <tex>${\bf a}_1$</tex>, which enables us
to compute the second leap value, <tex>${\bf v}_{3/2}$</tex>, using the
second equation above, and then we just march on.

A second way to write the leapfrog looks quite different at first sight.
Defining all quantities only at integer times, we can write:

<tex>\begin{eqnarray}
{\bf r}_{i+1} & = & {\bf r}_i + {\bf v}_{i} dt + 
{\bf a}_{i} (dt)^2/2                                  \nonumber \\
{\bf v}_{i+1} & = & {\bf v}_i + ({\bf a}_i +
{\bf a}_{i+1})dt / 2                                  \nonumber
\end{eqnarray}</tex>

This is still the same leapfrog scheme, although represented in a
different way.  Notice that the increment in <tex>${\bf r}$</tex> is
given by the time step multiplied by
<tex>${\bf v}_{i} dt + {\bf a}_{i} / 2$</tex>, effectively
equal to <tex>${\bf v}_{i+ 1/2}$</tex>.  Similarly, the increment in
<tex>${\bf v}$</tex> is given by the time step multiplied by
<tex>$({\bf a}_i + {\bf a}_{i+1}) / 2$</tex>, effectively equal to the
intermediate
value <tex>${\bf a}_{i+1/2}$</tex>.  In conclusion, although both
positions and velocities are defined at integer times, their
increments are governed by quantities approximately defined at
half-integer values of time.

== Time reversibility

*Alice*: A great summary!  I can see that you have taught numerical
integration classes before.  At this point an attentive student might
be surprized by the difference between the two descriptions, which you
claim to describe the samen algorithm.  They may doubt that they really
address the same scheme.

*Bob*: How would you convince them?

*Alice*: An interesting way to see the equivalence of the two descriptions
is to note the fact that the first two equations are explicitly
time-reversible, while it is not at all obvious whether the last two
equations are time-reversible.  For the two systems to be equivalent,
they'd better share this property.  Let us inspect.

Starting with the first set of equations,
even though it may be obvious, let us write out the time reversibility.
We will take one step forward, taking a time step <tex>$+dt$</tex>,
to evolve <tex>$\{{\bf r}_i, {\bf v}_{i-1/2}\}$</tex> to
<tex>$\{{\bf r}_{i+1}, {\bf v}_{i+1/2}\}$</tex>, and then we
will take one step backwards, using the same scheme, taking a time
step <tex>$-dt$</tex>.  Clearly, the time will return to the same value since
<tex>$+dt-dt=0$</tex>, but we have to inspect where the final positions and
velocities <tex>$\{{\bf r}_f(t=i), {\bf v}_f(t=i-1/2)\}$</tex> are
indeed equal to their initial values
<tex>$\{{\bf r}_i, {\bf v}_{i-1/2}\}$</tex>.  Here is the
calculation, resulting from applying the first set of equation twice:

<tex>\begin{eqnarray}
{\bf r}_f & = & {\bf r}_{i+1} - {\bf v}_{i+1/2} dt \nonumber \\
      & = & \left[ {\bf r}_i + {\bf v}_{i+1/2} dt \right]
            - {\bf v}_{i+1/2} dt \nonumber \\
      & = & {\bf r}_i \nonumber \\
                  \nonumber \\
{\bf v}_f & = & {\bf v}_{i+1/2} - {\bf r}_i dt \nonumber \\
      & = & \left[ {\bf v}_{i-1/2} + {\bf a}_i dt \right]
            - {\bf a}_i dt \nonumber \\
      & = & {\bf v}_{i-1/2} \nonumber
\end{eqnarray}</tex>

In an almost trivial way, we can see clearly that time reversal causes
both positions and velocities to return to their old values, not only
in an approximate way, but exactly.  In a computer application, this
means that we can evolve forward a thousand time steps and then evolve
backward for the same length of time.  Although we will make
integration errors (remember, leapfrog is only second-order, and thus
not very precise), those errors will exactly cancel each other, apart
from possible round-off effects, due to limited machine accuracy.

Now the real fun comes in, when we inspect the equal-time version, the
second set of equations you presented:

<tex>\begin{eqnarray}
{\bf r}_f & = & {\bf r}_{i+1} - {\bf v}_{i+1} dt + 
{\bf a}_{i+1} (dt)^2/2 \nonumber \\
      & = & \left[ {\bf r}_i + {\bf v}_i dt + {\bf a}_i (dt)^2/2 \right]
            - \left[ {\bf v}_i + ({\bf a}_i + {\bf a}_{i+1})dt / 2 \right] dt
            + {\bf a}_{i+1} (dt)^2/2 \nonumber \\
      & = & {\bf r}_i \nonumber \\
                  \nonumber \\
{\bf v}_f & = & {\bf v}_{i+1} - ({\bf a}_{i+1} + {\bf a}_i)dt / 2  \nonumber \\
      & = & \left[ {\bf v}_i + ({\bf a}_i + {\bf a}_{i+1})dt / 2 \right]
            - ({\bf a}_{i+1} + {\bf a}_i)dt / 2  \nonumber \\
      & = & {\bf v}_i  \nonumber
\end{eqnarray}</tex>

In this case, too, we have exact time reversibility.  Even though not
immediately obvious from an inspection of your second set of
equations, as soon as we write out the effects of stepping forward and
backward, the cancellations become manifest.

*Bob*: A good exercise to give them.  I'll add that to my notes.

== A New Driver

*Alice*: Now show me your leapfrog, I'm curious.

*Bob*: I wrote two new drivers, each with its own extended +Body+ class.
Let me show you the simplest one first.  Here is the leapfrog driver:

 :inccode: integrator_driver1.rb

Same as before, except that now you can choose your integrator.
The method +evolve+, at the end, now has an extra parameter,
namely the integrator.

*Alice*: And you can supply that parameter as a string, either
"forward" for our old forward Euler method, or "leapfrog" for your
new leapfrog integrator.  That is very nice, that you can treat
that choice on the same level as the other choice you have to make
when integrating, such as time step size, and so on.

*Bob*: And it makes it really easy to change integration method:
one moment you calculate with one method, the next moment with another.
You don't even have to type in the name of the method: I have written
it so that you can switch from leapfrog back to forward Euler with two
key strokes: you uncomment the line that now starts with
<tt>#method = "forward"</tt> and comment out the line that now starts
with <tt>method = "leapfrog"</tt>.

*Alice*: I'm curious to see how you let Ruby make that switch.  

== An Extended Body Class

*Bob*: Here is the new version of our +Body+ class, in a file called
<tt>lbody.rb</tt> with +l+ for leapfrog.  It is not much longer than 
the previous file <tt>body.rb</tt>, so let me show it again in full:

 :inccode: lbody.rb

== Minimal Changes

*Alice*: Before you explain to me the details, remember that I challenged
you to write a new code while changing or adding less than a doze lines?
How did you fare?

*Bob*: I forgot all about that.  It seemed so unrealistic at the time.
But let us check.  I first corrected this mistake about the mass factor
that I had left out in the file <tt>body.rb</tt>.  Then I wrote this
new file <tt>lbody.rb</tt>.  Let's do a diff:

    |gravity> diff body.rb
    11c11
    <   def evolve(dt, dt_dia, dt_out, dt_end)
    - -
    >   def evolve(integration_method, dt, dt_dia, dt_out, dt_end)
    22c22
    <       evolve_step(dt)
    - -
    >       self.send(integration_method,dt)
    36c36
    <   def evolve_step(dt)
    - -
    >   def acc
    39c39,42
    <     acc = @pos*(-@mass/r3)
    - -
    >     @pos*(-@mass/r3)
    >   end    
    > 
    >   def forward(dt)
    43a47,52
    >   def leapfrog(dt)
    >     @vel += acc*0.5*dt
    >     @pos += @vel*dt
    >     @vel += acc*0.5*dt
    >   end
    >
    |gravity> 

To wit: four lines from the old code have been left out, and eleven
new lines appeared.

*Alice*: Only eleven!  You did it, Bob, less than a dozen, indeed.

*Bob*: I had not realized that the changes were so minimal.  While
I was playing around, I first added a whole lot more, but when I
started to clean up the code, after it worked, I realized that most of
my changes could be expressed in a more compact way.

*Alice*: Clearly Ruby <i>is</i> very compact.

*Bob*: Let me step through the code.
