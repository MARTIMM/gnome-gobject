#TL:1:Gnome::GObject::Value:

use v6;
#-------------------------------------------------------------------------------
=begin pod

=head1 Gnome::GObject::Value

Standard Parameter and Value Types

=head1 Description

GValue provides an abstract container structure which can be copied, transformed and compared while holding a value of any (derived) type, which is registered as a GType with a GTypeValueTable in its GTypeInfo structure. Parameter specifications for most value types can be created as GParamSpec derived instances, to implement e.g. GObject properties which operate on GValue containers.

Parameter names need to start with a letter (a-z or A-Z). Subsequent characters can be letters, numbers or a '-'. All other characters are replaced by a '-' during construction.

GValue is a polymorphic type that can hold values of any other type operations and thus can be used as a type initializer for C<g_value_init()> and are defined by a separate interface.  See the [standard values API][gobject-Standard-Parameter-and-Value-Types] for details

The B<GValue> structure is basically a variable container that consists of a type identifier and a specific value of that type. The type identifier within a B<GValue> structure always determines the type of the associated value. To create a undefined B<GValue> structure, simply create a zero-filled B<GValue> structure. To initialize the B<GValue>, use the C<g_value_init()> function. A B<GValue> cannot be used until it is initialized. The basic type operations (such as freeing and copying) are determined by the B<GTypeValueTable> associated with the type ID stored in the B<GValue>. Other B<GValue> operations (such as converting values between types) are provided by this interface.

=begin comment
The code in the example program below demonstrates B<GValue>'s features.

|[<!-- language="C" -->
B<include> <glib-object.h>

static void
int2string (const GValue *src_value,
            GValue       *dest_value)
{
  if (g_value_get_int (src_value) == 42)
    g_value_set_static_string (dest_value, "An important number");
  else
    g_value_set_static_string (dest_value, "What's that?");
}

int
main (int   argc,
      char *argv[])
{
  // GValues must be initialized
  GValue a = G_VALUE_INIT;
  GValue b = G_VALUE_INIT;
  const gchar *message;

  // The GValue starts empty
  g_assert (!G_VALUE_HOLDS_STRING (&a));

  // Put a string in it
  g_value_init (&a, G_TYPE_STRING);
  g_assert (G_VALUE_HOLDS_STRING (&a));
  g_value_set_static_string (&a, "Hello, world!");
  g_printf ("C<s>\n", g_value_get_string (&a));

  // Reset it to its pristine state
  g_value_unset (&a);

  // It can then be reused for another type
  g_value_init (&a, G_TYPE_INT);
  g_value_set_int (&a, 42);

  // Attempt to transform it into a GValue of type STRING
  g_value_init (&b, G_TYPE_STRING);

  // An INT is transformable to a STRING
  g_assert (g_value_type_transformable (G_TYPE_INT, G_TYPE_STRING));

  g_value_transform (&a, &b);
  g_printf ("C<s>\n", g_value_get_string (&b));

  // Attempt to transform it again using a custom transform function
  g_value_register_transform_func (G_TYPE_INT, G_TYPE_STRING, int2string);
  g_value_transform (&a, &b);
  g_printf ("C<s>\n", g_value_get_string (&b));
  return 0;
}
]|
=end comment

=head1 Synopsis
=head2 Declaration

  unit class Gnome::GObject::Value;
  also is Gnome::GObject::Boxed;

=comment head2 Example

=end pod
#-------------------------------------------------------------------------------
use NativeCall;

use Gnome::N::X;
use Gnome::N::NativeLib;
use Gnome::N::N-GObject;
use Gnome::GObject::Type;
use Gnome::GObject::Boxed;

#-------------------------------------------------------------------------------
# gvalue.h / .c
# gvaluetypes.h / .c
#
# https://developer.gnome.org/gobject/stable/gobject-Generic-values.html
# /usr/include/glib-2.0/glib/gvaluetypes.h
# https://developer.gnome.org/gobject/stable/gobject-Standard-Parameter-and-Value-Types.html

