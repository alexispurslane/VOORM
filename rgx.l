(class +Rgx)

# The initial function which replaces @ with {at} and matches normally.
# If the normal match was a success we loop through the auxiliary tests.
# Ex. call: (match> '+Rgx "yaddayay@gmail.com" '((word > 0) "{at}" (dmn > 0) "." (ltr > 2 < 5)))

(dm match> (Str Ptrn)
  (let Lstr (replace (chop Str) '@ "{at}")
     (=: ptrns (list))
     (when (match (getPtrn> This Ptrn) Lstr)
        (loop 
           (T (= 64 (: pNum)) T)
           (NIL (tstRslt> This (val (intern (pack "@" (char (: pNum)))))))))))
    

# Evaluates each test, first the length constraints and then the contents.
# Clst == Check List, ex: (ltr > 2 < 5)
# Res: ("g" "m" "a" "i" "l")
# eval ex: (ltr> 'This '("g" "m" "a" "i" "l"))

(dm tstRslt> (Res Num)
  (let Clst (pop (: ptrns))
     (and 
        (if (> 2 (length (cdr Clst))) T (len> This Res (cdr Clst)))
        (eval (list (intern (pack (sym (car Clst)) ">")) 'This (lit Res))) 
        (t (dec (:: pNum))))))
    

# Gets the pattern that will be used in the "normal" match.

(dm getPtrn> (Ptrn)
  (=: pNum 64)
  (make
     (while Ptrn 
        (let Cur (pop 'Ptrn)
           (ifn (lst? Cur)
              (link Cur)
              (link (makeLink> This Cur)) ) ) ) ) )


# Makes sub-patterns, ex.: @A. Also stores our "tests" in (: ptrns), ex: (ltr > 2 < 5).

(dm makeLink> (Cur) 
  (push (: ptrns) Cur)
  (intern (pack "@" (char (inc (:: pNum))))) )


# Example: (tst-len> '+Rgx "hel#looo" 'alnum '(> 6))

(dm tst-len> (Str Fun Ct)
  (and
     (len> This Str Ct)
     (eval (list (intern (pack (sym Fun) ">")) 'This (lit Str)))))


# Evaluates the length part of the test patterns, ex: (> 2 < 5) or (> 2).

(dm len> (Res Ct)
  (and 
     (eval (list (car Ct) (length Res) (cadr Ct))) 
     (if (= 2 (length Ct)) T (eval (list (caddr Ct) (length Res) (cadddr Ct))) ) ) )


# Main test function that puts together the function to use with find.

(dm tst> (Res F)
  (unless (lst? Res) 
     (setq Res (chop Res)))
  (not (find '((C) (F This (char C))) Res)))
    

# Called test cases, uses negations to test with.

# Ye old ascii
(dm ascii> (Res)
    (tst> This Res 'nAscii>))

# Alpha numericals
(dm alnum> (Res)
    (tst> This Res 'nAlNum>))

# Numbers
(dm num> (Res)
    (tst> This Res 'nNum>))

# Whites
(dm white> (Res)
    (tst> This Res 'nWhite>))

# Word characters
(dm word> (Res)
    (tst> This Res 'nWord>))

# Letters
(dm ltr> (Res)
    (tst> This Res 'nLtr>))

# Allowed domain name characters
(dm dmn> (Res)
    (tst> This Res 'nDmn>))

# Single char testing functions that are used in conjuction with find.
# The reason these functions are separated and whose content is not
# passed directly to find is that the ability to combine them into arbitrarily
# complex tests is a good thing even if that means we have to write some
# redundant code. It might pay off in the long run. Besides, this way they can
# be called separately to test single characters, could come in handy.

(dm nLtr> (cn)
    (or (> 65 cn) (and (> 97 cn) (< 90 cn)) (< 122 cn)))

(dm nHyph> (cn)
    (<> 45 cn))

(dm nNum> (cn)
    (or (> 48 cn) (< 57 cn)))

(dm nDmn> (cn)
    (and (nLtr> This cn) (nHyph> This cn)))

(dm nAscii> (cn)
    (< 127 cn))

(dm nWhite> (cn)
    (< 32 cn))

(dm nWord> (cn)
    (or (> 33 cn) (= 127 cn)))

(dm nAlNum> (cn)
    (and (nLtr> This cn) (nNum> This cn)))
