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

I<N-GParamSpec> is an object structure that encapsulates the metadata required to specify parameters, such as e.g. I<GObject> properties.

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
=head2 class N-GParamSpec

All other fields of the N-GParamSpec struct are private and should not be used directly.

=item $.name: name of this parameter.
=item GParamFlags $.flags: Flags for this parameter
=item $.value_type: the I<GValue> type for this parameter
=item $.owner_type: I<GType> type that uses (introduces) this parameter

=end pod

#TT:0:N-GParamSpec:
class N-GParamSpec is export is repr('CStruct') {
  has Pointer $!g_type_instance;  # GTypeInstance
  has str $.name;
  has int32 $.flags;              # enum GParamFlags
  has uint64 $.value_type;        # GType
  has uint64 $.owner_type;        # GType
  has str $!_nick;
  has str $!_blurb;
  has Pointer $!qdata;            # GData
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
=item ___value_type: The I<GType> of values conforming to this I<N-GParamSpec>
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
has N-GParamSpec $!g-param-spec;

#-------------------------------------------------------------------------------
=begin pod
=head1 Methods
=head2 new
=head3 multi method new ( N-GParamSpec :$gparam! )

Create a N-GParamSpec using a native object from elsewhere.

=end pod

#TM:0:new(:gparam):
submethod BUILD ( *%options ) {

  # prevent creating wrong widgets
  return unless self.^name eq 'Gnome::GObject::Param';

  # process all named arguments
  if ? %options<empty> {
    $!g-param-spec .= new;
  }

  elsif ? %options<gparam> {
    $!g-param-spec = %options<gparam>;
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
#TODO destroy when overwritten? g_object_unref?
method CALL-ME ( N-GObject $gparam? --> N-GParamSpec ) {

  if ?$gparam {
    # if native object exists it will be overwritten. unref object first.
    if !$!g-param-spec {
      #TODO self.g_object_unref();
    }
    $!g-param-spec = $gparam;
    #TODO self.g_object_ref();
  }

  $!g-param-spec
}

#-------------------------------------------------------------------------------
# no pod. user does not have to know about it.
#
# Fallback method to find the native subs which then can be called as if it
# were a method. Each class must provide their own '_fallback' method which,
# when nothing found, must call the parents _fallback with 'callsame'.
# The subs in some class all start with some prefix which can be left out too
# provided that the _fallback functions must also test with an added prefix.
# So e.g. a sub 'gtk_label_get_text' defined in class GtlLabel can be called
# like '$label.gtk_label_get_text()' or '$label.get_text()'. As an extra
# feature dashes can be used instead of underscores, so '$label.get-text()'
# works too.
method FALLBACK ( $native-sub is copy, |c ) {

  CATCH { test-catch-exception( $_, $native-sub); }

  # convert all dashes to underscores if there are any. then check if
  # name is not too short.
  $native-sub ~~ s:g/ '-' /_/ if $native-sub.index('-').defined;
#`{{
  die X::Gnome.new(:message(
      "Native sub name '$native-sub' made too short." ~
      " Keep at least one '-' or '_'."
    )
  ) unless $native-sub.index('_') // -1 >= 0;
}}

  # check if there are underscores in the name. then the name is not too short.
  my Callable $s;

  # call the _fallback functions of this classes children starting
  # at the bottom
  $s = self._fallback($native-sub);

  die X::Gnome.new(:message("Native sub '$native-sub' not found"))
      unless $s.defined;

  # User convenience substitutions to get a native object instead of
  # a GtkSomeThing or other *SomeThing object.
  my Array $params = [];
  for c.list -> $p {

    # must handle RGBA differently because it's a structure, not a widget
    # with a native object
    if $p.^name ~~ m/^ 'Gnome::Gdk3::RGBA' / {
      $params.push($p);
    }

    elsif $p.^name ~~ m/^ 'Gnome::' [ Gtk3 || Gdk3 || Glib || GObject ] '::' / {
      $params.push($p());
    }

    else {
      $params.push($p);
    }
  }

  # cast to other gtk object type if the found subroutine is from another
  # gtk object type than the native object stored at $!g-object. This happens
  # e.g. when a Gnome::Gtk::Button object uses gtk-widget-show() which
  # belongs to Gnome::Gtk::Widget.
  my $g-object-cast;
#`{{
#note "type class: $!gtk-class-gtype, $!gtk-class-name";
  #TODO Not all classes have $!gtk-class-* defined so we need to test it
  if ?$!gtk-class-gtype and ?$!gtk-class-name and ?$!gtk-class-name-of-sub and
     $!gtk-class-name ne $!gtk-class-name-of-sub {
    note "\nObject gtype: $!gtk-class-gtype" if $Gnome::N::x-debug;
    note "Cast $!gtk-class-name to $!gtk-class-name-of-sub"
      if $Gnome::N::x-debug;

    $g-object-cast = Gnome::GObject::Type.new().check-instance-cast(
      $!g-object, $!gtk-class-gtype
    );
  }

  test-call( $s, $g-object-cast // $!g-object, |$params)
}}
  test-call( $s, $!g-param-spec, |$params)
}

