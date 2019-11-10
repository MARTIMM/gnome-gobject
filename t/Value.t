use v6;
use NativeCall;
use Test;

use Gnome::GObject::Value;
use Gnome::GObject::Type;

#use Gnome::N::X;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
my Gnome::GObject::Value $v .= new(:init(G_TYPE_STRING));
#-------------------------------------------------------------------------------
subtest 'ISA test', {
  $v .= new(:init(G_TYPE_STRING));
  isa-ok $v, Gnome::GObject::Value, '.new(:init)';
}

#-------------------------------------------------------------------------------
subtest 'Manipulations', {

  #$v .= new(:type(G_TYPE_STRING));
  $v.set-string('new value');
  is $v.get-string, 'new value', '.set-string() / .get-string()';

  $v .= new( :type(G_TYPE_INT), :value(42));
  is $v.get-int, 42, '.new( :type, :value) / .get-int()';

  $v .= new( :type(G_TYPE_DOUBLE), :value(42.6334e3));
  is $v.get-double, 42633.4e0, 'double value returned';
}

#-------------------------------------------------------------------------------
done-testing;
