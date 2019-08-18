#TL:0:Gnome::GObject::Param:

use v6;
#-------------------------------------------------------------------------------
=begin pod

=TITLE Gnome::GObject::Param

=SUBTITLE Metadata for parameter specifications

=head1 Description

=begin comment
    C<g_object_get()>, C<g_object_set_property()>, C<g_object_get_property()>,
    C<g_value_register_transform_func()>
=end comment

I<GParamSpec> is an object structure that encapsulates the metadata required to specify parameters, such as e.g. I<GObject> properties.

=head2 Parameter names

Parameter names need to start with a letter (a-z or A-Z). Subsequent characters can be letters, numbers or a '-'. All other characters are replaced by a '-' during construction. The result of this replacement is called the canonical name of the parameter.

=head2 See Also

C<g_object_class_install_property()>, C<g_object_set()>,

=head1 Synopsis
=head2 Declaration

  unit class Gnome::GObject::Param;

=head2 Example

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
unit class Gnome::GObject::Param:auth<github:MARTIMM>;

#-------------------------------------------------------------------------------
=begin pod
=head1 Types
=end pod

#-------------------------------------------------------------------------------
=begin pod
=head2 enum GParamFlags

Through the I<GParamFlags> flag values, certain aspects of parameters can be configured. See also I<G_PARAM_STATIC_STRINGS>.

=item G_PARAM_READABLE: the parameter is readable
=item G_PARAM_WRITABLE: the parameter is writable
=item G_PARAM_READWRITE: alias for C<G_PARAM_READABLE> | C<G_PARAM_WRITABLE>
=item G_PARAM_CONSTRUCT: the parameter will be set upon object construction
=item G_PARAM_CONSTRUCT_ONLY: the parameter can only be set upon object construction
=item G_PARAM_LAX_VALIDATION: upon parameter conversion (see C<g_param_value_convert()>) strict validation is not required
=item G_PARAM_STATIC_NAME: the string used as name when constructing the  parameter is guaranteed to remain valid and unmodified for the lifetime of the parameter.  Since 2.8
=item G_PARAM_STATIC_NICK: the string used as nick when constructing the parameter is guaranteed to remain valid and unmmodified for the lifetime of the parameter. Since 2.8
=item G_PARAM_STATIC_BLURB: the string used as blurb when constructing the  parameter is guaranteed to remain valid and  unmodified for the lifetime of the parameter.  Since 2.8
=item G_PARAM_EXPLICIT_NOTIFY: calls to C<g_object_set_property()> for this property will not automatically result in a "notify" signal being emitted: the implementation must call C<g_object_notify()> themselves in case the property actually changes.  Since: 2.42.
=item G_PARAM_PRIVATE: internal
=item G_PARAM_DEPRECATED: the parameter is deprecated and will be removed in a future version. A warning will be generated if it is used while running with G_ENABLE_DIAGNOSTIC=1. Since 2.26


=end pod

#TE:0:GParamFlags:
enum GParamFlags is export (
  'G_PARAM_READABLE'            => 0x0001, 0b00001,
  'G_PARAM_WRITABLE'            => 0x0002,
  'G_PARAM_READWRITE'           => (0x0001 +| 0x0002),
  'G_PARAM_CONSTRUCT'	          => 0x0004,
  'G_PARAM_CONSTRUCT_ONLY'      => 0x0008,
  'G_PARAM_LAX_VALIDATION'      => 0x0010,
  'G_PARAM_STATIC_NAME'	        => 0x0020,
  'G_PARAM_PRIVATE'	            => 0x0020,  # = G_PARAM_STATIC_NAME
  'G_PARAM_STATIC_NICK'	        => 0x0040,
  'G_PARAM_STATIC_BLURB'	      => 0x0080,
  'G_PARAM_EXPLICIT_NOTIFY'     => 1 +< 30,
  'G_PARAM_DEPRECATED'          => 1 +< 31,
);

#-------------------------------------------------------------------------------
=begin pod
=head2 class GParamSpec

All other fields of the GParamSpec struct are private and should not be used directly.

=item $.name: name of this parameter.
=item GParamFlags $.flags: Flags for this parameter
=item $.value_type: the I<GValue> type for this parameter
=item $.owner_type: I<GType> type that uses (introduces) this parameter

