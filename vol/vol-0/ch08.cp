=  Environment

== A Toolbox

*Alice*: Now that we know what we want to model, we have to address
the question of the environment in which we want to work.

*Bob*: You mean what type of computer hardware, or operating system,
or computer language?

*Alice*: All of these questions need to be addressed, and they are
general concerns for any software projects.  However, in our particular
case there is also the question of how to get data in and out of our
integrator, and how to analyze the results.

*Bob*: Of course, you have to produce some initial conditions,
and you want to look at the results, but basically we are dealing with
one big program, and a bunch of small ad hoc programs, which could be
some shell scripts or whatever you can put together quickly.  The main
point is to provide the students with a robust integrator.  The rest
they can take care of themselves.

*Alice*: But what about standard questions, such as deriving the
potential energy for each particle, and the local density around
each particle.  You almost always want to know those quantities.
Wouldn't it be better to build separate programs to compute those?

*Bob*: It would be much better to make that part of the integrator.
The potential will already be calculated at regular intervals anyway,
to provide accuracy diagnostics.  And it wouldn't be too difficult to
built in a density estimator as well.

*Alice*: Combining everything into one big program has been the
traditional approach for a long time, but it is far from optimal.
What I would prefer, certainly for a student demonstration project, is
to provide something that is more like a toolbox.  I'm happy to let
the calculation of quantities such as potential energy be done in the
integrator, as part of the necessary on-the-fly analysis.  But in
addition, I would want to have a separate stand-alone program that can
compute the potential as well.

*Bob*: Why?

*Alice*: Imagine that you want to calculate the total mass of a bound
subsystem within a larger N-body system.  You take the whole system,
and remove the particles that our not bound to the subsystem.  Perhaps
you want to iterate a few times, removing more particles until you
really have a self-gravitating subsystem.  At that point you may want
to check virial equilibrium, so you have to calculate the kinetic and
potential energy of all particles.

*Bob*: That makes sense.  And come to think of it, when you then want
to calculate Lagrangian radii, it may be nice for the students to have
yet another little program to do just that.  Ah, we can follow the way
of the Unix system: a large number of small tools, where you can pipe
the results from one tool into the next one.

*Alice*: That would be one example of what I had in mind, but it is not
the only one.  There are other ways of combining a number of small tools.
However, this type of decision we can make later.  The main thing now
is to agree upon the general approach: to provide a number of simple
tools that can be used together to analyze the results of a calculation.

*Bob*: Fair enough.  But you started out talking about choices we have
to make with respect to the software environment.  I thought you would
talk about operating systems and languages and stuff like that.  In
short: what type of platform do we run our toy model integrator and
toolbox on?

== Operating System

*Alice*: Given that we are both used to working in Unix, there is not
much of a question, as for as the operating system goes.  Most of my
work I do on a laptop, running Linux.

*Bob*: me too, but that is not necessarily true for most of the students.
If we do not make our environment available for Windows and for the Mac,
we may not have much of an audience.

*Alice*: I have no experience at all, porting software to a different
platform.

*Bob*: I have some.  For example, putting stuff on a Mac is not that
hard, after they switched to Unix as the underlying environment.  As
for windows, a lot of the GNU tools have been ported there as well.
If you use cygwin, basically any program written for Unix is likely
to work.

*Alice*: Can you just type gcc and expect to find a GNU compiler,
under cygwin?

*Bob*: Yes, you can.

*Alice*: Amazing.  And how about emacs?

*Bob*: Yes, emacs is there, as well as all the standard Unix commands
and programs.

*Alice*: Does that mean that when we develop our toy model under Linux,
we can make a tar ball, copy that to a machine running Windows and
cygwin, untar it, and expect everything to work right away?

*Bob*: Well, you can be lucky, but realistically speaking, you'll have
to test it first, and you may well find some minor problems here and
there.  But of course, if you would switch from one Unix system to
another, you would also have to make minor adjustments.

*Alice*: I know.  Even switching from one Linux distribution to another
has given me plenty of surprises in the past.  Often it was just a
question of tools being stored in different places.

*Bob*: Yes, but that's no big deal, and easy to fix.

*Alice*: For you perhaps, but if I had to do that myself I might be
stuck for hours, without someone more experienced to help me.  Well,
I'm glad we're doing this project together.  I'll count on you to
do what you call the easy things.

*Bob*: We aim to please!

== Choosing a Language

