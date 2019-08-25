use v6;
use NativeCall;
use Test;

use Gnome::GObject::Object;
use Gnome::GObject::Value;
use Gnome::GObject::Type;

#use Gnome::N::X;
Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
subtest 'ISA test', {
  my Gnome::GObject::Value $v .= new(:init(G_TYPE_STRING));
  $v.set-string('blue');

  my Gnome::GObject::Object $o .= new(
    :type(1), :names([<color>]), :values([$v])
  );

  isa-ok $o, Gnome::GObject::Object;
}

#-------------------------------------------------------------------------------
subtest 'Manipulations', {
  my Gnome::GObject::Value $vname .= new(:init(G_TYPE_STRING));
  $vname.set-string('blue');
  my Gnome::GObject::Value $vcolor .= new(:init(G_TYPE_INT));
  $vcolor.set-int(0x0000ff);

  my Gnome::GObject::Object $o .= new(
    :type(10000), :names([<name color>]), :values([ $vname, $vcolor])
  );

note "NO: $o.gobject-is-valid(), ", $o();
  note $o.get-property( 'name', G_TYPE_STRING);
}

#-------------------------------------------------------------------------------
done-testing;
