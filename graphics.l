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
