#TL:1:Gnome::GObject::Enums:

use v6;
#-------------------------------------------------------------------------------
=begin pod

=head1 Gnome::GObject::Enums

Enumeration and flags types

=head1 Description

The GLib type system provides fundamental types for enumeration and flags types. (Flags types are like enumerations, but allow their values to be combined by bitwise or). A registered enumeration or flags type associates a name and a nickname with each allowed value, and the methods C<g_enum_get_value_by_name()>, C<g_enum_get_value_by_nick()>, C<g_flags_get_value_by_name()> and C<g_flags_get_value_by_nick()> can look up values by their name or nickname.  When an enumeration or flags type is registered with the GLib type system, it can be used as value type for object properties, using C<g_param_spec_enum()> or C<g_param_spec_flags()>.

GObject ships with a utility called [glib-mkenums][glib-mkenums], that can construct suitable type registration functions from C enumeration definitions.

Example of how to get a string representation of an enum value:


=head2 See Also

B<GParamSpecEnum>, B<GParamSpecFlags>, C<g_param_spec_enum()>,

=head1 Synopsis
=head2 Declaration

  unit class Gnome::GObject::Enums;

=comment head2 Example
=begin comment
N-GEnumClass *enum_class;
N-GEnumValue *enum_value;

enum_class = g_type_class_ref (MAMAN_TYPE_MY_ENUM);
enum_value = g_enum_get_value (enum_class, MAMAN_MY_ENUM_FOO);

g_print ("Name: C<s>\n", enum_value->value_name);

g_type_class_unref (enum_class);

=end comment

=end pod
#-------------------------------------------------------------------------------
use NativeCall;

use Gnome::N::X;
use Gnome::N::NativeLib;
use Gnome::N::N-GObject;
use Gnome::GObject::Type;

#-------------------------------------------------------------------------------
# /usr/include/gtk-3.0/gtk/INCLUDE
# https://developer.gnome.org/WWW
unit class Gnome::GObject::Enums:auth<github:MARTIMM>;

#-------------------------------------------------------------------------------
=begin pod
=head2 class N-GEnumValue

A structure which contains a single enum value, its name, and its nickname.

=item Int $.value: the enum value
=item Str $.value_name: the name of the value
=item Str $.value_nick: the nickname of the value

=end pod

#TT:0:N-GEnumValue:
class N-GEnumValue is export is repr('CStruct') {
  has int32 $.value;
  has str $.value_name;
  has str $.value_nick;
}

#-------------------------------------------------------------------------------
=begin pod
=head2 class N-GFlagsValue

A structure which contains a single flags value, its name, and its
nickname.

=item UInt $.value: the flags value
=item Str $.value_name: the name of the value
=item Str $.value_nick: the nickname of the value


=end pod

#TT:0:N-GFlagsValue:
class N-GFlagsValue is export is repr('CStruct') {
  has uint32 $.value;
  has str $.value_name;
  has str $.value_nick;
}

#-------------------------------------------------------------------------------
=begin pod
=head2 class N-GEnumClass

=end pod

#TT:0:N-GEnumClass:
class N-GEnumClass is export is repr('CStruct') {
  has int32 $.minimum;
  has int32 $.maximum;
  has uint32 $.n_values;
  has CArray[N-GEnumValue] $.values;
}

#-------------------------------------------------------------------------------
=begin pod
=head2 class N-GFlagsClass

=end pod

#TT:0:N-GFlagsClass:
class N-GFlagsClass is export is repr('CStruct') {
  has N-GTypeClass $.g_type_class;
  has uint32 $.mask;
  has uint32 $.n_values;
  has CArray[N-GEnumValue] $.values;
}

#-------------------------------------------------------------------------------
=begin pod
=head1 Methods
=head2 new

Create a new plain object.

  multi method new ( Bool :empty! )

=begin comment
Create an object using a native object from elsewhere. See also B<Gnome::GObject::Object>.

  multi method new ( N-GObject :$native-object! )

Create an object using a native object from a builder. See also B<Gnome::GObject::Object>.

  multi method new ( Str :$build-id! )
