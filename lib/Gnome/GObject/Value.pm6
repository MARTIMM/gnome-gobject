#TL:1:Gnome::GObject::Value:

use v6;
#-------------------------------------------------------------------------------
=begin pod

=head1 Gnome::GObject::Value

Standard Parameter and Value Types

=head1 Description

This class provides an abstract container structure which can be copied, transformed and compared while holding a value of any (derived) type, which is registered as a GType with a GTypeValueTable in its GTypeInfo structure. Parameter specifications for most value types can be created as GParamSpec derived instances, to implement e.g. GObject properties which operate on GValue containers. (note that not everything is implemented in Raku)

Parameter names need to start with a letter (a-z or A-Z). Subsequent characters can be letters, numbers or a '-'. All other characters are replaced by a '-' during construction.

B<N-GValue> is a polymorphic type that can hold values of any other type operations and thus can be used as a type initializer for C<new(:$init)> and are defined by a separate interface. See the standard values API for details

The B<N-GValue> structure is basically a variable container that consists of a type identifier and a specific value of that type. The type identifier within a B<N-GValue> structure always determines the type of the associated value. To create an undefined B<N-GValue> structure, simply create a zero-filled B<N-GValue> structure. To initialize the B<N-GValue>, use the C<new(:$init)> function. A B<N-GValue> cannot be used until it is initialized. The basic type operations (such as freeing and copying) are determined by the B<GTypeValueTable> associated with the type ID stored in the B<N-GValue>. Other B<N-GValue> operations (such as converting values between types) are provided by this interface.

=begin comment
The code in the example program below demonstrates B<N-GValue>'s features.

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
  g_value_init (&a,#notePE_STRING);
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


=head2 Uml Diagram

![](plantuml/Value.svg)


=comment head2 Example

=end pod
#-------------------------------------------------------------------------------
use NativeCall;

use Gnome::N::X;
use Gnome::N::NativeLib;
#use Gnome::N::N-GValue;
use Gnome::N::GlibToRakuTypes;

use Gnome::GObject::Type;
use Gnome::GObject::Boxed;

#-------------------------------------------------------------------------------
# gvalue.h / .c
# gvaluetypes.h / .c
# gobject/genums.h /.c
#
# https://developer.gnome.org/gobject/stable/gobject-Generic-values.html
# https://developer.gnome.org/gobject/stable/gobject-Standard-Parameter-and-Value-Types.html
# https://developer.gnome.org/gobject/stable/gobject-Enumeration-and-Flag-Types.html
unit class Gnome::GObject::Value:auth<github:MARTIMM>:ver<0.2.0>;
also is Gnome::GObject::Boxed;

#-------------------------------------------------------------------------------
=head1 Types

=begin pod
=head2 N-GValue

A structure to hold a type and a value.
=coment Its type is readable from the structure as a 32 bit integer and holds type values like C<G_TYPE_UCHAR> and C<G_TYPE_LONG>.

Dynamic types from native widgets are also stored. The static type names like C<G_TYPE_UCHAR> and C<G_TYPE_LONG>, are defined in B<Gnome::GObject::Type>.

=end pod

#TS:1:N-GValue:
class N-GValue is repr('CStruct') is export {
  has GType $.g-type;

  # Data is a union. We do not use it but GTK does, so here it is
  # only set to a type with 64 bits for the longest field in the union.
  has gint64 $!g-data;

  # As if it was G_VALUE_INIT macro. g_value_init() must have
  # the $!g-type set to 0.
  submethod TWEAK {
    $!g-type = 0;
    $!g-data = 0;
  }
}

#`{{
#-------------------------------------------------------------------------------
=begin pod
=head2 class N-GEnumValue

A structure which contains a single enum value, its name, and its nickname.

=item Int $.value: the enum value
=item Str $.value-name: the name of the value
=item Str $.value-nick: the nickname of the value

=end pod

#TT:0:N-GEnumValue:
class N-GEnumValue is export is repr('CStruct') {
  has gint $.value;
  has gchar-ptr $.value_name;
  has gchar-ptr $.value_nick;
}

#-------------------------------------------------------------------------------
=begin pod
=head2 class N-GFlagsValue

A structure which contains a single flags value, its name, and its nickname.

=item UInt $.value: the flags value
=item Str $.value-name: the name of the value
=item Str $.value-nick: the nickname of the value

=end pod

#TT:0:N-GFlagsValue:
class N-GFlagsValue is export is repr('CStruct') {
  has guint $.value;
  has gchar-ptr $.value_name;
  has gchar-ptr $.value_nick;
}
}}

#-------------------------------------------------------------------------------
#TODO add $!value-is-valid flag
#-------------------------------------------------------------------------------
=begin pod
=head1 Methods
=head2 new

=head3 :init

Create a value object and initialize to type. Exampes of a type is G_TYPE_INT or G_TYPE_BOOLEAN.

  multi method new ( Int :$init! )


=head3 :type, :value

Create a value object and initialize to type and set a value.

  multi method new ( Int :$type!, Any :$value! )


=head3 :gvalue

Create an object using a native object from elsewhere.

  multi method new ( N-GValue :$gvalue! )


=head3 :native-object

Create an object using a native object from elsewhere. See also B<Gnome::N::TopLevelSupportClass>.

  multi method new ( N-GValue :$native-object! )

=end pod

#TM:1:new(:init):
#TM:1:new(:type,:value):
#TM:4:new(:native-object):
submethod BUILD ( *%options ) {

  # prevent creating wrong widgets
  return unless self.^name eq 'Gnome::GObject::Value';

  my N-GValue $new-object;

  # check if native object is set by a parent class
  if self.is-valid { }

  # process all options

  # check if common options are handled by some parent
  elsif %options<native-object>:exists { }

  elsif ? %options<init> {
    $new-object = _g_value_init( N-GValue.new, %options<init>);
  }

  elsif %options<type>.defined and %options<value>.defined {
    my GType $type = %options<type>;
    $new-object = _g_value_init( N-GValue.new, $type);

    given $type {
      when G_TYPE_BOOLEAN {
        g_value_set_boolean( $new-object, %options<value>);
      }
      when G_TYPE_CHAR { g_value_set_schar( $new-object, %options<value>); }
      when G_TYPE_UCHAR { g_value_set_uchar( $new-object, %options<value>); }
      when G_TYPE_INT { g_value_set_int( $new-object, %options<value>); }
      when G_TYPE_UINT { g_value_set_uint( $new-object, %options<value>); }
      when G_TYPE_LONG { g_value_set_long( $new-object, %options<value>); }
      when G_TYPE_ULONG { g_value_set_ulong( $new-object, %options<value>); }
      when G_TYPE_INT64 { g_value_set_int64( $new-object, %options<value>); }
      when G_TYPE_UINT64 { g_value_set_uint64( $new-object, %options<value>); }
      when G_TYPE_FLOAT { g_value_set_float( $new-object, %options<value>); }
      when G_TYPE_DOUBLE { g_value_set_double( $new-object, %options<value>); }
      when G_TYPE_STRING { g_value_set_string( $new-object, %options<value>); }

      when G_TYPE_ENUM { g_value_set_enum( $new-object, %options<value>); }
      when G_TYPE_FLAGS { g_value_set_flags( $new-object, %options<value>); }

      when G_TYPE_OBJECT {note "Type object for %options<value> not yet available";}# { g_value_set_( $new-object, %options<value>); }
      when G_TYPE_POINTER {note "Type pointer for %options<value> not yet available";}# { g_value_set_( $new-object, %options<value>); }
      when G_TYPE_BOXED {note "Type boxed for %options<value> not yet available";}# { g_value_set_( $new-object, %options<value>); }
      when G_TYPE_PARAM {note "Type param for %options<value> not yet available";}# { g_value_set_( $new-object, %options<value>); }
      when G_TYPE_VARIANT {note "Type variant for %options<value> not yet available";}# { g_value_set_( $new-object, %options<value>); }
    }
  }

  elsif %options<gvalue> ~~ N-GValue {
    Gnome::N::deprecate(
      '.new(:gvalue)', '.new(:native-object)', '0.15.11', '0.18.0'
    );

    $new-object = %options<gvalue>;
  }
#`{{
  elsif ?%options<native-object> {
    $new-object = %options<native-object>;
    $new-object .= get-native-object if $new-object ~~ Gnome::GObject::Value;
  }
}}

  elsif %options.keys.elems {
    die X::Gnome.new(
      :message('Unsupported options for ' ~ self.^name ~
               ': ' ~ %options.keys.join(', ')
              )
    );
  }

  if $new-object.defined {
#`{{
    if self.is-valid {
      g_value_unset(self.get-native-object);
#      self.set-valid(False);
    }
}}
    self.set-native-object($new-object);
  }

#note"Value: ", self.get-native-object.perl(), ', ', self.is-valid;

  # only after creating the native-object, the gtype is known
  self._set-class-info('GValue');
}

