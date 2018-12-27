(de curses @
    (pass native "libncursesw.so.6.1"))



(de ncurses-bits (M S) (>> (- (+ S 8)) M) )
(de ncurses-mouse-mask (B M) (>> (* (- B 1) -5) M) )

(setq *REPORT-MOUSE-POS (ncurses-mouse-mask 6 8))

(setq *ALL-MOUSE-EVENTS (- *REPORT-MOUSE-POS 1))

(setq *BOLD (ncurses-bits 1 13))
(setq *REVERSE (ncurses-bits 1 10))

(de color-pair (n)
    (& (>> -8 n) (>> -8 (- (>> -8 1) 1))))

(setq *COLOR-BLACK   0)
(setq *COLOR-RED     1)
(setq *COLOR-GREEN   2)
(setq *COLOR-CYAN    3)
(setq *COLOR-BLUE    4)
(setq *COLOR-MAGENTA 5)
(setq *COLOR-YELLOW  6)
(setq *COLOR-WHITE   7)

(setq *COLOR-SCHEME-COLOR-LIST '(BACKGROUND-DEFUALT
                                 BACKGROUND-LIGHTER
                                 BACKGROUND-SELECT
                                 BACKGROUND-COMMENT
                                 FOREGROUND-DARK
                                 FOREGROUND-DEFAULT
                                 FOREGROUND-LIGHT
                                 BACKGROUND-LIGHT
                                 VARIABLES
                                 VALUES
                                 CLASSES
                                 STRINGS
                                 SUPPORT
                                 FUNCTIONS
                                 KEYWORDS
                                 DEPRICATED))

(for I (range 1 16)
     (let (Name (chop (car (nth *COLOR-SCHEME-COLOR-LIST I)))
           ExName (pack (append (chop "*COLOR-SCHEME-") Name))
           Symbol (car (str ExName)))
       (set Symbol (+ 7 I))))

(de print-with-attr (A . Rest)
    (curses "attron" NIL A)
    (apply curses Rest)
    (curses "attroff" NIL A))

(setq *KEY-DOWN       258)
(setq *KEY-UP	        259)
(setq *KEY-LEFT       260)
(setq *KEY-RIGHT      261)
(setq *KEY-HOME       262)
(setq *KEY-BACKSPACE	263)
(setq *KEY-F0         264)
(de *KEY-F (n) (+ *KEY-F0 n))
(setq *KEY-MOUSE      409)
(setq *KEY-RESIZE     410)
(setq *key-event      411)


(de get-width (Win) (curses "getmaxx" 'I Win))
(de get-height (Win) (curses "getmaxy" 'I Win))

(de in-screen "Args"
    (let (Var (car "Args") Body (cdr "Args"))
      (native "@" "setlocale" NIL 0 "")
      (bind (list (cons Var (curses "initscr" 'N)))
            (finally (curses "endwin")
                     (curses "raw")
                     (curses "noecho")
                     (curses "set_escdelay" NIL 15)
                     (run Body)))))

(de create-new-window (X Y W H)
    (let Win (curses "newwin" 'N H W Y X)
         (curses "keypad" NIL Win 1)
         (curses "mousemask" 'N *ALL-MOUSE-EVENTS 0)
         Win))

(de destroy-window (Win)
    (curses "wborder" NIL Win 32 32 32 32 32 32 32 32)
    (curses "wclear" NIL Win)
    (curses "wrefresh" NIL Win)
    (curses "delwin" NIL Win))
