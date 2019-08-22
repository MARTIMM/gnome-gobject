use v6;
use NativeCall;
use Test;

use Gnome::GObject::Param;

#use Gnome::N::X;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
my Gnome::GObject::Param $p .= new(:empty);
#-------------------------------------------------------------------------------
subtest 'ISA test', {
  isa-ok $p, Gnome::GObject::Param;
  note $p().flags;
}

#-------------------------------------------------------------------------------
subtest 'Manipulations', {
  is 1, 1, 'ok';
}

#-------------------------------------------------------------------------------
done-testing;
