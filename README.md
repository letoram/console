About
=====

This is a simple 'console' like window manager intended to show just how easy
it can be to define a window manager of your own in the Arcan ecosystem.

The git history is arranged as a 'step by step' demonstration where each
commit adds some notable feature.

The blog post:
https://arcan-fe.com/2018/10/31/walkthrough-writing-a-kmscon-console-like-window-manager-using-arcan/
describes things in further detail.

_The window manager has been merged into the main arcan repository and is part of the
default distribution. Future development is being done there (github.com/letoram/arcan)_

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

Config
===

The arcan\_db tool can be used to set additional configuration options:

    arcan_db add_appl_kv console key value

The accepted keys are:

    keymap (default = devmaps/keyboard/default.lua)
    connection_point (default = console)
    terminal (extra terminal arguments, see ARCAN_ARG=help afsrv_terminal)
    font_size (preferred font size in PT)
    terminal_font (preferred terminal font, searched in ARCAN_FONTPATH env)

