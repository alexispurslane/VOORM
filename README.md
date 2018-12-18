# VOORM
## Lightweight, extensable, hotloading, VIM-compatable

VOORM is an editor born out of inspiration... It combines the philosophy of the language it is
written in-- PicoLisp, and the central, core ideas useful to making a good editor.
VOORM has four main goals:

1. VOORM must be lightweight, like PicoLisp. It must have a minimal CPU and memory footprint
   by default. This is not just purism speaking: in order to support a large variety of plugins
   and be fast and usable in spite of that, VOORM as a platform must be solid and unobtrusive--
  like a good foundation.
2. VOORM must be extensable, like Emacs. All of VOORM, both internal editor functionality and 
   the frameworks VOORM is built in, must be available to the plugins that run in it. Part of 
   this, however, is making VOORM *safe*: the libraries and functionality exposed by VOORM must
   be powerful, but not risk crashing it.
3. VOORM must be hotloading. VOORM must be able to run arbitrary picoLisp code in the context of
   the editor itself, performantly and stably. Plugins, user extentions, and scripts should be
   able to add to the editor and be removed from the editor without a restart.
4. VOORM must be VIM-compatable. Leveraging the wide userbase that has both muscle-memory for
   and an appreciation of VIM-keybindings, VOORM must support this extremely powerful mode of
   operation. (Pun intended)

All of these features are made possible by PicoLisp: for VOORM to be lightweight, we had few
choices, and almost none of them had the ability to do the other points as well as picolisp did.
For VOORM to be extensable, as much and more then Emacs, its exention language must be the same
as it's implementation language. Without being written in a interpreted, dynamic, flexible
language like PicoLisp, this would be impossible!
For VOORM to be hotloading, the logic is much the same, but even more so! With PicoLisp's
dynamic scoping, formal equivalency of code and data, and extreme dynamism, powerful hotloading
capabilities are within our reach.




