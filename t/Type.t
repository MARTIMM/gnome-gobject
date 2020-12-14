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
subtest 'type tests', {

#  diag 'G_TYPE_FUNDAMENTAL_SHIFT: ' ~ G_TYPE_FUNDAMENTAL_SHIFT;
#  diag 'G_TYPE_MAKE_FUNDAMENTAL_MAX: ' ~ G_TYPE_MAKE_FUNDAMENTAL_MAX;
  diag 'G_TYPE_INVALID: ' ~ G_TYPE_INVALID;
  diag 'G_TYPE_NONE: ' ~ G_TYPE_NONE;
  diag 'G_TYPE_INTERFACE: ' ~ G_TYPE_INTERFACE;
  diag 'G_TYPE_CHAR: ' ~ G_TYPE_CHAR;
  diag 'G_TYPE_UCHAR: ' ~ G_TYPE_UCHAR;
  diag 'G_TYPE_BOOLEAN: ' ~ G_TYPE_BOOLEAN;
  diag 'G_TYPE_INT: ' ~ G_TYPE_INT;
  diag 'G_TYPE_UINT: ' ~ G_TYPE_UINT;
  diag 'G_TYPE_LONG: ' ~ G_TYPE_LONG;
  diag 'G_TYPE_ULONG: ' ~ G_TYPE_ULONG;
  diag 'G_TYPE_INT64: ' ~ G_TYPE_INT64;
  diag 'G_TYPE_UINT64: ' ~ G_TYPE_UINT64;
  diag 'G_TYPE_ENUM: ' ~ G_TYPE_ENUM;
  diag 'G_TYPE_FLAGS: ' ~ G_TYPE_FLAGS;
  diag 'G_TYPE_FLOAT: ' ~ G_TYPE_FLOAT;
  diag 'G_TYPE_DOUBLE: ' ~ G_TYPE_DOUBLE;
  diag 'G_TYPE_STRING: ' ~ G_TYPE_STRING;
  diag 'G_TYPE_POINTER: ' ~ G_TYPE_POINTER;
  diag 'G_TYPE_BOXED: ' ~ G_TYPE_BOXED;
  diag 'G_TYPE_PARAM: ' ~ G_TYPE_PARAM;
  diag 'G_TYPE_OBJECT: ' ~ G_TYPE_OBJECT;
  diag 'G_TYPE_VARIANT: ' ~ G_TYPE_VARIANT;
}

#-------------------------------------------------------------------------------
done-testing;