#-------------------------------------------------------------------------------
# no pod. user does not have to know about it.
method _fallback ( $native-sub is copy --> Callable ) {

  my Callable $s;
  try { $s = &::("g_param_$native-sub"); };
  try { $s = &::("g_$native-sub"); } unless ?$s;
  try { $s = &::($native-sub); } if !$s and $native-sub ~~ m/^ 'g_' /;

#  self.set-class-name-of-sub('GParam');
  $s = callsame unless ?$s;

  $s;
}


#-------------------------------------------------------------------------------
#TM:0:g_param_spec_ref:
=begin pod
=head2 [g_param_] spec_ref

Increments the reference count of I<pspec>.

Returns: the I<N-GParamSpec> that was passed into this function

  method g_param_spec_ref ( N-GParamSpec $pspec --> N-GParamSpec  )

=item N-GParamSpec $pspec; a valid I<N-GParamSpec>

=end pod

sub g_param_spec_ref ( N-GParamSpec $pspec )
  returns N-GParamSpec
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_unref:
=begin pod
=head2 [g_param_] spec_unref

Decrements the reference count of a I<pspec>.

  method g_param_spec_unref ( N-GParamSpec $pspec )

=item N-GParamSpec $pspec; a valid I<N-GParamSpec>

=end pod

sub g_param_spec_unref ( N-GParamSpec $pspec )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_sink:
=begin pod
=head2 [g_param_] spec_sink

The initial reference count of a newly created I<N-GParamSpec> is 1, even though no one has explicitly called C<g_param_spec_ref()> on it yet. So the initial reference count is flagged as "floating", until someone calls C<g_param_spec_ref(pspec)> and C<g_param_spec_sink(pspec)> in sequence on it, taking over the initial reference count (thus ending up with a I<pspec> that has a reference count of 1 still, but is not flagged "floating" anymore).

  method g_param_spec_sink ( N-GParamSpec $pspec )

=item N-GParamSpec $pspec; a valid I<N-GParamSpec>

=end pod

sub g_param_spec_sink ( N-GParamSpec $pspec )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_ref_sink:
=begin pod
=head2 [g_param_] spec_ref_sink

Convenience function to ref and sink a I<N-GParamSpec>.

Since: 2.10
Returns: the I<N-GParamSpec> that was passed into this function

  method g_param_spec_ref_sink ( N-GParamSpec $pspec --> N-GParamSpec  )

=item N-GParamSpec $pspec; a valid I<N-GParamSpec>

=end pod

sub g_param_spec_ref_sink ( N-GParamSpec $pspec )
  returns N-GParamSpec
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_get_qdata:
=begin pod
=head2 [g_param_] spec_get_qdata

Gets back user data pointers stored via C<g_param_spec_set_qdata()>.

Returns: (transfer none): the user data pointer set, or C<Any>

  method g_param_spec_get_qdata ( N-GParamSpec $pspec, N-GObject $quark --> Pointer  )

=item N-GParamSpec $pspec; a valid I<N-GParamSpec>
=item N-GObject $quark; a I<GQuark>, naming the user data pointer

=end pod

sub g_param_spec_get_qdata ( N-GParamSpec $pspec, N-GObject $quark )
  returns Pointer
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_set_qdata:
=begin pod
=head2 [g_param_] spec_set_qdata

