About
=====

This is a simple 'console' like window manager intended to show just how easy
it can be to define a window manager of your own in the Arcan ecosystem.

The git history is arranged as a 'step by step' demonstration where each
commit adds some notable feature. Check the Arcan blog @ arcan-fe.com for
a write-up that explains the steps in further detail.

Use
===

Follow the normal setup / install instructions for arcan, and run with:

    arcan /path/to/console_wm/console

The default keyboard modifier for WM controlled keybindings is 'right shift'
and the F1..Fn keys switches workspaces. If there is no workspace in that slow
previously, a terminal gets spawned into it. Other keybindings are:

    modifier+V : clipboard paste
    modifier+DELETE : destroy current workspace
    modifier+SYSREQ : force-reset the WM
    modifier+M : toggle client audio
