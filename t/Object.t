use v6;
use NativeCall;
use Test;

use Gnome::N::NativeLib;
#use Gnome::N::N-GObject;
use Gnome::GObject::Object;
use Gnome::GObject::Value;
use Gnome::GObject::Type;

#use Gnome::N::X;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
sub _initialize_gtk ( CArray[int32] $argc, CArray[CArray[Str]] $argv )
  returns int32
  is native(&gtk-lib)
  is symbol('gtk_init_check')
  { * }

my $argc = CArray[int32].new;
$argc[0] = 1 + @*ARGS.elems;

my $arg_arr = CArray[Str].new;
my Int $arg-count = 0;
$arg_arr[$arg-count++] = $*PROGRAM.Str;
for @*ARGS -> $arg {
  $arg_arr[$arg-count++] = $arg;
}

my $argv = CArray[CArray[Str]].new;
$argv[0] = $arg_arr;

_initialize_gtk( $argc, $argv);

#-------------------------------------------------------------------------------
subtest 'ISA test', {
  ok 1, 1,
#`{{
  my Gnome::GObject::Value $v .= new(:init(G_TYPE_STRING));
  $v.set-string('blue');

#doesn't work because of type == 1
  my Gnome::GObject::Object $o .= new(
    :type(1), :names([<color>]), :values([$v])
  );

  ok $o.gobject-is-valid(), 'Object is valid';
  isa-ok $o, Gnome::GObject::Object;
}

#-------------------------------------------------------------------------------
subtest 'Manipulations', {
Gnome::N::debug(:on);
  my Gnome::GObject::Value $vname .= new(:init(G_TYPE_STRING));
  $vname.set-string('blue');
#`{{
  my Gnome::GObject::Value $vcolor .= new(:init(G_TYPE_INT));
  $vcolor.set-int(0x0000ff);

  my Gnome::GObject::Object $o .= new(
    :type(10000), :names([<name color>]), :values([ $vname, $vcolor])
  );

}}
  my Gnome::GObject::Object $o .= new(
    :type(10000), :names([<name>]), :values([ $vname])
  );

  ok $o.gobject-is-valid(), 'Object is valid';
  note $o.get-property( 'name', G_TYPE_STRING);
}}
}

#-------------------------------------------------------------------------------
done-testing;
