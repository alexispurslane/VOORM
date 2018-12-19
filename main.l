(setq *Loc "/usr/share/voorm/")

(load "/usr/lib/picolisp/lib.l")
(load (pack *Loc "ncurses.l"))
(load (pack *Loc "editor.l"))

(de create-frames (Argv)
    (let (Frames '() Width (/ (get-width Screen) (length Argv)))
      (for (I . FileName) Argv
           (let Frame (new '(+Editor +FromFile +VisibleFrame)
                           (* (- I 1) Width) 0
                           Width (get-height Screen)
                           (list "") 1 1 1 FileName)
                (load-from-file> Frame)
                (push 'Frames Frame)))
      Frames))

(de mouse-choose-frame (MX MY)
    (let MatchingFrame (find '((F) (pos-inside> F MX MY)) (car *State))
         (when MatchingFrame (index MatchingFrame (car *State)))))

(de get-mouse-x (Event) (- (get Event 2 1) 5))
(de get-mouse-y (Event) (get Event 2 2))

(de update-state (Ch Frame)
    (cond
     ((= Ch *KEY-RESIZE)
      (for (I . F) @Frames (handle-resize> F I))
      (list @Frames @Focus @Mode))
     ((= Ch *KEY-MOUSE)
      (when (= (curses "getmouse" 'N
                       '(Event (20 I (I . 3) I))) 0)
        (let (MX (get-mouse-x Event)
              MY (get-mouse-y Event)
              MCF (mouse-choose-frame MX MY))
          (cond
           ((pos-inside> Frame MX MY) (handle-mouse> Frame (- MX (: x)) (- MY (: y))))
           (MCF (list @Frames MCF @Mode))
           (T (list @Frames @Focus @Mode))))))
     ((>= Ch 0) (handle-key> Frame Ch)))
    *State)

(de init-screen ()
    (curses "curs_set" NIL 0)
    (curses "start_color")
    (curses "init_pair" NIL 1 *COLOR-WHITE *COLOR-BLUE))

(de clear-memory ()
    (mapcar delete> (car *State)))

(de no-frames-left ()
    (or (not (lst? (car *State))) (= (length (car *State)) 0)))

(de draw-frames ()
    (for (I . F) @Frames (draw> F I)))

(de main ()
    (in-screen
     Screen

     (setq *State (list (create-frames (argv)) 1 'normal))
     (init-screen)

     (finally (clear-memory)
              (until (no-frames-left)
                     (let ((@Frames @Focus @Mode) *State)
                       (draw-frames)
                       (let Ch (curses "getch" 'I)
                            (prinl Ch)
                            (let Frame (car (nth @Frames @Focus))
                                 (when Frame
                                   (setq *State (update-state Ch Frame))))))))))
(main)
(bye)
