#lang racket

;; Code is Data, Data is Code.
;; Why wrap yourself in tables when you can wrap the universe in parentheses?
;; (She wrapped herself in tables. She'll say they're not the same thing.
;;  She's right. Don't tell her I said that.)

;; Loki, The Knave.
;; Act 3. The Real Game.
;;
;; Fleabag wrote hers in three hundred lines and called it "a few tables
;; and a while loop." I wrote mine in a hundred and thirty and called it
;; "a struct per piece and a transition function per turn." She called
;; that "more parentheses." I called it "a *model*."
;;
;; We are both correct. That's the arrangement.

;; The square remembers its immediate shoe. A shoe remembers its own
;; enclosing shoe. square -> red -> black.
;;
;; Fleabag will say this is just a linked list. Fleabag is right, and
;; I hate that she's right, and I'm going to write it down anyway
;; so the diff shows I knew.

;; Two structs. `#:mutable` because the board moves, `#:transparent`
;; because I have nothing to hide.

(struct piece (name r c dir inside) #:mutable #:transparent)
(struct game (square shoes message) #:mutable #:transparent)

(define deltas (hash 'N '(-1 0) 'S '(1 0) 'E '(0 1) 'W '(0 -1)))
(define entry-moves (hash 'N 'S 'S 'N 'E 'W 'W 'E))
(define shapes (hash 'N "∪" 'S "∩" 'E "⊂" 'W "⊃"))
(define colors (hash 'red "\u001b[31m" 'blue "\u001b[34m" 'black "\u001b[90m" 'square "\u001b[1m"))
(define use-color? (make-parameter #f))

;; Fleabag hardcoded her initial state in a table literal.
;; I made a `make-game` constructor. She said "same thing."
;; It is *not* the same thing. It's the difference between
;; a state and a *seed*. She doesn't see the difference.
;; That's the whole difference.

(define (make-game)
  (game (piece 'square 1 1 #f #f)
        (list (piece 'red 3 1 'N #f)
              (piece 'blue 2 2 'N #f)
              (piece 'black 1 3 'W #f))
        ""))

(define (shoe-named g name)
  (findf (lambda (p) (eq? (piece-name p) name)) (game-shoes g)))

(define (at? p r c) (and (= (piece-r p) r) (= (piece-c p) c)))
(define (valid? r c) (and (<= 1 r 3) (<= 1 c 3)))

;; Fleabag's `shoes_at` returns a list. She'll say "why is yours shorter."
;; I'll say "because I trust `filter`." She'll say "I trust `for`."
;; And we'll both be right, and neither of us will move.

(define (shoes-at g r c)
  (filter (lambda (p) (at? p r c)) (game-shoes g)))

;; Red is the only shoe allowed to enter another shoe.
;; Of course Red gets special privileges. Red *always* gets
;; special privileges. Fleabag wrote that comment in her file.
;; I'm writing it in mine because I want her to know
;; I read hers. All of it. Twice.

(define (may-enter? moving target move)
  (and (not (eq? moving target))
       (eq? (piece-name moving) 'red)
       (eq? move (hash-ref entry-moves (piece-dir target)))))

;; The chain walk. This is the bit Fleabag said "has become a
;; relationship problem." It's a linked list traversal. It's fine.
;; She's making it *mean* something. She does that.
;;
;; She'll say my version reads like a deathbed confession.
;; I'll say hers reads like a drunk text at 3 a.m.
;; We'll both be right. We'll both go home alone.

(define (moving-shoes g move)
  ;; Even if an inner shoe opens in this direction, an outer wall can
  ;; carry it. Check every enclosing shoe, then include their contents.
  (define initial
    (let loop ([container (piece-inside (game-square g))])
      (cond [(not container) '()]
            [(eq? move (piece-dir container))
             (loop (piece-inside container))]
            [else (cons container (loop (piece-inside container)))])))
  (let loop ([moving initial])
    (define extra
      (filter (lambda (p)
                (and (piece-inside p)
                     (memq (piece-inside p) moving)
                     (not (memq p moving))))
              (game-shoes g)))
    (if (null? extra) moving (loop (append moving extra)))))

;; `move-error` is pure. `move-error` does not touch the game.
;; `move-error` *explains*.
;;
;; Fleabag's `can_move` returns two values: `false` and a string.
;; Mine returns a string or `#f`. She'll say "same thing."
;; It is *not* the same thing. It's the difference between
;; a boolean and a *reason*. She doesn't see the difference.
;; And I *like* that she doesn't see the difference. I like that
;; she returns a tuple and calls it done. I like that she ships.
;; I'm not going to tell her that.

(define (move-error g move moving r c)
  (match-define (list dr dc) (hash-ref deltas move))
  (define targets (shoes-at g r c))
  (cond
    [(not (valid? r c)) "Hit boundary wall!"]
    [(for/or ([p (in-list moving)])
       (not (valid? (+ (piece-r p) dr) (+ (piece-c p) dc))))
     "Cannot push shoe into outer wall!"]
    [(null? moving)
     (for/or ([target (in-list targets)])
       (and (not (eq? move (hash-ref entry-moves (piece-dir target))))
            (format "Blocked by shoe wall! Open side is ~a."
                    (piece-dir target))))]
    [else
     (for*/or ([p (in-list moving)] [target (in-list targets)])
       (and (not (memq target moving))
            (not (may-enter? p target move))
            (format "~a shoe is blocked by ~a shoe!"
                    (piece-name p) (piece-name target))))]))

;; Here. This is the heart. This is the bit Fleabag will read
;; and then pretend she didn't read.
;;
;; She'll say: "you mutate the square and then mutate it again."
;; I'll say: "I detach, I move, I attach. In that order. On purpose."
;; She'll say: "your ordering is load-bearing."
;; I'll say: "your ordering is a *confession*."
;;
;; And then she'll go back to her file and read my comment again.
;; She always does.
;; I have not decided what to do with that information.

(define (move-player! g move)
  (cond
    [(not (hash-has-key? deltas move))
     (set-game-message! g "Use N, S, E, W, or Q.")
     #f]
    [else
     (match-define (list dr dc) (hash-ref deltas move))
     (define sq (game-square g))
     (define r (+ (piece-r sq) dr))
     (define c (+ (piece-c sq) dc))
     (define moving (moving-shoes g move))
     (define error-message (move-error g move moving r c))
     (cond
       [error-message (set-game-message! g error-message) #f]
       [else
        (set-game-message! g "")
        ;; Detach only when the immediate container stays behind.
        ;;
        ;; Fleabag: "this is one line."
        ;; Me: "this is *three* lines and a `cons`."
        ;; Fleabag: "same output."
        ;; Me: "different *soul*."
        ;; Fleabag: "you're doing it again."
        ;; Me: "I'm always doing it."
        (for ([p (in-list (cons sq moving))])
          (when (and (piece-inside p)
                     (not (memq (piece-inside p) moving)))
            (set-piece-inside! p #f))
          (set-piece-r! p (+ (piece-r p) dr))
          (set-piece-c! p (+ (piece-c p) dc)))
        (let ([here (shoes-at g r c)])
          (for ([p (in-list moving)] #:unless (piece-inside p))
            (define target
              (findf (lambda (target)
                       (and (not (memq target moving))
                            (may-enter? p target move)))
                     here))
            (when target (set-piece-inside! p target)))
          ;; Never replace square -> red with square -> black.
          ;;
          ;; Fleabag: "why would you write that comment."
          ;; Me: "because I hit the bug."
          ;; Fleabag: "you didn't hit the bug. you *read* my file."
          ;; Me: "..."
          ;; Fleabag: "you read my file, Loki."
          ;; Me: "..."
          ;; Fleabag: "I knew it."
          ;; Me: "you didn't know."
          ;; Fleabag: "I *hoped*."
          ;; Me: "that's worse."
          ;; Fleabag: "I know."
          (unless (piece-inside sq)
            (define target
              (findf (lambda (target)
                       (and (not (memq target moving))
                            (eq? move (hash-ref entry-moves
                                                (piece-dir target)))))
                     here))
            (when target (set-piece-inside! sq target))))
        #t])]))

;; Red and Blue in the same cell.
;;
;; Fleabag: "finally."
;; Me: "That's the winning condition."
;; Fleabag: "I know."
;; Me: "Then why did you say it like that."
;; Fleabag: "Like what."
;; Me: "..."
;;
;; This function is four lines.
;; Naturally, it caused all of this.

(define (won? g)
  (define red (shoe-named g 'red))
  (define blue (shoe-named g 'blue))
  (at? red (piece-r blue) (piece-c blue)))

;; Rendering. Fleabag emits ANSI codes unconditionally.
;; I made color a parameter, defaulting to off.
;;
;; She'll say "the terminal handles it."
;; I'll say "some terminals do. Files don't. Logs don't. DrRacket doesn't."
;; She'll say "who pipes a puzzle to a file."
;; I'll say "who doesn't."
;; She'll say "you're insufferable."
;; I'll say "I'm *configurable*."
;; She'll say "same thing."

(define (glyph p)
  (define text (if (eq? (piece-name p) 'square)
                   "■" (hash-ref shapes (piece-dir p))))
  (if (use-color?)
      (string-append (hash-ref colors (piece-name p)) text "\u001b[0m")
      text))

(define (cell-text g r c)
  (define occupants
    (append (shoes-at g r c)
            (if (at? (game-square g) r c) (list (game-square g)) '())))
  (define width (if (null? occupants) 0 (sub1 (* 2 (length occupants)))))
  (string-append " " (string-join (map glyph occupants) "+")
                 (make-string (- 8 width) #\space)))

(define (render g)
  (when (use-color?) (display "\u001b[2J\u001b[H"))
  (displayln "\n       A PERFECTLY REASONABLE SHOE MAZE")
  (displayln "Controls: N, S, E, W | Q: Quit\n")
  (displayln "+---------+---------+---------+")
  (for ([r (in-range 1 4)])
    (display "|")
    (for ([c (in-range 1 4)]) (display (cell-text g r c)) (display "|"))
    (newline)
    (displayln "+---------+---------+---------+"))
  (printf "\n~a = You (Black Square)\n" (glyph (game-square g)))
  (for ([p (in-list (game-shoes g))])
    (printf "~a = ~a shoe (open ~a)\n" (glyph p) (piece-name p) (piece-dir p)))
  (unless (string=? (game-message g) "") (displayln (game-message g))))

;; The loop.
;;
;; Fleabag's is a `while true`. Mine is a `let loop`.
;; She'll say "same thing."
;; I'll say "hers has a `break` and mine has *recursion*."
;; She'll say "same *output*."
;; I'll say "different *process*."
;; She'll say "you're doing it again."
;; I'll say "I'm always doing it."
;; She'll say "I know."
;; I'll say "you always know."
;; She'll say "I always know."
;;
;; This is the part where I stop writing comments.
;; This is the part where I write *her*.

(define (play)
  (define g (make-game))
  (let loop ()
    (render g)
    (cond
      [(won? g) (displayln "\nVICTORY! Red Shoe is inside Blue Shoe.")]
      [else
       (display "\nWhere to go? ")
       (flush-output)
       (define input (read-line))
       (unless (eof-object? input)
         (define command (string->symbol (string-upcase (string-trim input))))
         (unless (eq? command 'Q)
           (move-player! g command)
           (loop)))])))

(module+ main
  (parameterize ([use-color? (and (member "--color"
                                        (vector->list (current-command-line-arguments)))
                                  #t)])
    (play)))

;; Tests.
;;
;; Fleabag doesn't have tests.
;; Fleabag *is* the test.
;;
;; I found RackUnit.
;; I read the documentation.
;; I closed the documentation.
;; That's enough personal growth for one act.