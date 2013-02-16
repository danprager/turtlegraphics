;; LICENSE: See License file LICENSE (MIT license)
;;
;; Repository: https://github.com/danprager/turtlegraphics
;;
;; Copyright 2013: Daniel Prager
;;                 daniel.a.prager@gmail.com

; TODO:
; * more documentation
; * more examples
; * define as a PLaneT packagege
; * set-as-exercise: show-frame-by-frame
; * extensions: fill (bit-blt)

#lang racket

(require rackunit)
(require (only-in plai
                  define-type
                  type-case))

(require 2htdp/universe)
(require (only-in racket/draw read-bitmap))
(require (rename-in 2htdp/image
                    (color set-color)
                    (polygon im-polygon)
                    (square im-square)
                    (circle im-circle)))  

(provide fd bk hop hop-bk rt lt
         repeat
         color
         undo redo
         clear reset
         set-turtle
         redraw
         movie
         show-program
         def
         square centered-square 
         circle centered-circle 
         polygon half-polygon)

;; Sugared language: exprS
;;
;; The high-level, internal representation of programs for
;; our turtles.  Desugared into the core language: exprC
;;
(define-type exprS
  [fdS (pixels number?)]
  [bkS (pixels number?)]
  [hopS (pixels number?)]
  [hop-bkS (pixels number?)]
  [rtS (degrees number?)]
  [ltS (degrees number?)]
  [colorS (color image-color?)]
  [repeatS (n integer?) (commands list?)]
  [compositeS (name list?) (commands list?)])

