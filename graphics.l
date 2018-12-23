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
    (=: shift 0)
    (=: window (create-new-window X Y W H)))

(dm width> () (: width))
(dm height> () (: height))
(dm pos-x> () (: x))
(dm pos-y> () (: y))
(dm window> () (: window))
(dm colors> () (: colors))
(dm name> () (: name))
(dm scroll-line> () (: scroll))
(dm shift-amount> () (: shift))

(dm window-call> (Name Ret . @)
    (pass curses Name Ret (window> This)))

(dm delete> ()
    (destroy-window (: window)))

(dm adjust-cursor> (DX DY)
    (super DX DY)
    (let Height (- (: height) 2)
         (cond
          ((and (> DY 0) (> (+ (: shift) (: cursory)) (+ (: scroll) Height)))
           (inc (:: scroll) 1))
          ((and (< DY 0) (< (+ (: shift) (: cursory)) (+ 1 (: scroll))))
           (dec (:: scroll) 1)))))

(dm draw-box> ()
    (when (= (cadr *State) Idx)
      (window-call> This "wattron" NIL (| *REVERSE *BOLD)))
    (window-call> This "wborder" NIL 32 32 32 32 32 32 32 32)
    (window-call> This "wattroff" NIL (| *REVERSE *BOLD)))

(dm draw-selection> ()
    (when (: select-start)
      (let (SelectStartX (car (: select-start))
            SelectStartY (cadr (: select-start))
            VisibleSSX (+ MarginOffset 3
                          (% SelectStartX (+ WindowWidth 1))
                          (/ SelectStartX (+ WindowWidth 1)))
            AdjSSY (- SelectStartY (: scroll))
            VisibleSSY (+ AdjSSY ShiftDown (/ SelectStartX (+ WindowWidth 1)))

            VisibleX (+ MarginOffset 3
                        (% (: cursorx) (+ WindowWidth 1))
                        (/ (: cursorx) (+ WindowWidth 1)))
            VisibleY (+ (- (: cursory) (: scroll)) ShiftDown (/ (: cursorx) (+ WindowWidth 1))))
        (for Y (range VisibleSSY VisibleY)
             (window-call> This "mvwchgat" NIL
                           Y
                           (cond
                            ((= Y (: cursory)) SelectStartX)
                            ((= Y SelectStartY) (: cursorx))
                            (T 1))
                           (cond
                            ((= SelectStartY (: cursory) Y) (+ (- (: cursorx) SelectStartX) 1))
                            ((= Y SelectStartY) (- WindowWidth SelectStartX))
                            ((= Y (: cursory)) (- WindowWidth (: cursorx)))
                            (T WindowWidth))
                           (| *REVERSE *BOLD) (: colors) 0)))))

(dm draw-cursor> ()
    (when (= LineNum (: cursory))
      (let (VisibleX (+ MarginOffset
                        (% (: cursorx) (+ WindowWidth 1))
                        (/ (: cursorx) (+ WindowWidth 1)))
            VisibleY (+ I ShiftDown (/ (: cursorx) (+ WindowWidth 1))))
        (window-call> This "mvwchgat" NIL
                      VisibleY
                      (- VisibleX 1)
                      1 (| *REVERSE *BOLD) (: colors) 0))))

(dm draw-contents> ()
    (let (Height (- (: height) 2)
          Start (max 1 (+ (: scroll) 1))
          End (min (- (length (: lines)) 1) Height)
          MarginOffset (length (format (length (: lines))))
          VisibleLines (head End (nth (: lines) Start))
          ShiftDown 0)
      (for (I . X) VisibleLines
           (when (> (+ I ShiftDown) 1)
             (setq ShiftDown (- ShiftDown 1)))
           (let (LineNum (+ (: scroll) I)
                 Offset (length (format LineNum))
                 Diff (- MarginOffset Offset)
                 LPad (if (> Diff 1)
                          (pack (mapcar '((I) " ") (range 2 Diff)))
                        "")
                 Len (+ MarginOffset (length X))
                 Rem (- (: width) Len)
                 WindowWidth (- (: width) (+ 3 MarginOffset))
                 LocalShiftDown ShiftDown
                 RPad (if (> (- Rem 5) 1)
                          (pack (mapcar '((I) " ") (range 1 (- Rem 5))))
                        ""))

             (when (= (cadr *State) Idx)
               (window-call> This "wattron" NIL (| *REVERSE *BOLD)))
             (window-call> This "mvwprintw" NIL (+ ShiftDown I) 0 "%s%d " LPad LineNum)
             (window-call> This "wattroff" NIL (| *REVERSE *BOLD))

             (when (= LineNum (: cursory)) (window-call> This "wattron" NIL *BOLD))
             (for O (+ (/ (length X) WindowWidth) 1)
                  (let (RealX (+ 1 (* (- O 1) WindowWidth))
                        Str (pack (head WindowWidth (nth (chop X) RealX))))
                       (window-call> This "mvwprintw" NIL
                                     (+ LocalShiftDown I)
                                     MarginOffset
                                     "%s%s"
                                     Str
                                     (if (< (length X) WindowWidth) RPad ""))
                       (setq LocalShiftDown (+ LocalShiftDown 1))))
             (when (= LineNum (: cursory)) (window-call> This "wattroff" NIL *BOLD))

             (draw-selection> This)
             (draw-cursor> This)
             (setq ShiftDown LocalShiftDown)))
      ShiftDown))

(dm draw-statusline> ()
    (when (= (cadr *State) Idx)
      (window-call> This "wattron" NIL (| *REVERSE *BOLD)))
    (window-call> This "mvwprintw" NIL 0 1 "\9094\ (%d, %d) \9112\ (%d, %d)\9205\   \8661\ %d \9093\ %d \9175\ %d\9205\   \9000\  %s"
                  (: cursorx)
                  (: cursory)
                  (car (: select-start))
                  (cadr (: select-start))
                  (: scroll) Idx (length (get-line> This))
                  (caddr *State))
    (window-call> This "mvwprintw" NIL 0 (- (: width) (length (: name)) 3) "<%s>" (: name))
    (window-call> This "wattroff" NIL (| *REVERSE *BOLD)))

(dm draw> (Idx)
    (window-call> This "wbkgd" NIL (color-pair (: colors)))
    (draw-box> This)
    (set (:: shift) (draw-contents> This))
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
    (move-cursor> This MX (- MY 1))
    (set (:: choice) (car (nth (: lines) (: cursory))))
    *State)

(dm handle-resize> ()
    (window-call> This "wclear" NIL)
    (set (:: width) (get-width Screen))
    (set (:: height) (get-height Screen))
    (destroy-window (: window))
    (set (:: window) (create-new-window (: x) (: y) (: width) (: height))))
