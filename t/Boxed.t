use v6;
use NativeCall;
use Test;

use Gnome::N::X;
use Gnome::GObject::Boxed;

#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
subtest 'create boxed', {
  my Gnome::GObject::Boxed $b .= new(:empty);
  isa-ok $b, Gnome::GObject::Boxed;
}

#-------------------------------------------------------------------------------
done-testing;
