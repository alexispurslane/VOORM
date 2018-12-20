(de curses @
    (pass native "libncursesw.so.6"))



(de ncurses-bits (M S)
    (>> (- (+ S 8)) M) )


(de ncurses-mouse-mask (B M)
    (>> (* (- B 1) -5) M) )

(setq *REPORT-MOUSE-POS (ncurses-mouse-mask 6 8))

(setq *ALL-MOUSE-EVENTS (- *REPORT-MOUSE-POS 1))

(setq *BOLD (ncurses-bits 1 13))
(setq *REVERSE (ncurses-bits 1 10))

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
(setq *key-event	411)


(de get-width (Win) (curses "getmaxx" 'I Win))
(de get-height (Win) (curses "getmaxy" 'I Win))

(de in-screen "Args"
    (let (Var (car "Args") Body (cdr "Args"))
      (bind (list (cons Var (curses "initscr" 'N)))
            (finally (curses "endwin")
                     (curses "raw")
                     (curses "noecho")
                     (curses "set_escdelay" NIL 15)
                     (curses "nodelay" NIL (run Var) 0)
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

(dm get-line> (Y) (car (nth (: lines) (or Y (: cursory)))))

(dm move-cursor> (CX CY)
    (let (LineLen (length (get-line> This CY))
          FileLen (length (: lines)))
      (set (:: cursorx) (max 1 (min (+ 1 LineLen) CX)))
      (set (:: cursory) (max 1 (min (- (length (: lines)) 1) CY)))))

(dm adjust-cursor> (DX DY)
    (move-cursor> This
                  (+ DX (: cursorx))
                  (+ DY (: cursory))))

(dm add-char> (Text)
    (cond
     ((not (= Text "\n"))
      (let Line (chop (get-line> This))
           (set (:: lines) (place (: cursory)
                                  (: lines)
                                  (pack (insert (: cursorx) Line Text)))))
      (adjust-cursor> This 1 0))
     ((= Text "\n")
      (let (Line (chop (get-line> This))
            RstLn (nth Line (: cursorx)))
        (set (:: lines) (place (: cursory)
                               (: lines)
                               (pack (head (- (: cursorx) 1) Line))))
        (set (:: lines) (insert (+ 1 (: cursory)) (: lines) (pack RstLn)))
        (move-cursor> This 1 (+ 1 (: cursory)))))))

(dm add-line> (Line)
    (set (:: lines) (append (: lines) (list Line))))

(dm delete-char> ()
    (cond
     ((= (: cursorx) 1)
      (let (ThisLine (chop (get-line> This))
            LastLine (chop (get-line> This (- (: cursory) 1))))
        (set (:: lines) (place (- (: cursory) 1)
                               (: lines)
                               (pack LastLine ThisLine)))
        (set (:: lines) (remove (: cursory) (: lines)))
        (move-cursor> This (- (length LastLine) 1) (- (: cursory) 1))))
     (T
      (let Line (chop (get-line> This))
           (set (:: lines) (place (: cursory)
                                  (: lines)
                                  (pack (remove (- (: cursorx) 1) Line)))))
      (adjust-cursor> This -1 0))))


(class +VisibleFrame +Frame)

(dm T (X Y W H Str CX CY ColorPair Name)
    (super Str CX CY)
    (=: x X)
    (=: name (or Name "Undefined"))
    (=: y Y)
    (=: width W)
    (=: height H)
    (=: colors ColorPair)
    (=: scroll 0)
    (=: window (create-new-window X Y W H)))

(dm width> () (: width))
(dm height> () (: height))
(dm pos-x> () (: x))
(dm pos-y> () (: y))
(dm window> () (: window))
(dm colors> () (: colors))
(dm name> () (: name))
(dm scroll-line> () (: scroll))

(dm window-call> (Name Ret . @)
    (pass curses Name Ret (window> This)))

(dm delete> ()
    (destroy-window (: window)))

(dm adjust-cursor> (DX DY)
    (super DX DY)
    (let Height (- (: height) 2)
         (cond
          ((and (> DY 0) (> (: cursory) (+ (: scroll) Height)))
           (inc (:: scroll) 1))
          ((and (< DY 0) (< (: cursory) (+ 1 (: scroll))))
           (dec (:: scroll) 1)))))

(dm draw-box> ()
    (when (= (cadr *State) Idx)
      (window-call> This "wattron" NIL (| *REVERSE *BOLD)))
    (window-call> This "wborder" NIL 32 32 32 32 32 32 32 32)
    (window-call> This "wattroff" NIL (| *REVERSE *BOLD)))

(dm draw-contents> ()
    (let (Height (- (: height) 2)
          Start (max 1 (+ (: scroll) 1))
          End (min (- (length (: lines)) 1) Height)
          MarginOffset (+ 2 (length (format (length (: lines))))))
      (for (I . X) (head End (nth (: lines) Start))
           (let (LineNum (+ (: scroll) I)
                 Offset (length (format LineNum))
                 FinalOffset (- (length (format (length (: lines)))) 1)
                 LPad (pack (mapcar '((I) " ") (range 1 (- Offset FinalOffset))))
                 Len (+ (+ FinalOffset (length X)) 1)
                 Rem (- (: width) Len)
                 WindowWidth (- (: width) (+ 3 MarginOffset))
                 RPad (pack (mapcar '((I) " ") (range 1 (- Rem 5)))))

             (window-call> This "wattron" NIL (| *REVERSE *BOLD))
             (window-call> This "mvwprintw" NIL I 1 "%s%d " LPad LineNum)
             (window-call> This "wattroff" NIL (| *REVERSE *BOLD))

             (when (= LineNum (: cursory)) (window-call> This "wattron" NIL *BOLD))
             (window-call> This "mvwprintw" NIL I (+ 2 MarginOffset) "%s%s"
                           (pack (head WindowWidth (chop X))) (if (< (length X) WindowWidth) RPad ""))
             (when (= LineNum (: cursory)) (window-call> This "wattroff" NIL *BOLD))

             (when (= LineNum (: cursory))
               (window-call> This "mvwchgat" NIL
                             (- (: cursory) (: scroll))
                             (+ (: cursorx) (+ FinalOffset 4))
                             1 (| *REVERSE *BOLD) (: colors) 0))))))

(dm draw-statusline> ()
    (window-call> This "wattron" NIL (| *REVERSE *BOLD))
    (window-call> This "mvwprintw" NIL 0 1 "%d, %d -- %s, %d (%d) L: %d"
                  (: cursorx)
                  (: cursory) (caddr *State) (: scroll) Idx (length (get-line> This)))
    (window-call> This "mvwprintw" NIL 0 (- (: width) (length (: name)) 3) "<%s>" (: name))
    (window-call> This "wattroff" NIL (| *REVERSE *BOLD)))

(dm draw> (Idx)
    (window-call> This "wclear" NIL)
    (window-call> This "wbkgd" NIL (color-pair (: colors)))
    (draw-box> This)
    (draw-contents> This)
    (draw-statusline> This)
    (window-call> This "wrefresh" NIL))

(class +Menu)

(dm choice> () (: choice))

(dm handle-key> (Ch)
    (cond
     ((= Ch (char "h")) (adjust-cursor> This -1 0))
     ((= Ch (char "k")) (adjust-cursor> This 0 -1))
     ((= Ch (char "j")) (adjust-cursor> This 0 1))
     ((= Ch (char "l")) (adjust-cursor> This 1 0))
     ((= Ch (char "\n"))
      (set (:: choice) (get-line> This))))
    *State)

(dm handle-mouse> (MX MY)
    (move-cursor> This (- MX 6) (- MY 1))
    (set (:: choice) (car (nth (: lines) (: cursory))))
    *State)

(dm handle-resize> ()
    (window-call> This "wclear" NIL)
    (set (:: width) (get-width Screen))
    (set (:: height) (get-height Screen))
    (destroy-window (: window))
    (set (:: window) (create-new-window (: x) (: y) (: width) (: height))))