Sets an opaque, named pointer on a I<N-GParamSpec>. The name is
specified through a I<GQuark> (retrieved e.g. via
C<g_quark_from_static_string()>), and the pointer can be gotten back
from the I<pspec> with C<g_param_spec_get_qdata()>.  Setting a
previously set user data pointer, overrides (frees) the old pointer
set, using C<Any> as pointer essentially removes the data stored.

  method g_param_spec_set_qdata ( N-GParamSpec $pspec, N-GObject $quark, Pointer $data )

=item N-GParamSpec $pspec; the I<N-GParamSpec> to set store a user data pointer
=item N-GObject $quark; a I<GQuark>, naming the user data pointer
=item Pointer $data; an opaque user data pointer

=end pod

sub g_param_spec_set_qdata ( N-GParamSpec $pspec, N-GObject $quark, Pointer $data )
  is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
#TM:0:g_param_spec_set_qdata_full:
=begin pod
=head2 [g_param_] spec_set_qdata_full

This function works like C<g_param_spec_set_qdata()>, but in addition,
a `void (*destroy) (gpointer)` function may be
specified which is called with I<data> as argument when the I<pspec> is
finalized, or the data is being overwritten by a call to
C<g_param_spec_set_qdata()> with the same I<quark>.

  method g_param_spec_set_qdata_full ( N-GParamSpec $pspec, N-GObject $quark, Pointer $data, GDestroyNotify $destroy )

=item N-GParamSpec $pspec; the I<N-GParamSpec> to set store a user data pointer
=item N-GObject $quark; a I<GQuark>, naming the user data pointer
=item Pointer $data; an opaque user data pointer
=item GDestroyNotify $destroy; function to invoke with I<data> as argument, when I<data> needs to be freed

=end pod

sub g_param_spec_set_qdata_full ( N-GParamSpec $pspec, N-GObject $quark, Pointer $data, GDestroyNotify $destroy )
  is native(&gobject-lib)
  { * }
}}

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_steal_qdata:
=begin pod
=head2 [g_param_] spec_steal_qdata

Gets back user data pointers stored via C<g_param_spec_set_qdata()>
and removes the I<data> from I<pspec> without invoking its C<destroy()>
function (if any was set).  Usually, calling this function is only
required to update user data pointers with a destroy notifier.

Returns: (transfer none): the user data pointer set, or C<Any>

  method g_param_spec_steal_qdata ( N-GParamSpec $pspec, N-GObject $quark --> Pointer  )

=item N-GParamSpec $pspec; the I<N-GParamSpec> to get a stored user data pointer from
=item N-GObject $quark; a I<GQuark>, naming the user data pointer

=end pod

sub g_param_spec_steal_qdata ( N-GParamSpec $pspec, N-GObject $quark )
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
of type I<N-GParamSpecOverride>. See C<g_object_class_override_property()>
for an example of the use of this capability.

Since: 2.4

Returns: (transfer none): paramspec to which requests on this
paramspec should be redirected, or C<Any> if none.

  method g_param_spec_get_redirect_target ( N-GParamSpec $pspec --> N-GParamSpec  )

=item N-GParamSpec $pspec; a I<N-GParamSpec>

=end pod

sub g_param_spec_get_redirect_target ( N-GParamSpec $pspec )
  returns N-GParamSpec
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_value_set_default:
=begin pod
=head2 [g_param_] value_set_default

Sets I<value> to its default value as specified in I<pspec>.

  method g_param_value_set_default ( N-GParamSpec $pspec, N-GObject $value )

=item N-GParamSpec $pspec; a valid I<N-GParamSpec>
=item N-GObject $value; a I<GValue> of correct type for I<pspec>

=end pod

sub g_param_value_set_default ( N-GParamSpec $pspec, N-GObject $value )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_value_defaults:
=begin pod
=head2 [g_param_] value_defaults

Checks whether I<value> contains the default value as specified in I<pspec>.

Returns: whether I<value> contains the canonical default for this I<pspec>

  method g_param_value_defaults ( N-GParamSpec $pspec, N-GObject $value --> Int  )

=item N-GParamSpec $pspec; a valid I<N-GParamSpec>
=item N-GObject $value; a I<GValue> of correct type for I<pspec>

=end pod

sub g_param_value_defaults ( N-GParamSpec $pspec, N-GObject $value )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_value_validate:
=begin pod
=head2 [g_param_] value_validate

