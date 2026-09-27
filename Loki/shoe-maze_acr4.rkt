#lang racket

;; Loki, The Knave.
;; Act 4. The Real Game, But Now With a Hint.
;;
;; Fleabag has tables. I have structs.
;; Fleabag has loops. I have more parentheses.
;;
;; This act we both added a solver.
;; Same problem. Same algorithm.
;; Suspiciously different opinions about everything else.
;;
;; We are both correct. That's the arrangement.

(require data/queue)

;; Two structs. `#:mutable` because the board moves, `#:transparent`
;; because I'd rather you see my fields than guess at them.
;;
;; Yes, I could rebuild the whole world on every move.
;; No, I'm not going to.

(struct piece (name r c dir inside) #:mutable #:transparent)
(struct game (square shoes message) #:mutable #:transparent)

(define deltas (hash 'N '(-1 0) 'S '(1 0) 'E '(0 1) 'W '(0 -1)))
(define entry-moves (hash 'N 'S 'S 'N 'E 'W 'W 'E))
(define shapes (hash 'N "∪" 'S "∩" 'E "⊂" 'W "⊃"))
(define colors (hash 'red "\u001b[31m" 'blue "\u001b[34m"
                     'black "\u001b[90m" 'square "\u001b[1m"))
(define use-color? (make-parameter #f))

;; Fleabag hardcoded her initial state in a table literal.
;; I made a constructor.
;;
;; She'll say "same thing."
;; I have decided not to start this argument before line 50.

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

;; Find every shoe occupying a cell.
;; Fleabag used a loop. I trust `filter`.
;; Nobody needs a meeting about this.

(define (shoes-at g r c)
  (filter (lambda (p) (at? p r c)) (game-shoes g)))

;; Red is the only shoe allowed to enter another shoe.
;; Of course Red gets special privileges.
;;
;; Fleabag wrote that first.
;; I read her file.

(define (may-enter? moving target move)
  (and (not (eq? moving target))
       (eq? (piece-name moving) 'red)
       (eq? move (hash-ref entry-moves (piece-dir target)))))

;; Work out which shoes travel with the square.
;;
;; Start with the chain of containers around it.
;; If a container moves, anything inside that moving container
;; has to move too.
;;
;; Fleabag called this a relationship problem.
;; It's a transitive closure.
;;
;; Fine. It may also be a relationship problem.

(define (moving-shoes g move)
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

;; `move-error` doesn't change the game.
;; It answers one question:
;;
;; If this move is illegal, why?
;;
;; `#f` means no complaint. A string means absolutely not.

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

;; The move itself:
;;
;; detach
;; move
;; attach
;;
;; In that order. On purpose.
;;
;; Fleabag would call that obvious.
;; Obvious things are still allowed to be load-bearing.

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
          ;; Don't replace an existing square -> shoe relationship
          ;; just because another shoe happens to share the cell.
          ;;
          ;; This comment exists because bugs have memories.
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
;; That's the winning condition.
;; Naturally, everything else exists because of them.

(define (won? g)
  (define red (shoe-named g 'red))
  (define blue (shoe-named g 'blue))
  (at? red (piece-r blue) (piece-c blue)))

;; ==========================================
;; Act 4 proper. The solver.
;; =====================================
;; Every legal move has the same cost, so the state graph is unweighted.
;; BFS explores it by distance: all states one move away, then two,
;; then three..
;;
;; Which means the first winning state it reaches gives us a
;; shortest solution.
;;
;; No prophecy. No clever heuristic.
;; Just a queue and some patience.

(define directions '(N S E W))
(define direction-names (hash 'N "North" 'S "South" 'E "East" 'W "West"))

(define (all-pieces g)
  (cons (game-square g) (game-shoes g)))

;; Clone a game in two passes.
;;
;; First copy every piece with `inside = #f`.
;; Then rebuild every `inside` reference so it points at
;; another piece in the clone, never back into the original.
;;
;; `make-hasheq` is useful here because the mapping is explicitly
;; original object -> cloned object, so identity is exactly what
;; we want while rebuilding the references.
;;
;; Fleabag did the same thing with a Lua table.
;; Silent nod across the repo.

(define (clone-game g)
  (define copies (make-hasheq))
  (for ([p (in-list (all-pieces g))])
    (hash-set! copies p
               (piece (piece-name p) (piece-r p) (piece-c p) (piece-dir p) #f)))
  (for ([p (in-list (all-pieces g))] #:when (piece-inside p))
    (set-piece-inside! (hash-ref copies p) (hash-ref copies (piece-inside p))))
  (game (hash-ref copies (game-square g))
        (map (lambda (p) (hash-ref copies p)) (game-shoes g))
        (game-message g)))

;; Turn the meaningful game state into a comparable value.
;;
;; Object identity is irrelevant to BFS: two independently cloned
;; games with the same positions, directions and containment
;; relationships are the same search state.
;;
;; Fleabag serializes hers into a string.
;; I use a list of lists.
;;
;; Same question:
;; Have I already been here?

(define (state-key g)
  (for/list ([p (in-list (all-pieces g))])
    (list (piece-name p) (piece-r p) (piece-c p) (piece-dir p)
          (and (piece-inside p) (piece-name (piece-inside p))))))

;; BFS
;;
;; Each queue entry carries:
;;   - the game state
;;   - the first move taken from the starting state
;;   - the distance travelled
;;
;; `let/ec found` gives the search an escape hatch.
;; As soon as we find a winning state, `(found first-move steps)`
;; returns the hint and its shortest distance immediately.
;;
;; Small function. Rather a lot hiding inside it.

(define (shortest-hint g)
  (cond
    [(won? g) (values #f 0)]
    [else
     (define queue (make-queue))
     (define visited (make-hash))
     (hash-set! visited (state-key g) #t)
     (enqueue! queue (list (clone-game g) #f 0))
     (let/ec found
       (let loop ()
         (cond
           [(queue-empty? queue) (values #f #f)]
           [else
            (match-define (list board first distance) (dequeue! queue))
            (for ([move (in-list directions)])
              (define next (clone-game board))
              (when (move-player! next move)
                (define key (state-key next))
                (unless (hash-has-key? visited key)
                  (define first-move (or first move))
                  (define steps (add1 distance))
                  (hash-set! visited key #t)
                  (when (won? next) (found first-move steps))
                  (enqueue! queue (list next first-move steps)))))
            (loop)])))]))

;; Compute elsewhere. Print here.
;; `show-hint` has one job and, unlike certain people,
;; does not turn that job into a philosophical argument.

(define (show-hint g)
  (define-values (direction distance) (shortest-hint g))
  (cond
    [direction
     (printf "Hint: ~a (~a). Shortest solution: ~a moves.\n"
             (hash-ref direction-names direction) direction distance)]
    [(equal? distance 0) (displayln "Already solved!")]
    [else (displayln "No solution exists from this position.")]))

;; Rendering.
;;
;; Color is optional because terminals are not the only places
;; output eventually ends up.

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
  (displayln "\n       FLEABAG'S SHOE MAZE")
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
;; Fleabag has `while true`.
;; I have `let loop`.
;;
;; Same output.
;; Different process.
;; Same loneliness.

(define (play)
  (define g (make-game))
  (let loop ()
    (render g)
    (cond
      [(won? g) (displayln "\nVICTORY! Red Shoe is inside Blue Shoe.")]
      [else
       (show-hint g)
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