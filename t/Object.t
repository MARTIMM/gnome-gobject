use v6;
use NativeCall;
use Test;

use Gnome::GObject::Object;

#use Gnome::N::X;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
subtest 'ISA test', {
  my Gnome::GObject::Object $o .= new(
    :type(1), :names([<color>], :values([<blue>])
  );
  isa-ok $o, Gnome::GObject::Object;
#  is 1, 1, 'Tests done later';
}

#-------------------------------------------------------------------------------
done-testing;
