use v6;
use NativeCall;

use Gnome::N::X;
use Gnome::N::NativeLib;
use Gnome::GObject::Object;

#-------------------------------------------------------------------------------
# See /usr/include/glib-2.0/gobject/gtypemodule.h
# https://developer.gnome.org/gobject/stable/GTypeModule.html
unit class Gnome::GObject::Interface:auth<github:MARTIMM>
  is Gnome::GObject::Object;

#-------------------------------------------------------------------------------
submethod BUILD ( *%options ) {

  # prevent creating wrong widgets
  return unless self.^name eq 'Gnome::GObject::Interface';

  if ? %options<widget> {
    # provided in GObject
  }

  elsif %options.keys.elems {
    die X::Gnome.new(
      :message('Unsupported options for ' ~ self.^name ~
               ': ' ~ %options.keys.join(', ')
              )
    );
  }
}

#-------------------------------------------------------------------------------
method _fallback ( $native-sub is copy --> Callable ) {

#  my Callable $s;
#  try { $s = &::($native-sub); }
#  try { $s = &::("g_type_module_$native-sub"); } unless ?$s;

#  $s = callsame unless ?$s;

  my Callable $s = callsame;
  $s;
}

#-------------------------------------------------------------------------------
# no pod. user does not have to know about it.
# Hook for modules using this interface. Same principle as _fallback but
# does not need callsame.
method _interface (
  Str $native-sub, Str $interface-class-name, Str $class-name
  --> Callable
) {

  my Callable $s;
  $s = self._fallback($native-sub) unless ?$s;

  $s;
}