=end pod

#TT:0:GParamSpec:
class GParamSpec is export is repr('CStruct') {
  has GTypeInstance $!g_type_instance;
  has str $.name;
  has GParamFlags $.flags;
  has int32 $.value_type;     # GType
  has int32 $.owner_type;     # GType
  has str $!_nick;
  has str $!_blurb;
  has Pointer $!qdata;        # GData
  has uint32 $!ref_count;
  has uint32 $!param_id;
}

#`{{
#-------------------------------------------------------------------------------
=begin pod
=head2 class GParameter

The GParameter struct is an auxiliary structure used to hand parameter name/value pairs to C<g_object_newv()>.

Deprecated: 2.54: This type is not introspectable.


=item Str $.name: the parameter name
=item N-GObject $.value: the parameter value


=end pod

#TT:0:GParameter:
class GParameter is export is repr('CStruct') {
  has str $.name;
  has N-GObject $.value;
}
}}

#`{{
#-------------------------------------------------------------------------------
=begin pod
=head2 class GParamSpecTypeInfo

This structure is used to provide the type system with the information required to initialize and destruct (finalize) a parameter's class and instances thereof.
The initialized structure is passed to the C<g_param_type_register_static()>
The type system will perform a deep copy of this structure, so its memory
does not need to be persistent across invocation of
C<g_param_type_register_static()>.


=item ___instance_size: Size of the instance (object) structure.
=item ___n_preallocs: Prior to GLib 2.10, it specified the number of pre-allocated (cached) instances to reserve memory for (0 indicates no caching). Since GLib 2.10, it is ignored, since instances are allocated with the [slice allocator][glib-Memory-Slices] now.
=item ___instance_init: Location of the instance initialization function (optional).
=item ___value_type: The I<GType> of values conforming to this I<GParamSpec>
=item ___finalize: The instance finalization function (optional).
=item ___value_set_default: Resets a I<value> to the default value for I<pspec>  (recommended, the default is C<g_value_reset()>), see  C<g_param_value_set_default()>.
=item ___value_validate: Ensures that the contents of I<value> comply with the  specifications set out by I<pspec> (optional), see  C<g_param_value_validate()>.
=item ___values_cmp: Compares I<value1> with I<value2> according to I<pspec>  (recommended, the default is C<memcmp()>), see C<g_param_values_cmp()>.

=end pod

#TT:0:GParamSpecTypeInfo:
class GParamSpecTypeInfo is export is repr('CStruct') {
  has N-GObject $.value);
  has N-GObject $.value);
  has N-GObject $.value2);
}
}}

#-------------------------------------------------------------------------------
has GParamSpec $!g-param-spec;

#-------------------------------------------------------------------------------
=begin pod
=head1 Methods
=head2 new
=head3 multi method new ( GParamSpec :$gparam! )

Create a GParamSpec using a native object from elsewhere.

=end pod

#TM:0:new(:gparam):
submethod BUILD ( *%options ) {

  # prevent creating wrong widgets
  return unless self.^name eq 'Gnome::GObject::Param';

  # process all named arguments
  if ? %options<gparam> {

  }

  elsif %options.keys.elems {
    die X::Gnome.new(
      :message('Unsupported options for ' ~ self.^name ~
               ': ' ~ %options.keys.join(', ')
              )
    );
  }

  else {
    if %options.keys.elems == 0 {
      note 'No options used to create or set the native widget'
        if $Gnome::N::x-debug;
      die X::Gnome.new(
        :message('No options used to create or set the native widget')
      );
    }
  }

  # only after creating the widget, the gtype is known
#  self.set-class-info('GParam');
}

#-------------------------------------------------------------------------------
# no pod. user does not have to know about it.
method fallback ( $native-sub is copy --> Callable ) {

  my Callable $s;
  try { $s = &::($native-sub); }
  try { $s = &::("g_param_$native-sub"); } unless ?$s;

#  self.set-class-name-of-sub('GParam');
  $s = callsame unless ?$s;

  $s;
}


#-------------------------------------------------------------------------------
#TM:0:g_param_spec_ref:
=begin pod
=head2 [g_param_] spec_ref

Increments the reference count of I<pspec>.

Returns: the I<GParamSpec> that was passed into this function

  method g_param_spec_ref ( GParamSpec $pspec --> GParamSpec  )

