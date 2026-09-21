#lang racket

;; Mask A2 - Loki / Racket
;; State is an illusion. We do not mutate variables;
;; we spawn fresh universes through recursion.
;; Coordinates: (x, y), where (0,0) is Top-Left
;; and (2,2) is Bottom-Right.

;; A note for the reader.
;;
;; Her name is Fleabag.
;; She wrote two numbers and called them a board.
;; She wrote four branches and called them a game.
;;
;; Her program is fine.
;;
;; There. I said it.
;;
;; It runs. It moves. It does exactly what was asked.
;; She'll read this and think I'm being generous.
;; Good.

(define (game-loop x y)

  ;; She'll call this "a loop with extra steps."
  ;; She's right.
  ;;
  ;; But it's a loop with extra dignity.
  ;;
  ;; Nothing changes here.
  ;; One world ends and another begins with slightly
  ;; different coordinates.
  ;;
  ;; Much cleaner than scribbling new numbers over the old ones.

  (displayln
   (string-append
    "\n[Loki's Grid] Space-Time Coordinates: ("
    (number->string x) ", "
    (number->string y) ")"))

  ;; "Space-Time Coordinates."
  ;; She'll roll her eyes.
  ;; That's partly why I called them that.

  (display "Where to go? ")
  (let ([move (string-upcase (read-line))])
    (cond
      [(string=? move "N") (game-loop x (max 0 (- y 1)))]
      [(string=? move "S") (game-loop x (min 2 (+ y 1)))]
      [(string=? move "E") (game-loop (min 2 (+ x 1)) y)]
      [(string=? move "W") (game-loop (max 0 (- x 1)) y)]
      [else (game-loop x y)])))

(game-loop 0 0)

;; One final note.
;;
;; Fleabag called the board a feeling.
;;
;; Cute.
;;
;; Her board is two mutable numbers.
;; Mine is two arguments passed into the next universe.
;;
;; Neither of us drew a board.
;;
;; Don't tell her we agree on something.
;;
;; I have a reputation to maintain.
;;
;; - Loki, The Knave