(setq *Loc "/usr/share/voorm/")

(load "/usr/lib/picolisp/lib.l")
(load (pack *Loc "ncurses.l"))
(load (pack *Loc "editor.l"))

(de main ()
    (in-screen
     Screen
     (curses "curs_set" NIL 0)
     (curses "start_color")
     (curses "init_pair" NIL 1 *COLOR-WHITE *COLOR-BLUE)
     (setq *Frames '())
     (setq CmdFileName (car (argv)))
     (setq CmdFileName1 (cadr (argv)))

     (let (MainFrame (new '(+Editor +FromFile +VisibleFrame)
                          0 0
                          (/ (get-width Screen) 2) (get-height Screen)
                          (list "") 1 1 1 CmdFileName)
           SideFrame (new '(+Editor +FromFile +VisibleFrame)
                          (/ (get-width Screen) 2) 0
                          (/ (get-width Screen) 2) (get-height Screen)
                          (list "") 1 1 1 CmdFileName1))
          (load-from-file> MainFrame)
          (load-from-file> SideFrame)
          (setq *Frames (append *Frames (list MainFrame SideFrame))))

     (setq *Focus 1)
     (finally (mapcar delete> *Frames)
              (setq *Mode 'normal)
              (until (= (length *Frames) 0)
                     (for (I . F) *Frames (draw> F *Mode (= I *Focus) I))
                     (let F (car (nth *Frames *Focus))
                          (when F
                            (let ((@Mode @Exit @MPos @NFocus) (update> F *Mode *Focus))
                              (setq *Focus (or (+ 1 (% (- @NFocus 1) (length *Frames))) *Focus))
                              (setq *Mode @Mode)
                              (when @MPos
                                (let ((@MX @MY) @MPos
                                      MatchingFrame (find
                                                     '((F) (pos-inside> F @MX @MY))
                                                     *Frames))
                                  (when MatchingFrame
                                    (setq *Focus (index MatchingFrame *Frames)))))
                              (when @Exit
                                (setq *Frames (delete F *Frames))
                                (setq *Focus (length *Frames))
                                (delete> F)))))))))
(main)
(bye)