=item GParamSpec $pspec; a valid I<GParamSpec>

=end pod

sub g_param_spec_ref ( GParamSpec $pspec )
  returns GParamSpec
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_unref:
=begin pod
=head2 [g_param_] spec_unref

Decrements the reference count of a I<pspec>.

  method g_param_spec_unref ( GParamSpec $pspec )

=item GParamSpec $pspec; a valid I<GParamSpec>

=end pod

sub g_param_spec_unref ( GParamSpec $pspec )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_sink:
=begin pod
=head2 [g_param_] spec_sink

The initial reference count of a newly created I<GParamSpec> is 1,
even though no one has explicitly called C<g_param_spec_ref()> on it
yet. So the initial reference count is flagged as "floating", until
someone calls `g_param_spec_ref (pspec); g_param_spec_sink
(pspec);` in sequence on it, taking over the initial
reference count (thus ending up with a I<pspec> that has a reference
count of 1 still, but is not flagged "floating" anymore).

  method g_param_spec_sink ( GParamSpec $pspec )

=item GParamSpec $pspec; a valid I<GParamSpec>

=end pod

sub g_param_spec_sink ( GParamSpec $pspec )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_ref_sink:
=begin pod
=head2 [g_param_] spec_ref_sink

Convenience function to ref and sink a I<GParamSpec>.

Since: 2.10
Returns: the I<GParamSpec> that was passed into this function

  method g_param_spec_ref_sink ( GParamSpec $pspec --> GParamSpec  )

=item GParamSpec $pspec; a valid I<GParamSpec>

=end pod

sub g_param_spec_ref_sink ( GParamSpec $pspec )
  returns GParamSpec
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_get_qdata:
=begin pod
=head2 [g_param_] spec_get_qdata

Gets back user data pointers stored via C<g_param_spec_set_qdata()>.

Returns: (transfer none): the user data pointer set, or C<Any>

  method g_param_spec_get_qdata ( GParamSpec $pspec, N-GObject $quark --> Pointer  )

=item GParamSpec $pspec; a valid I<GParamSpec>
=item N-GObject $quark; a I<GQuark>, naming the user data pointer

=end pod

sub g_param_spec_get_qdata ( GParamSpec $pspec, N-GObject $quark )
  returns Pointer
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_set_qdata:
=begin pod
=head2 [g_param_] spec_set_qdata

Sets an opaque, named pointer on a I<GParamSpec>. The name is
specified through a I<GQuark> (retrieved e.g. via
C<g_quark_from_static_string()>), and the pointer can be gotten back
from the I<pspec> with C<g_param_spec_get_qdata()>.  Setting a
previously set user data pointer, overrides (frees) the old pointer
set, using C<Any> as pointer essentially removes the data stored.

  method g_param_spec_set_qdata ( GParamSpec $pspec, N-GObject $quark, Pointer $data )

=item GParamSpec $pspec; the I<GParamSpec> to set store a user data pointer
=item N-GObject $quark; a I<GQuark>, naming the user data pointer
=item Pointer $data; an opaque user data pointer

=end pod

sub g_param_spec_set_qdata ( GParamSpec $pspec, N-GObject $quark, Pointer $data )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_set_qdata_full:
=begin pod
=head2 [g_param_] spec_set_qdata_full

This function works like C<g_param_spec_set_qdata()>, but in addition,
a `void (*destroy) (gpointer)` function may be
specified which is called with I<data> as argument when the I<pspec> is
finalized, or the data is being overwritten by a call to
C<g_param_spec_set_qdata()> with the same I<quark>.

  method g_param_spec_set_qdata_full ( GParamSpec $pspec, N-GObject $quark, Pointer $data, GDestroyNotify $destroy )

=item GParamSpec $pspec; the I<GParamSpec> to set store a user data pointer
=item N-GObject $quark; a I<GQuark>, naming the user data pointer
=item Pointer $data; an opaque user data pointer
=item GDestroyNotify $destroy; function to invoke with I<data> as argument, when I<data> needs to be freed

=end pod

sub g_param_spec_set_qdata_full ( GParamSpec $pspec, N-GObject $quark, Pointer $data, GDestroyNotify $destroy )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_steal_qdata:
=begin pod
=head2 [g_param_] spec_steal_qdata

