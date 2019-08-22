use v6;
use NativeCall;
use Test;

use Gnome::GObject::Object;
use Gnome::GObject::Value;
use Gnome::GObject::Type;

#use Gnome::N::X;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
subtest 'ISA test', {
  my Gnome::GObject::Value $v .= new(:init(G_TYPE_STRING));
  $v.set-string('blue');

  my Gnome::GObject::Object $o .= new(
    :type(1), :names([<color>]), :values([$v])
  );

  isa-ok $o, Gnome::GObject::Object;
#  is 1, 1, 'Tests done later';
}

#-------------------------------------------------------------------------------
done-testing;
