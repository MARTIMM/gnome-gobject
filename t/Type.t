use v6;
use Test;

use Gnome::GObject::Type;

#use Gnome::N::X;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
subtest 'ISA test', {
  my Gnome::GObject::Type $t .= new;
  isa-ok $t, Gnome::GObject::Type;
}

#-------------------------------------------------------------------------------
done-testing;