unit class Gnome::GObject::Value:auth<github:MARTIMM>;
also is Gnome::GObject::Boxed;

#-------------------------------------------------------------------------------
#TS:1:N-GValue:
class N-GValue is repr('CStruct') is export {
  has uint64 $!g-type;

  # Data is a union. We do not use it but GTK does so here it is
  # only set to a type with 64 bits for the longest field in the union.
  has int64 $!g-data;

  submethod TWEAK {
    $!g-type = 0;
    $!g-data = 0;
  }
}

#-------------------------------------------------------------------------------
=begin pod
=head1 Methods
=head2 new

Create a new plain object.

  multi method new ( Bool :empty! )

Create an object using a native object from elsewhere. See also B<Gnome::GObject::Object>.

  multi method new ( N-GObject :$widget! )

Create an object using a native object from a builder. See also B<Gnome::GObject::Object>.

  multi method new ( Str :$build-id! )

=end pod

#TM:1:new(:init):
#TM:1:new(:type,:value):
submethod BUILD ( *%options ) {

  # prevent creating wrong widgets
  return unless self.^name eq 'Gnome::GObject::Value';

  if ? %options<init> {
    self.native-gboxed(g_value_init( N-GValue.new, %options<init>));
  }

  elsif ? %options<type> and ? %options<value> {
    my $type = %options<type>;
    self.native-gboxed(g_value_init( N-GValue.new, $type));

    my $nv := self.get-native-gboxed;
    my $value = %options<value>;

    given $type {
      when G_TYPE_BOOLEAN { g_value_set_boolean( $nv, $value); }
      when G_TYPE_CHAR { g_value_set_schar( $nv, $value); }
      when G_TYPE_UCHAR { g_value_set_uchar( $nv, $value); }
      when G_TYPE_INT { g_value_set_int( $nv, $value); }
      when G_TYPE_UINT { g_value_set_uint( $nv, $value); }
      when G_TYPE_LONG { g_value_set_long( $nv, $value); }
      when G_TYPE_ULONG { g_value_set_ulong( $nv, $value); }
      when G_TYPE_INT64 { g_value_set_int64( $nv, $value); }
      when G_TYPE_UINT64 { g_value_set_uint64( $nv, $value); }
      when G_TYPE_FLOAT { g_value_set_float( $nv, $value); }
      when G_TYPE_DOUBLE { g_value_set_double( $nv, $value); }
      when G_TYPE_STRING { g_value_set_string( $nv, $value); }
      when G_TYPE_ENUM { g_value_set_enum( $nv, $value); }
      when G_TYPE_FLAGS { g_value_set_flags( $nv, $value); }

      when G_TYPE_OBJECT {note "Type object for $value not yet available";}# { g_value_set_( $nv, $value); }
      when G_TYPE_POINTER {note "Type pointer for $value not yet available";}# { g_value_set_( $nv, $value); }
      when G_TYPE_BOXED {note "Type boxed for $value not yet available";}# { g_value_set_( $nv, $value); }
      when G_TYPE_PARAM {note "Type param for $value not yet available";}# { g_value_set_( $nv, $value); }
      when G_TYPE_VARIANT {note "Type variant for $value not yet available";}# { g_value_set_( $nv, $value); }
    }

    #self.native-gboxed($nv);
  }

  elsif %options.keys.elems {
    die X::Gnome.new(
      :message('Unsupported options for ' ~ self.^name ~
               ': ' ~ %options.keys.join(', ')
              )
    );
  }

  # only after creating the widget, the gtype is known
  self.set-class-info('GValue');
}

#-------------------------------------------------------------------------------
# no pod. user does not have to know about it.
method _fallback ( $native-sub is copy --> Callable ) {

  my Callable $s;
  try { $s = &::($native-sub); }
  try { $s = &::("g_value_$native-sub"); } unless ?$s;
#  $s = self._buildable_interface($native-sub) unless ?$s;
#  $s = self._orientable_interface($native-sub) unless ?$s;

  self.set-class-name-of-sub('GValue');
  $s = callsame unless ?$s;

  $s;
}

