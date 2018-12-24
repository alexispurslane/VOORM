(setq *Loc "/usr/share/voorm/")

(load "/usr/lib/picolisp/lib.l")
(load (pack *Loc "ncurses.l"))
(load (pack *Loc "frame.l"))
(load (pack *Loc "graphics.l"))
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
          Colors (cdr (assoc 'color-scheme-colors Config))
          Scheme (cdr (assoc 'color-scheme Config))
          Bkg (cond
               ((= Scheme 'dark) *COLOR-SCHEME-BACKGROUND-DARK)
               ((= Scheme 'light) *COLOR-SCHEME-BACKGROUND-LIGHT)))
      (out "/usr/share/voorm/voorm.log"
           (prinl "Colors:")
           (for (I . C) Colors
                (let (OR (adjust-color (car C)) OG (adjust-color (cadr C)) OB (adjust-color (caddr C)))
                  (prinl I ": rgb(" OR ", " OG ", " OB ")")
                  (curses "init_color" NIL (+ 7 I) OR OG OB)))
           (curses "init_pair" NIL 1
                   (cond
                    ((= Scheme 'dark) *COLOR-SCHEME-TEXT)
                    ((= Scheme 'light) *COLOR-SCHEME-BACKGROUND-DARK))
                   Bkg)
           (curses "init_pair" NIL 2 *COLOR-SCHEME-COMMENT Bkg)
           (curses "init_pair" NIL 3 *COLOR-SCHEME-FUNCTION Bkg)
           (curses "init_pair" NIL 4 *COLOR-SCHEME-VALUE Bkg)
           (curses "init_pair" NIL 5 *COLOR-SCHEME-BACKGROUND-DARK *COLOR-SCHEME-COMMENT)
           (curses "init_pair" NIL 6 *COLOR-SCHEME-BACKGROUND-DARK *COLOR-SCHEME-FUNCTION)
           (curses "init_pair" NIL 7 *COLOR-SCHEME-BACKGROUND-DARK *COLOR-SCHEME-VALUE))))

(de no-frames-left ()
    (or (not (lst? (car *State))) (= (length (car *State)) 0)))

(de draw-frames ()
    (for (I . F) (car *State) (draw> F I)))

(de main ()
    (in-screen
     Screen

     (setq *State (list (create-frames (argv)) 1 'normal 'clipboard))
     (init-screen)

     (draw-frames)
     (until (no-frames-left)
            (let (Frames (car *State) Focus (cadr *State) Mode (caddr *State) Clipboard (cadddr *State))
              (draw-frames)
              (let? Frame (isa '+VisibleFrame (car (nth Frames Focus)))
                    (setq *State (update-state (window-call> Frame "wgetch" 'I)
                                               Frame)))))))
(main)
(bye)
