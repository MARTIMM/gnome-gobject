use v6;
use NativeCall;

use Gnome::N::X;
use Gnome::N::NativeLib;

#-------------------------------------------------------------------------------
# See /usr/include/glib-2.0/gobject/gtypemodule.h
# https://developer.gnome.org/gobject/stable/GTypeModule.html
unit class Gnome::GObject::Interface:auth<github:MARTIMM>;

#TODO Cache the found subs here as `my`
#TODO Reset not found hits at start of search in Object to prevent repeated searches for the same sub via widget tree, a kind of $searched-before-but-not-found-here Hash {module-name}{sub-name}.

#-------------------------------------------------------------------------------
submethod BUILD ( ) { }
