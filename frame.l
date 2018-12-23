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

(dm select-start> () (: select-start))

(dm start-selection> ()
    (set (:: select-start) (list (: cursorx) (: cursory))))

(dm in-selection> (X Y)
    (and (>= (car (: select-start)) X)
         (<= (: cursorx))
         (>= (cadr (: select-start)))
         (<= (: cursory))))

(dm selected-text> ()
    (let Selection '()
         (for (LY . L) (head (+ 1 (- (: cursory)
                                     (cadr (: select-start))))
                             (nth (: lines) (cadr (: select-start))))
              (let (LY (+ LY (- (cadr (: select-start)) 1))
                    Line (chop L)
                    Dist (cond
                          ((= LY (cadr (: select-start)) (: cursory))
                           (- (: cursorx) (car (: select-start))))
                          ((= LY (cadr (: select-start)))
                           (- (length Line) (car (: select-start))))
                          ((= LY (: cursory)) (: cursorx))
                          (T (length Line)))
                    SX (cond
                        ((= LY (cadr (: select-start)))
                         (car (: select-start)))
                        ((= LY (: cursory))
                         (: cursorx))
                        (T 1))
                    Section (head (+ Dist 1) (nth Line SX))
                    NewLineInsert (append Selection
                                          (list (if (> (- LY (cadr (: select-start))) 0) "\n" "")
                                                Section)))
                (setq Selection NewLineInsert)))
         (pack Selection)))

(dm copy> (Register)
    (put (cadddr *State) Register (selected-text> This)))

(dm paste> (Register)
    (mapcar '((C) (add-char> This C)) (chop (get (cadddr *State) Register))))

(dm get-line> (Y) (car (nth (: lines) (or Y (: cursory)))))

(dm move-cursor> (CX CY)
    (let (LineLen (length (get-line> This CY))
          FileLen (length (: lines)))
      (set (:: cursorx) (max 1 (min (+ 1 LineLen) CX)))
      (set (:: cursory) (max 1 (min (length (: lines)) CY)))))

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
