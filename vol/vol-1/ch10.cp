= Diagnostics

== Evolve

*Bob*: You are familiar already with the accessor shorthand that gives read
and write handles to the internal variables for the mass, position,
and velocity, as well as with the initialization method, that uses our
nifty vector class.

The first new function is +evolve+, the one function that the driver
program invokes, and that guides all the work.  Here it is, by itself:

 :inccode: .body.rb+evolve

*Bob*: At the top, it sets two counters to zero.  One is +time+, which
measures how the simulated time during wchich the two-body motion is
integrated, so that the calculation can be halted properly after an
amount of time equal to <tt>dt_end</tt> has passed.  The other is
+nsteps+, the number of time steps that the system has taken.  I keep
track of that, since I like to know how much work the code has done,
at any given point.

*Alice*: With a constant time step, you could also divide the total
integration time by the step size.

*Bob*: Of course, but in future codes we'll soon switch to variable
time steps, in which case you have no independent way of knowing how
many steps the code took.  So we may as well get into the habit of
reporting that number.

*Alice*: In the third line you introduce a variable.  What is it
doing there, all by itself?  It looks a bit lonely and lost.

== Brevity and Modularity

*Bob*: Ah, the brevity of Ruby!  <tt>e_init</tt> is not a variable, it is a
method, in other words a function or subroutine, depending on your
dialect.

*Alice*: Without parentheses?

*Bob*: Without parentheses!  This is a method without arguments.
So why put parentheses around nothing?

*Alice*: But in any language I have worked with, if a fuction
<tt>do_something</tt> has no arguments, you still have to invoke it with
<tt>do_something()</tt>, or <tt>call do_something</tt>.  Otherwise how
will the compiler know that
it is dealing with a function, sorry, method, rather than a variable?

*Bob*: The compilers of the languages you are familiar with cannot.
But here we are dealing with a really _smart_ language.

*Alice*: You mean the Ruby compiler can figure out . . . 

*Bob*: . . . the Ruby interpreter, you mean . . .

*Alice*: . . . ah yes, the Ruby interpreter, how can it figure out
when a name stands for a variable and when it stands for a method?

*Bob*: Ruby will look around within the proper context, in this case
within the body of the class definition we are in . . .

*Alice*: . . . the body of +Body+ you mean . . . 

*Bob*: . . . yes, names can get confusing, even for human interpreters.
And the Ruby interpreter will then see a statement <tt>def e_init</tt>,
and will realize that the name <tt>e_init</tt> belongs to a method.

*Alice*: How elegant.

*Bob*: Indeed.  Of course, you are perfectly free to write <tt>e_init()</tt>
instead, if you like, but I prefer brevity.  So this third line of +evolve+
invokes the methode <tt>e_init</tt> below.  We'll look at that in a moment, but
all it does is to compute the total energy of the system at the beginning
of a run, and stores the value in an internal variable, so that we can
compare the energy at a later time with the initial value, to see how much
the energy has drifted.

The next line invokes the method <tt>write_diagnostics</tt>, which does
exactly what its name says.  It has two arguments, +nsteps+ and +time+,
since those two counters have been defined locally within the body of
the +evolve+ method, and therefore they are not visible outside that
method.  I want <tt>write_diagnostics</tt> to write those numbers as well, so
I have to pass them explicitly.

*Alice*: You could of course have defined them as internal variables
for the +Body+ class, how did you call them again?  Ah, instance variables.

*Bob*: Yes, but that would be confusing and potentially dangerous.  The
+Body+ class is growing bigger now, so I don't like to have an unnecessary
proliferation of internal variables that float around inside, visible for
every function.  Debugging then becomes much harder.  There is a reason
that the human body has cells and that cells have cell walls and that
within a cell there is the membrane around the nucleus as well as a variety
of other compartmentalized structures.

*Alice*: See, that is what I mean when I insist on modular programming.

*Bob*: If so, I agree with you on this level.  The problem I had with your
earlier descriptions was that you seemed to want to compartmentalize on
higher levels as well.  I am glad that each cell of my body does not share
its contents with every other cell.  But I would be unhappy if my left hand
would not know what my right hand would be doing.  And even though I don't
like to put my foot in my mouth, I'm glad I have the freedom to do so!