#-------------------------------------------------------------------------------
# no pod. user does not have to know about it.
method _fallback ( $native-sub is copy --> Callable ) {

  my Callable $s;
  try { $s = &::("g_value_$native-sub"); };
  try { $s = &::("g_$native-sub"); } unless ?$s;
  try { $s = &::($native-sub); } if !$s and $native-sub ~~ m/^ 'g_' /;

  self._set-class-name-of-sub('GValue');
  $s = callsame unless ?$s;

  $s;
}

#-------------------------------------------------------------------------------
# no ref/unref
method native-object-ref ( $n-native-object --> Any ) {
  $n-native-object
}

#-------------------------------------------------------------------------------
method native-object-unref ( $n-native-object ) {
#note'value cleared';
  _g_value_unset($n-native-object)
}



#-------------------------------------------------------------------------------
# TM:0:copy:
# TM:0:copy-rk:
=begin pod
=head2 copy, copy-rk

Copies the value of this Value object.

  method copy ( --> N-GValue )
  method copy-rk ( --> Gnome::GObject::Value )

=item N-GValue $dest_value; An initialized B<Gnome::GObject::Value> structure of the same type as I<src-value>.
=end pod

method copy ( --> N-GValue ) {
  my N-GValue $src_value = self.get-native-object-no-reffing;
  my N-GValue $dest_value .= new(:init($src_value.g-type));
  g_value_copy( $src_value, $dest_value);
  $dest_value
}

method copy-rk ( --> Gnome::GObject::Value ) {
  my N-GValue $src_value = self.get-native-object-no-reffing;
  my N-GValue $dest_value .= new(:init($src_value.g-type));
  g_value_copy( $src_value, $dest_value);
  Gnome::GObject::Value.new(:native-object($dest_value))
}

sub g_value_copy (
  N-GValue $src_value, N-GValue $dest_value
) is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
# TM:0:dup-string:
=begin pod
=head2 dup-string

Get a copy the contents of a C<G-TYPE-STRING> B<Gnome::GObject::Value>.

Returns: a newly allocated copy of the string content of I<value>

  method dup-string ( --> Str )

=end pod

method dup-string ( --> Str ) {

  g_value_dup_string(
    self.get-native-object-no-reffing,
  )
}

