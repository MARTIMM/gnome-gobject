use v6;
use NativeCall;

use Gnome::N::X;
use Gnome::N::NativeLib;
use Gnome::GObject::Object;

#-------------------------------------------------------------------------------
# No documentation, only from object hierarchy
# https://developer.gnome.org/gtk3/stable/ch02.html
unit class Gnome::GObject::InitiallyUnowned:auth<github:MARTIMM>
  is Gnome::GObject::Object;

#-------------------------------------------------------------------------------
# No subs implemented. Just setup for hierargy.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
submethod BUILD ( *%options ) {

  # prevent creating wrong widgets
  return unless self.^name eq 'Gnome::GObject::InitiallyUnowned';
  die X::Gnome.new(:message('Forbidden to initialize for ' ~ self.^name));
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
