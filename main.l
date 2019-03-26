(setq *Loc "/home/christopherdumas/voorm/")

(load "/usr/lib/picolisp/lib.l")
(load "/usr/lib/picolisp/lib/misc.l")
(load (pack *Loc "ncurses.l"))
(load (pack *Loc "frame.l"))
(load (pack *Loc "graphics.l"))
(load (pack *Loc "editor.l"))

(de create-frames (Argv)
    (unless (> (length Argv) 0)
        (setq Argv (list "scratch.txt")))
    (let (Frames '() Width (/ (get-width Screen) (length Argv)))
      (for (I . FileName) Argv
           (let Frame (new '(+Editor +FromFile +VisibleFrame)
                           (* (- I 1) Width) 0
                           Width (get-height Screen)
                           (list "") 1 1 1 FileName)
                (unless (= FileName "scratch.txt")
                  (load-from-file> Frame))
                (push 'Frames Frame)))
      Frames))

(de mouse-choose-frame (MX MY)
    (let MatchingFrame (find '((F) (pos-inside> F MX MY)) (car *State))
         (when MatchingFrame (index MatchingFrame (car *State)))))

(de get-mouse-x (Event) (get Event 2 1))
(de get-mouse-y (Event) (get Event 2 2))

(de update-state (Ch Frame)
    (cond
     ((= Ch *KEY-RESIZE)
      (for (I . F) Frames (handle-resize> F I))
      *State)
     ((= Ch *KEY-MOUSE)
      (when (= (curses "getmouse" 'N
                       '(Event (20 I (I . 3) I))) 0)
        (let (MX (get-mouse-x Event)
              MY (get-mouse-y Event)
              MCF (mouse-choose-frame MX MY))
          (cond
           ((pos-inside> Frame MX MY)
            (handle-mouse> Frame
                           (- MX (pos-x> Frame))
                           (- MY (pos-y> Frame))))
           (MCF (list Frames MCF Mode Clipboard))
           (T *State)))))
     ((>= Ch 0) (handle-key> Frame Ch))))

(de adjust-color (C)
    (min 1000 (max 1 (* C 4))))

(de init-screen ()
    (curses "curs_set" NIL 0)
    (curses "start_color")
    (let (Config (eval (in "/usr/share/voorm/voorm-settings.l" (read)))
          Schemes (cdr (assoc 'color-scheme-colors Config))
          SchemeName (cdr (assoc 'color-scheme Config))
          Colors (cdr (assoc SchemeName Schemes))
          Fgds (5 6 7 9 10 11 12 13 14 15 16)
          Bgds (1 2 3 4 8)
          ColorPairs (uniq (mapcar '((Fgd) (mapcar '((Bgd) (cons Fgd Bgd)) Bgds)) Fgds)))
      (prinl "Scheme Count: " (length Schemes))

      (prin "Scheme Names: ")
      (println (mapcar car Schemes))

      (prinl "Chosen Scheme: " SchemeName)

      (prinl "Colors:")
      (println Colors)
      (for (I . C) Colors
           (let (Color
                 (cond [(str? C)
                        (let (Color (chop C) Colors '())
                          (for I 3
                               (let (Sect (head 2 (nth Color (+ 1 (* (- I 1) 2))))
                                     ColorPart (list (adjust-color (hex (pack Sect)))))
                                 (setq Colors (append Colors ColorPart))))
                          Colors)]
                       [(lst? C) (mapcar adjust-color C)]
                       [T (prinl "Error parsing color")])
                 (R G B) Color)
             (prinl I ": rgb(" R ", " G ", " B ")")
             (curses "init_color" NIL (+ 7 I) R G B)))
      (let I 1
           (for (Y . ColorPairs2) ColorPairs
                (for (X . P) (uniq ColorPairs2)
                     (prinl "Color pair " I ": { Foreground = " (+ 7 (car P))
                            ", Background = " (+ 7 (cdr P)) "  }")
                     (curses "init_pair" NIL I (+ 7 (car P)) (+ 7 (cdr P)))
                     (setq I (+ 1 I)))))))

(de no-frames-left ()
    (or (not (lst? (car *State))) (= (length (car *State)) 0)))

(de draw-frames ()
    (for (I . F) (car *State) (draw> F I)))

(de main ()
    (in-screen
     Screen
     (out (pack *Loc "voorm.log")
          (prinl (catch '("Undefined" "No such file" "Div")
                   (setq *State (list (create-frames (argv)) 1 'normal 'clipboard))
                   (init-screen)

                   (draw-frames)
                   (until (no-frames-left)
                          (let (Frames (car *State)
                                       Focus (cadr *State)
                                       Mode (caddr *State)
                                       Clipboard (cadddr *State))
                            (draw-frames)
                            (let? Frame (isa '+VisibleFrame (car (nth Frames Focus)))
                                  (setq *State (update-state (window-call> Frame "wgetch" 'I)
                                                             Frame))))))))))
(main)
(prinl "Bye!")
(bye)