Ensures that the contents of I<value> comply with the specifications
set out by I<pspec>. For example, a I<N-GParamSpecInt> might require
that integers stored in I<value> may not be smaller than -42 and not be
greater than +42. If I<value> contains an integer outside of this range,
it is modified accordingly, so the resulting value will fit into the
range -42 .. +42.

Returns: whether modifying I<value> was necessary to ensure validity

  method g_param_value_validate ( N-GParamSpec $pspec, N-GObject $value --> Int  )

=item N-GParamSpec $pspec; a valid I<N-GParamSpec>
=item N-GObject $value; a I<GValue> of correct type for I<pspec>

=end pod

sub g_param_value_validate ( N-GParamSpec $pspec, N-GObject $value )
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

  method g_param_value_convert ( N-GParamSpec $pspec, N-GObject $src_value, N-GObject $dest_value, Int $strict_validation --> Int  )

=item N-GParamSpec $pspec; a valid I<N-GParamSpec>
=item N-GObject $src_value; souce I<GValue>
=item N-GObject $dest_value; destination I<GValue> of correct type for I<pspec>
=item Int $strict_validation; C<1> requires I<dest_value> to conform to I<pspec> without modifications

=end pod

sub g_param_value_convert ( N-GParamSpec $pspec, N-GObject $src_value, N-GObject $dest_value, int32 $strict_validation )
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

  method g_param_values_cmp ( N-GParamSpec $pspec, N-GObject $value1, N-GObject $value2 --> Int  )

=item N-GParamSpec $pspec; a valid I<N-GParamSpec>
=item N-GObject $value1; a I<GValue> of correct type for I<pspec>
=item N-GObject $value2; a I<GValue> of correct type for I<pspec>

=end pod

sub g_param_values_cmp ( N-GParamSpec $pspec, N-GObject $value1, N-GObject $value2 )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_get_name:
=begin pod
=head2 [g_param_] spec_get_name

Get the name of a I<N-GParamSpec>.

The name is always an "interned" string (as per C<g_intern_string()>).
This allows for pointer-value comparisons.

Returns: the name of I<pspec>.

  method g_param_spec_get_name ( N-GParamSpec $pspec --> Str  )

=item N-GParamSpec $pspec; a valid I<N-GParamSpec>

=end pod

sub g_param_spec_get_name ( N-GParamSpec $pspec )
  returns Str
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_get_nick:
=begin pod
=head2 [g_param_] spec_get_nick

Get the nickname of a I<N-GParamSpec>.

Returns: the nickname of I<pspec>.

  method g_param_spec_get_nick ( N-GParamSpec $pspec --> Str  )

=item N-GParamSpec $pspec; a valid I<N-GParamSpec>

=end pod

sub g_param_spec_get_nick ( N-GParamSpec $pspec )
  returns Str
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_get_blurb:
=begin pod
=head2 [g_param_] spec_get_blurb

Get the short description of a I<N-GParamSpec>.

Returns: the short description of I<pspec>.

  method g_param_spec_get_blurb ( N-GParamSpec $pspec --> Str  )

=item N-GParamSpec $pspec; a valid I<N-GParamSpec>

=end pod

sub g_param_spec_get_blurb ( N-GParamSpec $pspec )
  returns Str
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_set_param:
=begin pod
=head2 g_value_set_param

Set the contents of a C<G_TYPE_PARAM> I<GValue> to I<param>.

  method g_value_set_param ( N-GObject $value, N-GParamSpec $param )

=item N-GObject $value; a valid I<GValue> of type C<G_TYPE_PARAM>
=item N-GParamSpec $param; (nullable): the I<N-GParamSpec> to be set

=end pod

sub g_value_set_param ( N-GObject $value, N-GParamSpec $param )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_get_param:
=begin pod
=head2 g_value_get_param

Get the contents of a C<G_TYPE_PARAM> I<GValue>.

Returns: (transfer none): I<N-GParamSpec> content of I<value>

  method g_value_get_param ( N-GObject $value --> N-GParamSpec  )

=item N-GObject $value; a valid I<GValue> whose type is derived from C<G_TYPE_PARAM>

=end pod

sub g_value_get_param ( N-GObject $value )
  returns N-GParamSpec
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_dup_param:
=begin pod
=head2 g_value_dup_param

Get the contents of a C<G_TYPE_PARAM> I<GValue>, increasing its
reference count.

