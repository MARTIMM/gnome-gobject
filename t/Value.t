use v6;
use NativeCall;
use Test;

use Gnome::GObject::Value;
use Gnome::GObject::Type;
use Gnome::N::GlibToRakuTypes;

use Gnome::N::X;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
my Gnome::GObject::Value $v .= new(:init(G_TYPE_STRING));
#-------------------------------------------------------------------------------
subtest 'ISA test', {
  $v .= new(:init(G_TYPE_STRING));
  isa-ok $v, Gnome::GObject::Value, '.new(:init)';
  ok $v.is-valid, '.is-valid() True after :init';

  $v .= new( :type(G_TYPE_STRING), :value('new value'));
  is $v.get-string, 'new value', '.new( :type, :value)';
  ok $v.is-valid, '.is-valid() True after :type and :value';

  $v.g_value_reset;
  nok ?$v.get-string, '.g_value_reset()';
  is $v.get-native-object.g-type, G_TYPE_STRING,
      'native object type still string';
  ok $v.is-valid, '.is-valid() True after reset';

  $v.clear-object;
  nok $v.is-valid, '.clear-object()';
}

#-------------------------------------------------------------------------------
subtest 'Manipulations', {

  $v .= new( :type(G_TYPE_BOOLEAN), :value(True));
  is $v.get-boolean.Bool, True, '.get-boolean()';
  $v.set-boolean(False);
  is $v.get-boolean.Bool, False, '.set-boolean()';
  $v.clear-object;

  $v .= new( :type(G_TYPE_CHAR), :value(41));
  is $v.get-schar, 41, '.get-schar()';
  $v.set-schar(-80);
  is $v.get-schar, -80, '.set-schar()';
  $v.clear-object;

  $v .= new( :type(G_TYPE_UCHAR), :value(130));
  is $v.get-uchar, 130, '.get-uchar()';
  $v.set-uchar(200);
  is $v.get-uchar, 200, '.set-uchar()';
  $v.clear-object;

  $v .= new( :type(G_TYPE_INT), :value(-42));
  is $v.get-int, -42, '.get-int()';
  $v.set-int(-1001);
  is $v.get-int, -1001, '.set-int()';
  $v.clear-object;

  $v .= new( :type(G_TYPE_UINT), :value(42));
  is $v.get-uint, 42, '.get-uint()';
  $v.set-uint(1001);
  is $v.get-uint, 1001, '.set-uint()';
  $v.clear-object;

#Gnome::N::debug(:on);
#`{{
  my glong $gl1 = -2030;
  diag "gl1: $gl1";
  my gulong $gl2 = -2030;
  diag "gl2: $gl2";
  my guint32 $gl3 = -2030;
  diag "gl3: $gl3";
  diag "G_TYPE_LONG: " ~ G_TYPE_LONG;

  sub a (--> glong) {-2030};
  diag 'sub a: ' ~ a();
}}
  $v .= new( :type(G_TYPE_LONG), :value(-2030));
  is $v.get-long, -2030, '.get-long()';
  $v.set-long(-7786);
  is $v.get-long, -7786, '.set-long()';
  $v.clear-object;

  $v .= new( :type(G_TYPE_ULONG), :value(47654));
  is $v.get-ulong, 47654, '.get-ulong()';
  $v.set-ulong(65432);
  is $v.get-ulong, 65432, '.set-ulong()';
  $v.clear-object;
#Gnome::N::debug(:off);

  $v .= new( :type(G_TYPE_INT64), :value(-20304050607));
  is $v.get-int64, -20304050607, '.get-int64()';
  $v.set-int64(-2030405007);
  is $v.get-int64, -2030405007, '.set-int64()';
  $v.clear-object;

  $v .= new( :type(G_TYPE_UINT64), :value(3847));
  is $v.get-uint64, 3847, '.get-uint64()';
  $v.set-uint64(7654);
  is $v.get-uint64, 7654, '.set-uint64()';
  $v.clear-object;

  $v .= new( :type(G_TYPE_FLOAT), :value(42.6334e1));
  is-approx $v.get-float, 42633.4e-2, '.get-float()';
  $v.set-float(42.63354e1);
  is-approx $v.get-float, 426335.4e-3, '.set-float()';
  $v.clear-object;

  $v .= new( :type(G_TYPE_DOUBLE), :value(42.6334e13));
  is-approx $v.get-double, 42633.4e10, '.get-double()';
  $v.set-double(1001e15);
  is-approx $v.get-double, 1001e15, '.set-double()';
  $v.clear-object;

  $v .= new( :type(G_TYPE_STRING), :value('new value'));
  is $v.get-string, 'new value', '.get-string()';
  $v.set-string('other value');
  is $v.get-string, 'other value', '.set-string()';
  $v.clear-object;

#`{{
#TODO G_TYPE_ENUM is abstract. Must use a GType of a real enumeration.
# See https://stackoverflow.com/questions/58540419/how-do-you-set-an-enum-property-on-a-glib-object

  $v .= new(:init(G_TYPE_ENUM));
  $v.set-enum(0x124);
  is $v.get-enum, 0x124, '.set-enum() / .get-enum()';
  $v.clear-object;

#TODO G_TYPE_FLAGS idem
  $v .= new( :type(G_TYPE_FLAGS), :value(0x20F));
  is $v.get-flags, 0x20F, '.get-flags()';
  $v.set-flags(0x80);
  is $v.get-flags, 0x80, '.set-flags()';
  $v.clear-object;
}}

  ok $v.type-compatible( G_TYPE_INT64, G_TYPE_INT64), '.type-compatible()';
  ok $v.type-transformable( G_TYPE_INT, G_TYPE_INT64), '.type-transformable()';

  my Gnome::GObject::Type $t .= new;
  $v .= new(:init($t.gtype-get-type));
  $v.set-gtype(0xff);
  is $v.get-gtype, 0xff, 't.gtype-get-type() / .set-gtype() / .get-gtype()';

  ok $v.type-compatible( G_TYPE_INT64, G_TYPE_INT64), '.type-compatible()';
  ok $v.type-transformable( G_TYPE_INT, G_TYPE_INT64), '.type-transformable()';

#  ok $v.type-transformable( G_TYPE_FLAGS, G_TYPE_INT), '.type-transformable()';
#  my Gnome::GObject::Value $v1 .= new( :type(G_TYPE_FLAGS), :value(0x20F));
#  my Gnome::GObject::Value $v2 .= new( :type(G_TYPE_INT), :value(-1));
#  ok $v1.transform($v2), '.transform() ok';
#  is $v2.get-int, 0x20F, '.transform() int matches flags';
}

#-------------------------------------------------------------------------------
done-testing;