#-------------------------------------------------------------------------------
#TM:2:g_value_init:new(:init)
=begin pod
=head2 g_value_init

Initializes I<value> with the default value of I<type>.

Returns: (transfer none): the B<GValue> structure that has been passed in

  method g_value_init ( UInt $g_type --> N-GValue  )

=item uInt $g_type; Type the B<GValue> should hold values of.

=end pod

sub g_value_init ( N-GValue $value, uint64 $g_type )
  returns N-GValue
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_copy:
=begin pod
=head2 g_value_copy

Copies the value of I<src_value> into I<dest_value>.

  method g_value_copy ( N-GValue $dest_value )

=item N-GValue $dest_value; An initialized B<GValue> structure of the same type as I<src_value>.

=end pod

sub g_value_copy ( N-GValue $src_value, N-GValue $dest_value )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_reset:
=begin pod
=head2 g_value_reset

Clears the current value in I<value> and resets it to the default value
(as if the value had just been initialized).

Returns: the B<GValue> structure that has been passed in

  method g_value_reset ( --> N-GValue  )


=end pod

sub g_value_reset ( N-GValue $value )
  returns N-GValue
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_unset:
=begin pod
=head2 g_value_unset

Clears the current value in I<value> (if any) and "unsets" the type,
this releases all resources associated with this GValue. An unset
value is the same as an uninitialized (zero-filled) B<GValue>
structure.

  method g_value_unset ( )


=end pod

sub g_value_unset ( N-GValue $value )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_set_instance:
=begin pod
=head2 [g_value_] set_instance

Sets I<value> from an instantiatable type via the
value_table's C<collect_value()> function.

  method g_value_set_instance ( Pointer $instance )

=item Pointer $instance; (nullable): the instance

=end pod

sub g_value_set_instance ( N-GValue $value, Pointer $instance )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_init_from_instance:
=begin pod
=head2 [g_value_] init_from_instance

Initializes and sets I<value> from an instantiatable type via the
value_table's C<collect_value()> function.

Note: The I<value> will be initialised with the exact type of
I<instance>.  If you wish to set the I<value>'s type to a different GType
(such as a parent class GType), you need to manually call
C<g_value_init()> and C<g_value_set_instance()>.

Since: 2.42

  method g_value_init_from_instance ( Pointer $instance )

=item Pointer $instance; (type GObject.TypeInstance): the instance

=end pod

sub g_value_init_from_instance ( N-GValue $value, Pointer $instance )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_fits_pointer:
=begin pod
=head2 [g_value_] fits_pointer

Determines if I<value> will fit inside the size of a pointer value.
This is an internal function introduced mainly for C marshallers.

Returns: C<1> if I<value> will fit inside a pointer value.

  method g_value_fits_pointer ( --> Int  )


=end pod

sub g_value_fits_pointer ( N-GValue $value )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_peek_pointer:
=begin pod
=head2 [g_value_] peek_pointer

Returns the value contents as pointer. This function asserts that
C<g_value_fits_pointer()> returned C<1> for the passed in value.
This is an internal function introduced mainly for C marshallers.

Returns: (transfer none): the value contents as pointer

  method g_value_peek_pointer ( --> Pointer  )


=end pod

sub g_value_peek_pointer ( N-GValue $value )
  returns Pointer
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_type_compatible:
=begin pod
=head2 [g_value_] type_compatible

Returns whether a B<GValue> of type I<src_type> can be copied into
a B<GValue> of type I<dest_type>.

Returns: C<1> if C<g_value_copy()> is possible with I<src_type> and I<dest_type>.

  method g_value_type_compatible ( uInt $src_type, uInt $dest_type --> Int  )

=item uInt $src_type; source type to be copied.
=item uInt $dest_type; destination type for copying.

=end pod

sub g_value_type_compatible ( uint64 $src_type, uint64 $dest_type )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_type_transformable:
=begin pod
=head2 [g_value_] type_transformable

