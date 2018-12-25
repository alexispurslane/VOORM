(de curses @
    (pass native "libncursesw.so.6.1"))



(de ncurses-bits (M S)
    (>> (- (+ S 8)) M) )

(setq *Color (ncurses-bits (- (>> 1 -8) 1) 0))

(de color-pair (n) (& (ncurses-bits n 0) *Color))

(setq *COLOR-BLACK   0)
(setq *COLOR-RED     1)
(setq *COLOR-GREEN   2)
(setq *COLOR-CYAN    3)
(setq *COLOR-BLUE    4)
(setq *COLOR-MAGENTA 5)
(setq *COLOR-YELLOW  6)
(setq *COLOR-WHITE   7)

(de init-color-pairs ()
    (curses "start_color")
    (curses "init_pair" NIL 1 *COLOR-RED *COLOR-WHITE)
    (curses "init_pair" NIL 2 *COLOR-WHITE *COLOR-GREEN))

(de draw-border (pair)
    (curses "attrset" NIL (color-pair pair))
    (curses "border" NIL
            (char "*") (char "*") (char "~") (char "~")
            (char "*") (char "*") (char "*") (char "*")))

(de draw-message (pair)
    (curses "attrset" NIL (color-pair pair))
    (curses "mvprintw" NIL 1 1 "Merry Christmas!"))

(de main ()
    (let Screen (curses "initscr" 'N)
         (native "@" "setlocale" NIL 0 "")
         (curses "raw")
         (curses "noecho")

         (init-color-pairs)

         (draw-border 1)
         (draw-message 2)

         (curses "getch" 'I)
         (curses  "refresh")
         (curses "endwin")))
(main)
(bye)
