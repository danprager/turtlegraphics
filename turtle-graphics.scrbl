#lang scribble/manual
 
@title{Interactive Turtles}

The intention of this library -- interactive turtle 
graphics -- is two-fold:

@itemlist[@item{to provide a fun toolkit to introduce 
                elementary (Australia/UK: primary) age
                children to programming using a subset of 
                Racket, possibly in the company of their parents.}
           @item{to explore in its implementation
                 some of the simpler ideas of layered languages a la
                 PLAI.}]


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
"microworld" in which the child can instruct the turtle to draw
pictures, simultaneously exploring several mathematical concepts
and gaining a foothold in the world of programming.

@section{Getting started - Surface Syntax}

@codeblock{(require "turtle-graphics.rkt")}



@section{Getting started - Challenges for Kids (and Adults)}

@section{Understanding the Implementation}
 
@section{Extending the Implementation}

@section{Where to from here?}
For children, the Bootstrap project, which enables children
to design and implement their own games in Racket could be
a suitable next step.

For implementors (including parents), Shriram Krishnamurti's
PLAI book and lectures, or possibly head to The Realm of Racket.