*Alice*: We'll come back to that.  For now, I'm glad we're in agreement
about modularity on a local level.  While creating larger programs, we will
move up to more global issues, and there we can fight things out with
concrete examples.  Meanwhile, I'll try not to tease you any longer about
modularity.  This code looks already as modular as you can ask for.

== Keeping Time

*Bob*: Moving right along, we see three lines of assignment.  Here I set
up a book keeping process that will tell us when we need to take some
action other than integrating.  The variable <tt>t_dia</tt> stores the
next time at which we want to report energy diagnostics.  Initially we
set it equal to the time interval between diagnostics output, which is
<tt>dt_dia</tt>.  Later on during the integration, there may be many
times at which you want to see the energy being reported.  Each time
that is done, the variable <tt>t_dia</tt> is updated to the subsequent
diagnostics output time, as we will see in a moment.  So first we have
a trivial looking <tt>t_dia = dt_dia</tt>, but after the first output
<tt>t_dia</tt> will be changed to <tt>2dt_dia</tt>, then to
<tt>3dt_dia</tt>, and so on, until the integration finishes.

*Alice*: Except that there is this extra term <tt>- 0.5*dt</tt>.

*Bob*: Ah, I have added that because the time variables are all floating
point numbers.  So when we make a comparison between the actual time
+time+ and the time <tt>t_dia</tt> at which you want to have an output done,
it is possible that the actual time is still ever so slightly smaller
than the time for the next scheduled output.  In that case, the
integrator will happily take another step.  But when you then change
the time step, the second run will stop at a different place.  This
will make it difficult to compare the results between two different
runs: are the final particle positions different because the
integrations have different accuracy or because one of the two
calculations happened to overshoot?  Subtracting half a time step
guarantees that the system is ready to trigger an output call, already
half a time step before the predicted time.  Whether the system lands
exactly on the predicted time or slightly before or after, in all cases
it will halt at the right time.  The reason is that floating point round
off occurs typically in the fifteenth decimal or so, so the error is
far smaller than any conceivable time step.

*Alice*: I'm glad you thought about that.

*Bob*: In a similar way, the variable <tt>t_out</tt> stores the time at which
the next particle output will be done, <i>i.e.</i> the time at which
we print the mass, position, and velocity of the relative motion.  The
mass will not change, of course, although we could introduce mass
losing stars or even exploding stars at some point later on.  But the
position and velocity will change, as we have seen.  Sometimes we may
be interested in getting frequent output of these numbers, for example
when we will make a movie of a particle motion, as we will do soon.
At other occasions we may be more interested in studying the energy
drift with a fine comb.  So by having <tt>dt_out</tt> and
<tt>dt_dia</tt> as free dials to determing the output frequency of of
positions and velocities on the one hand, and the energy on the other
hand, gives us a lot of flexibility.

The variable <tt>t_end</tt> is similar to the other two I just
discussed, except that it will not be updated during the integration:
when <tt>t_end</tt> is first reached, that will be the end . . .

*Alice*: . . . of a single call to +evolve+.  I presume that you can give
repeated calls to the +evolve+ method, from your driver, if you chose to
do so.

*Bob*: Indeed.  But each time you invoke +evolve+, everything starts from
scratch again within the body of +evolve+; the +evolve+ method itself has
no idea whether it has been called before or not.  It just does its thing,
starting with what it thinks is time zero.

*Alice*: So if you call +evolve+ twice, the time is set back to zero
in between.

*Bob*: For now, yes.  That just was the simplest way to implement it.
Time is used here only internally, for bookkeeping during a single
invocation of +evolve+.  Of course, I could have introduced a time
variable on the level of the driver.  But then I would have to pass
that also to +evolve+ and I thought that four arguments was enough for
a first attempt.  Anything can be made arbitrarily complex quickly, and
I like to keep things simple.

*Alice*: That makes a lot of sense.  So all we have left to look at within
+evolve+ is the +while+ loop, which keeps track of time.  When the time
+time+ exceeds the value of <tt>t_end</tt>, the method stops and control is
handed back to the driver, which called +evolve+.