Check whether C<g_value_transform()> is able to transform values
of type I<src_type> into values of type I<dest_type>. Note that for
the types to be transformable, they must be compatible or a
transformation function must be registered.

Returns: C<1> if the transformation is possible, C<0> otherwise.

  method g_value_type_transformable ( uInt $src_type, uInt $dest_type --> Int  )

=item uInt $src_type; Source type.
=item uInt $dest_type; Target type.

=end pod

sub g_value_type_transformable ( uint64 $src_type, uint64 $dest_type )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_transform:
=begin pod
=head2 g_value_transform

Tries to cast the contents of I<src_value> into a type appropriate
to store in I<dest_value>, e.g. to transform a C<G_TYPE_INT> value
into a C<G_TYPE_FLOAT> value. Performing transformations between
value types might incur precision lossage. Especially
transformations into strings might reveal seemingly arbitrary
results and shouldn't be relied upon for production code (such
as rcfile value or object property serialization).

Returns: Whether a transformation rule was found and could be applied.
Upon failing transformations, I<dest_value> is left untouched.

  method g_value_transform ( N-GValue $dest_value --> Int  )

=item N-GValue $dest_value; Target value.

=end pod

sub g_value_transform ( N-GValue $src_value, N-GValue $dest_value )
  returns int32
  is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
#TM:0:g_value_register_transform_func:
=begin pod
=head2 [g_value_] register_transform_func

Registers a value transformation function for use in C<g_value_transform()>.
A previously registered transformation function for I<src_type> and I<dest_type>
will be replaced.

  method g_value_register_transform_func ( uInt $src_type, uInt $dest_type, GValueTransform $transform_func )

=item uInt $src_type; Source type.
=item uInt $dest_type; Target type.
=item GValueTransform $transform_func; a function which transforms values of type I<src_type> into value of type I<dest_type>

=end pod

sub g_value_register_transform_func ( uint64 $src_type, uint64 $dest_type, GValueTransform $transform_func )
  is native(&gobject-lib)
  { * }
}}




#-------------------------------------------------------------------------------
#TM:0:g_value_set_schar:
=begin pod
=head2 g_value_set_schar

Set the contents of a C<G_TYPE_CHAR> B<GValue> to I<v_char>.

Since: 2.32

  method g_value_set_schar ( Int $v_char )

=item Int $v_char; signed 8 bit integer to be set

=end pod

sub g_value_set_schar ( N-GValue $value, int8 $v_char )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_get_schar:
=begin pod
=head2 g_value_get_schar

Get the contents of a C<G_TYPE_CHAR> B<GValue>.

Returns: signed 8 bit integer contents of I<value>
Since: 2.32

  method g_value_get_schar ( --> Int  )

=end pod

sub g_value_get_schar ( N-GValue $value )
  returns int8
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_set_uchar:
=begin pod
=head2 g_value_set_uchar

Set the contents of a C<G_TYPE_UCHAR> B<GValue> to I<v_uchar>.

  method g_value_set_uchar ( UInt $v_uchar )

=item UInt $v_uchar; unsigned character value to be set

=end pod

sub g_value_set_uchar ( N-GValue $value, byte $v_uchar )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_get_uchar:
=begin pod
=head2 g_value_get_uchar

Get the contents of a C<G_TYPE_UCHAR> B<GValue>.

Returns: unsigned character contents of I<value>

  method g_value_get_uchar ( --> UInt  )


=end pod

sub g_value_get_uchar ( N-GValue $value )
  returns byte
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_set_boolean:
=begin pod
=head2 g_value_set_boolean

Set the contents of a C<G_TYPE_BOOLEAN> B<GValue> to I<v_boolean>.

  method g_value_set_boolean ( Int $v_boolean )

=item Int $v_boolean; boolean value to be set

=end pod

sub g_value_set_boolean ( N-GValue $value, int32 $v_boolean )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_get_boolean:
=begin pod
=head2 g_value_get_boolean

Get the contents of a C<G_TYPE_BOOLEAN> B<GValue>.

Returns: boolean contents of I<value>

  method g_value_get_boolean ( --> Int  )

