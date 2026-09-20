#lang racket

;; Mask A2 - Loki, The Knave
;; "Why wrap yourself in classes when you can wrap the universe in parentheses?"

;; ---

;; Dear Fleabag,

;; You call it "play-doh." Cute.
;; You call it "3 lines." I also have 3 lines.
;; This is already awkward for you, isn't it?
;; And yes, there are parentheses.
;; A lot of parentheses.
;; I'm starting to like them.
;; They make everything look far more important than it probably is.

;; "No 400-page manual." It's 398, and I've read it twice,
;;  Enough to feel superuor.
;; ---

(display "Who are you? ")

;; Look at that.
;; `display`, because I would like the poor human to answer
;; on the same line instead of shouting into the void.
;; Presentation matters.

(define name (read-line))

;; You have `local`.
;; It sounds temporary.
;; Nervous.
;; Afraid of commitment.
;; Very you, actually.

(displayln (string-append "Hello, " name "!"))

;; ---

;; And there it is. Three lines.
;; No tears.
;;
;; Also, Fleabag...
;; You told me to go cry about it.
;; Unfortunately, Racket was much less painful than you hoped.
;; DrRacket looks like something I would have installed
;; centures ago, but I'm strangely enjoying it.
;; Perhaps it's the nostalgia.
;; Perhaps it's the parentheses.
;; Perhaps I've simply been here too long.

;; Anyway.
;;
;; Keep the play-doh.
;; I'll keep the 398-page manual.
;;
;; See you in Act 2.
;;
;; - Loki, The Knave
;;   (still not crying)