*Bob*: Indeed.  And the first thing that happens is a call to
<tt>evolve_step</tt>.  Like +evolve+, it integrates the orbit of our
particle, but only for one step.

*Alice*: Divide and conquer.

*Bob*: Yes, the level of +evolve+ is pure management; all the footwork is
down by <tt>evolve_step</tt>, step for step.

== More Brevity

*Alice*: In the next line, the time gets updated, by the amount of time
that was spent while stepping our particle forward by one step, and
similarly the +nsteps+ counter is increased by one.  I see what happens
next.  Unless there is an immediate need to do a form of output, for
energy of particle positions and velocities, we just move on.  And in
those cases where you do an output, you immediately schedule the next
output, by increasing the future output time by the corresponding output
interval.

*Bob*: Indeed.  And that's it!  Then next method we have seen before:

 :inccode: .body.rb+evolve_step

Newton in action: the acceleration is calculated and both position and
velocity are updated.

*Alice*: Using this coordinate-free notation.  I love it.  It is so compact!
Like a minicar that you love to drive in a crowded city.

*Bob*: Wait till you get to the diagnostics method, you'll love that even
more.  But first we have three short methods.  The first two calculate
the kinetic and potential energy for the relative motion:

 :inccode: .body.rb+ekin

 :inccode: .body.rb+epot

*Alice*: You can just read them off, kinetic energy quadratic in velocity,
potential energy proportional to inverse distance.  Wonderful.  One-liners
are great.

*Bob*: Note that both +ekin+ and +epot+ are methods, not variables, just
like the method we already saw earlier, <tt>e_init</tt>:

 :inccode: .body.rb+e_init

As long as this function is called responsibly, <i>i.e.</i> only at
the beginning of the integration, the internal variable <tt>@e0</tt>
will be set to the initial sum of the kinetic and potential energy, in
other words to the total initial energy.

*Alice*: That is funny, that you can just add +ekin+ and +epot+, as if
they were variables, even though they are really functions.

== Ruby Smiling

*Bob*: Yes, but as I promised you, it is getting even better.  Look at the
first line in the method that does the output for our energy diagnostics:

 :inccode: .body.rb+write_diagnostics

*Alice*: It reads <tt>etot = ekin + epot</tt>.  Yes, of course, the total
energy is the sum of the kinetic and potential energy.  But wait, the
first variable +etot+ must be a local variable, local to the body of the
method <tt>write_diagnostics</tt>, while +ekin+ and +epot+ are methods.  That
is remarkable!  It seems as if we are freely mixing nouns and verbs,
and yet everything looks so natural, and I presume it does the right
thing.

*Bob*: It does, yes, I did test it.

*Alice*: How _very_ elegant!

*Bob*: I knew you would like this line in particular.  And I was wondering
what grandiose philosophical explanation you would connect with it.

