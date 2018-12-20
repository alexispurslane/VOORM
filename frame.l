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
