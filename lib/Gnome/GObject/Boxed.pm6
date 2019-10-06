use v6;
use NativeCall;

use Gnome::N::X;
use Gnome::N::NativeLib;

#-------------------------------------------------------------------------------
# See /usr/include/glib-2.0/glib/gboxed.h
# https://developer.gnome.org/gobject/stable/gobject-Boxed-Types.html
unit class Gnome::GObject::Boxed:auth<github:MARTIMM>;

#-------------------------------------------------------------------------------
# No subs implemented yet.
#-------------------------------------------------------------------------------
# No type specified. GBoxed is a wrapper for any structure
has Any $!g-boxed;

has Int $!gboxed-class-gtype;
has Str $!gboxed-class-name;
has Str $!gboxed-class-name-of-sub;

#-------------------------------------------------------------------------------
submethod BUILD (*%options ) {

  if %options.keys.elems == 0 {
    note 'No options used to create or set the native widget'
      if $Gnome::N::x-debug;
    die X::Gnome.new(
      :message('No options used to create or set the native widget')
    );
  }
}

#-------------------------------------------------------------------------------
#TODO destroy when overwritten?
method CALL-ME ( $g-boxed? --> Any ) {

  if ?$g-boxed {
    $!g-boxed = $g-boxed;
  }

  $!g-boxed
}

#-------------------------------------------------------------------------------
method FALLBACK ( $native-sub is copy, |c ) {

  CATCH { test-catch-exception( $_, $native-sub); }

  # convert all dashes to underscores if there are any. then check if
  # name is not too short.
  $native-sub ~~ s:g/ '-' /_/ if $native-sub.index('-');
  die X::Gnome.new(:message(
      "Native sub name '$native-sub' made too short. Keep at least one '-' or '_'."
    )
  ) unless $native-sub.index('_') >= 0;

  # check if there are underscores in the name. then the name is not too short.
  my Callable $s;

  # call the _fallback functions of this classes children starting
  # at the bottom
  $s = self._fallback($native-sub);

  die X::Gnome.new(:message("Native sub '$native-sub' not found"))
      unless $s.defined;
#  unless $s.defined {
#    note "Native sub '$native-sub' not found";
#    return;
#  }

  # User convenience substitutions to get a native object instead of
  # a GtkSomeThing or GlibSomeThing object
  my Array $params = [];
  for c.list -> $p {
    if $p.^name ~~ m/:s ^ 'Gnome::' [ Gtk || Gdk || Glib || GObject ] '::'/ {
      $params.push($p());
    }

    else {
      $params.push($p);
    }
  }

  # cast to other gtk object type if the found subroutine is from another
  # gtk object type than the native object stored at $!g-boxed. This happens
  # e.g. when a Gnome::Gtk::Button object uses gtk-widget-show() which
  # belongs to Gnome::Gtk::Widget.
  my $g-object-cast;

#note "type class: $!gboxed-class-gtype, $!gboxed-class-name";
  #TODO Not all classes have $!gboxed-class-* defined so we need to test it
  if ?$!gboxed-class-gtype and ?$!gboxed-class-name and
     ?$!gboxed-class-name-of-sub and
     $!gboxed-class-name ne $!gboxed-class-name-of-sub {

    note "\nObject gtype: $!gboxed-class-gtype" if $Gnome::N::x-debug;
    note "Cast $!gboxed-class-name to $!gboxed-class-name-of-sub"
      if $Gnome::N::x-debug;

    $g-object-cast = Gnome::GObject::Type.new().check-instance-cast(
      $!g-boxed, $!gboxed-class-gtype
    );
  }

  test-call( $s, $!g-boxed, |$params)
}

#-------------------------------------------------------------------------------
method _fallback ( $native-sub is copy --> Callable ) {

#  my Callable $s;
#  try { $s = &::($native-sub); }
#  try { $s = &::("g_type_module_$native-sub"); } unless ?$s;

#  $s = callsame unless ?$s;

  my Callable $s = callsame;
  $s
}

#-------------------------------------------------------------------------------
#TODO destroy when overwritten?
method native-gboxed ( Any:D $g-boxed --> Any ) {

  $!g-boxed = $g-boxed;
}

#-------------------------------------------------------------------------------
method get-native-gboxed ( --> Any ) {

  $!g-boxed
}

#-------------------------------------------------------------------------------
# no pod. user does not have to know about it.
method set-class-info ( Str:D $!gboxed-class-name ) {
  $!gboxed-class-gtype = _g_type_from_name($!gboxed-class-name);
}

#-------------------------------------------------------------------------------
# no pod. user does not have to know about it.
method set-class-name-of-sub ( Str:D $!gboxed-class-name-of-sub ) { }

#-------------------------------------------------------------------------------
=begin pod
=head2 get-class-gtype

Return class's type code after registration. this is like calling Gnome::GObject::Type.new().g_type_from_name(GTK+ class type name).

  method get-class-gtype ( --> Int )
=end pod

method get-class-gtype ( --> Int ) {
  $!gboxed-class-gtype
}

#-------------------------------------------------------------------------------
=begin pod
=head2 get-class-name

Return class name.

  method get-class-name ( --> Str )
=end pod

method get-class-name ( --> Str ) {
  $!gboxed-class-name
}

#-------------------------------------------------------------------------------
# Must specify this from Gnome::GObject::Type because of circ dependency
# via Gnome::GObject::Value
sub _g_type_from_name ( Str $name )
  returns int32
  is native(&gobject-lib)
  is symbol('g_type_from_name')
  { * }