=end comment

=end pod

#TM:0:new():inheriting
#TM:0:new(:empty):
#TM:0:new(:native-object):
# TM:0:new(:build-id):

submethod BUILD ( *%options ) {

  # prevent creating wrong widgets
  return unless self.^name eq 'Gnome::GObject::Enums';

  # process all named arguments
  if ? %options<empty> {
    # self.set-native-object(g_enums_new());
  }

#`{{
  elsif ? %options<native-object> || ? %options<widget> || %options<build-id> {
    # provided in Gnome::GObject::Object
  }
}}

  elsif %options.keys.elems {
    die X::Gnome.new(
      :message('Unsupported options for ' ~ self.^name ~
               ': ' ~ %options.keys.join(', ')
              )
    );
  }

  # only after creating the widget, the gtype is known
  self.set-class-info('GEnums');
}

#-------------------------------------------------------------------------------
#TODO no FALBACK ?? test subs below! # no pod. user does not have to know about it.
method _fallback ( $native-sub is copy --> Callable ) {

  my Callable $s;
  try { $s = &::("g_enums_$native-sub"); };
  try { $s = &::("g_$native-sub"); } unless ?$s;
  try { $s = &::($native-sub); } if !$s and $native-sub ~~ m/^ 'g_' /;

  self.set-class-name-of-sub('GEnums');
  $s = callsame unless ?$s;

  $s;
}

#-------------------------------------------------------------------------------
#TM:0:g_enum_get_value:
=begin pod
=head2 [g_] enum_get_value

Returns the B<N-GEnumValue> for a value.

Returns: (transfer none): the B<N-GEnumValue> for I<value>, or C<Any>
if I<value> is not a member of the enumeration

  method g_enum_get_value ( N-GEnumClass $enum_class, Int $value --> N-GEnumValue  )

=item N-GEnumClass $enum_class; a B<N-GEnumClass>
=item Int $value; the value to look up

=end pod

sub g_enum_get_value ( N-GEnumClass $enum_class, int32 $value )
  returns N-GEnumValue
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_enum_get_value_by_name:
=begin pod
=head2 [g_] enum_get_value_by_name

Looks up a B<N-GEnumValue> by name.

Returns: (transfer none): the B<N-GEnumValue> with name I<name>,
or C<Any> if the enumeration doesn't have a member
with that name

  method g_enum_get_value_by_name ( N-GEnumClass $enum_class, Str $name --> N-GEnumValue  )

=item N-GEnumClass $enum_class; a B<N-GEnumClass>
=item Str $name; the name to look up

=end pod

sub g_enum_get_value_by_name ( N-GEnumClass $enum_class, Str $name )
  returns N-GEnumValue
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_enum_get_value_by_nick:
=begin pod
=head2 [g_] enum_get_value_by_nick

Looks up a B<N-GEnumValue> by nickname.

Returns: (transfer none): the B<N-GEnumValue> with nickname I<nick>,
or C<Any> if the enumeration doesn't have a member
with that nickname

  method g_enum_get_value_by_nick ( N-GEnumClass $enum_class, Str $nick --> N-GEnumValue  )

=item N-GEnumClass $enum_class; a B<N-GEnumClass>
=item Str $nick; the nickname to look up

=end pod

sub g_enum_get_value_by_nick ( N-GEnumClass $enum_class, Str $nick )
  returns N-GEnumValue
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_flags_get_first_value:
=begin pod
=head2 [g_] flags_get_first_value

Returns the first B<N-GFlagsValue> which is set in I<value>.

Returns: (transfer none): the first B<N-GFlagsValue> which is set in
I<value>, or C<Any> if none is set

  method g_flags_get_first_value ( N-GFlagsClass $flags_class, UInt $value --> N-GFlagsValue  )

=item N-GFlagsClass $flags_class; a B<N-GFlagsClass>
=item UInt $value; the value

=end pod

sub g_flags_get_first_value ( N-GFlagsClass $flags_class, uint32 $value )
  returns N-GFlagsValue
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_flags_get_value_by_name:
=begin pod
=head2 [g_] flags_get_value_by_name