*Alice*: Easy!  It shows that Ruby is a natural kind of language, almost
a natural language.  In English, you mix nouns and verbs in one sentence
without having to think at the start of each sentence how to connect them.
You just talk, because you have become familiar with them.  In contrast,
in a language like C++ you can `talk' in it for years, and still you have
to look up the rules of the game, each time you do something new.  I've
never felt a natural familiarity with C++, no matter how much I have used
it.  And here, how can you not love Ruby, with <tt>etot = ekin + epot</tt>
smiling at you!

*Bob*: You have a point there, Ruby does feel comfortable, like a natural
language, or an old shoe.

*Alice*: You're mixing metaphors, but I know what you mean.  Well, let's
see what you did with the total energy that you so magically created.
You are sending something to the standard error stream, yes?

*Bob*: That's what you would call it in C++, indeed.  We have seen that
+print+ directs output to the standard output stream, by default.  But
by calling +STDERR+ 's +print+ method, we are now sending the string
that follows it to the standard error stream.

*Alice*: Why do you send positions and velocities to the standard ouput
channel, and the energy diagnostics to the error channel?  Because you
expect errors in your energy?

*Bob*: Very funny.  No, because I may want to separate the two streams,
later on.  In order to make a graphics movie, for example, we could
output the positions every timestep, or every ten time steps or so.
If we then would ask for energy diagnostics only occasionally, the
diagnostics information would get completely lost in the middle of all
that other ouput.  Besides, the graphics reader could get confused,
if it expected only particle data.

Of course you can work around all that with a little awking and grepping,
but it is cleaner to separatings things right at the start.  In that way,
you can redirect the standard output to a file, while letting the
diagnostics appear on your screen.  Or you can put both types of
output into separate files.

*Alice*: I agree completely.  You are locally modular!  I won't tease
you anymore.

*Bob*: Only praise me?  That's fine, that I don't mind at all.

== A Here Document

*Alice*: While I get the idea of what you want to print out, in the
statement starting with <tt>STDERR.print</tt>, I'm completely confused
by what follows on the next few lines.  Here, let me have the keyboard,
and let me at least properly indent it, it hurts my eyes.

*Bob*: No, stop, don't do that!  It has a meaning.

*Alice*: Meaning?

*Bob*: I'm glad emacs has an undo.  Yes, meaning.  The funny symbols
<tt><<END</tt> indicate the beginning of what is called a "here document".

*Alice*: As opposed to a "there document"?

*Bob*: It is really called like that, and for a simple reason: everything
that is here, in between <tt><<END</tt> and <tt>END</tt> is interpreted
as one long string, and that string is the taken as the argument for the
<tt>STDERR.print</tt> command.

*Alice*: What are the backslash symbols <tt>\\</tt> doing there at the end
of the second and third line?

*Bob*: They indicate that the next line should continue after the previous
line.  Without them, each of the three lines starting with
<tt>E_kin</tt>, <tt>E_pot</tt>, and <tt>E_tot</tt>, would appear on
separate lines, and I prefer to have them appearing on one line of the
output.  So I have to escape the first two of the three new-line
characters at the end of those three lines.

*Alice*: I think I get the idea.  Basically the print command gobbles up
everything it see until it comes across the magic word +END+ and then it
stops.

*Bob*: Effectively, yes, but more precisely speaking the print command
itself doesn't know about here documents.  The symbol <tt><<END</tt>
is what causes the rest up to +END+ to be formed into a string.  Then
that string, once formed, is what the print command sees.  Here, let
me show you.  Ruby invites you not to take anything on faith, since it
is so easy to test things for yourself.  When it doubt, test it out!

    |gravity> irb --prompt short_prompt -r vbody1.rb
    001:0> <<END
    002:0" this is special string,
    003:0" for Alice, from Bob.
    004:0" END
    "this is special string,\nfor Alice, from Bob.\n"
    005:0> s = <<END
    006:0" here is another string,
    007:0" with another new-line in the middle
    008:0" END
    "here is another string,\nwith another new-line in the middle\n"
    009:0> print s
    here is another string,
    with another new-line in the middle
    nil
    010:0> print <<END
    011:0" as you can see, and END in the middle does not really end
    012:0" the here document.
    013:0" END
    as you can see, and END in the middle does not really end
    the here document.
    nil
    014:0> print <<END
    015:0" Also, no space is allowed beteen << and END,
    016:0" as I will show in a moment
    017:0" END
    Also, no space is allowed beteen << and END,
    as I will show in a moment
    nil
    018:0> << END
    SyntaxError: compile error
    (irb):18: syntax error
    << END
      ^
    	from (irb):18

*Alice*: It should be called a mountain document, with all that echoing;
or better even a valley document, in between those two mountainous ENDs.

*Bob*: Well, the remaining four methods are the ones we've seen before,
we this is the end of the guided tour.  Pretty pretty, hey?

*Alice*: Yes, very, apart from the here document.  I still think that
looks ugly, but I see that you have no choice.

*Bob*: The basic question is: do you want pretty code of pretty output.
In this case you can't have both.

*Alice*: I guess in that case I prefer pretty output.  But speaking of
output, I haven't seen anything yet.  You said you've tested the code,
and it really works?

*Bob*: I'll show you.