;; As the user enters commands in the repl, the *steps*
;; are recorded.  These may be undone via (undo) and
;; redone via (redo).
(define *steps* '())      ; The program listing in reverse order
(define *redo-stack* '()) ; Used to enable redos of undone commands

;; Each time a repeat or function is entered [exited] the level
;; of nesting increments [decrements]
;;
(define *nesting* 0)      
(define (nested?) (positive? *nesting*))
(define (nest) (set! *nesting* (add1 *nesting*)))
(define (un-nest) (set! *nesting* (sub1 *nesting*)))

;; Redraws the current world
;;
(define (redraw)
  (when (not (nested?))
    (show-turtle-on *world*)))

;; Add a step to *steps* and optionally clear the redo-stack
;;
(define (add-step expr #:clear-redo [clear-redo #t])
  (set! *steps* (cons expr *steps*))
  (when clear-redo
    (set! *redo-stack* '()))
  (set! *world* (draw (desugar (list expr)) *world*))
  (redraw))

;; Undo the last command
;;
(define (undo)
  (cond [(null? *steps*) "Nothing to undo."]
        [else (set! *redo-stack* 
                    (cons (first *steps*) *redo-stack*))
              (set! *steps* (rest *steps*))
              (set! *world* 
                    (draw (optimize (desugar *steps*)) 
                          (make-world)))
              (show-turtle-on *world*)]))

;; Redo the last command
;;
(define (redo)
  (if (null? *redo-stack*) 
      "Nothing to redo."
      (let ([step (first *redo-stack*)])
        (set! *redo-stack* (rest *redo-stack*))
        (add-step step #:clear-redo #f))))

;; Print out an executable representation of the current turtle
;; instructions.  Maps back from the sugared language to the 
;; user-level syntax.
;;
(define (show-program [steps *steps*])
  (reverse
   (map (λ (s)
          (type-case exprS s
            [fdS (px) `(fd ,px)]
            [bkS (px) `(bk ,px)]
            [hopS (px) `(hop ,px)]
            [hop-bkS (px) `(hop-bk ,px)]
            [rtS (dg) `(rt ,dg)]
            [ltS (dg) `(lt ,dg)]
            [colorS (c) `(color ,c)]
            [repeatS (n cmd) `(repeat ,n ,@(show-program cmd))]
            [compositeS (nm cmd) nm])) steps)))

;; Define new commands with (def proc-name arg ...)
;; rather than define.  
;;
;; (def ...) is a macro that generates a (define ...), 
;; hooking up the machinery of the sugared language to 
;; generate a suitable compositeS structure.
;;
(define-syntax-rule (def (proc-name arg ...) body ...)
  (define (proc-name arg ...)
    (if (nested?)
        (compositeS (list 'proc-name arg ...)
                    (list body ...))
        (begin
          (nest)
          (add-step (compositeS (list 'proc-name arg ...)
                                (list body ...)))
          (un-nest)
          (redraw)))))

;; Define user-level syntax.  Straightforward mapping to
;; sugared language from sexps.  
;; 
;; E.g. (fd pixels) -> (fdS pixels)
;;
;; Uses add-step to achieve interactivity when not nested.
;;
(define-syntax-rule (declare-primitive (name arg) nameS)
  (define (name arg)
    ((if (nested?) 
         identity 
         add-step) (nameS arg))))

(declare-primitive (fd pixels) fdS)
(declare-primitive (bk pixels) bkS)
(declare-primitive (hop pixels) hopS)
(declare-primitive (hop-bk pixels) hop-bkS)
(declare-primitive (rt degrees) rtS)
(declare-primitive (lt degrees) ltS)
(declare-primitive (color c) colorS)


;; Repeat one or more drawing instructions n times.
;;
(define-syntax-rule (repeat n cmds ...)
  (begin
    (when (< n 1) 
      (error 'repeat 
             "Can't repeat less than once."))
    (let ([result 'undefined])
      (nest)
      (set! result (repeatS n (list cmds ...)))
      (un-nest)
      ((if (nested?) identity add-step) result))))

;; Draw a regular, n-sided polygon with side-length side,
;; turning right.
;;
(def (polygon n side)
  (repeat n
          (fd side)
          (rt (/ 360 n))))

;; Draw half of an n-sided polygon with side-length side,
;; turning right.
;;
(def (half-polygon n-sides side-length)
  (repeat (half n-sides)
          (fd side-length)
          (rt (/ 360 n-sides))))
  
(define (half x) (/ x 2))

;; Draw a circle -- really a polygon with side-length of
;; roughly two pixels -- of specified radius, turning right.
;;
(def (circle radius)
  (let* ([circumference (* 2 pi radius)]
         [sides (exact-round (half circumference))])
    (polygon sides (/ circumference sides))))

;; Draw a square with side-length side, turning right.
;;
(def (square side)
  (polygon 4 side))

;; Draw a square with side-length side, centered on the current
;; turtle location.
;;
(def (centered-square side)
  (hop (half side))
  (rt 90)
  (fd (half side))
  (repeat 3 
          (rt 90)
          (fd side))
  (rt 90)
  (fd (half side))
  (lt 90)
  (hop-bk (half side)))

;; Draw a circle centered on the current turtle location.
;;
(def (centered-circle radius)
  (hop radius)
  (rt 90)
  (circle radius)
  (lt 90)
  (hop-bk radius))

;; Core (de-sugared language)
;;
(define-type exprC
  [fdC (pixels number?)]
  [hopC (pixels number?)]
  [rtC (degrees number?)]
  [colorC (color image-color?)]
  [no-opC])

;; desugar : list(exprS) -> list(exprC)
;;
(define (desugar exps)
  (define (R n cmd)
    (if (zero? n) 
        '()
        (append cmd (R (sub1 n) cmd))))
  (define (D exps)
    (map (λ (x) (type-case exprS x
                  [fdS (px) (fdC px)]
                  [bkS (px) (fdC (- px))]
                  [hopS (px) (hopC px)]
                  [hop-bkS (px) (hopC (- px))]
                  [rtS (dg) (rtC dg)]
                  [ltS (dg) (rtC (- dg))]
                  [colorS (c) (colorC c)]
                  [repeatS (n cmd) 
                           (R n (D (reverse cmd)))]
                  [compositeS (nm cmd) (D (reverse cmd))]))
         exps))
  (flatten (D exps)))
        
;; resugar : list(exprC) -> list(exprS)
;;
(define (resugar exps)
  (define (by-sign arg posS negS)
    (case (sgn arg)
      [(1) (posS arg)]
      [(-1) (negS (- arg))]
      [else #f]))
  
  (filter-map (λ (x) (type-case exprC x
                       [fdC (px) (by-sign px fdS bkS)]
                       [hopC (px) (by-sign px hopS hop-bkS)]
                       [rtC (dg) (by-sign dg rtS ltS)]
                       [colorC (c) (colorS c)]
                       [no-opC () #f]))
              exps))
             
;; optimize : list(exprC) -> list(exprC)
;;
;; Removes no-opCs and concatenates adjacent fdCs, hopCs and rtCs
;; iff their arguments have the same sign.
;;
(define (optimize exps)
  (letrec ([try-to-merge (λ (last head tail opC opC-arg)
                           (let ([a (opC-arg last)]
                                 [b (opC-arg head)])
                             (if (= (sgn a) (sgn b))
                                 (O (opC (+ a b)) tail)
                                 (construct last head tail))))]
           [is-null-op? (λ (op) (type-case exprC op
                                  [no-opC () #t]
                                  [colorC (c) #f]
                                  [fdC (px) (= px 0)]
                                  [hopC (px) (= px 0)]
                                  [rtC (dg) (= dg 0)]))]
           [construct (λ (last head tail)
                        (if (is-null-op? last)
                            (O head tail)
                            (cons last (O head tail))))]
           [O (λ (last exps)
                (cond [(null? exps) (if (is-null-op? last) 
                                        '() 
                                        (list last))]
                      [else (let ([head (first exps)]
                                  [tail (rest exps)])
                              (cond 
                                [(is-null-op? head) (O last tail)]
                                [(andmap fdC? (list last head))
                                 (try-to-merge last head tail
                                               fdC fdC-pixels)]
                                [(andmap hopC? (list last head))
                                 (try-to-merge last head tail
                                               hopC hopC-pixels)]
                                [(andmap rtC? (list last head)) 
                                 (try-to-merge last head tail
                                               rtC rtC-degrees)]
                                [else (construct last head tail)]))]))])
    (O (no-opC) exps)))

;;
;; Core language facilities, including interpreter
;;

;; Options for the visible representation of the turtle.
;; 
(define *turtle-image* (read-bitmap "./turtle.png"))
(define *pink-girl-image* (read-bitmap "./pink-girl.png"))
(define *train-image* (read-bitmap "./train.png"))
(define *turtles* 'undefined)

;; Choose a particular turtle image and pre-compute 360
;; rotations: 1 per degree.
;;
(define (set-turtle im)
  (let ([turtle-image
         (case im 
           ['girl *pink-girl-image*]
           ['train *train-image*]
           [else *turtle-image*])])
    (set! *turtles* 
          (build-vector 360 (λ (n) (rotate (modulo (- 360 90 n) 360) 
                                           turtle-image))))))
                                
(set-turtle 'turtle)    ; Default to an image of a turtle

;; A "world" consists of an image, a pen, x,y-coordinates of the
;; turtle, and a heading (an angle) for the turtle.
;;
(struct world (image pen x y heading))

;; Default dimensions of the world's image.
;;
(define *default-width* 500)
(define *default-height* 250)

;; Specify an empty, initial world.
;;
(define (make-world
         [w *default-width*]
         [h *default-height*]
         [pen 'black]
         [x (/ w 2)]
         [y (/ h 2)]
         [heading -90])
  (world (empty-scene w h) pen x y heading))

(define *world* (make-world))

;; Reset the world, without redrawing
(define (reset)
  (set! *steps* '())
  (set! *world* (make-world)))

;; Clear the world, and the set of steps that build up the 
;; current image.
;;
(define (clear)
  (set! *steps* '())
  (set! *world* (make-world))
  (show-turtle-on *world*))

; turtle-angle : world -> radians 
;
(define (turtle-angle w)
  (degrees->radians (world-heading w)))

;; fd-x : world, number -> number 
;;
;; What would the new x-coordinate of the turtle in world w be if
;; it advanced w pixels?
(define (fd-x w pixels)
  (+ (world-x w) (* pixels (cos (turtle-angle w)))))

;; fd-y : world, number -> number 
;;
;; What would the new y-coordinate of the turtle in world w be if
;; it advanced w pixels?
(define (fd-y w pixels)
  (+ (world-y w) (* pixels (sin (turtle-angle w)))))

;; show-turtle-on : world -> image
;;
;; Superimpose a suitable turtle on the current world image
(define (show-turtle-on w)
  (letrec ([fix-angle (lambda (a)
                        (if (>= a 0) a (fix-angle (+ a 360))))]
           [heading 
            (modulo (fix-angle (exact-round (world-heading w)))
                    360)])
    (place-image (vector-ref *turtles* heading)
                 (world-x w) (world-y w) (world-image w))))

;; draw : list(exprC) world -> world
;;
;; Interpret the steps (in reverse order) and apply them to the world
;;
(define (draw steps world)
  (foldr (λ (s w) (interp s w)) world steps))

;; interp : exprC world -> world
;;
(define (interp expr w)
  (let ([image (world-image w)]
        [pen (world-pen w)]
        [x1 (world-x w)]
        [y1 (world-y w)]
        [heading (world-heading w)])
    (type-case exprC expr
      [fdC (px) (let ([x2 (fd-x w px)]
                      [y2 (fd-y w px)])
                  (world (scene+line image x1 y1 x2 y2 pen)
                         pen x2 y2 heading))]
      [hopC (px) (world image pen (fd-x w px) (fd-y w px) heading)]
      [rtC (dg) (world image pen x1 y1 (+ heading dg))]
      [colorC (c) (world image c x1 y1 heading)]
      [no-opC () w])))
 
;; Parameters for animating the turtle, walking and turning
;; speeds, and fps.
;;
(define *pixels-per-tick* 4)   ; How fast can the turtle walk?
(define *degrees-per-tick* 8)  ; How fast can the turtle rotate?
(define *tick-rate* 1/24)

;; partition : list(exprC) number number -> list(list(exprC))
;;
;; partition a list of steps into a sequence of frames
(define (partition steps [pixels-per-tick 6] [degrees-per-tick 12])
  (define (ticks e)
    (type-case exprC e
      [no-opC () 0]
      [colorC (c) 0]
      [fdC (px) (/ (abs px) pixels-per-tick)]
      [hopC (px) (/ (abs px) pixels-per-tick)]
      [rtC (dg) (/ (abs dg) degrees-per-tick)]))
  
  (define (linear-split opC arg r t)
    (let* ([x (* arg (/ r t))]
           [a (if (> (abs x) 0.99) 
                  (exact-round x) 
                  x)])
      (list (opC a) (list (opC (- arg a))))))
  
  (define (split r t a)
    (if (= r t)
        (list a '())
        (type-case exprC a
          [fdC (px) (linear-split fdC px r t)]
          [hopC (px) (linear-split hopC px r t)] 
          [rtC (dg) (linear-split rtC dg r t)]
          [else (error 'partition "Error in split")])))

  (let P ([time-remaining 1.0]
          [frame '()]
          [steps steps])
    (if (null? steps) 
        (list (reverse frame))
        (let* ([a (first steps)]
               [r (rest steps)]
               [t (ticks a)])
          (if (< t time-remaining)
                (P (- time-remaining t) (cons a frame) r)
                (let ([s (split time-remaining t a)])
                  (cons (reverse (cons (first s) frame))
                        (P 1.0 '() (append (second s) r)))))))))


;; Animate the current series of steps.
;;
(define (movie)
  (letrec ([steps ((compose reverse partition optimize desugar)
                   *steps*)]
           [world (make-world)]
           [next-frame (λ (image)
                         (when (not (null? steps))
                           (let ([frame-steps (first steps)])
                             (set! steps (rest steps))
                             (set! world
                                   (draw frame-steps world))))
                         (world-image world))]
           [show-frame (λ (image)
                         (show-turtle-on world))])
  
    (big-bang (world-image world)
              (on-tick next-frame *tick-rate*)
              (on-draw show-frame)
              (name "turtle-graphics"))))


;; TESTS
;;

; show-program
;
(check-equal?
 (show-program
  (list (fdS 10) (bkS 10) (hopS 10) (hop-bkS 10) 
        (rtS 90) (ltS 90) (colorS 'blue)))
 '((color blue) (lt 90) (rt 90) (hop-bk 10) 
                (hop 10) (bk 10) (fd 10)))

(check-equal?
 (show-program 
    (list
     (repeatS 4 (list (fdS 90) (rtS 90)))
     (compositeS '(equilateral 100)
                 (list (fdS 100) (rt 120)
                       (fdS 100) (rt 120)
                       (fdS 100) (rt 120)))))
 '((equilateral 100) 
   (repeat 4 (rt 90) (fd 90))))

; desugar
;
(check-equal? 
 (desugar 
  (list (fdS 10) (bkS 10) (hopS 10) (hop-bkS 10) 
        (rtS 90) (ltS 90) (colorS 'blue))) 
 (list (fdC 10) (fdC -10) (hopC 10) (hopC -10)
       (rtC 90) (rtC -90) (colorC 'blue)))

(check-equal? 
 (desugar
  (list (repeatS 2 (list (hopS 50) (fdS 100) (rtS 90)))))
 (list (rtC 90) (fdC 100) (hopC 50) 
       (rtC 90) (fdC 100) (hopC 50)))

; resugar
;
(check-equal?
 (resugar 
  (desugar
   (list (repeatS 2 (list (hopS 50) (fdS 100) (rtS 90))))))
 (list (rtS 90) (fdS 100) (hopS 50)
       (rtS 90) (fdS 100) (hopS 50)))

; optimize
;
(check-equal?
 (optimize (list (fdC 10) (fdC 10) (fdC 10)
                 (fdC -10) (fdC -10)
                 (hopC 20) (hopC 30)
                 (hopC -1) (hopC -1) (hopC 0) (hopC -97)
                 (rtC 90) (rtC 90)
                 (rtC -90) (rtC -90)))
           (list (fdC 30) (fdC -20) 
                 (hopC 50) (hopC -99)
                 (rtC 180) (rtC -180)))

; partition
;
(check-equal?
 (partition
  (list (fdC 15) (rtC 30)) 6 12)
 (list
  (list (fdC 6))
  (list (fdC 6))
  (list (fdC 3) (rtC 6))
  (list (rtC 12))
  (list (rtC 12))
  '()))
 
  