=end pod

sub g_value_get_boolean ( N-GValue $value )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_set_int:
=begin pod
=head2 g_value_set_int

Set the contents of a C<G_TYPE_INT> B<GValue> to I<v_int>.

  method g_value_set_int ( Int $v_int )

=item Int $v_int; integer value to be set

=end pod

sub g_value_set_int ( N-GValue $value, int32 $v_int )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_get_int:
=begin pod
=head2 g_value_get_int

Get the contents of a C<G_TYPE_INT> B<GValue>.

Returns: integer contents of I<value>

  method g_value_get_int ( --> Int  )

=end pod

sub g_value_get_int ( N-GValue $value )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_set_uint:
=begin pod
=head2 g_value_set_uint

Set the contents of a C<G_TYPE_UINT> B<GValue> to I<v_uint>.

  method g_value_set_uint ( guInt $v_uint )

=item guInt $v_uint; unsigned integer value to be set

=end pod

sub g_value_set_uint ( N-GValue $value, uint32 $v_uint )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_get_uint:
=begin pod
=head2 g_value_get_uint

Get the contents of a C<G_TYPE_UINT> B<GValue>.

Returns: unsigned integer contents of I<value>

  method g_value_get_uint ( --> guInt  )

=end pod

sub g_value_get_uint ( N-GValue $value )
  returns uint32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_set_long:
=begin pod
=head2 g_value_set_long

Set the contents of a C<G_TYPE_LONG> B<GValue> to I<v_long>.

  method g_value_set_long ( Int $v_long )

=item Int $v_long; long integer value to be set

=end pod

sub g_value_set_long ( N-GValue $value, int64 $v_long )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_get_long:
=begin pod
=head2 g_value_get_long

Get the contents of a C<G_TYPE_LONG> B<GValue>.

Returns: long integer contents of I<value>

  method g_value_get_long ( --> Int  )

=end pod

sub g_value_get_long ( N-GValue $value )
  returns int64
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_set_ulong:
=begin pod
=head2 g_value_set_ulong

Set the contents of a C<G_TYPE_ULONG> B<GValue> to I<v_ulong>.

  method g_value_set_ulong ( UInt $v_ulong )

=item UInt $v_ulong; unsigned long integer value to be set

=end pod

sub g_value_set_ulong ( N-GValue $value, uint64 $v_ulong )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_get_ulong:
=begin pod
=head2 g_value_get_ulong

Get the contents of a C<G_TYPE_ULONG> B<GValue>.

Returns: unsigned long integer contents of I<value>

  method g_value_get_ulong ( --> UInt  )

=end pod

sub g_value_get_ulong ( N-GValue $value )
  returns uint64
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_set_int64:
=begin pod
=head2 g_value_set_int64

Set the contents of a C<G_TYPE_INT64> B<GValue> to I<v_int64>.

  method g_value_set_int64 ( Int $v_int64 )

=item Int $v_int64; 64bit integer value to be set

=end pod

sub g_value_set_int64 ( N-GValue $value, int64 $v_int64 )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_get_int64:
=begin pod
=head2 g_value_get_int64

Get the contents of a C<G_TYPE_INT64> B<GValue>.

Returns: 64bit integer contents of I<value>

  method g_value_get_int64 ( --> Int  )

=end pod

sub g_value_get_int64 ( N-GValue $value )
  returns int64
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_set_uint64:
=begin pod
=head2 g_value_set_uint64

Set the contents of a C<G_TYPE_UINT64> B<GValue> to I<v_uint64>.

  method g_value_set_uint64 ( guInt $v_uint64 )

=item guInt $v_uint64; unsigned 64bit integer value to be set

=end pod

sub g_value_set_uint64 ( N-GValue $value, uint64 $v_uint64 )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_get_uint64:
=begin pod
=head2 g_value_get_uint64

Get the contents of a C<G_TYPE_UINT64> B<GValue>.

Returns: unsigned 64bit integer contents of I<value>

  method g_value_get_uint64 ( --> guInt  )

