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
                     (run Body)))))

(de create-new-window (X Y W H)
    (let Win (curses "newwin" 'N H W Y X)
         (curses "keypad" NIL Win 1)
         (curses "mousemask" 'N *ALL-MOUSE-EVENTS 0)
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
    (let (LineLen (length (get-line> This CY))
                  FileLen (length (: lines)))
      (set (:: cursorx) (max 1 (min (+ 1 LineLen) CX)))
      (set (:: cursory) (max 1 CY))
      (cond
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
      (let Line (chop (get-line> This (: cursory)))
           (set (:: lines) (place (: cursory)
                                  (: lines)
                                  (pack (insert (: cursorx) Line Text)))))
      (adjust-cursor> This 1 0))
     ((= Text "\n")
      (let (Line (chop (get-line> This (: cursory)))
            RstLn (nth Line (: cursorx)))
        (set (:: lines) (place (: cursory)
                               (: lines)
                               (pack (head (- (: cursorx) 1) Line))))
        (set (:: lines) (insert (+ 1 (: cursory)) (: lines) (pack RstLn)))
        (move-cursor> This 1 (+ 1 (: cursory)))))))

(dm add-line> (Line)
    (set (:: lines) (append (: lines) (list Line))))

(dm delete-char> ()
    (let Line (chop (get-line> This (: cursory)))
      (set (:: lines) (place (: cursory)
                             (: lines)
                             (pack (remove (- (: cursorx) 1) Line)))))
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
    (=: window (create-new-window X Y W H)))

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
         (let (Offset (length (format I))
               FinalOffset (- (length (format (length (: lines)))) 1)
               LPad (pack (mapcar '((I) " ") (range 1 (- Offset FinalOffset))))
               Len (+ (+ FinalOffset (length X)) 1)
               Rem (- (: width) Len)
               RPad (pack (mapcar '((I) " ") (range 1 (- Rem 5)))))
              (window-call> This "mvwprintw" NIL I 1 "%s%d| %s%s" LPad I X RPad)
              (when (= I (: cursory))
                  (window-call> This "mvwchgat" NIL
                                (: cursory)
                                (+ (: cursorx) (+ FinalOffset 4))
                                1 *REVERSE (: colors) 0))))
    (window-call> This "mvwprintw" NIL 0 1 "%d, %d -- %s"
                  (: cursorx)
                  (: cursory) Mode)
    (window-call> This "mvwprintw" NIL 0 (- (: width) (length (: name)) 3) "<%s>" (: name))
    (window-call> This "wrefresh" NIL))


(class +FromFile)

(dm load-from-file> (Name)
    (let Name (or Name (: name))
         (ifn (info Name)
              (out Name))
         (set (:: lines) (in Name (make (until (eof) (link (line T))))))))

(dm out-to-file> (Name)
    (let Name (or Name (: name))
         (out Name (prinl (text> This)))))

(class +Interactive)

(dm handle-key> (Ch Mode Exit)
    (cond
     ((= Mode 'normal) (cond
                        ((= Ch (char "q")) (setq Exit T))
                        ((= Ch (char "i"))
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
                        ((= Ch (char "w")) (out-to-file> This))
                        ((= Ch (char "x"))
                         (adjust-cursor> This 1 0)
                         (delete-char> This))
                        ((= Ch (char "r"))
                         (adjust-cursor> This 1 0)
                         (delete-char> This)
                         (setq Mode 'insert))
                        ((= Ch (char "h")) (adjust-cursor> This -1 0))
                        ((= Ch (char "k")) (adjust-cursor> This 0 -1))
                        ((= Ch (char "j")) (adjust-cursor> This 0 1))
                        ((= Ch (char "l")) (adjust-cursor> This 1 0))))
     ((= Mode 'insert) (cond
                        ((= Ch *KEY-BACKSPACE) (delete-char> This))
                        ((= Ch 27)
                         (adjust-cursor> This -1 0)
                         (setq Mode 'normal))
                        (T (add-char> This (char Ch))))))
    (list Mode Exit))

(dm handle-mouse> (MX MY Mode Exit)
    (move-cursor> This (- MX 6) (- MY 1))
    (list Mode Exit))

(dm handle-resize> (Mode Exit)
    (window-call> This "wclear" NIL)
    (set (:: height) (get-height Screen))
    (set (:: width) (get-width Screen))
    (list Mode Exit))

(dm update> (Mode Exit)
    (let Ch (window-call> This "wgetch" 'I)
         (cond
          ((= Ch *KEY-RESIZE)
           (handle-resize> This Mode Exit))
          ((= Ch *KEY-MOUSE)
           (when (= (curses "getmouse" 'N
                            '(Event (20 I (I . 3) I))) 0)
             (handle-mouse> This
                            (+ (get Event 2 1) 1)
                            (+ (get Event 2 2) 1)
                            Mode
                            Exit)))
          ((>= Ch 0)
           (handle-key> This Ch Mode Exit)))))
