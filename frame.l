(class +Frame)

(dm T (Str CX CY)
    (=: lines (or Str (list "")))
    (=: cursorx (or CX 1))
    (=: cursory (or CY 1))
    (=: clipboard 'clipboard)
    (=: select-start NIL))

(dm text> ()
    (apply pack (mapcar '((S) (pack S "\n")) (: lines))))
(dm lines> ()
    (: lines))
(dm cursor-x> () (: cursorx))
(dm cursor-y> () (: cursory))

(de real-y (Text Pos)
    (prinl "Real Y: " Pos)
    (flush)
    (let (Y 1 Text (chop Text))
         (for I Pos
              (let C (car (nth Text I))
                   (if (= C "\n")
                       (setq Y (+ 1 Y)))))
         Y))

(de real-x (Text Pos)
    (prinl "Real X: " Pos)
    (flush)
    (let (C "" Text (chop Text))
      (max 1
           (- Pos (for (I Pos (and (>= I 1) (not (= C "\n"))) (dec I))
                       (setq C (car (nth Text I)))
                       I)))))

(de offset-to-points (MatchPtr)
    (prinl "Matched at: " MatchPtr)
    (let ((StringOffsetStart StringOffsetEnd) MatchPtr
          RealY1 (real-y (text> This) (+ 1 StringOffsetStart))
          RealX1 (real-x (text> This) (+ 1 StringOffsetStart))
          RealY2 (real-y (text> This) (+ 1 StringOffsetEnd))
          RealX2 (real-x (text> This) (+ 1 StringOffsetEnd)))
      (prinl "Real Points: " RealX1 ", " RealY1 "; " RealX2 ", " RealY2)
      (list (list RealX1 RealY1) (list RealX2 RealY2))))

(dm look-for> (Pat)
    (let (String (text> This))
      (use (Preg MatchPtrList)
           (native "@" "regcomp" 'I '(Preg (64 B . 64)) Pat 1)
           (let Result (native "@" "regexec" 'I
                               (cons NIL (64) Preg)
                               String
                               0
                               '(MatchPtrList (400 (I . 2)) . 0)
                               0)
                (println MatchPtrList)
                (cond
                 ((=0 Result)
                  (println MatchPtrList)
                  (mapcar offset-to-points MatchPtrList))
                 (T (prinl "Search Failed: C library returned " Result)
                    '()))))))

(dm select-start> () (: select-start))

(dm start-selection> ()
    (set (:: select-start) (list (: cursorx) (: cursory))))

(de >pnt (A B)
    (let ((X1 Y1) A (X2 Y2) B)
      (or (> X1 X2) (> Y1 Y2))))
(de <pnt (A B)
    (let ((X1 Y1) A (X2 Y2) B)
      (or (< X1 X2) (< Y1 Y2))))

(dm order-sel-pnts> ()
    (cond
     ((>pnt (: select-start) (list (: cursorx) (: cursory)))
      (list (list (: cursorx) (: cursory)) (: select-start)))
     ((<pnt (: select-start) (list (: cursorx) (: cursory)))
      (list (: select-start) (list (: cursorx) (: cursory))))
     (T (list (: select-start) (list (: cursorx) (: cursory))))))

(dm in-selection> (X Y)
    (let (((SX SY) (CX CY)) (order-sel-pnts> This))
      (and (: select-start)
           (cond
            ((and (= Y SY CY) (>= X SX) (<= X CX)) T)
            ((and (= Y CY) (not (= Y SY)) (<= X CX)) T)
            ((and (= Y SY) (not (= Y CY)) (>= X SX)) T)
            (T (and (< Y CY) (> Y SY)))))))

(dm selected-text> ()
    (let (Selection '()
          ((SX SY) (CX CY)) (order-sel-pnts> This))
         (for (LY . L) (head (+ 1 (- CY SY))
                             (nth (: lines) SY))
              (let (LY (+ LY (- SY 1))
                    Line (chop L)
                    Dist (cond
                          ((= LY SY CY) (- CX SX))
                          ((= LY SY) (- (length Line) SX))
                          ((= LY CY) (- CX 1))
                          (T (length Line)))
                    S1X (cond
                        ((= LY SY) SX)
                        ((= LY CY) 1)
                        (T 1))
                    Section (head (+ Dist 1) (nth Line S1X))
                    NewLineInsert (append Selection
                                          (list (if (> (- LY SY) 0) "\n" "") Section)))
                (setq Selection NewLineInsert)))
         (pack Selection)))

(dm copy> (Register)
    (put (cadddr *State) Register (selected-text> This)))

(dm paste> (Register)
    (mapcar '((C) (add-char> This C)) (chop (get (cadddr *State) Register))))

(dm delete-between> (Pos1 Pos2)
    (let (Begin (head (- (cadr Pos1) 1) (: lines))
                Insert (cond
                        ((> (car Pos1) 1)
                         (head (max 1 (- (car Pos1) 2)) (chop (get-line> This (cadr Pos1)))))
                        (T ""))
          End (nth (: lines) (+ (cadr Pos2) 1))
          Outert (nth (chop (get-line> This (cadr Pos2))) (+ (car Pos2) 1)))
      (set (:: lines) (append Begin (list (pack Insert Outert)) End))))

(dm get-line> (Y) (car (nth (: lines) (or Y (: cursory)))))

(dm move-cursor> (CX CY)
    (let (LineLen (length (get-line> This CY))
          FileLen (length (: lines)))
      (set (:: cursorx) (max 1 (min (+ 1 LineLen) CX)))
      (set (:: cursory) (max 1 (min (max 1 (length (: lines))) CY)))))

(dm adjust-cursor> (DX DY)
    (move-cursor> This
                  (+ DX (: cursorx))
                  (+ DY (: cursory))))

(dm replace-char> (Text)
    (delete-char>)
    (add-char> Text))

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

(class +Popup)

(dm register-handler> (Callback)
    (set (:: callbacks) (cons Callback (: callbacks))))

(dm handle-mouse> (MX MY)
    (move-cursor> This MX (+ MY (: scroll)))
    *State)

(dm pos-inside> (MX MY)
    (and (>= MX (: x)) (>= MY (: y))
         (<= MY (+ (: height) (: y))) (<= MX (+ (: x) (: width)))))

(dm handle-key> (Ch)
    (let (Frames (car *State) Focus (cadr *State) Mode (caddr *State) Clipboard (cadddr *State))
      (setq Exit NIL)
      (cond
       ((= Ch *KEY-LEFT) (adjust-cursor> This -1 0))
       ((= Ch *KEY-UP) (adjust-cursor> This 0 -1))
       ((= Ch *KEY-DOWN) (adjust-cursor> This 0 1))
       ((= Ch *KEY-RIGHT) (adjust-cursor> This 1 0))
       ((= Ch (char "")) (delete-char> This))
       ((= Ch (char "q")) (setq Exit T))
       ((or (= Ch (char "\n")) (= Ch (char "\r")))
        (setq Exit T))
       ((= Ch 27) (setq Exit T))
       (T (add-char> This (char Ch))))
      (if Exit
          (let Res (list (delete This Frames) (max 1 (- (length Frames) 1)) Mode Clipboard)
               (delete> This)
               (curses "clear" NIL)
               (for Callback (: callbacks) (Callback (get-line> This)))
               Res)
        (list Frames Focus Mode Clipboard))))