=end pod

sub g_value_get_uint64 ( N-GValue $value )
  returns uint64
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_set_float:
=begin pod
=head2 g_value_set_float

Set the contents of a C<G_TYPE_FLOAT> B<GValue> to I<v_float>.

  method g_value_set_float ( Num $v_float )

=item Num $v_float; float value to be set

=end pod

sub g_value_set_float ( N-GValue $value, num32 $v_float )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_get_float:
=begin pod
=head2 g_value_get_float

Get the contents of a C<G_TYPE_FLOAT> B<GValue>.

Returns: float contents of I<value>

  method g_value_get_float ( --> Num  )

=end pod

sub g_value_get_float ( N-GValue $value )
  returns num32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_set_double:
=begin pod
=head2 g_value_set_double

Set the contents of a C<G_TYPE_DOUBLE> B<GValue> to I<v_double>.

  method g_value_set_double ( Num $v_double )

=item Num $v_double; double value to be set

=end pod

sub g_value_set_double ( N-GValue $value, num64 $v_double )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_get_double:
=begin pod
=head2 g_value_get_double

Get the contents of a C<G_TYPE_DOUBLE> B<GValue>.

Returns: double contents of I<value>

  method g_value_get_double ( --> Num  )

=end pod

sub g_value_get_double ( N-GValue $value )
  returns num64
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_set_enum:
sub g_value_set_enum ( N-GValue $value, int32 $v_enum )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_get_enum:
sub g_value_get_enum ( N-GValue $value )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_set_flags:
sub g_value_set_flags ( N-GValue $value, uint32 $v_flags )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_get_flags:
sub g_value_get_flags ( N-GValue $value )
  returns uint32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_set_string:
=begin pod
=head2 g_value_set_string

Set the contents of a C<G_TYPE_STRING> B<GValue> to I<v_string>.

  method g_value_set_string ( Str $v_string )

=item Str $v_string; (nullable): caller-owned string to be duplicated for the B<GValue>

=end pod

sub g_value_set_string ( N-GValue $value, Str $v_string )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_set_static_string:
=begin pod
=head2 g_value_set_static_string

Set the contents of a C<G_TYPE_STRING> B<GValue> to I<v_string>.
The string is assumed to be static, and is thus not duplicated
when setting the B<GValue>.

  method g_value_set_static_string ( Str $v_string )

=item Str $v_string; (nullable): static string to be set

=end pod

sub g_value_set_static_string ( N-GValue $value, Str $v_string )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_get_string:
=begin pod
=head2 g_value_get_string

Get the contents of a C<G_TYPE_STRING> B<GValue>.

Returns: string content of I<value>

  method g_value_get_string ( --> Str  )

=end pod

sub g_value_get_string ( N-GValue $value )
  returns Str
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_dup_string:
=begin pod
=head2 g_value_dup_string

Get a copy the contents of a C<G_TYPE_STRING> B<GValue>.

Returns: a newly allocated copy of the string content of I<value>

  method g_value_dup_string ( --> Str  )

=end pod

sub g_value_dup_string ( N-GValue $value )
  returns Str
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_set_pointer:
=begin pod
=head2 g_value_set_pointer

Set the contents of a pointer B<GValue> to I<v_pointer>.

  method g_value_set_pointer ( Pointer $v_pointer )

=item Pointer $v_pointer; pointer value to be set

=end pod

sub g_value_set_pointer ( N-GValue $value, Pointer $v_pointer )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_get_pointer:
=begin pod
=head2 g_value_get_pointer

Get the contents of a pointer B<GValue>.

Returns: (transfer none): pointer contents of I<value>

  method g_value_get_pointer ( --> Pointer  )

=end pod

sub g_value_get_pointer ( N-GValue $value )
  returns Pointer
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_gtype_get_type:
=begin pod
=head2 g_gtype_get_type



  method g_gtype_get_type ( --> uInt  )


=end pod

sub g_gtype_get_type (  )
  returns uint64
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_set_gtype:
=begin pod
=head2 g_value_set_gtype

