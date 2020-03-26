use v6;
use NativeCall;

use Gnome::N::X;
use Gnome::N::N-GObject;
use Gnome::N::NativeLib;
use Gnome::N::TopLevelClassSupport;

#-------------------------------------------------------------------------------
# See /usr/include/glib-2.0/glib/gboxed.h
# https://developer.gnome.org/gobject/stable/gobject-Boxed-Types.html
unit class Gnome::GObject::Boxed:auth<github:MARTIMM>;
also is Gnome::N::TopLevelClassSupport;

#-------------------------------------------------------------------------------
# No type specified. GBoxed is a wrapper for any structure
#has Any $!g-boxed;

# Wrapped object is not valid
#has Bool $.is-valid = False;

#has Int $!gboxed-class-gtype;
#has Str $!gboxed-class-name;
#has Str $!gboxed-class-name-of-sub;

#-------------------------------------------------------------------------------
#`{{
submethod BUILD (*%options ) {
  if %options.keys.elems == 0 {
    note 'No options used to create or set the native widget'
      if $Gnome::N::x-debug;
    die X::Gnome.new(
      :message('No options used to create or set the native widget')
    );
  }
}
}}

#`{{
#-------------------------------------------------------------------------------
method FALLBACK ( $native-sub is copy, *@params is copy, *%named-params ) {

  CATCH { test-catch-exception( $_, $native-sub); }

  # convert all dashes to underscores if there are any. then check if
  # name is not too short.
  $native-sub ~~ s:g/ '-' /_/ if $native-sub.index('-').defined;

  # check if there are underscores in the name. then the name is not too short.
  my Callable $s;

  # call the _fallback functions of this classes children starting
  # at the bottom
  $s = self._fallback($native-sub);

  die X::Gnome.new(:message("Native sub '$native-sub' not found"))
      unless $s.defined;

  # cast to other g object type if the found subroutine is from another
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

  convert-to-natives(@params);
  test-call( $s, $!g-boxed, |@params, |%named-params)
}
}}

#-------------------------------------------------------------------------------
method _fallback ( $native-sub is copy --> Callable ) {

#  my Callable $s;
#  try { $s = &::("g_$native-sub"); }
#  try { $s = &::($native-sub); } if !$s and $native-sub ~~ m/^ 'g_' /;

#  $s = callsame unless ?$s;

  my Callable $s = callsame;
  $s
}

#-------------------------------------------------------------------------------
#TODO destroy when overwritten?
method native-gboxed ( Any:D $g-boxed --> Any ) {

  Gnome::N::deprecate(
    '.native-gboxed()', '.set-native-object()', '0.15.10', '0.18.0'
  );

  self.set-native-object($g-boxed) if ? $g-boxed;
  self.get-native-object

#  $!g-boxed = $g-boxed;
#  $!g-boxed
}

#-------------------------------------------------------------------------------
method get-native-gboxed ( --> Any ) {

  Gnome::N::deprecate(
    '.get-native-gboxed()', '.get-native-object()', '0.15.10', '0.18.0'
  );

  self.get-native-object
#  $!g-boxed
}

#`{{
#-------------------------------------------------------------------------------
# Boxed class has no knoledge of wrapped abjects. Destroy must take place there
method set-native-object ( Any $g-boxed ) {

#TODO destroy when overwritten?
#TODO clear-object call into child methods? something like an abstract method
#TODO method clear-object ( ) { !!! }.
#TODO This removes the need to set/clear is-valid using calls to methods

  if $g-boxed.defined {
    $!g-boxed = $g-boxed;
    $!is-valid = True;
  }
}

#-------------------------------------------------------------------------------
method get-native-object ( --> Any ) {

  $!g-boxed
}

#-------------------------------------------------------------------------------
#TM:1:is-valid
# doc of $!is-valid defined above
=begin pod
=head2 is-valid

Returns True if native boxed object is valid, otherwise C<False>.

  method is-valid ( --> Bool )

=end pod
}}

#-------------------------------------------------------------------------------
# no info to the user!
#method set-valid ( Bool $v = False ) {
#  $!is-valid = $v;
#}

#`{{
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
}}

#`{{
#-------------------------------------------------------------------------------
# ? no ref/unref for a all boxed types must be
method native-object-ref ( $n-native-object --> Any ) {
  $n-native-object
}

#-------------------------------------------------------------------------------
method native-object-unref ( $n-native-object ) {
#  _g_..._free($n-native-object)
}
}}