Gets back user data pointers stored via C<g_param_spec_set_qdata()>
and removes the I<data> from I<pspec> without invoking its C<destroy()>
function (if any was set).  Usually, calling this function is only
required to update user data pointers with a destroy notifier.

Returns: (transfer none): the user data pointer set, or C<Any>

  method g_param_spec_steal_qdata ( GParamSpec $pspec, N-GObject $quark --> Pointer  )

=item GParamSpec $pspec; the I<GParamSpec> to get a stored user data pointer from
=item N-GObject $quark; a I<GQuark>, naming the user data pointer

=end pod

sub g_param_spec_steal_qdata ( GParamSpec $pspec, N-GObject $quark )
  returns Pointer
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_get_redirect_target:
=begin pod
=head2 [g_param_] spec_get_redirect_target

If the paramspec redirects operations to another paramspec,
returns that paramspec. Redirect is used typically for
providing a new implementation of a property in a derived
type while preserving all the properties from the parent
type. Redirection is established by creating a property
of type I<GParamSpecOverride>. See C<g_object_class_override_property()>
for an example of the use of this capability.

Since: 2.4

Returns: (transfer none): paramspec to which requests on this
paramspec should be redirected, or C<Any> if none.

  method g_param_spec_get_redirect_target ( GParamSpec $pspec --> GParamSpec  )

=item GParamSpec $pspec; a I<GParamSpec>

=end pod

sub g_param_spec_get_redirect_target ( GParamSpec $pspec )
  returns GParamSpec
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_value_set_default:
=begin pod
=head2 [g_param_] value_set_default

Sets I<value> to its default value as specified in I<pspec>.

  method g_param_value_set_default ( GParamSpec $pspec, N-GObject $value )

=item GParamSpec $pspec; a valid I<GParamSpec>
=item N-GObject $value; a I<GValue> of correct type for I<pspec>

=end pod

sub g_param_value_set_default ( GParamSpec $pspec, N-GObject $value )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_value_defaults:
=begin pod
=head2 [g_param_] value_defaults

Checks whether I<value> contains the default value as specified in I<pspec>.

Returns: whether I<value> contains the canonical default for this I<pspec>

  method g_param_value_defaults ( GParamSpec $pspec, N-GObject $value --> Int  )

=item GParamSpec $pspec; a valid I<GParamSpec>
=item N-GObject $value; a I<GValue> of correct type for I<pspec>

=end pod

sub g_param_value_defaults ( GParamSpec $pspec, N-GObject $value )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_value_validate:
=begin pod
=head2 [g_param_] value_validate

Ensures that the contents of I<value> comply with the specifications
set out by I<pspec>. For example, a I<GParamSpecInt> might require
that integers stored in I<value> may not be smaller than -42 and not be
greater than +42. If I<value> contains an integer outside of this range,
it is modified accordingly, so the resulting value will fit into the
range -42 .. +42.

Returns: whether modifying I<value> was necessary to ensure validity

  method g_param_value_validate ( GParamSpec $pspec, N-GObject $value --> Int  )

=item GParamSpec $pspec; a valid I<GParamSpec>
=item N-GObject $value; a I<GValue> of correct type for I<pspec>

=end pod

sub g_param_value_validate ( GParamSpec $pspec, N-GObject $value )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_value_convert:
=begin pod
=head2 [g_param_] value_convert

Transforms I<src_value> into I<dest_value> if possible, and then
validates I<dest_value>, in order for it to conform to I<pspec>.  If
I<strict_validation> is C<1> this function will only succeed if the
transformed I<dest_value> complied to I<pspec> without modifications.

See also C<g_value_type_transformable()>, C<g_value_transform()> and
C<g_param_value_validate()>.

Returns: C<1> if transformation and validation were successful,
C<0> otherwise and I<dest_value> is left untouched.

  method g_param_value_convert ( GParamSpec $pspec, N-GObject $src_value, N-GObject $dest_value, Int $strict_validation --> Int  )

=item GParamSpec $pspec; a valid I<GParamSpec>
=item N-GObject $src_value; souce I<GValue>
=item N-GObject $dest_value; destination I<GValue> of correct type for I<pspec>
=item Int $strict_validation; C<1> requires I<dest_value> to conform to I<pspec> without modifications