Set the contents of a C<G_TYPE_GTYPE> B<GValue> to I<v_gtype>.

Since: 2.12

  method g_value_set_gtype ( uInt $v_gtype )

=item uInt $v_gtype; B<GType> to be set

=end pod

sub g_value_set_gtype ( N-GValue $value, uint64 $v_gtype )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_get_gtype:
=begin pod
=head2 g_value_get_gtype

Get the contents of a C<G_TYPE_GTYPE> B<GValue>.

Since: 2.12

Returns: the B<GType> stored in I<value>

  method g_value_get_gtype ( --> uInt  )

=end pod

sub g_value_get_gtype ( N-GValue $value )
  returns uint64
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_set_variant:
=begin pod
=head2 g_value_set_variant

Set the contents of a variant B<GValue> to I<variant>.
If the variant is floating, it is consumed.

Since: 2.26

  method g_value_set_variant ( N-GValue $variant )

=item N-GValue $variant; (nullable): a B<GVariant>, or C<Any>

=end pod

sub g_value_set_variant ( N-GValue $value, N-GValue $variant )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_take_variant:
=begin pod
=head2 g_value_take_variant

Set the contents of a variant B<GValue> to I<variant>, and takes over
the ownership of the caller's reference to I<variant>;
the caller doesn't have to unref it any more (i.e. the reference
count of the variant is not increased).

If I<variant> was floating then its floating reference is converted to
a hard reference.

If you want the B<GValue> to hold its own reference to I<variant>, use
C<g_value_set_variant()> instead.

This is an internal function introduced mainly for C marshallers.

Since: 2.26

  method g_value_take_variant ( N-GValue $variant )

=item N-GValue $variant; (nullable) (transfer full): a B<GVariant>, or C<Any>

=end pod

sub g_value_take_variant ( N-GValue $value, N-GValue $variant )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_get_variant:
=begin pod
=head2 g_value_get_variant

Get the contents of a variant B<GValue>.

Returns: (transfer none) (nullable): variant contents of I<value> (may be C<Any>)

Since: 2.26

  method g_value_get_variant ( --> N-GValue  )

=end pod

sub g_value_get_variant ( N-GValue $value )
  returns N-GValue
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_dup_variant:
=begin pod
=head2 g_value_dup_variant

Get the contents of a variant B<GValue>, increasing its refcount. The returned
B<GVariant> is never floating.

Returns: (transfer full) (nullable): variant contents of I<value> (may be C<Any>);
should be unreffed using C<g_variant_unref()> when no longer needed

Since: 2.26

  method g_value_dup_variant ( --> N-GValue  )

=end pod

sub g_value_dup_variant ( N-GValue $value )
  returns N-GValue
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_pointer_type_register_static:
=begin pod
=head2 g_pointer_type_register_static

Creates a new C<G_TYPE_POINTER> derived type id for a new
pointer type with name I<name>.

Returns: a new C<G_TYPE_POINTER> derived type id for I<name>.

  method g_pointer_type_register_static ( Str $name --> uInt  )

=item Str $name; the name of the new pointer type.

=end pod

sub g_pointer_type_register_static ( Str $name )
  returns uint64
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_strdup_value_contents:
=begin pod
=head2 g_strdup_value_contents

Return a newly allocated string, which describes the contents of a
B<GValue>.  The main purpose of this function is to describe B<GValue>
contents for debugging output, the way in which the contents are
described may change between different GLib versions.

Returns: Newly allocated string.

  method g_strdup_value_contents ( --> Str  )

=end pod

sub g_strdup_value_contents ( N-GValue $value )
  returns Str
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_take_string:
=begin pod
=head2 g_value_take_string

Sets the contents of a C<G_TYPE_STRING> B<GValue> to I<v_string>.

Since: 2.4

  method g_value_take_string ( Str $v_string )

=item Str $v_string; (nullable): string to take ownership of

=end pod

sub g_value_take_string ( N-GValue $value, Str $v_string )
  is native(&gobject-lib)
  { * }
