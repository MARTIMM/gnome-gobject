use v6;
use NativeCall;

use Gnome::N::X:api<1>;
use Gnome::N::NativeLib:api<1>;
use Gnome::GObject::Object:api<1>;

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

  # when direct init here, die on it
  die X::Gnome.new(:message('Forbidden to initialize for ' ~ self.^name));
}