*Bob*: Finally we will have to make the decision which programming
language to use.  I have no strong preference among Fortran, C, or
C++.  They all have their strengths and weaknesses.  C is nice and
fast and straightforward.  Fortran has by now caught up with C quite
well, after lagging behind for a long time in a lack of appropriate
date structures.  C++ is an unwieldy beast of a language, but if you
use an appropriate subset, and you don't try to become a language
lawyer dealing with multiple inheritance and all that stuff, it's a
good tool; it's fast enough, and you don't look at the unreadable
stuff the compiler produces.  Your choice: which of the three?

*Alice*: Perhaps none of the above?

*Bob*: Huh?  Do you want to use Cobol?  Or Lisp?  Too late for Pascal,
I'm afraid.

*Alice*: Frankly, I'd love to use Lisp, or the dialect Scheme to be more
precise, but don't worry; I know that most non-Lispers have an aversion
to too many parentheses.  While I love the language, I don't have the
illusion that I can single-handedly convert a critical mass fraction
of the astrophysics community to start writing and thinking in terms
of lambda calculus.

*Bob*: What calculus?

*Alice*: Forget I said that.  No, I'm not thinking about Lisp or other
more traditional languages.  Rather, I have been considering using a
scripting language.

*Bob*: You mean Perl?

*Alice*: Perl is one example of a scripting language, but there are others.

*Bob*: I've heard many good things about Perl.  I've never used it myself,
but I, too, have been thinking more and more about learning it.  There
are just too many times that I feel hampered by the limitations of C
shell scripts, or whatever similar shells you can use in Unix.  A
little awking and grepping will help you in making C shell script more
powerful, to analyze the output from N-body codes, for example.  But
still, I could easily be convinced to use Perl instead.  I know several
colleagues who swear by it.

*Alice*: I wasn't thinking about Perl.  Nor Python.

*Bob*: Ah yes, Python, I couldn't remember the name, just now.  What's
the difference with Perl?

*Alice*: It's object oriented, like C++ but less unwieldy.

*Bob*: Hmm, that I like.  I've grown quite fond of using classes in C++,
for the types of problems where I know what I want to do.  It would be
nice to have a more playful language in which to prototype classes,
and throw them away if you don't like them, without having to redeclare
everything all over the place to make the gods of the C++ compiler happy.

*Alice*: Exactly, that was my thought.  So given the two, I would prefer
Python.  But in fact, there is another choice, even better in my eyes.
It is called Ruby.

*Bob*: Never heard of it.  What's the difference with Perl and Python?

*Alice*: Since it was developed after Perl and Python had already come
into being, the author of the language, Yukihiro Matsumoto, had the
advantage of being able to learn from his experience with those other
two languages.  It is in fact more fully object oriented than Python.
It has iterators and all kind of neat stuff.  And very importantly,
it is simple and natural.  It seems to be build on what is called the
principle of least surprise: immediately after you get a quick and
rough familiarity with Ruby, you will be able to guess in most cases
what a given expression will do.  That sounds like a strong claim, but
I know several computer science friends who have told me that this is
really the case.

*Bob*: Well, since I have never yet learned any scripting language, I
don't care which one I will learn.  You choose.

*Alice*: Same for me, it will be my first one too.  Okay, let's take Ruby.
It is freely available on the web, all fully open source, and there
are already a number of good books available.  The fist book to
introduced it in the English language is in fact fully available on the
web, so we can get started immediately.

*Bob*: Okay, Ruby it will be.

*Alice*: I'll have to warn you, though: a scripting language is slower
than a compiled language.  Ruby especially: besides being an interpreted
language, almost everything goes through two layers of indirection, which
makes for a marvelous flexibility, but a large penalty in
performance.

*Bob*: There you go again, choosing flexibility over performance.  But
this time I don't care, as long as we have agreed to write only a toy
model.  My students will be slower in understanding stellar dynamics
than the computer will be in running their programs, even if they are
ten times slower.

*Alice*: Hmm, would you settle for a hundred times slower?

*Bob*: What?!?  Surely you're joking!

*Alice*: I'm not joking.  But the good news is: Ruby defines a way to
interface with C code.  So you can write the most time-critical part
of a code directly in C, if you want to make your code run faster.

*Bob*: That sounds much better already.  But as long as we want students
to study the cold collapse of, say, a 25-body system, we can even live
with a factor of 100.  What do I care?  People ran 25-body systems
back in the sixties, when computers where much more than a million
times slower than they are now, so we can loose a couple zeroes in
factors of speed.  And it will prevent you from ever claiming that
your toy model have much to do with the reality of production runs!

