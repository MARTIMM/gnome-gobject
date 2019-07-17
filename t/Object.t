use v6;
use NativeCall;
use Test;

use Gnome::GObject::Object;

#use Gnome::N::X;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
subtest 'ISA test', {
  my Gnome::GObject::Object $o .= new;
  isa-ok $o, Gnome::GObject::Object;
}

#-------------------------------------------------------------------------------
done-testing;