Looks up a B<N-GFlagsValue> by name.

Returns: (transfer none): the B<N-GFlagsValue> with name I<name>,
or C<Any> if there is no flag with that name

  method g_flags_get_value_by_name ( N-GFlagsClass $flags_class, Str $name --> N-GFlagsValue  )

=item N-GFlagsClass $flags_class; a B<N-GFlagsClass>
=item Str $name; the name to look up

=end pod

sub g_flags_get_value_by_name ( N-GFlagsClass $flags_class, Str $name )
  returns N-GFlagsValue
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_flags_get_value_by_nick:
=begin pod
=head2 [g_] flags_get_value_by_nick

Looks up a B<N-GFlagsValue> by nickname.

Returns: (transfer none): the B<N-GFlagsValue> with nickname I<nick>,
or C<Any> if there is no flag with that nickname

  method g_flags_get_value_by_nick ( N-GFlagsClass $flags_class, Str $nick --> N-GFlagsValue  )

=item N-GFlagsClass $flags_class; a B<N-GFlagsClass>
=item Str $nick; the nickname to look up

=end pod

sub g_flags_get_value_by_nick ( N-GFlagsClass $flags_class, Str $nick )
  returns N-GFlagsValue
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_enum_to_string:
=begin pod
=head2 [g_] enum_to_string

Pretty-prints I<value> in the form of the enum’s name.

This is intended to be used for debugging purposes. The format of the output
may change in the future.

Returns: (transfer full): a newly-allocated text string

Since: 2.54

  method g_enum_to_string ( int32 $g_enum_type, Int $value --> Str  )

=item int32 $g_enum_type; the type identifier of a B<N-GEnumClass> type
=item Int $value; the value

=end pod

sub g_enum_to_string ( int32 $g_enum_type, int32 $value )
  returns Str
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_flags_to_string:
=begin pod
=head2 [g_] flags_to_string

Pretty-prints I<value> in the form of the flag names separated by ` | ` and
sorted. Any extra bits will be shown at the end as a hexadecimal number.

This is intended to be used for debugging purposes. The format of the output
may change in the future.

Returns: (transfer full): a newly-allocated text string

Since: 2.54

  method g_flags_to_string ( int32 $flags_type, UInt $value --> Str  )

=item int32 $flags_type; the type identifier of a B<N-GFlagsClass> type
=item UInt $value; the value

=end pod

sub g_flags_to_string ( int32 $flags_type, uint32 $value )
  returns Str
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_set_enum:
=begin pod
=head2 [g_] value_set_enum

Set the contents of a C<G_TYPE_ENUM> B<GValue> to I<v_enum>.

  method g_value_set_enum ( N-GObject $value, Int $v_enum )

=item N-GObject $value; a valid B<GValue> whose type is derived from C<G_TYPE_ENUM>
=item Int $v_enum; enum value to be set

=end pod

sub g_value_set_enum ( N-GObject $value, int32 $v_enum )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_get_enum:
=begin pod
=head2 [g_] value_get_enum

Get the contents of a C<G_TYPE_ENUM> B<GValue>.

Returns: enum contents of I<value>

  method g_value_get_enum ( N-GObject $value --> Int  )

=item N-GObject $value; a valid B<GValue> whose type is derived from C<G_TYPE_ENUM>

=end pod

sub g_value_get_enum ( N-GObject $value )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_set_flags:
=begin pod
=head2 [g_] value_set_flags

Set the contents of a C<G_TYPE_FLAGS> B<GValue> to I<v_flags>.

  method g_value_set_flags ( N-GObject $value, UInt $v_flags )

=item N-GObject $value; a valid B<GValue> whose type is derived from C<G_TYPE_FLAGS>
=item UInt $v_flags; flags value to be set

=end pod

sub g_value_set_flags ( N-GObject $value, uint32 $v_flags )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_get_flags:
=begin pod
=head2 [g_] value_get_flags

Get the contents of a C<G_TYPE_FLAGS> B<GValue>.