Returns: I<N-GParamSpec> content of I<value>, should be unreferenced when
no longer needed.

  method g_value_dup_param ( N-GObject $value --> N-GParamSpec  )

=item N-GObject $value; a valid I<GValue> whose type is derived from C<G_TYPE_PARAM>

=end pod

sub g_value_dup_param ( N-GObject $value )
  returns N-GParamSpec
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

  method g_value_take_param ( N-GObject $value, N-GParamSpec $param )

=item N-GObject $value; a valid I<GValue> of type C<G_TYPE_PARAM>
=item N-GParamSpec $param; (nullable): the I<N-GParamSpec> to be set

=end pod

sub g_value_take_param ( N-GObject $value, N-GParamSpec $param )
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

  method g_param_spec_get_default_value ( N-GParamSpec $pspec --> N-GObject  )

=item N-GParamSpec $pspec; a I<N-GParamSpec>

=end pod

sub g_param_spec_get_default_value ( N-GParamSpec $pspec )
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

  method g_param_spec_get_name_quark ( N-GParamSpec $pspec --> N-GObject  )

=item N-GParamSpec $pspec; a I<N-GParamSpec>

=end pod

sub g_param_spec_get_name_quark ( N-GParamSpec $pspec )
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
the I<N-GParamSpecTypeInfo> structure pointed to by I<info> to manage the
I<N-GParamSpec> type and its instances.

Returns: The new type identifier.

  method g_param_type_register_static ( Str $name, N-GParamSpecTypeInfo $pspec_info --> N-GObject  )

=item Str $name; 0-terminated string used as the name of the new I<N-GParamSpec> type.
=item N-GParamSpecTypeInfo $pspec_info; The I<N-GParamSpecTypeInfo> for this I<N-GParamSpec> type.

=end pod

sub g_param_type_register_static ( Str $name, N-GParamSpecTypeInfo $pspec_info )
  returns N-GObject
  is native(&gobject-lib)
  { * }
}}

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_internal:
=begin pod
=head2 [g_param_] spec_internal

Creates a new I<N-GParamSpec> instance.

A property name consists of segments consisting of ASCII letters and
digits, separated by either the '-' or '_' character. The first
character of a property name must be a letter. Names which violate these
rules lead to undefined behaviour.

When creating and looking up a I<N-GParamSpec>, either separator can be
used, but they cannot be mixed. Using '-' is considerably more
efficient and in fact required when using property names as detail
strings for signals.

Beyond the name, I<N-GParamSpecs> have two more descriptive
strings associated with them, the I<nick>, which should be suitable
for use as a label for the property in a property editor, and the
I<blurb>, which should be a somewhat longer description, suitable for
e.g. a tooltip. The I<nick> and I<blurb> should ideally be localized.

Returns: (type GObject.ParamSpec): a newly allocated I<N-GParamSpec> instance

  method g_param_spec_internal ( N-GObject $param_type, Str $name, Str $nick, Str $blurb, GParamFlags $flags --> Pointer  )

=item N-GObject $param_type; the I<GType> for the property; must be derived from I<G_TYPE_PARAM>
=item Str $name; the canonical name of the property
=item Str $nick; the nickname of the property
=item Str $blurb; a short description of the property
=item GParamFlags $flags; a combination of I<GParamFlags>

=end pod

sub g_param_spec_internal ( N-GObject $param_type, Str $name, Str $nick, Str $blurb, int32 $flags )
  returns Pointer
  is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
#TM:0:g_param_spec_pool_new:
=begin pod
=head2 [g_param_] spec_pool_new

Creates a new I<N-GParamSpecPool>.

If I<type_prefixing> is C<1>, lookups in the newly created pool will
allow to specify the owner as a colon-separated prefix of the
property name, like "I<Gnome::Gtk3::Container>:border-width". This feature is
deprecated, so you should always set I<type_prefixing> to C<0>.

Returns: (transfer none): a newly allocated I<N-GParamSpecPool>.

  method g_param_spec_pool_new ( Int $type_prefixing --> N-GParamSpecPool  )

=item Int $type_prefixing; Whether the pool will support type-prefixed property names.

=end pod

sub g_param_spec_pool_new ( int32 $type_prefixing )
  returns N-GParamSpecPool
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_pool_insert:
=begin pod
=head2 [g_param_] spec_pool_insert

