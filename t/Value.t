use v6;
use NativeCall;
use Test;

use Gnome::N::X;
#use Gnome::GObject::Boxed;
use Gnome::GObject::Value;
use Gnome::GObject::Type;

#X::Gnome.debug(:on);

#-------------------------------------------------------------------------------
subtest 'create value', {
  my Gnome::GObject::Value $v .= new(:init(G_TYPE_STRING));
  isa-ok $v, Gnome::GObject::Value;
  $v.set-string('new value');
  is $v.get-string, 'new value', 'string value returned';

  $v .= new(:init(G_TYPE_INT));
  $v.set-int(42);
  is $v.get-int, 42, 'int value returned';

  $v .= new(:init(G_TYPE_DOUBLE));
  $v.set-double(42.6334e3);
  is $v.get-double, 42633.4e0, 'double value returned';
}

#-------------------------------------------------------------------------------
done-testing;