=end pod

sub g_param_value_convert ( GParamSpec $pspec, N-GObject $src_value, N-GObject $dest_value, int32 $strict_validation )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_values_cmp:
=begin pod
=head2 [g_param_] values_cmp

Compares I<value1> with I<value2> according to I<pspec>, and return -1, 0 or +1,
if I<value1> is found to be less than, equal to or greater than I<value2>,
respectively.

Returns: -1, 0 or +1, for a less than, equal to or greater than result

  method g_param_values_cmp ( GParamSpec $pspec, N-GObject $value1, N-GObject $value2 --> Int  )

=item GParamSpec $pspec; a valid I<GParamSpec>
=item N-GObject $value1; a I<GValue> of correct type for I<pspec>
=item N-GObject $value2; a I<GValue> of correct type for I<pspec>

=end pod

sub g_param_values_cmp ( GParamSpec $pspec, N-GObject $value1, N-GObject $value2 )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_get_name:
=begin pod
=head2 [g_param_] spec_get_name

Get the name of a I<GParamSpec>.

The name is always an "interned" string (as per C<g_intern_string()>).
This allows for pointer-value comparisons.

Returns: the name of I<pspec>.

  method g_param_spec_get_name ( GParamSpec $pspec --> Str  )

=item GParamSpec $pspec; a valid I<GParamSpec>

=end pod

sub g_param_spec_get_name ( GParamSpec $pspec )
  returns Str
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_get_nick:
=begin pod
=head2 [g_param_] spec_get_nick

Get the nickname of a I<GParamSpec>.

Returns: the nickname of I<pspec>.

  method g_param_spec_get_nick ( GParamSpec $pspec --> Str  )

=item GParamSpec $pspec; a valid I<GParamSpec>

=end pod

sub g_param_spec_get_nick ( GParamSpec $pspec )
  returns Str
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_get_blurb:
=begin pod
=head2 [g_param_] spec_get_blurb

Get the short description of a I<GParamSpec>.

Returns: the short description of I<pspec>.

  method g_param_spec_get_blurb ( GParamSpec $pspec --> Str  )

=item GParamSpec $pspec; a valid I<GParamSpec>

=end pod

sub g_param_spec_get_blurb ( GParamSpec $pspec )
  returns Str
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_set_param:
=begin pod
=head2 g_value_set_param

Set the contents of a C<G_TYPE_PARAM> I<GValue> to I<param>.

  method g_value_set_param ( N-GObject $value, GParamSpec $param )

=item N-GObject $value; a valid I<GValue> of type C<G_TYPE_PARAM>
=item GParamSpec $param; (nullable): the I<GParamSpec> to be set

=end pod

sub g_value_set_param ( N-GObject $value, GParamSpec $param )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_get_param:
=begin pod
=head2 g_value_get_param

Get the contents of a C<G_TYPE_PARAM> I<GValue>.

Returns: (transfer none): I<GParamSpec> content of I<value>

  method g_value_get_param ( N-GObject $value --> GParamSpec  )

=item N-GObject $value; a valid I<GValue> whose type is derived from C<G_TYPE_PARAM>

=end pod

sub g_value_get_param ( N-GObject $value )
  returns GParamSpec
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_dup_param:
=begin pod
=head2 g_value_dup_param

Get the contents of a C<G_TYPE_PARAM> I<GValue>, increasing its
reference count.

Returns: I<GParamSpec> content of I<value>, should be unreferenced when
no longer needed.

  method g_value_dup_param ( N-GObject $value --> GParamSpec  )

=item N-GObject $value; a valid I<GValue> whose type is derived from C<G_TYPE_PARAM>

=end pod

sub g_value_dup_param ( N-GObject $value )
  returns GParamSpec
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_take_param:
=begin pod
=head2 g_value_take_param

Sets the contents of a C<G_TYPE_PARAM> I<GValue> to I<param> and takes
over the ownership of the callers reference to I<param>; the caller
doesn't have to unref it any more.

Since: 2.4

  method g_value_take_param ( N-GObject $value, GParamSpec $param )

=item N-GObject $value; a valid I<GValue> of type C<G_TYPE_PARAM>
=item GParamSpec $param; (nullable): the I<GParamSpec> to be set

=end pod

