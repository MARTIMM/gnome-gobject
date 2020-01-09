use v6;
use NativeCall;
use Test;

use Gnome::GObject::Value;
use Gnome::GObject::Type;

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

  $v.g_value_unset;
  ok $v.get-native-object.g-type == G_TYPE_INVALID, '.g_value_unset()';
  nok $v.is-valid, '.is-valid() False after unset';
}

#-------------------------------------------------------------------------------
subtest 'Manipulations', {

  $v .= new( :type(G_TYPE_BOOLEAN), :value(True));
  is $v.get-boolean.Bool, True, '.new( :type, :value) / .get-boolean()';
  $v.set-boolean(False);
  is $v.get-boolean.Bool, False, '.set-boolean()';
  $v.g_value_unset;

  $v .= new( :type(G_TYPE_CHAR), :value(41));
  is $v.get-schar, 41, '.new( :type, :value) / .get-schar()';
  $v.set-schar(-80);
  is $v.get-schar, -80, '.set-schar()';
  $v.g_value_unset;

  $v .= new( :type(G_TYPE_UCHAR), :value(130));
  is $v.get-uchar, 130, '.new( :type, :value) / .get-uchar()';
  $v.set-uchar(200);
  is $v.get-uchar, 200, '.set-uchar()';
  $v.g_value_unset;

  $v .= new( :type(G_TYPE_INT), :value(-42));
  is $v.get-int, -42, '.new( :type, :value) / .get-int()';
  $v.set-int(-1001);
  is $v.get-int, -1001, '.set-int()';
  $v.g_value_unset;

  $v .= new( :type(G_TYPE_UINT), :value(42));
  is $v.get-uint, 42, '.new( :type, :value) / .get-uint()';
  $v.set-uint(1001);
  is $v.get-uint, 1001, '.set-uint()';
  $v.g_value_unset;

  $v .= new( :type(G_TYPE_LONG), :value(-20304050607));
  is $v.get-long, -20304050607, '.new( :type, :value) / .get-long()';
  $v.set-long(-20304050607786);
  is $v.get-long, -20304050607786, '.set-long()';
  $v.g_value_unset;

  $v .= new( :type(G_TYPE_ULONG), :value(76523847654));
  is $v.get-ulong, 76523847654, '.new( :type, :value) / .get-ulong()';
  $v.set-ulong(7652384765432);
  is $v.get-ulong, 7652384765432, '.set-ulong()';
  $v.g_value_unset;

  $v .= new( :type(G_TYPE_INT64), :value(-20304050607));
  is $v.get-int64, -20304050607, '.new( :type, :value) / .get-int64()';
  $v.set-int64(-2030405007);
  is $v.get-int64, -2030405007, '.set-int64()';
  $v.g_value_unset;

  $v .= new( :type(G_TYPE_UINT64), :value(3847));
  is $v.get-uint64, 3847, '.new( :type, :value) / .get-uint64()';
  $v.set-uint64(7654);
  is $v.get-uint64, 7654, '.set-uint64()';
  $v.g_value_unset;

  $v .= new( :type(G_TYPE_FLOAT), :value(42.6334e1));
  is-approx $v.get-float, 42633.4e-2, '.new( :type, :value) / .get-float()';
  $v.set-float(42.63354e1);
  is-approx $v.get-float, 426335.4e-3, '.set-float()';
  $v.g_value_unset;

  $v .= new( :type(G_TYPE_DOUBLE), :value(42.6334e13));
  is-approx $v.get-double, 42633.4e10, '.get-double()';
  $v.set-double(1001e15);
  is-approx $v.get-double, 1001e15, '.set-double()';
  $v.g_value_unset;

  $v .= new( :type(G_TYPE_STRING), :value('new value'));
  is $v.get-string, 'new value', '.new( :type, :value) / .get-string()';
  $v.set-string('other value');
  is $v.get-string, 'other value', '.set-string()';
  $v.g_value_unset;

#`{{
Gnome::N::debug(:on);
  enum SomeType ( :Tset1(0x1), :Tset2(0x2), :Tset3(0x4), :Tset4(0x8) );
  my N-GEnumValue $ev .= new(
    :value(Tset2), :value_name('Tset2'), :value_nick('ts2')
  );
  $v .= new(:init(G_TYPE_ENUM));
#  is $v.get-gtype, G_TYPE_ENUM, '.new(:init(G_TYPE_ENUM))';
  $v.set-enum($ev);
  is SomeType($v.get-enum.value), Tset2, '.set-enum() / .get-enum()';
}}

#`{{
  enum SomeType ( :Tset1(0x1), :Tset2(0x2), :Tset3(0x4), :Tset4(0x8) );
  my N-GEnumValue $ev .= new(
    :value(Tset2), :value_name('Tset2'), :value_nick('ts2')
  );
  $v .= new( :type(G_TYPE_ENUM), :value($ev));

#  is SomeType($v.get-enum), Tset2, '.new( :type, :value) / .get-enum()';
#  $v.set-enum(Tset4);
#  is $v.get-enum, Tset4, '.set-enum()';
  $v.g_value_unset;
}}

#`{{
  $v .= new( :type(G_TYPE_FLAGS), :value(Tset2 +| Tset4));
  is $v.get-flags, 0xa, '.new( :type, :value) / .get-flags()';
  $v.set-flags(Tset3 +| Tset1);
  is $v.get-flags, 0x5, '.set-flags()';
  $v.g_value_unset;
}}
}

#-------------------------------------------------------------------------------
done-testing;
