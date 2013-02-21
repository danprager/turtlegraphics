#lang scribble/manual
 
@title{Interactive Turtles}

The intention of this library -- interactive turtle 
graphics -- is two-fold:

@itemlist[@item{to provide a fun toolkit to introduce 
                elementary (Australia/UK: primary) age
                children to programming from within Dr Racket, 
                ideally in the company of a suitably 
                geeky parent or mentor.}
           @item{to explore in its implementation
                 some of the simpler ideas of layered languages 
                 a la PLAI.}]


@section{Motivation: Why Turtle Graphics?  Why Racket?}

The choice of turtle graphics in Racket is in the tradition of
Seymour Papert's Logo language and Microworlds, and more recently 
the MIT Scratch project.  Papert's idea was to provide children 
with a low bar to entry, but no ceiling on achievement.

@margin-note{@bold{My motivation}: when I was a teenager and getting my first
computer an old friend of my father advised me to ``learn
Pascal, rather than Basic''.  With my own children, I wanted to 
start with a Lisp (i.e. Racket), but the current materials are 
not aimed at the under-10 set, so this project is my first 
attempt to lower the age bar.}

Modern child-oriented languages like Scratch and Alice
have much to commend them, but I fear that they may be subject to the
cultural trap that Logo fell into, of becoming perceived as
child-@italic{only} languages, with a sharp discontinuity when
make the leap to mainstream languages.

Why not instead give them the keys to the kingdom of Racket /
Scheme / Lisp, and aim for a smoother learning curve?

Turtle graphics provide children with a self-contained, concrete
``microworld'' in which the child can instruct the turtle to draw
pictures, simultaneously exploring several mathematical concepts
and gaining a foothold in the world of programming.

@section{Getting started - an interactive visual guide}

This package is designed to be used interactively from within Dr Racket.

From the interactive prompt type

@codeblock{(require "turtle-graphics.rkt")}
@(require "turtle-graphics.rkt")

and press <Enter>.

@subsection{Basic commands}
The basic commands control the turtle and output a new image interactively:

@codeblock{(clear)} Clear the world:
@(clear)

@codeblock{(fd 50)} Move the turtle forward 50 pixels, 
leaving a trail:
@(fd 50)

@codeblock{(rt 90)} Turn right 90 degrees:
@(rt 90)

