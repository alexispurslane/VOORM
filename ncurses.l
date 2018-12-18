(de curses @
    (pass native "libncursesw.so.6"))



(de ncurses-bits (M S)
    (>> (- (+ S 8)) M) )

(setq *BOLD (ncurses-bits 1 13))

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

(de print-with-attr (A . Rest)
    (curses "attron" NIL A)
    (apply curses Rest)
    (curses "attroff" NIL A))

(setq *KEY-DOWN	258)
(setq *KEY-UP		259)
(setq *KEY-LEFT	260)
(setq *KEY-RIGHT	261)
(setq *KEY-HOME	262)
(setq *KEY-BACKSPACE	263)
(setq *KEY-F0    264)
(de *KEY-F (n) (+ *KEY-F0 n))
(setq *KEY-MOUSE	409)
(setq *KEY-RESIZE	410)
(setq *KEY-EVENT	411)


(de get-width (Win) (curses "getmaxx" 'I Win))
(de get-height (Win) (curses "getmaxy" 'I Win))

(de in-screen "Args"
    (let (Var (car "Args") Body (cdr "Args"))
      (bind (list (cons Var (curses "initscr" 'N)))
            (finally (curses "endwin")
                     (curses "keypad" NIL (run Var) 1)
                     (curses "raw")
                     (curses "noecho")
                     (run Body)))))

(de create-new-window (X Y W H)
    (let Win (curses "newwin" 'N H W Y X)
         (curses "wrefresh" NIL Win)
         Win))

(de destroy-window (Win)
    (curses "wborder" NIL Win 32 32 32 32 32 32 32 32)
    (curses "wrefresh" NIL Win)
    (curses "delwin" NIL Win))

(class +Frame)

(dm T (Str CX CY)
    (=: lines (or Str (list "")))
    (=: cursorx (or CX 1))
    (=: cursory (or CY 1)))

(dm text> ()
    (apply pack (mapcar '((S) (pack S "\n")) (: lines))))
(dm lines> ()
    (: lines))
(dm cursor-x> () (: cursorx))
(dm cursor-y> () (: cursory))

(dm get-line> (Y)
    (let R (nth (: lines) (: cursory))
         (if R (car R) NIL)))

(dm move-cursor> (CX CY)
    (let (LineLen (length (get-line> This (: cursory)))
                  FileLen (length (: lines)))
      (cond
       ((and (>= CX 1) (>= CY 1) (<= CX (+ 1 LineLen)))
        (set (:: cursorx) CX)
        (set (:: cursory) CY))
       ((> CY FileLen) (add-line> This ""))
       ((and (not (= (: cursory) CY)) (= LineLen 0))
        (set (:: lines) (head -1 (: lines)))))))

(dm adjust-cursor> (DX DY)
    (move-cursor> This
                  (+ DX (: cursorx))
                  (+ DY (: cursory))))

(dm add-char> (Text)
    (cond
     ((not (= Text "\n"))
      (let (Line (chop (get-line> This (: cursory)))
            LineHead (head (- (: cursorx) 1) Line)
            LineTail (nth Line (: cursorx)))
        (set (:: lines) (let (Head (head (- (: cursory) 1) (: lines))
                              Tail (nth (: lines) (+ (: cursory) 1)))
                          (append Head (list (pack LineHead Text LineTail)) Tail))))
      (adjust-cursor> This 1 0))
     ((= Text "\n")
      (move-cursor> This 1 (+ 1 (: cursory))))))

(dm add-line> (Line)
    (set (:: lines) (append (: lines) (list Line))))

(dm delete-char> ()
    (let (Line (chop (get-line> This (: cursory)))
          LineHead (head (- (: cursorx) 2) Line)
          LineTail (nth Line (: cursorx)))
      (set (:: lines) (let (Head (head (- (: cursory) 1) (: lines))
                            Tail (nth (: lines) (+ (: cursory) 1)))
                        (append Head (list (pack LineHead LineTail)) Tail))))
    (adjust-cursor> This -1 0))


(class +VisibleFrame +Frame)

(dm T (X Y W H Str CX CY ColorPair Name)
    (super Str CX CY)
    (=: x X)
    (=: name (or Name "Undefined"))
    (=: y Y)
    (=: width W)
    (=: height H)
    (=: colors ColorPair)
    (=: window (create-new-window X Y W H))
    (window-call> This "nodelay" NIL 1))

(dm width> () (: width))
(dm height> () (: height))
(dm pos-x () (: x))
(dm pos-y> () (: y))
(dm window> () (: window))
(dm colors> () (: colors))
(dm name> () (: name))

(dm window-call> (Name Ret . @)
    (pass curses Name Ret (window> This)))

(dm delete> ()
    (destroy-window (: window)))

(dm draw> (Mode)
    (window-call> This "wbkgd" NIL (color-pair (: colors)))
    (window-call> This "box" NIL 0 0)
    (for (I . X) (: lines)
         (window-call> This "mvwprintw" NIL I 1 "%d| %s" I X)
         (window-call> This "mvwchgat" NIL
                       (: cursory)
                       (+ (: cursorx) (+ (length (format I)) 2))
                       1 0 (+ 1 (: colors)) 0))
    (window-call> This "mvwprintw" NIL 0 1 "%d, %d -- %s"
                  (: cursorx)
                  (: cursory) Mode)
    (window-call> This "mvwprintw" NIL 0 (- (: width) (length (: name)) 3) "<%s>" (: name))
    (window-call> This "wrefresh" NIL))


(class +Interactive)

(dm handle-key> (Ch Mode Exit)
    (cond
     ((= Ch *KEY-RESIZE) (window-call> This "wclear" NIL))
     ((= Mode 'normal) (cond
                        ((= Ch (char "q")) (setq Exit T))
                        ((= Ch (char "i"))
                         (adjust-cursor> This -1 0)
                         (setq Mode 'insert))
                        ((= Ch (char "A"))
                         (move-cursor> This
                                       (+ 1 (length (get-line> This (cursor-y> This))))
                                       (cursor-y> This))
                         (setq Mode 'insert))
                        ((= Ch (char "$"))
                         (move-cursor> This
                                       (+ 1 (length (get-line> This (cursor-y> This))))
                                       (cursor-y> This)))
                        ((= Ch (char "0"))
                         (move-cursor> This 1 (cursor-y> This)))
                        ((= Ch (char "o"))
                         (move-cursor> This 1 (+ 1 (cursor-y> This)))
                         (setq Mode 'insert))
                        ((= Ch (char "x"))
                         (delete-char> This))
                        ((= Ch (char "h")) (adjust-cursor> This -1 0))
                        ((= Ch (char "k")) (adjust-cursor> This 0 -1))
                        ((= Ch (char "j")) (adjust-cursor> This 0 1))
                        ((= Ch (char "l")) (adjust-cursor> This 1 0))))
     ((= Mode 'insert) (cond
                        ((= Ch 127) (delete-char> This))
                        ((= Ch 27) (setq Mode 'normal))
                        (T (add-char> This (char Ch))))))
    (list Mode Exit))

(dm update> (Mode Exit)
    (let Ch (window-call> This "wgetch" 'I)
         (if (>= Ch 0)
             (handle-key> This Ch Mode Exit)
             (list Mode Exit))))