Inserts a I<N-GParamSpec> in the pool.

  method g_param_spec_pool_insert ( N-GParamSpecPool $pool, N-GParamSpec $pspec, N-GObject $owner_type )

=item N-GParamSpecPool $pool; a I<N-GParamSpecPool>.
=item N-GParamSpec $pspec; the I<N-GParamSpec> to insert
=item N-GObject $owner_type; a I<GType> identifying the owner of I<pspec>

=end pod

sub g_param_spec_pool_insert ( N-GParamSpecPool $pool, N-GParamSpec $pspec, N-GObject $owner_type )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_pool_remove:
=begin pod
=head2 [g_param_] spec_pool_remove

Removes a I<N-GParamSpec> from the pool.

  method g_param_spec_pool_remove ( N-GParamSpecPool $pool, N-GParamSpec $pspec )

=item N-GParamSpecPool $pool; a I<N-GParamSpecPool>
=item N-GParamSpec $pspec; the I<N-GParamSpec> to remove

=end pod

sub g_param_spec_pool_remove ( N-GParamSpecPool $pool, N-GParamSpec $pspec )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_pool_lookup:
=begin pod
=head2 [g_param_] spec_pool_lookup

Looks up a I<N-GParamSpec> in the pool.

Returns: (transfer none): The found I<N-GParamSpec>, or C<Any> if no
matching I<N-GParamSpec> was found.

  method g_param_spec_pool_lookup ( N-GParamSpecPool $pool, Str $param_name, N-GObject $owner_type, Int $walk_ancestors --> N-GParamSpec  )

=item N-GParamSpecPool $pool; a I<N-GParamSpecPool>
=item Str $param_name; the name to look for
=item N-GObject $owner_type; the owner to look for
=item Int $walk_ancestors; If C<1>, also try to find a I<N-GParamSpec> with I<param_name> owned by an ancestor of I<owner_type>.

=end pod

sub g_param_spec_pool_lookup ( N-GParamSpecPool $pool, Str $param_name, N-GObject $owner_type, int32 $walk_ancestors )
  returns N-GParamSpec
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_pool_list_owned:
=begin pod
=head2 [g_param_] spec_pool_list_owned

Gets an I<GList> of all I<N-GParamSpecs> owned by I<owner_type> in
the pool.

Returns: (transfer container) (element-type GObject.ParamSpec): a
I<GList> of all I<N-GParamSpecs> owned by I<owner_type> in
the poolI<N-GParamSpecs>.

  method g_param_spec_pool_list_owned ( N-GParamSpecPool $pool, N-GObject $owner_type --> N-GList  )

=item N-GParamSpecPool $pool; a I<N-GParamSpecPool>
=item N-GObject $owner_type; the owner to look for

=end pod

sub g_param_spec_pool_list_owned ( N-GParamSpecPool $pool, N-GObject $owner_type )
  returns N-GList
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_param_spec_pool_list:
=begin pod
=head2 [g_param_] spec_pool_list

Gets an array of all I<N-GParamSpecs> owned by I<owner_type> in
the pool.

Returns: (array length=n_pspecs_p) (transfer container): a newly
allocated array containing pointers to all I<N-GParamSpecs>
owned by I<owner_type> in the pool

  method g_param_spec_pool_list ( N-GParamSpecPool $pool, N-GObject $owner_type, UInt $n_pspecs_p --> N-GParamSpec  )

=item N-GParamSpecPool $pool; a I<N-GParamSpecPool>
=item N-GObject $owner_type; the owner to look for
=item UInt $n_pspecs_p; (out): return location for the length of the returned array

=end pod

sub g_param_spec_pool_list ( N-GParamSpecPool $pool, N-GObject $owner_type, uint32 $n_pspecs_p )
  returns N-GParamSpec
  is native(&gobject-lib)
  { * }
}}
#-------------------------------------------------------------------------------
=begin pod
=begin comment

=head1 Not yet implemented methods

=head3 method g_param_type_register_static ( ... )
=head3 method g_param_spec_set_qdata_full ( ... )
=head3 method g_param_spec_pool_new ( ... )
=head3 method g_param_spec_pool_insert ( ... )
=head3 method g_param_spec_pool_remove ( ... )
=head3 method g_param_spec_pool_lookup ( ... )
=head3 method g_param_spec_pool_list_owned ( ... )
=head3 method g_param_spec_pool_list ( ... )
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