sub g_value_dup_string (
  N-GValue $value --> gchar-ptr
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:dup-variant:
=begin pod
=head2 dup-variant

Get the contents of a variant B<Gnome::GObject::Value>, increasing its refcount. The returned B<Gnome::GObject::Variant> is never floating.

Returns: variant contents of I<value> (may be C<undefined>); should be unreffed using C<g-variant-unref()> when no longer needed

  method dup-variant ( --> N-GValue )

=end pod

method dup-variant ( --> N-GValue ) {

  g_value_dup_variant(
    self.get-native-object-no-reffing,
  )
}

sub g_value_dup_variant (
  N-GValue $value --> N-GValue
) is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
# TM:0:enum-complete-type-info:
=begin pod
=head2 enum-complete-type-info

This function is meant to be called from the `complete-type-info` function of a B<Gnome::GObject::TypePlugin> implementation, as in the following example:

|[<!-- language="C" --> static void my-enum-complete-type-info (GTypePlugin *plugin, GType g-type, GTypeInfo *info, GTypeValueTable *value-table) { static const GEnumValue values[] = { { MY-ENUM-FOO, "MY-ENUM-FOO", "foo" }, { MY-ENUM-BAR, "MY-ENUM-BAR", "bar" }, { 0, NULL, NULL } };

enum-complete-type-info (type, info, values); } ]|

  method enum-complete-type-info ( N-GValue $g_enum_type, GTypeInfo $info, GEnumValue $const_values )

=item N-GValue $g_enum_type; the type identifier of the type being completed
=item GTypeInfo $info; (out callee-allocates): the B<Gnome::GObject::TypeInfo> struct to be filled in
=item GEnumValue $const_values; An array of B<Gnome::GObject::EnumValue> structs for the possible enumeration values. The array is terminated by a struct with all members being 0.
=end pod

method enum-complete-type-info ( $g_enum_type is copy, GTypeInfo $info, GEnumValue $const_values ) {
  $g_enum_type .= get-native-object-no-reffing unless $g_enum_type ~~ N-GValue;

  g_enum_complete_type_info(
    self.get-native-object-no-reffing, $g_enum_type, $info, $const_values
  );
}

sub g_enum_complete_type_info (
  N-GValue $g_enum_type, GTypeInfo $info, GEnumValue $const_values
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:enum-get-value:
=begin pod
=head2 enum-get-value

Returns the B<Gnome::GObject::EnumValue> for a value.

Returns: the B<Gnome::GObject::EnumValue> for I<value>, or C<undefined> if I<value> is not a member of the enumeration

  method enum-get-value ( GEnumClass $enum_class, Int() $value --> GEnumValue )

=item GEnumClass $enum_class; a B<Gnome::GObject::EnumClass>
=item Int() $value; the value to look up
=end pod

method enum-get-value ( GEnumClass $enum_class, Int() $value --> GEnumValue ) {

  g_enum_get_value(
    self.get-native-object-no-reffing, $enum_class, $value
  )
}

sub g_enum_get_value (
  GEnumClass $enum_class, gint $value --> GEnumValue
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:enum-get-value-by-name:
=begin pod
=head2 enum-get-value-by-name

Looks up a B<Gnome::GObject::EnumValue> by name.

Returns: the B<Gnome::GObject::EnumValue> with name I<name>, or C<undefined> if the enumeration doesn't have a member with that name

  method enum-get-value-by-name ( GEnumClass $enum_class, Str $name --> GEnumValue )

=item GEnumClass $enum_class; a B<Gnome::GObject::EnumClass>
=item Str $name; the name to look up
=end pod

method enum-get-value-by-name ( GEnumClass $enum_class, Str $name --> GEnumValue ) {

  g_enum_get_value_by_name(
    self.get-native-object-no-reffing, $enum_class, $name
  )
}

sub g_enum_get_value_by_name (
  GEnumClass $enum_class, gchar-ptr $name --> GEnumValue
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:enum-get-value-by-nick:
=begin pod
=head2 enum-get-value-by-nick

Looks up a B<Gnome::GObject::EnumValue> by nickname.

Returns: the B<Gnome::GObject::EnumValue> with nickname I<nick>, or C<undefined> if the enumeration doesn't have a member with that nickname

  method enum-get-value-by-nick ( GEnumClass $enum_class, Str $nick --> GEnumValue )

=item GEnumClass $enum_class; a B<Gnome::GObject::EnumClass>
=item Str $nick; the nickname to look up
=end pod

method enum-get-value-by-nick ( GEnumClass $enum_class, Str $nick --> GEnumValue ) {

  g_enum_get_value_by_nick(
    self.get-native-object-no-reffing, $enum_class, $nick
  )
}

sub g_enum_get_value_by_nick (
  GEnumClass $enum_class, gchar-ptr $nick --> GEnumValue
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:enum-register-static:
=begin pod
=head2 enum-register-static

Registers a new static enumeration type with the name I<name>.

It is normally more convenient to let [glib-mkenums][glib-mkenums], generate a C<my-enum-get-type()> function from a usual C enumeration definition than to write one yourself using C<enum-register-static()>.

Returns: The new type identifier.

  method enum-register-static ( Str $name, GEnumValue $const_static_values --> N-GValue )

=item Str $name; A nul-terminated string used as the name of the new type.
=item GEnumValue $const_static_values; An array of B<Gnome::GObject::EnumValue> structs for the possible enumeration values. The array is terminated by a struct with all members being 0. GObject keeps a reference to the data, so it cannot be stack-allocated.
=end pod

method enum-register-static ( Str $name, GEnumValue $const_static_values --> N-GValue ) {

  g_enum_register_static(
    self.get-native-object-no-reffing, $name, $const_static_values
  )
}

sub g_enum_register_static (
  gchar-ptr $name, GEnumValue $const_static_values --> N-GValue
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:enum-to-string:
=begin pod
=head2 enum-to-string

Pretty-prints I<value> in the form of the enum’s name.

This is intended to be used for debugging purposes. The format of the output may change in the future.

Returns: a newly-allocated text string

  method enum-to-string ( N-GValue $g_enum_type, Int() $value --> Str )

=item N-GValue $g_enum_type; the type identifier of a B<Gnome::GObject::EnumClass> type
=item Int() $value; the value
=end pod

method enum-to-string ( $g_enum_type is copy, Int() $value --> Str ) {
  $g_enum_type .= get-native-object-no-reffing unless $g_enum_type ~~ N-GValue;

  g_enum_to_string(
    self.get-native-object-no-reffing, $g_enum_type, $value
  )
}

sub g_enum_to_string (
  N-GValue $g_enum_type, gint $value --> gchar-ptr
) is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
# TM:0:fits-pointer:
=begin pod
=head2 fits-pointer

Determines if I<value> will fit inside the size of a pointer value. This is an internal function introduced mainly for C marshallers.

Returns: C<True> if I<value> will fit inside a pointer value.

  method fits-pointer ( --> Bool )

=end pod

method fits-pointer ( --> Bool ) {

  g_value_fits_pointer(
    self.get-native-object-no-reffing,
  ).Bool
}

sub g_value_fits_pointer (
  N-GValue $value --> gboolean
) is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
# TM:0:flags-complete-type-info:
=begin pod
=head2 flags-complete-type-info

This function is meant to be called from the C<complete-type-info()> function of a B<Gnome::GObject::TypePlugin> implementation, see the example for C<enum-complete-type-info()> above.

  method flags-complete-type-info ( N-GValue $g_flags_type, GTypeInfo $info, GFlagsValue $const_values )

=item N-GValue $g_flags_type; the type identifier of the type being completed
=item GTypeInfo $info; (out callee-allocates): the B<Gnome::GObject::TypeInfo> struct to be filled in
=item GFlagsValue $const_values; An array of B<Gnome::GObject::FlagsValue> structs for the possible enumeration values. The array is terminated by a struct with all members being 0.
=end pod

method flags-complete-type-info ( $g_flags_type is copy, GTypeInfo $info, GFlagsValue $const_values ) {
  $g_flags_type .= get-native-object-no-reffing unless $g_flags_type ~~ N-GValue;

  g_flags_complete_type_info(
    self.get-native-object-no-reffing, $g_flags_type, $info, $const_values
  );
}

sub g_flags_complete_type_info (
  N-GValue $g_flags_type, GTypeInfo $info, GFlagsValue $const_values
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:flags-get-first-value:
=begin pod
=head2 flags-get-first-value

Returns the first B<Gnome::GObject::FlagsValue> which is set in I<value>.

Returns: the first B<Gnome::GObject::FlagsValue> which is set in I<value>, or C<undefined> if none is set

  method flags-get-first-value ( GFlagsClass $flags_class, UInt $value --> GFlagsValue )

=item GFlagsClass $flags_class; a B<Gnome::GObject::FlagsClass>
=item UInt $value; the value
=end pod

method flags-get-first-value ( GFlagsClass $flags_class, UInt $value --> GFlagsValue ) {

  g_flags_get_first_value(
    self.get-native-object-no-reffing, $flags_class, $value
  )
}

sub g_flags_get_first_value (
  GFlagsClass $flags_class, guint $value --> GFlagsValue
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:flags-get-value-by-name:
=begin pod
=head2 flags-get-value-by-name

Looks up a B<Gnome::GObject::FlagsValue> by name.

Returns: the B<Gnome::GObject::FlagsValue> with name I<name>, or C<undefined> if there is no flag with that name

  method flags-get-value-by-name ( GFlagsClass $flags_class, Str $name --> GFlagsValue )

=item GFlagsClass $flags_class; a B<Gnome::GObject::FlagsClass>
=item Str $name; the name to look up
=end pod

method flags-get-value-by-name ( GFlagsClass $flags_class, Str $name --> GFlagsValue ) {

  g_flags_get_value_by_name(
    self.get-native-object-no-reffing, $flags_class, $name
  )
}

sub g_flags_get_value_by_name (
  GFlagsClass $flags_class, gchar-ptr $name --> GFlagsValue
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:flags-get-value-by-nick:
=begin pod
=head2 flags-get-value-by-nick

Looks up a B<Gnome::GObject::FlagsValue> by nickname.

Returns: the B<Gnome::GObject::FlagsValue> with nickname I<nick>, or C<undefined> if there is no flag with that nickname

  method flags-get-value-by-nick ( GFlagsClass $flags_class, Str $nick --> GFlagsValue )

=item GFlagsClass $flags_class; a B<Gnome::GObject::FlagsClass>
=item Str $nick; the nickname to look up
=end pod

method flags-get-value-by-nick ( GFlagsClass $flags_class, Str $nick --> GFlagsValue ) {

  g_flags_get_value_by_nick(
    self.get-native-object-no-reffing, $flags_class, $nick
  )
}

sub g_flags_get_value_by_nick (
  GFlagsClass $flags_class, gchar-ptr $nick --> GFlagsValue
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:flags-register-static:
=begin pod
=head2 flags-register-static

Registers a new static flags type with the name I<name>.

It is normally more convenient to let [glib-mkenums][glib-mkenums] generate a C<my-flags-get-type()> function from a usual C enumeration definition than to write one yourself using C<flags-register-static()>.

Returns: The new type identifier.

  method flags-register-static ( Str $name, GFlagsValue $const_static_values --> N-GValue )

=item Str $name; A nul-terminated string used as the name of the new type.
=item GFlagsValue $const_static_values; An array of B<Gnome::GObject::FlagsValue> structs for the possible flags values. The array is terminated by a struct with all members being 0. GObject keeps a reference to the data, so it cannot be stack-allocated.
=end pod

method flags-register-static ( Str $name, GFlagsValue $const_static_values --> N-GValue ) {

  g_flags_register_static(
    self.get-native-object-no-reffing, $name, $const_static_values
  )
}

sub g_flags_register_static (
  gchar-ptr $name, GFlagsValue $const_static_values --> N-GValue
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:flags-to-string:
=begin pod
=head2 flags-to-string

Pretty-prints I<value> in the form of the flag names separated by ` | ` and sorted. Any extra bits will be shown at the end as a hexadecimal number.

This is intended to be used for debugging purposes. The format of the output may change in the future.

Returns: a newly-allocated text string

  method flags-to-string ( N-GValue $flags_type, UInt $value --> Str )

=item N-GValue $flags_type; the type identifier of a B<Gnome::GObject::FlagsClass> type
=item UInt $value; the value
=end pod

method flags-to-string ( $flags_type is copy, UInt $value --> Str ) {
  $flags_type .= get-native-object-no-reffing unless $flags_type ~~ N-GValue;

  g_flags_to_string(
    self.get-native-object-no-reffing, $flags_type, $value
  )
}

sub g_flags_to_string (
  N-GValue $flags_type, guint $value --> gchar-ptr
) is native(&gobject-lib)
  { * }
}}

#-------------------------------------------------------------------------------
# TM:0:get-boolean:
=begin pod
=head2 get-boolean

Get the contents of a C<G-TYPE-BOOLEAN> B<Gnome::GObject::Value>.

Returns: boolean contents of I<value>

  method get-boolean ( --> Bool )

=end pod

method get-boolean ( --> Bool ) {

  g_value_get_boolean(
    self.get-native-object-no-reffing,
  ).Bool
}

sub g_value_get_boolean (
  N-GValue $value --> gboolean
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:get-double:
=begin pod
=head2 get-double

Get the contents of a C<G-TYPE-DOUBLE> B<Gnome::GObject::Value>.

Returns: double contents of I<value>

  method get-double ( --> Num )

=end pod

method get-double ( --> Num ) {

  g_value_get_double(
    self.get-native-object-no-reffing,
  )
}

sub g_value_get_double (
  N-GValue $value --> gdouble
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:get-enum:
=begin pod
=head2 get-enum

Get the contents of a C<G-TYPE-ENUM> B<Gnome::GObject::Value>.

  method get-enum ( --> Int )

=end pod

method get-enum ( --> Int ) {
  g_value_get_enum(self.get-native-object-no-reffing)
}

sub g_value_get_enum (
  N-GValue $value --> gint
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:get-flags:
=begin pod
=head2 get-flags

Get the contents of a C<G-TYPE-FLAGS> B<Gnome::GObject::Value>.

Returns: flags contents of I<value>

  method get-flags ( --> UInt )

=end pod

method get-flags ( --> UInt ) {
  g_value_get_flags(self.get-native-object-no-reffing)
}

sub g_value_get_flags (
  N-GValue $value --> guint
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:get-float:
=begin pod
=head2 get-float

Get the contents of a C<G-TYPE-FLOAT> B<Gnome::GObject::Value>.

Returns: float contents of I<value>

  method get-float ( --> Num )

=end pod

method get-float ( --> Num ) {
  g_value_get_float(self.get-native-object-no-reffing)
}

sub g_value_get_float (
  N-GValue $value --> gfloat
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:get-gtype:
=begin pod
=head2 get-gtype

Get the contents of a C<G-TYPE-GTYPE> B<Gnome::GObject::Value>.

Returns: the B<Gnome::GObject::Type> stored in I<value>

  method get-gtype ( --> N-GValue )

=end pod

method get-gtype ( --> N-GValue ) {
  g_value_get_gtype(self.get-native-object-no-reffing)
}

sub g_value_get_gtype (
  N-GValue $value --> N-GValue
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:get-int:
=begin pod
=head2 get-int

Get the contents of a C<G-TYPE-INT> B<Gnome::GObject::Value>.

Returns: integer contents of I<value>

  method get-int ( --> Int )

=end pod

method get-int ( --> Int ) {

  g_value_get_int(
    self.get-native-object-no-reffing,
  )
}

sub g_value_get_int (
  N-GValue $value --> gint
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:get-int64:
=begin pod
=head2 get-int64

Get the contents of a C<G-TYPE-INT64> B<Gnome::GObject::Value>.

Returns: 64bit integer contents of I<value>

  method get-int64 ( --> Int )

=end pod

method get-int64 ( --> Int ) {

  g_value_get_int64(
    self.get-native-object-no-reffing,
  )
}

sub g_value_get_int64 (
  N-GValue $value --> gint64
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:get-long:
=begin pod
=head2 get-long

Get the contents of a C<G-TYPE-LONG> B<Gnome::GObject::Value>.

Returns: long integer contents of I<value>

  method get-long ( --> Int )

=end pod

method get-long ( --> Int ) {

  g_value_get_long(
    self.get-native-object-no-reffing,
  )
}

sub g_value_get_long (
  N-GValue $value --> glong
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:get-pointer:
=begin pod
=head2 get-pointer

Get the contents of a pointer B<Gnome::GObject::Value>.

Returns: pointer contents of I<value>

  method get-pointer ( --> Pointer )

=end pod

method get-pointer ( --> Pointer ) {

  g_value_get_pointer(
    self.get-native-object-no-reffing,
  )
}

sub g_value_get_pointer (
  N-GValue $value --> gpointer
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:get-schar:
=begin pod
=head2 get-schar

Get the contents of a C<G-TYPE-CHAR> B<Gnome::GObject::Value>.

Returns: signed 8 bit integer contents of I<value>

  method get-schar ( --> Int )

=end pod

method get-schar ( --> Int ) {

  g_value_get_schar(
    self.get-native-object-no-reffing,
  )
}

sub g_value_get_schar (
  N-GValue $value --> gint8
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:get-string:
=begin pod
=head2 get-string

Get the contents of a C<G-TYPE-STRING> B<Gnome::GObject::Value>.

Returns: string content of I<value>

  method get-string ( --> Str )

=end pod

method get-string ( --> Str ) {

  g_value_get_string(
    self.get-native-object-no-reffing,
  )
}

sub g_value_get_string (
  N-GValue $value --> gchar-ptr
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:get-uchar:
=begin pod
=head2 get-uchar

Get the contents of a C<G-TYPE-UCHAR> B<Gnome::GObject::Value>.

Returns: unsigned character contents of I<value>

  method get-uchar ( --> UInt )

=end pod

method get-uchar ( --> UInt ) {

  g_value_get_uchar(
    self.get-native-object-no-reffing,
  )
}

sub g_value_get_uchar (
  N-GValue $value --> guchar
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:get-uint:
=begin pod
=head2 get-uint

Get the contents of a C<G-TYPE-UINT> B<Gnome::GObject::Value>.

Returns: unsigned integer contents of I<value>

  method get-uint ( --> UInt )

=end pod

method get-uint ( --> UInt ) {

  g_value_get_uint(
    self.get-native-object-no-reffing,
  )
}

sub g_value_get_uint (
  N-GValue $value --> guint
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:get-uint64:
=begin pod
=head2 get-uint64

Get the contents of a C<G-TYPE-UINT64> B<Gnome::GObject::Value>.

Returns: unsigned 64bit integer contents of I<value>

  method get-uint64 ( --> UInt )

=end pod

method get-uint64 ( --> UInt ) {

  g_value_get_uint64(
    self.get-native-object-no-reffing,
  )
}

sub g_value_get_uint64 (
  N-GValue $value --> guint64
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:get-ulong:
=begin pod
=head2 get-ulong

Get the contents of a C<G-TYPE-ULONG> B<Gnome::GObject::Value>.

Returns: unsigned long integer contents of I<value>

  method get-ulong ( --> UInt )

=end pod

method get-ulong ( --> UInt ) {

  g_value_get_ulong(
    self.get-native-object-no-reffing,
  )
}

sub g_value_get_ulong (
  N-GValue $value --> gulong
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:get-variant:
=begin pod
=head2 get-variant

Get the contents of a variant B<Gnome::GObject::Value>.

Returns: variant contents of I<value> (may be C<undefined>)

  method get-variant ( --> N-GValue )

=end pod

method get-variant ( --> N-GValue ) {

  g_value_get_variant(
    self.get-native-object-no-reffing,
  )
}

sub g_value_get_variant (
  N-GValue $value --> N-GValue
) is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
# moved to Gnome::GObject::Type
# TM:0:gtype-get-type:
=begin pod
=head2 gtype-get-type

  method gtype-get-type ( --> UInt )

=end pod

sub g_gtype_get_type (  --> GType )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:init-from-instance:
=begin pod
=head2 init-from-instance

Initializes and sets I<value> from an instantiatable type via the value-table's C<collect-value()> function.

Note: The I<value> will be initialised with the exact type of I<instance>. If you wish to set the I<value>'s type to a different GType (such as a parent class GType), you need to manually call C<init()> and C<g-value-set-instance()>.

  method init-from-instance ( Pointer $instance )

=item Pointer $instance; (type GObject.TypeInstance): the instance
=end pod

method init-from-instance ( Pointer $instance ) {

  g_value_init_from_instance(
    self.get-native-object-no-reffing, $instance
  );
}

sub g_value_init_from_instance (
  N-GValue $value, gpointer $instance
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:peek-pointer:
=begin pod
=head2 peek-pointer

Returns the value contents as pointer. This function asserts that C<fits-pointer()> returned C<True> for the passed in value. This is an internal function introduced mainly for C marshallers.

Returns: the value contents as pointer

  method peek-pointer ( --> Pointer )

=end pod

method peek-pointer ( --> Pointer ) {

  g_value_peek_pointer(
    self.get-native-object-no-reffing,
  )
}

sub g_value_peek_pointer (
  N-GValue $value --> gpointer
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:pointer-type-register-static:
=begin pod
=head2 pointer-type-register-static

Creates a new C<G-TYPE-POINTER> derived type id for a new pointer type with name I<name>.

Returns: a new C<G-TYPE-POINTER> derived type id for I<name>.

  method g-pointer-type-register-static ( Str $name --> N-GValue )

=item Str $name; the name of the new pointer type.
=end pod

method pointer-type-register-static ( Str $name --> N-GValue ) {

  g_pointer_type_register_static(
    self.get-native-object-no-reffing, $name
  )
}

sub g_pointer_type_register_static (
  gchar-ptr $name --> N-GValue
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:register-transform-func:
=begin pod
=head2 register-transform-func

Registers a value transformation function for use in C<transform()>. A previously registered transformation function for I<src-type> and I<dest-type> will be replaced.

  method register-transform-func ( N-GValue $src_type, N-GValue $dest_type, GValueTransform $transform_func )

=item N-GValue $src_type; Source type.
=item N-GValue $dest_type; Target type.
=item GValueTransform $transform_func; a function which transforms values of type I<src-type> into value of type I<dest-type>
=end pod

method register-transform-func ( $src_type is copy, $dest_type is copy, GValueTransform $transform_func ) {
  $src_type .= get-native-object-no-reffing unless $src_type ~~ N-GValue;
  $dest_type .= get-native-object-no-reffing unless $dest_type ~~ N-GValue;

  g_value_register_transform_func(
    self.get-native-object-no-reffing, $src_type, $dest_type, $transform_func
  );
}

sub g_value_register_transform_func (
  N-GValue $src_type, N-GValue $dest_type, GValueTransform $transform_func
) is native(&gobject-lib)
  { * }
}}

#-------------------------------------------------------------------------------
# TM:0:reset:
=begin pod
=head2 reset

Clears the current value in I<value> and resets it to the default value (as if the value had just been initialized).

Returns: the B<Gnome::GObject::Value> structure that has been passed in

  method reset ( --> N-GValue )

=end pod

method reset ( --> N-GValue ) {
  g_value_reset( self.get-native-object-no-reffing )
}

sub g_value_reset (
  N-GValue $value --> N-GValue
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:set-boolean:
=begin pod
=head2 set-boolean

Set the contents of a C<G-TYPE-BOOLEAN> B<Gnome::GObject::Value> to I<v-boolean>.

  method set-boolean ( Bool $v_boolean )

=item Bool $v_boolean; boolean value to be set
=end pod

method set-boolean ( Bool $v_boolean ) {

  g_value_set_boolean(
    self.get-native-object-no-reffing, $v_boolean
  );
}

sub g_value_set_boolean (
  N-GValue $value, gboolean $v_boolean
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:set-double:
=begin pod
=head2 set-double

Set the contents of a C<G-TYPE-DOUBLE> B<Gnome::GObject::Value> to I<v-double>.

  method set-double ( Num() $v_double )

=item Num() $v_double; double value to be set
=end pod

method set-double ( Num() $v_double ) {

  g_value_set_double(
    self.get-native-object-no-reffing, $v_double
  );
}

sub g_value_set_double (
  N-GValue $value, gdouble $v_double
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:set-enum:
=begin pod
=head2 set-enum

Set the contents of a C<G-TYPE-ENUM> B<Gnome::GObject::Value> to I<v-enum>.

  method set-enum ( Int() $v_enum )

=item Int() $v_enum; enum value to be set
=end pod

method set-enum ( Int() $v_enum ) {

  g_value_set_enum(
    self.get-native-object-no-reffing, $v_enum
  );
}

sub g_value_set_enum (
  N-GValue $value, gint $v_enum
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:set-flags:
=begin pod
=head2 set-flags

Set the contents of a C<G-TYPE-FLAGS> B<Gnome::GObject::Value> to I<v-flags>.

  method set-flags ( UInt $v_flags )

=item UInt $v_flags; flags value to be set
=end pod

method set-flags ( UInt $v_flags ) {

  g_value_set_flags(
    self.get-native-object-no-reffing, $v_flags
  );
}

sub g_value_set_flags (
  N-GValue $value, guint $v_flags
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:set-float:
=begin pod
=head2 set-float

Set the contents of a C<G-TYPE-FLOAT> B<Gnome::GObject::Value> to I<v-float>.

  method set-float ( Num() $v_float )

=item Num() $v_float; float value to be set
=end pod

method set-float ( Num() $v_float ) {

  g_value_set_float(
    self.get-native-object-no-reffing, $v_float
  );
}

sub g_value_set_float (
  N-GValue $value, gfloat $v_float
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:set-gtype:
=begin pod
=head2 set-gtype

Set the contents of a C<G-TYPE-GTYPE> B<Gnome::GObject::Value> to I<v-gtype>.

  method set-gtype ( N-GValue $v_gtype )

=item N-GValue $v_gtype; B<Gnome::GObject::Type> to be set
=end pod

method set-gtype ( $v_gtype is copy ) {
  $v_gtype .= get-native-object-no-reffing unless $v_gtype ~~ N-GValue;

  g_value_set_gtype(
    self.get-native-object-no-reffing, $v_gtype
  );
}

sub g_value_set_gtype (
  N-GValue $value, N-GValue $v_gtype
) is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
# TM:0:set-instance:
=begin pod
=head2 set-instance

Sets I<value> from an instantiatable type via the value-table's C<collect-value()> function.

  method set-instance ( Pointer $instance )

=item Pointer $instance; the instance
=end pod

method set-instance ( Pointer $instance ) {

  g_value_set_instance(
    self.get-native-object-no-reffing, $instance
  );
}

sub g_value_set_instance (
  N-GValue $value, gpointer $instance
) is native(&gobject-lib)
  { * }
}}

#-------------------------------------------------------------------------------
#TM:1:set-int:
=begin pod
=head2 set-int

Set the contents of a C<G-TYPE-INT> B<Gnome::GObject::Value> to I<v-int>.

  method set-int ( Int() $v_int )

=item Int() $v_int; integer value to be set
=end pod

method set-int ( Int() $v_int ) {

  g_value_set_int(
    self.get-native-object-no-reffing, $v_int
  );
}

sub g_value_set_int (
  N-GValue $value, gint $v_int
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:set-int64:
=begin pod
=head2 set-int64

Set the contents of a C<G-TYPE-INT64> B<Gnome::GObject::Value> to I<v-int64>.

  method set-int64 ( Int() $v_int64 )

=item Int() $v_int64; 64bit integer value to be set
=end pod

method set-int64 ( Int() $v_int64 ) {

  g_value_set_int64(
    self.get-native-object-no-reffing, $v_int64
  );
}

sub g_value_set_int64 (
  N-GValue $value, gint64 $v_int64
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:set-long:
=begin pod
=head2 set-long

Set the contents of a C<G-TYPE-LONG> B<Gnome::GObject::Value> to I<v-long>.

  method set-long ( Int() $v_long )

=item Int() $v_long; long integer value to be set
=end pod

method set-long ( Int() $v_long ) {
  g_value_set_long( self.get-native-object-no-reffing, $v_long);
}

sub g_value_set_long (
  N-GValue $value, glong $v_long
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:set-pointer:
=begin pod
=head2 set-pointer

Set the contents of a pointer B<Gnome::GObject::Value> to I<v-pointer>.

  method set-pointer ( Pointer $v_pointer )

=item Pointer $v_pointer; pointer value to be set
=end pod

method set-pointer ( Pointer $v_pointer ) {
  g_value_set_pointer( self.get-native-object-no-reffing, $v_pointer);
}

sub g_value_set_pointer (
  N-GValue $value, gpointer $v_pointer
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:set-schar:
=begin pod
=head2 set-schar

Set the contents of a C<G-TYPE-CHAR> B<Gnome::GObject::Value> to I<v-char>.

  method set-schar ( Int() $v_char )

=item Int() $v_char; signed 8 bit integer to be set
=end pod

method set-schar ( Int() $v_char ) {
  g_value_set_schar( self.get-native-object-no-reffing, $v_char);
}

sub g_value_set_schar (
  N-GValue $value, gint8 $v_char
) is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
# TM:0:set-static-string:
=begin pod
=head2 set-static-string

Set the contents of a C<G-TYPE-STRING> B<Gnome::GObject::Value> to I<v-string>. The string is assumed to be static, and is thus not duplicated when setting the B<Gnome::GObject::Value>.

  method set-static-string ( Str $v_string )

=item Str $v_string; static string to be set
=end pod

method set-static-string ( Str $v_string ) {

  g_value_set_static_string(
    self.get-native-object-no-reffing, $v_string
  );
}

sub g_value_set_static_string (
  N-GValue $value, gchar-ptr $v_string
) is native(&gobject-lib)
  { * }
}}

#-------------------------------------------------------------------------------
#TM:1:set-string:
=begin pod
=head2 set-string

Set the contents of a C<G-TYPE-STRING> B<Gnome::GObject::Value> to I<v-string>.

  method set-string ( Str $v_string )

=item Str $v_string; caller-owned string to be duplicated for the B<Gnome::GObject::Value>
=end pod

method set-string ( Str $v_string ) {

  g_value_set_string(
    self.get-native-object-no-reffing, $v_string
  );
}

sub g_value_set_string (
  N-GValue $value, gchar-ptr $v_string
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:set-uchar:
=begin pod
=head2 set-uchar

Set the contents of a C<G-TYPE-UCHAR> B<Gnome::GObject::Value> to I<v-uchar>.

  method set-uchar ( UInt $v_uchar )

=item UInt $v_uchar; unsigned character value to be set
=end pod

method set-uchar ( UInt $v_uchar ) {

  g_value_set_uchar(
    self.get-native-object-no-reffing, $v_uchar
  );
}

sub g_value_set_uchar (
  N-GValue $value, guchar $v_uchar
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:set-uint:
=begin pod
=head2 set-uint

Set the contents of a C<G-TYPE-UINT> B<Gnome::GObject::Value> to I<v-uint>.

  method set-uint ( UInt $v_uint )

=item UInt $v_uint; unsigned integer value to be set
=end pod

method set-uint ( UInt $v_uint ) {

  g_value_set_uint(
    self.get-native-object-no-reffing, $v_uint
  );
}

sub g_value_set_uint (
  N-GValue $value, guint $v_uint
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:set-uint64:
=begin pod
=head2 set-uint64

Set the contents of a C<G-TYPE-UINT64> B<Gnome::GObject::Value> to I<v-uint64>.

  method set-uint64 ( UInt $v_uint64 )

=item UInt $v_uint64; unsigned 64bit integer value to be set
=end pod

method set-uint64 ( UInt $v_uint64 ) {

  g_value_set_uint64(
    self.get-native-object-no-reffing, $v_uint64
  );
}

sub g_value_set_uint64 (
  N-GValue $value, guint64 $v_uint64
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:set-ulong:
=begin pod
=head2 set-ulong

Set the contents of a C<G-TYPE-ULONG> B<Gnome::GObject::Value> to I<v-ulong>.

  method set-ulong ( UInt $v_ulong )

=item UInt $v_ulong; unsigned long integer value to be set
=end pod

method set-ulong ( UInt $v_ulong ) {

  g_value_set_ulong(
    self.get-native-object-no-reffing, $v_ulong
  );
}

sub g_value_set_ulong (
  N-GValue $value, gulong $v_ulong
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:set-variant:
=begin pod
=head2 set-variant

Set the contents of a variant B<Gnome::GObject::Value> to I<variant>. If the variant is floating, it is consumed.

  method set-variant ( N-GValue $variant )

=item N-GValue $variant; a B<Gnome::GObject::Variant>, or C<undefined>
=end pod

method set-variant ( $variant is copy ) {
  $variant .= get-native-object-no-reffing unless $variant ~~ N-GValue;

  g_value_set_variant(
    self.get-native-object-no-reffing, $variant
  );
}

sub g_value_set_variant (
  N-GValue $value, N-GValue $variant
) is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
# TM:0:strdup-value-contents:
=begin pod
=head2 strdup-value-contents

Return a newly allocated string, which describes the contents of a B<Gnome::GObject::Value>. The main purpose of this function is to describe B<Gnome::GObject::Value> contents for debugging output, the way in which the contents are described may change between different GLib versions.

Returns: Newly allocated string.

  method strdup-value-contents ( --> Str )

=end pod

method strdup-value-contents ( --> Str ) {

  g_strdup_value_contents(
    self.get-native-object-no-reffing,
  )
}

sub g_strdup_value_contents (
  N-GValue $value --> gchar-ptr
) is native(&gobject-lib)
  { * }
}}

#-------------------------------------------------------------------------------
# TM:0:take-string:
=begin pod
=head2 take-string

Sets the contents of a C<G-TYPE-STRING> B<Gnome::GObject::Value> to I<v-string>.

  method take-string ( Str $v_string )

=item Str $v_string; string to take ownership of
=end pod

method take-string ( Str $v_string ) {

  g_value_take_string(
    self.get-native-object-no-reffing, $v_string
  );
}

sub g_value_take_string (
  N-GValue $value, gchar-ptr $v_string
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:take-variant:
=begin pod
=head2 take-variant

Set the contents of a variant B<Gnome::GObject::Value> to I<variant>, and takes over the ownership of the caller's reference to I<variant>; the caller doesn't have to unref it any more (i.e. the reference count of the variant is not increased).

If I<variant> was floating then its floating reference is converted to a hard reference.

If you want the B<Gnome::GObject::Value> to hold its own reference to I<variant>, use C<set-variant()> instead.

This is an internal function introduced mainly for C marshallers.

  method take-variant ( N-GValue $variant )

=item N-GValue $variant; a B<Gnome::GObject::Variant>, or C<undefined>
=end pod

method take-variant ( $variant is copy ) {
  $variant .= get-native-object-no-reffing unless $variant ~~ N-GValue;

  g_value_take_variant(
    self.get-native-object-no-reffing, $variant
  );
}

sub g_value_take_variant (
  N-GValue $value, N-GValue $variant
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:transform:
=begin pod
=head2 transform

Tries to cast the contents of this into a type appropriate to store in I<$dest-value>, e.g. to transform a C<G-TYPE-INT> value into a C<G-TYPE-FLOAT> value. Performing transformations between value types might incur precision lossage. Especially transformations into strings might reveal seemingly arbitrary results and shouldn't be relied upon for production code (such as rcfile value or object property serialization).

Returns: Whether a transformation rule was found and could be applied. Upon failing transformations, I<$dest-value> is left untouched.

  method transform ( N-GValue $dest_value --> Bool )

=item N-GValue $dest_value; Target value.
=end pod

method transform ( $dest_value is copy --> Bool ) {
  $dest_value .= get-native-object-no-reffing unless $dest_value ~~ N-GValue;
  g_value_transform( self.get-native-object-no-reffing, $dest_value).Bool
}

sub g_value_transform (
  N-GValue $src_value, N-GValue $dest_value --> gboolean
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:type-compatible:
=begin pod
=head2 type-compatible

Returns whether a B<N-GValue> of type I<$src-type> can be copied into a B<-GValue> of type I<$dest-type>.

Returns: C<True> if C<copy()> is possible with I<src-type> and I<dest-type>.

  method type-compatible ( UInt $src_type, UInt $dest_type --> Bool )

=item UInt $src_type; source type to be copied.
=item UInt $dest_type; destination type for copying.
=end pod

method type-compatible ( GType $src_type, GType $dest_type --> Bool ) {
  g_value_type_compatible( $src_type, $dest_type).Bool
}

sub g_value_type_compatible (
  GType $src_type, GType $dest_type --> gboolean
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:type-transformable:
=begin pod
=head2 type-transformable

Check whether C<transform()> is able to transform values of type I<src-type> into values of type I<dest-type>. Note that for the types to be transformable, they must be compatible or a transformation function must be registered.

Returns: C<True> if the transformation is possible, C<False> otherwise.

  method type-transformable ( UInt $src_type, UInt $dest_type --> Bool )

=item UInt $src_type; Source type.
=item UInt $dest_type; Target type.
=end pod

method type-transformable ( GType $src_type, GType $dest_type --> Bool ) {
  g_value_type_transformable( $src_type, $dest_type).Bool
}

sub g_value_type_transformable (
  GType $src_type, GType $dest_type --> gboolean
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:_g_value_unset:
#`{{
=begin pod
=head2 unset

Clears the current value in I<value> (if any) and "unsets" the type, this releases all resources associated with this GValue. An unset value is the same as an uninitialized (zero-filled) B<Gnome::GObject::Value> structure.

  method unset ( )

=end pod

method unset ( ) {
  g_value_unset(self.get-native-object-no-reffing);
}
}}

sub _g_value_unset (
  N-GValue $value
) is native(&gobject-lib)
  is symbol('g_value_unset')
  { * }

#-------------------------------------------------------------------------------
#TM:2:_g_value_init:new
#`{{
=begin pod
=head2 init

Initializes I<value> with the default value of I<type>.

Returns: the B<Gnome::GObject::Value> structure that has been passed in

  method init ( N-GValue $g_type --> N-GValue )

=item N-GValue $g_type; Type the B<Gnome::GObject::Value> should hold values of.
=end pod

method init ( $g_type is copy --> N-GValue ) {
  $g_type .= get-native-object-no-reffing unless $g_type ~~ N-GValue;

  g_value_init(
    self.get-native-object-no-reffing, $g_type
  )
}
}}

sub _g_value_init (
  N-GValue $value, GType $g_type --> N-GValue
) is native(&gobject-lib)
  is symbol('g_value_init')
  { * }































=finish

#-------------------------------------------------------------------------------
#TM:2:g_value_init:new(:init)
=begin pod
=head2 [g_] value_init

Initializes with the default value of I<$g_type>.

Returns: the B<N-GValue> structure that has been passed in

  method g_value_init ( UInt $g_type --> N-GValue  )

=item UInt $g_type; Type the B<N-GValue> should hold values of.

=end pod

sub g_value_init ( N-GValue $value, GType $g_type --> N-GValue )
  is native(&gobject-lib)
  { * }

#`{{
# Useless sub. destination must be initialized with type and value of which
# value gets overwritten. So before copy, one must create the dest first
# before it can be used to copy to.
#-------------------------------------------------------------------------------
# TM:0:g_value_copy:
=begin pod
=head2 [g_] value_copy

Returns a copy of this object.

  method g_value_copy ( --> Gnome::GObject::Value )

=end pod

sub g_value_copy ( N-GValue $src_value --> Gnome::GObject::Value ) {
#note"type: ", $src_value.g-type;
  my N-GValue $nv .= new(:init($src_value.g-type));
  _g_value_copy( $src_value, $nv);
  Gnome::GObject::Value.new(:native-object($nv))
}

sub _g_value_copy ( N-GValue $src_value, N-GValue $dest_value is rw )
  is native(&gobject-lib)
  is symbol('g_value_copy')
  { * }
}}
#-------------------------------------------------------------------------------
#TM:1:g_value_reset:
=begin pod
=head2 [g_] value_reset

Clears the current value in this object and resets it to the default value (as if the value had just been initialized).

Returns: the B<N-GValue> structure that has been passed in

  method g_value_reset ( --> N-GValue )


=end pod

sub g_value_reset ( N-GValue $value --> N-GValue )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_unset:
=begin pod
=head2 [g_] value_unset

Clears the current value (if any) and "unsets" the type, this releases all resources associated with this GValue. An unset value is the same as an uninitialized (zero-filled) B<N-GValue> structure. The method C<.is-valid()> will return False after the call.

  method g_value_unset ( )

=end pod

sub g_value_unset ( N-GValue $value ) {
  Gnome::N::deprecate(
    '.g_value_unset', '.clear-object', '0.16.0', '0.18.0'
  );

  _g_value_unset($value);
}

sub _g_value_unset ( N-GValue $value )
  is native(&gobject-lib)
  is symbol('g_value_unset')
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_type_compatible:
=begin pod
=head2 [[g_] value_] type_compatible

Returns whether a B<N-GValue> of type I<$src_type> can be copied into a B<N-GValue> of type I<$dest_type>.

Returns: C<1> if C<g_value_copy()> is possible with I<$src_type> and I<dest_type>.

  method g_value_type_compatible (
    UInt $src_type, UInt $dest_type --> Int
  )

=item UInt $src_type; source type to be copied.
=item UInt $dest_type; destination type for copying.

=end pod

sub g_value_type_compatible ( GType $src_type, GType $dest_type --> gboolean )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_type_transformable:
=begin pod
=head2 [[g_] value_] type_transformable

Check whether C<g_value_transform()> is able to transform values of type I<$src_type> into values of type I<$dest_type>. Note that for the types to be transformable, they must be compatible or a transformation function must be registered.

Returns: C<1> if the transformation is possible, C<0> otherwise.

  method g_value_type_transformable (
    UInt $src_type, UInt $dest_type --> Int
  )

=item UInt $src_type; Source type.
=item UInt $dest_type; Target type.

=end pod

sub g_value_type_transformable (
  GType $src_type, GType $dest_type --> gboolean
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_transform:
=begin pod
=head2 [g_] value_transform

Tries to cast the contents of this value into a type appropriate to store in I<$dest_value>, e.g. to transform a C<G_TYPE_INT> value into a C<G_TYPE_FLOAT> value. Performing transformations between value types might incur precision lossage. Especially transformations into strings might reveal seemingly arbitrary results and shouldn't be relied upon for production code (such as rcfile value or object property serialization).

Returns: Whether a transformation rule was found and could be applied. Upon failing transformations, I<$dest_value> is left untouched and C<0> is returned.

  method g_value_transform ( N-GValue $dest_value --> Int )

=item N-GValue $dest_value; Target value.

=end pod

sub g_value_transform ( N-GValue $src_value, N-GValue $dest_value --> gboolean )
  is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
# TM:0:g_value_register_transform_func:
=begin pod
=head2 [[g_] value_] register_transform_func

Registers a value transformation function for use in C<g_value_transform()>.
A previously registered transformation function for I<src_type> and I<dest_type>
will be replaced.

  method g_value_register_transform_func ( UInt $src_type, UInt $dest_type, GValueTransform $transform_func )

=item UInt $src_type; Source type.
=item UInt $dest_type; Target type.
=item GValueTransform $transform_func; a function which transforms values of type I<src_type> into value of type I<dest_type>

=end pod

sub g_value_register_transform_func ( uint64 $src_type, uint64 $dest_type, GValueTransform $transform_func )
  is native(&gobject-lib)
  { * }
}}




#-------------------------------------------------------------------------------
#TM:1:g_value_set_schar:
=begin pod
=head2 [g_] value_set_schar

Set the contents of a C<G_TYPE_CHAR> typed B<N-GValue> to I<$v_char>.

  method g_value_set_schar ( Int $v_char )

=item Int $v_char; signed 8 bit integer to be set

=end pod

sub g_value_set_schar ( N-GValue $value, gint8 $v_char )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_get_schar:
=begin pod
=head2 [g_] value_get_schar

Get the signed 8 bit integer contents of a C<G_TYPE_CHAR> typed B<N-GValue>.

  method g_value_get_schar ( --> Int  )

=end pod

sub g_value_get_schar ( N-GValue $value --> gint8 )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_set_uchar:
=begin pod
=head2 [g_] value_set_uchar

Set the contents of a C<G_TYPE_UCHAR> typed B<N-GValue> to I<$v_uchar>.

  method g_value_set_uchar ( UInt $v_uchar )

=item UInt $v_uchar; unsigned character value to be set

=end pod

sub g_value_set_uchar ( N-GValue $value, guint8 $v_uchar )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_get_uchar:
=begin pod
=head2 [g_] value_get_uchar

Get the contents of a C<G_TYPE_UCHAR> typed B<N-GValue>.

  method g_value_get_uchar ( --> UInt  )

=end pod

sub g_value_get_uchar ( N-GValue $value --> guint8 )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_set_boolean:
=begin pod
=head2 [g_] value_set_boolean

Set the contents of a C<G_TYPE_BOOLEAN> typed B<N-GValue> to I<$v_boolean>.

  method g_value_set_boolean ( Bool $v_boolean )

=item Int $v_boolean; boolean value to be set

=end pod

sub g_value_set_boolean ( N-GValue $value, gboolean $v_boolean )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_get_boolean:
=begin pod
=head2 [g_] value_get_boolean

Get the contents of a C<G_TYPE_BOOLEAN> typed B<N-GValue>. Returns 0 or 1.

  method g_value_get_boolean ( --> Int )

=end pod

sub g_value_get_boolean ( N-GValue $value --> gboolean )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_set_int:
=begin pod
=head2 [g_] value_set_int

Set the contents of a C<G_TYPE_INT> typed B<N-GValue> to I<$v_int>.

  method g_value_set_int ( Int $v_int )

=item Int $v_int; integer value to be set

=end pod

sub g_value_set_int ( N-GValue $value, gint $v_int )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_get_int:
=begin pod
=head2 [g_] value_get_int

Get the contents of a C<G_TYPE_INT> typed B<N-GValue>.


  method g_value_get_int ( --> Int  )

=end pod

sub g_value_get_int ( N-GValue $value --> gint )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_set_uint:
=begin pod
=head2 [g_] value_set_uint

Set the contents of a C<G_TYPE_UINT> typed B<N-GValue> to I<$v_uint>.

  method g_value_set_uint ( UInt $v_uint )

=item gUInt $v_uint; unsigned integer value to be set

=end pod

sub g_value_set_uint ( N-GValue $value, guint $v_uint )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_get_uint:
=begin pod
=head2 [g_] value_get_uint

Get the contents of a C<G_TYPE_UINT> typed B<N-GValue>.

  method g_value_get_uint ( --> UInt  )

=end pod

sub g_value_get_uint ( N-GValue $value --> guint )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_set_long:
=begin pod
=head2 [g_] value_set_long

Set the contents of a C<G_TYPE_LONG> typed B<N-GValue> to I<$v_long>.

  method g_value_set_long ( Int $v_long )

=item Int $v_long; long integer value to be set

=end pod

sub g_value_set_long ( N-GValue $value, glong $v_long )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_get_long:
=begin pod
=head2 [g_] value_get_long

Get the contents of a C<G_TYPE_LONG> typed B<N-GValue>.

  method g_value_get_long ( --> Int )

=end pod

sub g_value_get_long ( N-GValue $value --> glong )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_set_ulong:
=begin pod
=head2 [g_] value_set_ulong

Set the contents of a C<G_TYPE_ULONG> typed B<N-GValue> to I<$v_ulong>.

  method g_value_set_ulong ( UInt $v_ulong )

=item UInt $v_ulong; unsigned long integer value to be set

=end pod

sub g_value_set_ulong ( N-GValue $value, gulong $v_ulong )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_get_ulong:
=begin pod
=head2 [g_] value_get_ulong

Get the contents of a C<G_TYPE_ULONG> typed B<N-GValue>.

  method g_value_get_ulong ( --> UInt  )

=end pod

sub g_value_get_ulong ( N-GValue $value --> gulong )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_set_int64:
=begin pod
=head2 [g_] value_set_int64

Set the contents of a C<G_TYPE_INT64> typed B<N-GValue> to I<$v_int64>.

  method g_value_set_int64 ( Int $v_int64 )

=item Int $v_int64; 64bit integer value to be set

=end pod

sub g_value_set_int64 ( N-GValue $value, gint64 $v_int64 )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_get_int64:
=begin pod
=head2 [g_] value_get_int64

Get the contents of a C<G_TYPE_INT64> typed B<N-GValue>.

  method g_value_get_int64 ( --> Int  )

=end pod

sub g_value_get_int64 ( N-GValue $value --> gint64 )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_set_uint64:
=begin pod
=head2 [g_] value_set_uint64

Set the contents of a C<G_TYPE_UINT64> typed B<N-GValue> to I<$v_uint64>.

  method g_value_set_uint64 ( UInt $v_uint64 )

=item gUInt $v_uint64; unsigned 64bit integer value to be set

=end pod

sub g_value_set_uint64 ( N-GValue $value, guint64 $v_uint64 )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_get_uint64:
=begin pod
=head2 [[g_] value_] get_uint64

Get the contents of a C<G_TYPE_UINT64> typed B<N-GValue>.

  method g_value_get_uint64 ( --> gUInt  )

=end pod

sub g_value_get_uint64 ( N-GValue $value --> guint64 )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_set_float:
=begin pod
=head2 [[g_] value_] set_float

Set the contents of a C<G_TYPE_FLOAT> typed B<N-GValue> to I<$v_float>.

  method g_value_set_float ( Num $v_float )

=item Num $v_float; float value to be set

=end pod

sub g_value_set_float ( N-GValue $value, gfloat $v_float )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_get_float:
=begin pod
=head2 [[g_] value_] get_float

Get the contents of a C<G_TYPE_FLOAT> typed B<N-GValue>.

  method g_value_get_float ( --> Num )

=end pod

sub g_value_get_float ( N-GValue $value --> gfloat )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_set_double:
=begin pod
=head2 [[g_] value_] set_double

Set the contents of a C<G_TYPE_DOUBLE> typed B<N-GValue> to I<$v_double>.

  method g_value_set_double ( Num $v_double )

=item Num $v_double; double value to be set

=end pod

sub g_value_set_double ( N-GValue $value, gdouble $v_double )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_get_double:
=begin pod
=head2 [[g_] value_] get_double

Get the contents of a C<G_TYPE_DOUBLE> typed B<N-GValue>.

  method g_value_get_double ( --> Num  )

=end pod

sub g_value_get_double ( N-GValue $value --> gdouble )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_set_enum:
sub g_value_set_enum ( N-GValue $value, GEnum $v_enum )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_get_enum:
sub g_value_get_enum ( N-GValue $value --> GEnum )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_value_set_flags:
sub g_value_set_flags ( N-GValue $value, GFlag $v_flags )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_value_get_flags:
sub g_value_get_flags ( N-GValue $value --> GFlag )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_set_string:
=begin pod
=head2 [[g_] value_] set_string

Set the contents of a C<G_TYPE_STRING> typed B<N-GValue> to I<$v_string>.

  method g_value_set_string ( Str $v_string )

=item Str $v_string; caller-owned string to be duplicated for the B<N-GValue>

=end pod

sub g_value_set_string ( N-GValue $value, gchar-ptr $v_string )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_get_string:
=begin pod
=head2 [[g_] value_] get_string

Get the contents of a C<G_TYPE_STRING> typed B<N-GValue>.

Returns: string content of I<$value>

  method g_value_get_string ( --> Str  )

=end pod

sub g_value_get_string ( N-GValue $value --> gchar-ptr )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_set_gtype:
=begin pod
=head2 [[g_] value_] set_gtype

Set the contents of a C<G_TYPE_GTYPE> B<N-GValue> to I<v_gtype>.

  method g_value_set_gtype ( UInt $v_gtype )

=item UInt $v_gtype; B<GType> to be set

=end pod

sub g_value_set_gtype ( N-GValue $value, GType $v_gtype )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_value_get_gtype:
=begin pod
=head2 [[g_] value_] get_gtype

Get the type of B<N-GValue>.

  method g_value_get_gtype ( --> UInt  )

=end pod

sub g_value_get_gtype ( N-GValue $value --> GType )
  is native(&gobject-lib)
  { * }














=finish






#-------------------------------------------------------------------------------
# TM:0:g_value_dup_string:
=begin pod
=head2 [[g_] value_] dup_string

Get a copy the contents of a C<G_TYPE_STRING> typed B<N-GValue>.

Returns: a newly allocated copy of the string content of I<value>

  method g_value_dup_string ( --> Str  )

=end pod

sub g_value_dup_string ( N-GValue $value --> Str )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_value_set_pointer:
=begin pod
=head2 [[g_] value_] set_pointer

Set the contents of a pointer B<N-GValue> to I<v_pointer>.

  method g_value_set_pointer ( Pointer $v_pointer )

=item Pointer $v_pointer; pointer value to be set

=end pod

sub g_value_set_pointer ( N-GValue $value, Pointer $v_pointer )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_value_get_pointer:
=begin pod
=head2 [[g_] value_] get_pointer

Get the contents of a pointer B<N-GValue>.

Returns: (transfer none): pointer contents of I<value>

  method g_value_get_pointer ( --> Pointer  )

=end pod

sub g_value_get_pointer ( N-GValue $value --> Pointer )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_value_set_static_string:
=begin pod
=head2 [[g_] value_] set_static_string

Set the contents of a C<G_TYPE_STRING> typed B<N-GValue> to I<$v_string>. The string is assumed to be static, and is thus not duplicated when setting the B<N-GValue>.

  method g_value_set_static_string ( Str $v_string )

=item Str $v_string; static string to be set

=end pod

sub g_value_set_static_string ( N-GValue $value, Str $v_string )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_value_set_instance:
=begin pod
=head2 [[g_] value_] set_instance

Sets the value from an instantiatable type via the value_table's C<collect_value()> function.

  method g_value_set_instance ( Pointer $instance )

=item Pointer $instance; the instance

=end pod

sub g_value_set_instance ( N-GValue $value, gpointer $instance )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_value_init_from_instance:
=begin pod
=head2 [[g_] value_] init_from_instance

Initializes and sets I<value> from an instantiatable type via the value_table's C<collect_value()> function.

Note: The I<value> will be initialised with the exact type of I<instance>.  If you wish to set the I<value>'s type to a different GType (such as a parent class GType), you need to manually call C<g_value_init()> and C<g_value_set_instance()>.

  method g_value_init_from_instance ( Pointer $instance )

=item Pointer $instance; (type GObject.TypeInstance): the instance

=end pod

sub g_value_init_from_instance ( N-GValue $value, Pointer $instance )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_value_fits_pointer:
=begin pod
=head2 [[g_] value_] fits_pointer

Determines if I<value> will fit inside the size of a pointer value. This is an internal function introduced mainly for C marshallers.

Returns: C<1> if I<value> will fit inside a pointer value.

  method g_value_fits_pointer ( --> Int  )


=end pod

sub g_value_fits_pointer ( N-GValue $value --> int32 )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_value_peek_pointer:
=begin pod
=head2 [[g_] value_] peek_pointer

Returns the value contents as pointer. This function asserts that C<g_value_fits_pointer()> returned C<1> for the passed in value. This is an internal function introduced mainly for C marshallers.

Returns: (transfer none): the value contents as pointer

  method g_value_peek_pointer ( --> Pointer  )


=end pod

sub g_value_peek_pointer ( N-GValue $value --> Pointer )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_value_set_variant:
=begin pod
=head2 [[g_] value_] set_variant

Set the contents of a variant B<N-GValue> to I<variant>.
If the variant is floating, it is consumed.

  method g_value_set_variant ( N-GValue $variant )

=item N-GValue $variant; (nullable): a B<GVariant>, or C<Any>

=end pod

sub g_value_set_variant ( N-GValue $value, N-GValue $variant )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_value_take_variant:
=begin pod
=head2 [[g_] value_] take_variant

Set the contents of a variant B<N-GValue> to I<variant>, and takes over
the ownership of the caller's reference to I<variant>;
the caller doesn't have to unref it any more (i.e. the reference
count of the variant is not increased).

If I<variant> was floating then its floating reference is converted to
a hard reference.

If you want the B<N-GValue> to hold its own reference to I<variant>, use
C<g_value_set_variant()> instead.

This is an internal function introduced mainly for C marshallers.

  method g_value_take_variant ( N-GValue $variant )

=item N-GValue $variant; (nullable) (transfer full): a B<GVariant>, or C<Any>

=end pod

sub g_value_take_variant ( N-GValue $value, N-GValue $variant )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_value_get_variant:
=begin pod
=head2 [[g_] value_] get_variant

Get the contents of a variant B<N-GValue>.

Returns: (transfer none) (nullable): variant contents of I<value> (may be C<Any>)

  method g_value_get_variant ( --> N-GValue  )

=end pod

sub g_value_get_variant ( N-GValue $value --> N-GValue )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_value_dup_variant:
=begin pod
=head2 [[g_] value_] dup_variant

Get the contents of a variant B<N-GValue>, increasing its refcount. The returned
B<GVariant> is never floating.

Returns: (transfer full) (nullable): variant contents of I<value> (may be C<Any>);
should be unreffed using C<g_variant_unref()> when no longer needed

  method g_value_dup_variant ( --> N-GValue  )

=end pod

sub g_value_dup_variant ( N-GValue $value --> N-GValue )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_pointer_type_register_static:
=begin pod
=head2 [g_] pointer_type_register_static

Creates a new C<G_TYPE_POINTER> derived type id for a new
pointer type with name I<name>.

Returns: a new C<G_TYPE_POINTER> derived type id for I<name>.

  method g_pointer_type_register_static ( Str $name --> UInt  )

=item Str $name; the name of the new pointer type.

=end pod

sub g_pointer_type_register_static ( Str $name --> uint64 )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_strdup_value_contents:
=begin pod
=head2 [g_] strdup_value_contents

Return a newly allocated string, which describes the contents of a
B<N-GValue>.  The main purpose of this function is to describe B<N-GValue>
contents for debugging output, the way in which the contents are
described may change between different GLib versions.

Returns: Newly allocated string.

  method g_strdup_value_contents ( --> Str  )

=end pod

sub g_strdup_value_contents ( N-GValue $value --> Str )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_value_take_string:
=begin pod
=head2 [[g_] value_] take_string

Sets the contents of a C<G_TYPE_STRING> B<N-GValue> to I<v_string>.

  method g_value_take_string ( Str $v_string )

=item Str $v_string; (nullable): string to take ownership of

=end pod

sub g_value_take_string ( N-GValue $value, Str $v_string )
  is native(&gobject-lib)
  { * }


#-------------------------------------------------------------------------------
# moved to Type
# TM:0:g_gtype_get_type:
=begin pod
=head2 [g_] gtype_get_type

  method g_gtype_get_type ( --> UInt  )

=end pod

sub g_gtype_get_type (  --> GType )
  is native(&gobject-lib)
  { * }
