use v6;
use NativeCall;
use Test;

use Gnome::GObject::Param;

#use Gnome::N::X;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
my Gnome::GObject::Param $p .= new;
#-------------------------------------------------------------------------------
subtest 'ISA test', {
  isa-ok $p, Gnome::GObject::Param;
  is $p.get-native-object.flags, 0, 'no flags set';
  ok $p.is-valid, '.is-valid()';
}

#-------------------------------------------------------------------------------
done-testing;
#`{{

#-------------------------------------------------------------------------------
subtest 'Manipulations', {
  is 1, 1, 'ok';
}
}}