*Alice*: We'll see about that.

== Graphics

*Bob*: One more thing to decide, that is just as essential as choosing
an operating system and a programming language.  We have to pick a
plotting package.  The students must have a way to display the results
of their calculations on the screen, and also a good way to print the
pictures they produce.

*Alice*: I am using pgplot for my own work.  That seems to be doing all
that I want, normally.

*Bob*: Same here.  I have some familiarity with Matlab, as well as a
number of other packages, but none of them are open source.  And since
we decided to go the route of free software, we cannot rely on
proprietary packages.  So pgplot would be a reasonable choice.
However, I'm not hundred percent sure that it is open source.

*Alice*: No?  I was convinced it was open source.  I've never paid
for it, or signed any license.

*Bob*: I know.  But when I checked on their web site, it was not really
clear to me what their status was.  Yes, they are open source in the
sense that their source is open: you have free access to all the
source code.  However, in their case this does not automatically imply
that you can distribute it freely to third parties.

*Alice*: That would be inconvenient.  It would be far easier if we can
bundle our own environment together with the libraries that we invoke.
And graphics will indeed form an essential part of our whole package.
Are you sure we can't make it available?  If we and everybody else can
copy it freely from the web, what difference would it make if we put
up our own copy?

*Bob*: That's the point: not everybody can pick it up freely.  If you
read the fine print, you will see that it is only really free for
educational purpose.

*Alice*: That may be good enough for us, since we are only dealing
with students.

*Bob*: For our classes, yes, we can make pgplot available.  But it seems
that we cannot make it available on the web, since anybody can access
our web site, also people who are not officially within the educational
sphere.

*Alice*: In that case, we can put a pointer on our web site to the
place where one can pick up the source code.  That's not as convenient
as providing everything in a bundled way, though.

*Bob*: I know.  They have a line on their web site, saying that you
can only copy their software to your web site after getting official
permission from them.  Right now may be premature, but once we have a
reasonable package installed on our web site, we may want to send
them an email, asking for permission to put a copy of pgplot directly
on our web site.

*Alice*: That seems like a good idea.  Are there any alternatives?

*Bob*: The only thing I can think of is Gnuplot, but I have found pgplot
to be far more convenient for scientific plotting.

*Alice*: I have tried Gnuplot too, and I agree.  So let's at least get
started with pgplot.  But here is an idea.  Since we may want to switch
to a different graphics package in the future, it would be very unpleasant
if we then had to translate all pgplot commands into the equivalent
commands in that other package.  We could instead define our own
virtual plotting commands, and write a simple wrapper to translate them
into a subset of pgplot commands that is large enough for our purposes.

*Bob*: Well, I don't like all those extra layers of code, and I'm afraid
I've already given you too much leeway with your interface demands.  Why
not just write everything in pgplot for now.  If and when we switch to
a different plotting package, only then do we write a wrapper that
emulates pgplot.

*Alice*: But it might be a lot of work to write a wrapper around a
whole package.  If we decide right from the beginning to use only a
small subset of pgplot, and if we keep a list of the commands we use,
we only have to write a wrapper around those commands, not around the
whole package.  Finally, the best way to insure that we really don't
use anything else but our small list of commands is to give each
command we use an alias.  That way we cannot make any mistakes.

*Bob*: If a very good function is available in pgplot, why not use it?

*Alice*: Oh, it would be fine to add extra functions to our list of what
we use.  We can certainly extend the subset, whenever we like.  My main
point is that we keep close tabs on exactly what we use, and that we think
carefully, before adding something to the subset.

*Bob*: The problem with providing a virtual layer between the user and
pgplot is that we have to make a decision of what type of plotting model
we want to use.  Even if we restrict ourselves to two dimensional plots,
there are several models.  For example, in postscript you deal  directly
with a set of coordinates on paper, in terms of inches.  And other
graphics packages provide transformations between model coordinates,
often called world coordinates, and device coordinates.  So we are dealing
with a situation that is much more complex than just providing a set of
aliases.

*Alice*: I see.  Well, perhaps you are right.  Maybe it would be okay to
go ahead with pgplot for now.  But let us come back to this question
before too long, after we have build a skeleton version of our toy model.
By that time, we might have a better idea of how fancy our requirements
will turn out to be.

*Bob*: I'm glad I could finally convince you not to add an extra layer
of software somewhere.  So now we can finally get started?