sub g_value_take_param ( N-GObject $value, GParamSpec $param )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_get_default_value:
=begin pod
=head2 [g_param_] spec_get_default_value

Gets the default value of I<pspec> as a pointer to a I<GValue>.

The I<GValue> will remain valid for the life of I<pspec>.

Returns: a pointer to a I<GValue> which must not be modified

Since: 2.38

  method g_param_spec_get_default_value ( GParamSpec $pspec --> N-GObject  )

=item GParamSpec $pspec; a I<GParamSpec>

=end pod

sub g_param_spec_get_default_value ( GParamSpec $pspec )
  returns N-GObject
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_get_name_quark:
=begin pod
=head2 [g_param_] spec_get_name_quark

Gets the GQuark for the name.

Returns: the GQuark for I<pspec>->name.

Since: 2.46

  method g_param_spec_get_name_quark ( GParamSpec $pspec --> N-GObject  )

=item GParamSpec $pspec; a I<GParamSpec>

=end pod

sub g_param_spec_get_name_quark ( GParamSpec $pspec )
  returns N-GObject
  is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
#TM:0:g_param_type_register_static:
=begin pod
=head2 [g_param_] type_register_static

Registers I<name> as the name of a new static type derived from
I<G_TYPE_PARAM>. The type system uses the information contained in
the I<GParamSpecTypeInfo> structure pointed to by I<info> to manage the
I<GParamSpec> type and its instances.

Returns: The new type identifier.

  method g_param_type_register_static ( Str $name, GParamSpecTypeInfo $pspec_info --> N-GObject  )

=item Str $name; 0-terminated string used as the name of the new I<GParamSpec> type.
=item GParamSpecTypeInfo $pspec_info; The I<GParamSpecTypeInfo> for this I<GParamSpec> type.

=end pod

sub g_param_type_register_static ( Str $name, GParamSpecTypeInfo $pspec_info )
  returns N-GObject
  is native(&gobject-lib)
  { * }
}}

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_internal:
=begin pod
=head2 [g_param_] spec_internal

Creates a new I<GParamSpec> instance.

A property name consists of segments consisting of ASCII letters and
digits, separated by either the '-' or '_' character. The first
character of a property name must be a letter. Names which violate these
rules lead to undefined behaviour.

When creating and looking up a I<GParamSpec>, either separator can be
used, but they cannot be mixed. Using '-' is considerably more
efficient and in fact required when using property names as detail
strings for signals.

Beyond the name, I<GParamSpecs> have two more descriptive
strings associated with them, the I<nick>, which should be suitable
for use as a label for the property in a property editor, and the
I<blurb>, which should be a somewhat longer description, suitable for
e.g. a tooltip. The I<nick> and I<blurb> should ideally be localized.

Returns: (type GObject.ParamSpec): a newly allocated I<GParamSpec> instance

  method g_param_spec_internal ( N-GObject $param_type, Str $name, Str $nick, Str $blurb, GParamFlags $flags --> Pointer  )

=item N-GObject $param_type; the I<GType> for the property; must be derived from I<G_TYPE_PARAM>
=item Str $name; the canonical name of the property
=item Str $nick; the nickname of the property
=item Str $blurb; a short description of the property
=item GParamFlags $flags; a combination of I<GParamFlags>

=end pod

sub g_param_spec_internal ( N-GObject $param_type, Str $name, Str $nick, Str $blurb, GParamFlags $flags )
  returns Pointer
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_pool_new:
=begin pod
=head2 [g_param_] spec_pool_new

Creates a new I<GParamSpecPool>.

If I<type_prefixing> is C<1>, lookups in the newly created pool will
allow to specify the owner as a colon-separated prefix of the
property name, like "I<Gnome::Gtk3::Container>:border-width". This feature is
deprecated, so you should always set I<type_prefixing> to C<0>.

Returns: (transfer none): a newly allocated I<GParamSpecPool>.

  method g_param_spec_pool_new ( Int $type_prefixing --> GParamSpecPool  )

=item Int $type_prefixing; Whether the pool will support type-prefixed property names.

=end pod

sub g_param_spec_pool_new ( int32 $type_prefixing )
  returns GParamSpecPool
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_pool_insert:
=begin pod
=head2 [g_param_] spec_pool_insert

