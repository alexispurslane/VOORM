(setq *Loc "/usr/share/voorm/")

(load "/usr/lib/picolisp/lib.l")
(load (pack *Loc "ncurses.l"))

(de main ()
    (in-screen
     Screen
     (curses "curs_set" NIL 0)
     (curses "start_color")
     (curses "init_pair" NIL 1 *COLOR-WHITE *COLOR-BLUE)
     (curses "init_pair" NIL 2 *COLOR-BLUE *COLOR-WHITE)
     (setq CmdFileName (car (argv)))
     (let MainFrame (new '(+Interactive +FromFile +VisibleFrame)
                         0 0
                         (get-width Screen) (get-height Screen)
                         (list "") 1 1 1 CmdFileName)
          (load-from-file> MainFrame)
          (draw> MainFrame *Mode)
          (finally (delete> MainFrame)
                   (setq *Exit NIL)
                   (setq *Mode 'normal)
                   (until *Exit
                          (let ((@Mode @Exit) (update> MainFrame *Mode *Exit))
                            (setq *Mode @Mode)
                            (setq *Exit @Exit))
                          (draw> MainFrame *Mode)))
          (text> MainFrame))))
(println (main))
(bye)