@codeblock{(color 'red)} Change the color of the turtle's pen: 
takes effect when the turtle next draws.
@(color 'red)

@codeblock{(fd 50)} Move the turtle back 100 pixels, 
leaving a trail:
@(bk 100)

@codeblock{(lt 225)} Turn left 225 degrees:
@(lt 225)

@codeblock{(hop 150)} Hop forward 150 pixels (no trail):
@(hop 150)

@codeblock{(hop-bk 200)} Hop backward 200 pixels (no trail):
@(hop-bk 200)

@subsection{Interactive commands}
@codeblock{(undo)} Undo the previous command.  You can undo as
many times as there are steps to undo.  Undo (and redo) are 
vital in-so-far as they allow the child to experiment, and
make mistakes as they learn:
@(undo)

@codeblock{(redo)} Redo the previous command.  Reverse of undo.
@(redo)

@codeblock{(show-program)} Print a listing of the commands 
so far:
@codeblock{'((fd 50) 
             (rt 90) 
             (color red) 
             (bk 100) 
             (lt 225) 
             (hop 150) 
             (hop-bk 200))}

This is especially useful in allowing a child to build up
a sequence of commands interactively, then copy them into
Dr Racket's definition window for saving / turning into a
subroutine.

@subsection{Advanced commands}

@codeblock{(repeat 3 (fd 100) (rt 120))}
The repeat command repeats a sequence of commands. 
In this example the effect of going forward then turning right
120 degrees three times is to draw a triangle:
@(repeat 3 (fd 100) (rt 120))

@codeblock{(set-turtle 'girl)}
@(set-turtle 'girl)
The set-turtle command changes the appearance of the turtle.
A pink @bold{'girl} and a choo-choo @bold{'train} are the 
out-of-the-box alternatives to the default, literal 
@bold{'turtle}.

@codeblock{(redraw)}
@(redraw)
Redraws the current image with the current turtle:

@codeblock{(movie)}
Animates the drawing so far in a separate window.

TODO: Get an animated gif in here!

@subsection{Defining your own commands}

@codeblock{
  (def (colored-square c pix)
    (color c)
    (repeat 4 (lt 90) 
              (fd pix)))}
@(def (colored-square c pix)
    (color c)
    (repeat 4 (lt 90) 
              (fd pix)))

Use def to capture a sequence of commands and give them a name.
This is how the child extends the language beyond the basic 
commands.

Once you have defined a new command you can use it:

@codeblock{(colored-square 'green 75)}
@(colored-square 'green 75)

Some out-of-the-box defs are provided:

@codeblock{(centered-square 100)}
@(begin
   (set-turtle 'turtle)
   (reset)
   (centered-square 100))

@codeblock{(centered-circle 50)}
@(begin
   (reset)
   (centered-circle 50))

@codeblock{(polygon 5 50)}
@(begin 
   (reset)
   (polygon 5 50))

@margin-note{Square, circle and half-polygon are also pre-defined.}

@section{Getting started - Challenges for Kids (and Adults)}

@subsection{Simple activities}
@itemlist[@item{Draw some simple shapes: rectangles, triangles, squiggles}
          @item{Experiment with colors}
          @item{Draw a zig-zaggy line}
          @item{Draw a simple house}
          @item{Draw a cartoony cat}
          @item{Draw the same cat five times}
          @item{Draw a stick figure person}
          @item{Draw a star}
          @item{Draw a brick wall}
          @item{Experiment with mirror images}
          @item{Experiment with rotated images}]

@subsection{Draw your name}
@(require "jake.rkt")
Start by figuring out a single letter, for example J:
@codeblock{
(def (J)
  (rt 180) 
  (fd 100)
  (half-polygon 100 2.5)
  (hop 103)
  (rt 90)
  (hop 25)
  (fd 100))}

@codeblock{(J)}
@(begin 
   (reset)
   (repeat 1
           (hop 75)
           (J)))

And work your way up to your whole first name.  Example:

@codeblock{(JAKE)}
@(begin
   (reset)
   (JAKE))

@section{Understanding the Implementation}

First of all, run the code.  Secondly, read it.  
There are some tests at the end that give the gist of what the
main transformations -- desugar, resugar, optimize, and 
partition -- do.

@subsection{Types}

In terms of types there is a higher-level, sugared language:
@codeblock{(define-type exprS
             [fdS (pixels number?)]
             [bkS (pixels number?)]
             [hopS (pixels number?)]
             [hop-bkS (pixels number?)]
             [rtS (degrees number?)]
             [ltS (degrees number?)]
             [colorS (color image-color?)]
             [repeatS (n integer?) (commands list?)]
             [compositeS (name list?) (commands list?)])}

that is desugared into the simpler core language:

@codeblock{(define-type exprC
             [fdC (pixels number?)]
             [hopC (pixels number?)]
             [rtC (degrees number?)]
             [colorC (color image-color?)]
             [no-opC])}

@bold{define-type} is defined in the untyped PLAI language, 
from Shriram Krishnamurti's book and video lectures on
Programming Languages and their Interpretation.

Note that the language as it stands is fairly impoverished.
For example commands -- notwithstanding the use of (repeat ...) 
are fully expanded -- without recourse to function calls or
variables.  

@subsection{State}

Global state consists of a list of sugared actions or
@bold{*steps*} together with a @bold{*redo-stack*};
@bold{*turtles*} stores 360 rotated images of the current
turtle; and @bold{*world*} captures the current drawn image and the
coordinates and orientation of the turtle.

Movies create and maintain their own state.

@subsection{Miscellany}
One of the design goals was
to provide an undo / redo that works unsurprisingly: an earlier
incarnation of this code would require 8 undos to undo a call
to a (square), which was inconvenient and unwieldy for a child
to use.  Another goal was to allow the child to experiment
interactively, then list the program in order to capture it
and copy into Dr Racket's interaction window.

At the user level there's some macrology to get from the 
interactive prompt to the sugared language.

One interesting aspect of the core language is that commands
are executed directly for interactivity, but 
@bold{(partition)}ed for timing purposes when making a 
@bold{(movie)}.

@section{Extending the Implementation}

Fork the git repository and extend away!

@subsection{Transformation}
Because the language is so simple, other explorations are 
possible, probably most easily done at the core language level.
Examples:
@itemlist[@item{A non-destructive transformation could allow
                the turtle to create the image via a different
                route series of steps}
          @item{More creative transformations could take
                a series of steps and vary them to give
                an effect to the image}]


@subsection{Extensions}

The core and sugared languages could stand some enrichment.  
Some ideas:
@itemlist[@item{bit-blt to color in sections}
          @item{some way to vary the length of the turtle's
                steps, to scale drawing up and down}
          @item{save/load an image}
          @item{save an animation as an animated gif}
          @item{show text}
          @item{interactive help}
          @item{make a scaled down``picture book'' of all
                the steps in the drawing, or the last few
                steps, together with state information, as 
                an aid to debugging}]
           
@section{Where to from here?}
For children, the Bootstrap project, which enables children
to design and implement their own games in Racket could be
a suitable next step.

For implementors (including parents), Shriram Krishnamurti's
PLAI book and lectures, or possibly head to The Realm of Racket.