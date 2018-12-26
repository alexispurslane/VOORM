(setq *MAIN-COLOR 6)
(setq *BORDER-COLOR 2)
(setq *SELECTION-COLOR 8)

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
    (window-call> This "wborder" NIL 32 32 32 32 32 32 32 32))

(dm draw-selection> ()
    (when (and (: select-start) (<= (cadr (: select-start)) I) (>= (: cursory) I))
      (let (SelectStartX (car (: select-start))
            SelectStartY (cadr (: select-start))
            VisibleSSX (+ (- MarginOffset 1)
                          (% SelectStartX (+ WindowWidth 1))
                          (/ SelectStartX (+ WindowWidth 1)))
            AdjSSY (- SelectStartY (: scroll))
            VisibleSSY (+ AdjSSY ShiftDown (/ SelectStartX (+ WindowWidth 1)))

            VisibleX (+ MarginOffset
                        (% (: cursorx) (+ WindowWidth 1))
                        (/ (: cursorx) (+ WindowWidth 1)))
            VisibleY (+ I ShiftDown (/ (: cursorx) (+ WindowWidth 1))))
        (for Y (range VisibleSSY VisibleY)
             (window-call> This "mvwchgat" NIL
                           Y
                           (cond
                            ((= Y VisibleSSY) VisibleSSX)
                            ((= Y VisibleY) VisibleX)
                            (T 1))
                           (cond
                            ((= Y VisibleSSY VisibleY)
                             (- VisibleX VisibleSSX))
                            ((= Y VisibleSSY)
                             (- (length Line) VisibleSSX))
                            ((= Y VisibleY) VisibleX)
                            (T (length Line)))
                           0 *SELECTION-COLOR 0)))))

(dm draw-cursor> ()
    (when (= LineNum (: cursory))
      (let (VisibleX (+ MarginOffset
                        (% (: cursorx) (+ WindowWidth 1))
                        (/ (: cursorx) (+ WindowWidth 1)))
            VisibleY (+ I ShiftDown (/ (: cursorx) (+ WindowWidth 1))))
        (window-call> This "mvwchgat" NIL
                      VisibleY
                      (- VisibleX 1)
                      1 0 10 0))))

(dm draw-contents> ()
    (let (Height (- (: height) 1)
          Start (max 1 (+ (: scroll) 1))
          End (min (length (: lines)) Height)
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
                 RPad (if (> Rem 1)
                          (pack (mapcar '((I) " ") (range 2 Rem)))
                        ""))

             (window-call> This "wattrset" NIL (| (color-pair *BORDER-COLOR) *BOLD))
             (window-call> This "mvwprintw" NIL (+ ShiftDown I) 0 "%s%d " LPad LineNum)

             (window-call> This "wattrset" NIL (color-pair *MAIN-COLOR))
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

             (draw-selection> This)
             (draw-cursor> This)

             (setq ShiftDown LocalShiftDown)))
      ShiftDown))

(dm draw-statusline> ()
    (let (Section1 "\9094\ (%d, %d) \9112\ (%d, %d)"
          Section2 "\8661\ %d \9093\ %d \9175\ %d"
          Section3 "\9000\  %s")
      (window-call> This "wattrset" NIL (| (color-pair 36) *REVERSE))
      (window-call> This "mvwprintw" NIL 0 1 Section1
                    (: cursorx)
                    (: cursory)
                    (car (: select-start))
                    (cadr (: select-start)))

      (window-call> This "wattrset" NIL (| (color-pair 4) *REVERSE))
      (window-call> This "wprintw" NIL "\9205\ ")

      (window-call> This "wattrset" NIL (| (color-pair 41) *REVERSE))
      (window-call> This "wprintw" NIL Section2
                    (: scroll) Idx (length (get-line> This)))

      (window-call> This "wattrset" NIL (| (color-pair 4) *REVERSE))
      (window-call> This "wprintw" NIL "\9205\ ")

      (window-call> This "wattrset" NIL (| (color-pair 46) *REVERSE))
      (window-call> This "wprintw" NIL Section3
                    (caddr *State)))

    (window-call> This "mvwprintw" NIL 0 (- (: width) (length (: name)) 3) "<%s>" (: name)))

(dm draw> (Idx)
    (window-call> This "wbkgd" NIL (color-pair *MAIN-COLOR))


    (if (= (cadr *State) Idx)
        (window-call> This "wattrset" NIL (| (color-pair *BORDER-COLOR) *BOLD))
      (window-call> This "wattrset" NIL (color-pair *BORDER-COLOR)))

    (draw-box> This)
    (draw-statusline> This)

    (set (:: shift) (draw-contents> This))

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