Returns: flags contents of I<value>

  method g_value_get_flags ( N-GObject $value --> UInt  )

=item N-GObject $value; a valid B<GValue> whose type is derived from C<G_TYPE_FLAGS>

=end pod

sub g_value_get_flags ( N-GObject $value )
  returns uint32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_enum_register_static:
=begin pod
=head2 [g_] enum_register_static

Registers a new static enumeration type with the name I<name>.

It is normally more convenient to let [glib-mkenums][glib-mkenums],
generate a C<my_enum_get_type()> function from a usual C enumeration
definition  than to write one yourself using C<g_enum_register_static()>.

Returns: The new type identifier.

  method g_enum_register_static ( Str $name, N-GEnumValue $const_static_values --> int32  )

=item Str $name; A nul-terminated string used as the name of the new type.
=item N-GEnumValue $const_static_values; An array of B<N-GEnumValue> structs for the possible enumeration values. The array is terminated by a struct with all members being 0. GObject keeps a reference to the data, so it cannot be stack-allocated.

=end pod

sub g_enum_register_static ( Str $name, N-GEnumValue $const_static_values )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_flags_register_static:
=begin pod
=head2 [g_] flags_register_static

Registers a new static flags type with the name I<name>.

It is normally more convenient to let [glib-mkenums][glib-mkenums]
generate a C<my_flags_get_type()> function from a usual C enumeration
definition than to write one yourself using C<g_flags_register_static()>.

Returns: The new type identifier.

  method g_flags_register_static ( Str $name, N-GFlagsValue $const_static_values --> int32  )

=item Str $name; A nul-terminated string used as the name of the new type.
=item N-GFlagsValue $const_static_values; An array of B<N-GFlagsValue> structs for the possible flags values. The array is terminated by a struct with all members being 0. GObject keeps a reference to the data, so it cannot be stack-allocated.

=end pod

sub g_flags_register_static ( Str $name, N-GFlagsValue $const_static_values )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_enum_complete_type_info:
=begin pod
=head2 [g_] enum_complete_type_info

This function is meant to be called from the `complete_type_info`
function of a B<GTypePlugin> implementation, as in the following
example:

|[<!-- language="C" -->
static void
my_enum_complete_type_info (GTypePlugin     *plugin,
GType            g_type,
GTypeInfo       *info,
GTypeValueTable *value_table)
{
static const N-GEnumValue values[] = {
{ MY_ENUM_FOO, "MY_ENUM_FOO", "foo" },
{ MY_ENUM_BAR, "MY_ENUM_BAR", "bar" },
{ 0, NULL, NULL }
};

g_enum_complete_type_info (type, info, values);
}
]|

  method g_enum_complete_type_info ( int32 $g_enum_type, int32 $info, N-GEnumValue $const_values )

=item int32 $g_enum_type; the type identifier of the type being completed
=item int32 $info; (out callee-allocates): the B<GTypeInfo> struct to be filled in
=item N-GEnumValue $const_values; An array of B<N-GEnumValue> structs for the possible enumeration values. The array is terminated by a struct with all members being 0.

=end pod

sub g_enum_complete_type_info ( int32 $g_enum_type, int32 $info, N-GEnumValue $const_values )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_flags_complete_type_info:
=begin pod
=head2 [g_] flags_complete_type_info

This function is meant to be called from the C<complete_type_info()>
function of a B<GTypePlugin> implementation, see the example for
C<g_enum_complete_type_info()> above.

  method g_flags_complete_type_info ( int32 $g_flags_type, int32 $info, N-GFlagsValue $const_values )

=item int32 $g_flags_type; the type identifier of the type being completed
=item int32 $info; (out callee-allocates): the B<GTypeInfo> struct to be filled in
=item N-GFlagsValue $const_values; An array of B<N-GFlagsValue> structs for the possible enumeration values. The array is terminated by a struct with all members being 0.

=end pod

sub g_flags_complete_type_info ( int32 $g_flags_type, int32 $info, N-GFlagsValue $const_values )
  is native(&gobject-lib)
  { * }
