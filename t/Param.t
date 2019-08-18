use v6;
use NativeCall;
use Test;

use Gnome::GObject::Param;

#use Gnome::N::X;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
my Gnome::GObject::Param $p .= new(:gparam());
#-------------------------------------------------------------------------------
subtest 'ISA test', {
  isa-ok $p, Gnome::GObject::Param;
}

#-------------------------------------------------------------------------------
subtest 'Manipulations', {
  is 1, 1, 'ok';
}

#-------------------------------------------------------------------------------
done-testing;