Inserts a I<GParamSpec> in the pool.

  method g_param_spec_pool_insert ( GParamSpecPool $pool, GParamSpec $pspec, N-GObject $owner_type )

=item GParamSpecPool $pool; a I<GParamSpecPool>.
=item GParamSpec $pspec; the I<GParamSpec> to insert
=item N-GObject $owner_type; a I<GType> identifying the owner of I<pspec>

=end pod

sub g_param_spec_pool_insert ( GParamSpecPool $pool, GParamSpec $pspec, N-GObject $owner_type )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_pool_remove:
=begin pod
=head2 [g_param_] spec_pool_remove

Removes a I<GParamSpec> from the pool.

  method g_param_spec_pool_remove ( GParamSpecPool $pool, GParamSpec $pspec )

=item GParamSpecPool $pool; a I<GParamSpecPool>
=item GParamSpec $pspec; the I<GParamSpec> to remove

=end pod

sub g_param_spec_pool_remove ( GParamSpecPool $pool, GParamSpec $pspec )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_pool_lookup:
=begin pod
=head2 [g_param_] spec_pool_lookup

Looks up a I<GParamSpec> in the pool.

Returns: (transfer none): The found I<GParamSpec>, or C<Any> if no
matching I<GParamSpec> was found.

  method g_param_spec_pool_lookup ( GParamSpecPool $pool, Str $param_name, N-GObject $owner_type, Int $walk_ancestors --> GParamSpec  )

=item GParamSpecPool $pool; a I<GParamSpecPool>
=item Str $param_name; the name to look for
=item N-GObject $owner_type; the owner to look for
=item Int $walk_ancestors; If C<1>, also try to find a I<GParamSpec> with I<param_name> owned by an ancestor of I<owner_type>.

=end pod

sub g_param_spec_pool_lookup ( GParamSpecPool $pool, Str $param_name, N-GObject $owner_type, int32 $walk_ancestors )
  returns GParamSpec
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_pool_list_owned:
=begin pod
=head2 [g_param_] spec_pool_list_owned

Gets an I<GList> of all I<GParamSpecs> owned by I<owner_type> in
the pool.

Returns: (transfer container) (element-type GObject.ParamSpec): a
I<GList> of all I<GParamSpecs> owned by I<owner_type> in
the poolI<GParamSpecs>.

  method g_param_spec_pool_list_owned ( GParamSpecPool $pool, N-GObject $owner_type --> N-GList  )

=item GParamSpecPool $pool; a I<GParamSpecPool>
=item N-GObject $owner_type; the owner to look for

=end pod

sub g_param_spec_pool_list_owned ( GParamSpecPool $pool, N-GObject $owner_type )
  returns N-GList
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_pool_list:
=begin pod
=head2 [g_param_] spec_pool_list

Gets an array of all I<GParamSpecs> owned by I<owner_type> in
the pool.

Returns: (array length=n_pspecs_p) (transfer container): a newly
allocated array containing pointers to all I<GParamSpecs>
owned by I<owner_type> in the pool

  method g_param_spec_pool_list ( GParamSpecPool $pool, N-GObject $owner_type, UInt $n_pspecs_p --> GParamSpec  )

=item GParamSpecPool $pool; a I<GParamSpecPool>
=item N-GObject $owner_type; the owner to look for
=item UInt $n_pspecs_p; (out): return location for the length of the returned array

=end pod

sub g_param_spec_pool_list ( GParamSpecPool $pool, N-GObject $owner_type, uint32 $n_pspecs_p )
  returns GParamSpec
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
=begin pod
=begin comment

=head1 Not yet implemented methods

=head3 method g_param_type_register_static ( ... )
=head3 method  ( ... )
=head3 method  ( ... )
=head3 method  ( ... )
=head3 method  ( ... )
=head3 method  ( ... )
=head3 method  ( ... )
=head3 method  ( ... )
=head3 method  ( ... )

=end comment
=end pod

#-------------------------------------------------------------------------------
=begin pod
=begin comment

=head1 Not implemented methods

=head3 method  ( ... )
=head3 method  ( ... )
=head3 method  ( ... )
=head3 method  ( ... )
=head3 method  ( ... )
=head3 method  ( ... )
=head3 method  ( ... )
=head3 method  ( ... )
=head3 method  ( ... )

=end comment
=end pod
