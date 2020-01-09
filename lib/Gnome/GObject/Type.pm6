#TL:0:Gnome::GObject::Type:

use v6;
#-------------------------------------------------------------------------------
=begin pod

=TITLE Gnome::GObject::Type

=SUBTITLE The GLib Runtime type identification and management system

I<B<Note: The methods described here are mostly used internally and is not interesting for the normal Perl6 user.>>

=head1 Description

The GType API is the foundation of the GObject system. It provides the facilities for registering and managing all fundamental data types, user-defined object and interface types.

For type creation and registration purposes, all types fall into one of two categories: static or dynamic. Static types are never loaded or unloaded at run-time as dynamic types may be.

=begin comment
Static types are created with C<g_type_register_static()> that gets type specific information passed in via a I<GTypeInfo> structure.

Dynamic types are created with C<g_type_register_dynamic()> which takes a I<GTypePlugin> structure instead. The remaining type information (the I<GTypeInfo> structure) is retrieved during runtime through I<GTypePlugin> and the g_type_plugin_*() API.

These registration functions are usually called only once from a function whose only purpose is to return the type identifier for a specific class. Once the type (or class or interface) is registered, it may be instantiated, inherited, or implemented depending on exactly what sort of type it is.

There is also a third registration function for registering fundamental types called C<g_type_register_fundamental()> which requires both a I<GTypeInfo> structure and a I<GTypeFundamentalInfo> structure but it is seldom used since most fundamental types are predefined rather than user-defined.

Type instance and class structs are limited to a total of 64 KiB, including all parent types. Similarly, type instances' private data (as created by C<G_ADD_PRIVATE()>) are limited to a total of 64 KiB. If a type instance needs a large static buffer, allocate it separately (typically by using I<GArray> or I<GPtrArray>) and put a pointer to the buffer in the structure.
=end comment

As mentioned in the [GType conventions](https://developer.gnome.org/gobject/stable/gtype-conventions.html), type names must be at least three characters long. There is no upper length limit. The first character must be a letter (a–z or A–Z) or an underscore (‘_’). Subsequent characters can be letters, numbers or any of ‘-_+’.

=head1 Synopsis
=head2 Declaration

  unit class Gnome::GObject::Type;

=comment '=head2 Example'

=end pod
#-------------------------------------------------------------------------------
use NativeCall;

use Gnome::N::X;
use Gnome::N::NativeLib;
use Gnome::N::N-GObject;
#use Gnome::GObject::Value;

#-------------------------------------------------------------------------------
# See /usr/include/glib-2.0/gtypes.h
# https://developer.gnome.org/gobject/stable/gobject-Type-Information.html
# https://developer.gnome.org/glib/stable/glib-Basic-Types.html
unit class Gnome::GObject::Type:auth<github:MARTIMM>;

#-------------------------------------------------------------------------------
=begin pod
=head2 class N-GTypeInstance

An opaque structure used as the base of all type instances.

=end pod

#TT:0:N-GTypeInstance:
class N-GTypeInstance
  is repr('CPointer')
  is export
  { }

#-------------------------------------------------------------------------------
=begin pod
=head2 class N-GTypeInterface

An opaque structure used as the base of all interface types.

=end pod

#TT:0:N-GTypeInterface:
class N-GTypeInterface
  is repr('CPointer')
  is export
  { }

#-------------------------------------------------------------------------------
=begin pod
=head2 class N-GTypeClass

An opaque structure used as the base of all type instances.

=end pod

#TT:0::N-GTypeClass
class N-GTypeClass
  is repr('CPointer')
  is export
  { }

#-------------------------------------------------------------------------------
=begin pod
=head2 class N-GTypeQuery

A structure holding information for a specific type. It is filled in by the C<g_type_query()> function.

=item int32 $.type: the B<N-GType> value of the type.
=item Str $.type_name: the name of the type.
=item UInt $.class_size: the size of the class structure.
=item UInt $.instance_size: the size of the instance structure.

=end pod

#TT:0:N-GTypeQuery:
class N-GTypeQuery is export is repr('CStruct') {
  has int32 $.type;
  has str $.type_name;
  has uint32 $.class_size;
  has uint32 $.instance_size;
}

#-------------------------------------------------------------------------------
=begin pod
=head2 class N-GTypeInfo

This structure is used to provide the type system with the information required to initialize and destruct (finalize) a type's class and its instances.

The initialized structure is passed to the C<g_type_register_static()> function (or is copied into the provided I<N-GTypeInfo> structure in the C<g_type_plugin_complete_type_info()>). The type system will perform a deep copy of this structure, so its memory does not need to be persistent across invocation of C<g_type_register_static()>.

=item UInt $.class_size: Size of the class structure (required for interface, classed and instantiatable types)
=item GBaseInitFunc $.base_init: Location of the base initialization function (optional)
=item GBaseFinalizeFunc $.base_finalize: Location of the base finalization function (optional)
=item GClassInitFunc $.class_init: Location of the class initialization function for classed and instantiatable types. Location of the default vtable  inititalization function for interface types. (optional) This function  is used both to fill in virtual functions in the class or default vtable,  and to do type-specific setup such as registering signals and object properties.
=item GClassFinalizeFunc $.class_finalize: Location of the class finalization function for classed and instantiatable types. Location of the default vtable finalization function for interface types. (optional)
=item Pointer $.class_data: User-supplied data passed to the class init/finalize functions
=item UInt $.instance_size: Size of the instance (object) structure (required for instantiatable types only)
=item UInt $.n_preallocs: Prior to GLib 2.10, it specified the number of pre-allocated (cached) instances to reserve memory for (0 indicates no caching). Since GLib 2.10, it is ignored, since instances are allocated with the [slice allocator][glib-Memory-Slices] now.
=item GInstanceInitFunc $.instance_init: Location of the instance initialization function (optional, for instantiatable types only)
=item int32 $.value_table: A I<N-GTypeValueTable> function table for generic handling of GValues of this type (usually only useful for fundamental types)


=end pod

#TT:0:N-GTypeInfo:
class N-GTypeInfo is export is repr('CStruct') {
  has uint16 $.class_size;
  has Pointer $.base_init;      #has GBaseInitFunc $.base_init;
  has Pointer $.base_finalize;  #has GBaseFinalizeFunc $.base_finalize;
  has Pointer $.class_init;     #has GClassInitFunc $.class_init;
  has Pointer $.class_finalize; #has GClassFinalizeFunc $.class_finalize;
  has Pointer $.class_data;
  has uint16 $.instance_size;
  has uint16 $.n_preallocs;
  has Pointer $.instance_init;  #has GInstanceInitFunc $.instance_init;
  has int32 $.value_table;
}

#-------------------------------------------------------------------------------
=begin pod
=head2 class N-GTypeFundamentalInfo

A structure that provides information to the type system which is used specifically for managing fundamental types.

=item int32 $.type_flags: I<N-GTypeFundamentalFlags> describing the characteristics of the fundamental type

=end pod

#TT:0:N-GTypeFundamentalInfo:
class N-GTypeFundamentalInfo is export is repr('CStruct') {
  has int32 $.type_flags;
}

#-------------------------------------------------------------------------------
=begin pod
=head2 class N-GInterfaceInfo

A structure that provides information to the type system which is used specifically for managing interface types.

=item GInterfaceInitFunc $.interface_init: location of the interface initialization function
=item GInterfaceFinalizeFunc $.interface_finalize: location of the interface finalization function
=item Pointer $.interface_data: user-supplied data passed to the interface init/finalize functions

=end pod

#TT:0:N-GInterfaceInfo:
class N-GInterfaceInfo is export is repr('CStruct') {
  has Pointer $.interface_init;     #has GInterfaceInitFunc $.interface_init;
  has Pointer $.interface_finalize; #has GInterfaceFinalizeFunc $.interface_finalize;
  has Pointer $.interface_data;
}

#`{{
#-------------------------------------------------------------------------------
=begin pod
=head2 class N-GTypeValueTable

The I<GTypeValueTable> provides the functions required by the I<GValue>
implementation, to serve as a container for values of a type.

=item ___value_init: Default initialize I<values> contents by poking values directly into the value->data array. The data array of the I<GValue> passed into this function was zero-filled with `C<memset()>`, so no care has to be taken to free any old contents. E.g. for the implementation of a string value that may never be C<Any>, the implementation might look like: |[<!-- language="C" --> value->data[0].v_pointer = g_strdup (""); ]|
=item ___value_free: Free any old contents that might be left in the data array of the passed in I<value>. No resources may remain allocated through the I<GValue> contents after this function returns. E.g. for our above string type: |[<!-- language="C" --> // only free strings without a specific flag for static storage if (!(value->data[1].v_uint & G_VALUE_NOCOPY_CONTENTS)) g_free (value->data[0].v_pointer); ]|
=item ___value_copy: I<dest_value> is a I<GValue> with zero-filled data section and I<src_value> is a properly setup I<GValue> of same or derived type. The purpose of this function is to copy the contents of I<src_value> into I<dest_value> in a way, that even after I<src_value> has been freed, the contents of I<dest_value> remain valid. String type example: |[<!-- language="C" --> dest_value->data[0].v_pointer = g_strdup (src_value->data[0].v_pointer); ]|
=item ___value_peek_pointer: If the value contents fit into a pointer, such as objects or strings, return this pointer, so the caller can peek at the current contents. To extend on our above string example: |[<!-- language="C" --> return value->data[0].v_pointer; ]|
=item Str $.collect_format: A string format describing how to collect the contents of this value bit-by-bit. Each character in the format represents an argument to be collected, and the characters themselves indicate the type of the argument. Currently supported arguments are: - 'i' - Integers. passed as collect_values[].v_int. - 'l' - Longs. passed as collect_values[].v_long. - 'd' - Doubles. passed as collect_values[].v_double. - 'p' - Pointers. passed as collect_values[].v_pointer. It should be noted that for variable argument list construction, ANSI C promotes every type smaller than an integer to an int, and floats to doubles. So for collection of short int or char, 'i' needs to be used, and for collection of floats 'd'.
=item ___collect_value: The C<collect_value()> function is responsible for converting the values collected from a variable argument list into contents suitable for storage in a GValue. This function should setup I<value> similar to C<value_init()>; e.g. for a string value that does not allow C<Any> pointers, it needs to either spew an error, or do an implicit conversion by storing an empty string. The I<value> passed in to this function has a zero-filled data array, so just like for C<value_init()> it is guaranteed to not contain any old contents that might need freeing. I<n_collect_values> is exactly the string length of I<collect_format>, and I<collect_values> is an array of unions I<GTypeCValue> with length I<n_collect_values>, containing the collected values according to I<collect_format>. I<collect_flags> is an argument provided as a hint by the caller. It may contain the flag C<G_VALUE_NOCOPY_CONTENTS> indicating, that the collected value contents may be considered "static" for the duration of the I<value> lifetime. Thus an extra copy of the contents stored in I<collect_values> is not required for assignment to I<value>. For our above string example, we continue with: |[<!-- language="C" --> if (!collect_values[0].v_pointer) value->data[0].v_pointer = g_strdup (""); else if (collect_flags & G_VALUE_NOCOPY_CONTENTS) { value->data[0].v_pointer = collect_values[0].v_pointer; // keep a flag for the C<value_free()> implementation to not free this string value->data[1].v_uint = G_VALUE_NOCOPY_CONTENTS; } else value->data[0].v_pointer = g_strdup (collect_values[0].v_pointer); return NULL; ]| It should be noted, that it is generally a bad idea to follow the I<G_VALUE_NOCOPY_CONTENTS> hint for reference counted types. Due to reentrancy requirements and reference count assertions performed by the signal emission code, reference counts should always be incremented for reference counted contents stored in the value->data array.  To deviate from our string example for a moment, and taking a look at an exemplary implementation for C<collect_value()> of I<GObject>: |[<!-- language="C" --> if (collect_values[0].v_pointer) { GObject *object = G_OBJECT (collect_values[0].v_pointer); // never honour G_VALUE_NOCOPY_CONTENTS for ref-counted types value->data[0].v_pointer = g_object_ref (object); return NULL; } else return g_strdup_printf ("Object passed as invalid NULL pointer"); } ]| The reference count for valid objects is always incremented, regardless of I<collect_flags>. For invalid objects, the example returns a newly allocated string without altering I<value>. Upon success, C<collect_value()> needs to return C<Any>. If, however, an error condition occurred, C<collect_value()> may spew an error by returning a newly allocated non-C<Any> string, giving a suitable description of the error condition. The calling code makes no assumptions about the I<value> contents being valid upon error returns, I<value> is simply thrown away without further freeing. As such, it is a good idea to not allocate I<GValue> contents, prior to returning an error, however, C<collect_values()> is not obliged to return a correctly setup I<value> for error returns, simply because any non-C<Any> return is considered a fatal condition so further program behaviour is undefined.
=item Str $.lcopy_format: Format description of the arguments to collect for I<lcopy_value>, analogous to I<collect_format>. Usually, I<lcopy_format> string consists only of 'p's to provide C<lcopy_value()> with pointers to storage locations.
=item ___lcopy_value: This function is responsible for storing the I<value> contents into arguments passed through a variable argument list which got collected into I<collect_values> according to I<lcopy_format>. I<n_collect_values> equals the string length of I<lcopy_format>, and I<collect_flags> may contain C<G_VALUE_NOCOPY_CONTENTS>. In contrast to C<collect_value()>, C<lcopy_value()> is obliged to always properly support C<G_VALUE_NOCOPY_CONTENTS>. Similar to C<collect_value()> the function may prematurely abort by returning a newly allocated string describing an error condition. To complete the string example: |[<!-- language="C" --> gchar **string_p = collect_values[0].v_pointer; if (!string_p) return g_strdup_printf ("string location passed as NULL"); if (collect_flags & G_VALUE_NOCOPY_CONTENTS) *string_p = value->data[0].v_pointer; else *string_p = g_strdup (value->data[0].v_pointer); ]| And an illustrative version of C<lcopy_value()> for reference-counted types: |[<!-- language="C" --> GObject **object_p = collect_values[0].v_pointer; if (!object_p) return g_strdup_printf ("object location passed as NULL"); if (!value->data[0].v_pointer) *object_p = NULL; else if (collect_flags & G_VALUE_NOCOPY_CONTENTS) // always honour *object_p = value->data[0].v_pointer; else *object_p = g_object_ref (value->data[0].v_pointer); return NULL; ]|

=end pod

#TT:0:N-GTypeValueTable:
class N-GTypeValueTable is export is repr('CStruct') {
  has voi $.d     (*value_init)         (GValue       *value);
  has voi $.d     (*value_free)         (GValue       *value);
  has N-GObject $.dest_value);
  has gpointe $.r (*value_peek_pointer) (const GValue *value);
  has str $.collect_format;
  has uint32 $.collect_flags);
  has str $.lcopy_format;
  has uint32 $.collect_flags);
}
}}

#-------------------------------------------------------------------------------
#define	G_TYPE_FUNDAMENTAL_SHIFT (2)
constant G_TYPE_FUNDAMENTAL_SHIFT = 2;

#define	G_TYPE_FUNDAMENTAL_MAX		(255 << G_TYPE_FUNDAMENTAL_SHIFT)
constant G_TYPE_MAKE_FUNDAMENTAL_MAX is export =
         255 +< G_TYPE_FUNDAMENTAL_SHIFT;

#define G_TYPE_INVALID G_TYPE_MAKE_FUNDAMENTAL (0)
constant G_TYPE_INVALID is export = 0 +< G_TYPE_FUNDAMENTAL_SHIFT;

#define G_TYPE_NONE G_TYPE_MAKE_FUNDAMENTAL (1)
constant G_TYPE_NONE is export = 1 +< G_TYPE_FUNDAMENTAL_SHIFT;

#define G_TYPE_INTERFACE G_TYPE_MAKE_FUNDAMENTAL (2)
constant G_TYPE_INTERFACE is export = 2 +< G_TYPE_FUNDAMENTAL_SHIFT;

#define G_TYPE_CHAR G_TYPE_MAKE_FUNDAMENTAL (3)
constant G_TYPE_CHAR is export = 3 +< G_TYPE_FUNDAMENTAL_SHIFT;

#define G_TYPE_UCHAR G_TYPE_MAKE_FUNDAMENTAL (4)
constant G_TYPE_UCHAR is export = 4 +< G_TYPE_FUNDAMENTAL_SHIFT;

#define G_TYPE_BOOLEAN G_TYPE_MAKE_FUNDAMENTAL (5)
constant G_TYPE_BOOLEAN is export = 5 +< G_TYPE_FUNDAMENTAL_SHIFT;

#define G_TYPE_INT G_TYPE_MAKE_FUNDAMENTAL (6)
constant G_TYPE_INT is export = 6 +< G_TYPE_FUNDAMENTAL_SHIFT;

#define G_TYPE_UINT G_TYPE_MAKE_FUNDAMENTAL (7)
constant G_TYPE_UINT is export = 7 +< G_TYPE_FUNDAMENTAL_SHIFT;

#define G_TYPE_LONG G_TYPE_MAKE_FUNDAMENTAL (8)
constant G_TYPE_LONG is export = 8 +< G_TYPE_FUNDAMENTAL_SHIFT;

#define G_TYPE_ULONG G_TYPE_MAKE_FUNDAMENTAL (9)
constant G_TYPE_ULONG is export = 9 +< G_TYPE_FUNDAMENTAL_SHIFT;

#define G_TYPE_INT64 G_TYPE_MAKE_FUNDAMENTAL (10)
constant G_TYPE_INT64 is export = 10 +< G_TYPE_FUNDAMENTAL_SHIFT;

#define G_TYPE_UINT64 G_TYPE_MAKE_FUNDAMENTAL (11)
constant G_TYPE_UINT64 is export = 11 +< G_TYPE_FUNDAMENTAL_SHIFT;

#define G_TYPE_ENUM G_TYPE_MAKE_FUNDAMENTAL (12)
constant G_TYPE_ENUM is export = 12 +< G_TYPE_FUNDAMENTAL_SHIFT;

#define G_TYPE_FLAGS G_TYPE_MAKE_FUNDAMENTAL (13)
constant G_TYPE_FLAGS is export = 13 +< G_TYPE_FUNDAMENTAL_SHIFT;

#define G_TYPE_FLOAT G_TYPE_MAKE_FUNDAMENTAL (14)
constant G_TYPE_FLOAT is export = 14 +< G_TYPE_FUNDAMENTAL_SHIFT;

#define G_TYPE_DOUBLE G_TYPE_MAKE_FUNDAMENTAL (15)
constant G_TYPE_DOUBLE is export = 15 +< G_TYPE_FUNDAMENTAL_SHIFT;

#define G_TYPE_STRING G_TYPE_MAKE_FUNDAMENTAL (16)
constant G_TYPE_STRING is export = 16 +< G_TYPE_FUNDAMENTAL_SHIFT;

#define G_TYPE_POINTER G_TYPE_MAKE_FUNDAMENTAL (17)
constant G_TYPE_POINTER is export = 17 +< G_TYPE_FUNDAMENTAL_SHIFT;

#define G_TYPE_BOXED G_TYPE_MAKE_FUNDAMENTAL (18)
constant G_TYPE_BOXED is export = 18 +< G_TYPE_FUNDAMENTAL_SHIFT;

#define G_TYPE_PARAM G_TYPE_MAKE_FUNDAMENTAL (19)
constant G_TYPE_PARAM is export = 19 +< G_TYPE_FUNDAMENTAL_SHIFT;

#define G_TYPE_OBJECT G_TYPE_MAKE_FUNDAMENTAL (20)
constant G_TYPE_OBJECT is export = 20 +< G_TYPE_FUNDAMENTAL_SHIFT;

#define	G_TYPE_VARIANT G_TYPE_MAKE_FUNDAMENTAL (21)
constant G_TYPE_VARIANT is export = 21 +< G_TYPE_FUNDAMENTAL_SHIFT;

#-------------------------------------------------------------------------------
class N-TypesMap is repr('CUnion') is export {
  has int8 $.int8;          # G_TYPE_CHAR
  has uint8 $.uint8;        # G_TYPE_UCHAR
  has int32 $.bool;         # G_TYPE_BOOLEAN
  has int32 $.int32;        # G_TYPE_INT
  has uint32 $.uint32;      # G_TYPE_UINT
  has int64 $.long;         # G_TYPE_LONG
  has uint64 $.ulong;       # G_TYPE_ULONG
  has int64 $.int64;        # G_TYPE_INT64
  has uint64 $.uint64;      # G_TYPE_UINT64
  has int32 $.enum;         # G_TYPE_ENUM
  has int32 $.flags;        # G_TYPE_FLAGS
  has num32 $.float;        # G_TYPE_FLOAT
  has num64 $.double;       # G_TYPE_DOUBLE
  has str $.string;         # G_TYPE_STRING
  has Pointer $.pointer;    # G_TYPE_POINTER
  has Pointer $.boxed;      # G_TYPE_BOXED
  has Pointer $.param;      # G_TYPE_PARAM
  has N-GObject $.object;   # G_TYPE_OBJECT
  has Pointer $.variant;    # G_TYPE_VARIANT
}

#-------------------------------------------------------------------------------
#my Bool $signals-added = False;
#-------------------------------------------------------------------------------
=begin pod
=head1 Methods
=head2 new
=head3 multi method new ( )

Create a new plain object. In contrast with other objects, this class doesn't wrap a native object, so therefore no named arguments to specify something

=end pod

#TM:0:new():
submethod BUILD ( *%options ) {

  # add signal info in the form of group<signal-name>.
  # groups are e.g. signal, event, nativeobject etc
  #$signals-added = self.add-signal-types( $?CLASS.^name,
  #  # ... :type<signame>
  #) unless $signals-added;

  # prevent creating wrong widgets
  #return unless self.^name eq 'Gnome::GObject::Type';

  if %options.keys.elems {
    die X::Gnome.new(
      :message('Unsupported options for ' ~ self.^name ~
               ': ' ~ %options.keys.join(', ') ~
               ', cannot have any arguments'
              )
    );
  }

  # only after creating the widget, the gtype is known
  #self.set-class-info('GType');
}

#-------------------------------------------------------------------------------
method FALLBACK ( $native-sub is copy, |c ) {

  CATCH { test-catch-exception( $_, $native-sub); }

  $native-sub ~~ s:g/ '-' /_/ if $native-sub.index('-');
  die X::Gnome.new(:message(
    "Native sub name '$native-sub' made too short. Keep at least one '-' or '_'."
    )
  ) unless $native-sub.index('_') >= 0;

  my Callable $s;
  try { $s = &::("g_type_$native-sub"); };
  try { $s = &::("g_$native-sub") } unless ?$s;
  try { $s = &::($native-sub); } if !$s and $native-sub ~~ m/^ 'g_' /;

  $s(|c)
}

#-------------------------------------------------------------------------------
# conveniance method to convert a type to a perl6 parameter
#TM:2:get-parameter:Gnome::Gtk3::ListStore
method get-parameter( Int $type, :$otype --> Parameter ) {

  my Parameter $p;
  given $type {
    when G_TYPE_CHAR    { $p .= new(type => int8); }
    when G_TYPE_UCHAR   { $p .= new(type => uint8); }
    when G_TYPE_BOOLEAN { $p .= new(type => int32); }
    when G_TYPE_INT     { $p .= new(type => int32); }
    when G_TYPE_UINT    { $p .= new(type => uint32); }
    when G_TYPE_LONG    { $p .= new(type => int64); }
    when G_TYPE_ULONG   { $p .= new(type => uint64); }
    when G_TYPE_INT64   { $p .= new(type => int64); }
    when G_TYPE_UINT64  { $p .= new(type => uint64); }
    when G_TYPE_ENUM    { $p .= new(type => int32); }
    when G_TYPE_FLAGS   { $p .= new(type => int32); }
    when G_TYPE_FLOAT   { $p .= new(type => num32); }
    when G_TYPE_DOUBLE  { $p .= new(type => num64); }
    when G_TYPE_STRING  { $p .= new(type => str); }

#    when G_TYPE_OBJECT | G_TYPE_BOXED {
#      die X::Gnome.new(:message('Object in named argument :o not defined'))
#          unless ?$otype;
#      $p .= new(type => $otype.get-class-gtype);
#      $p .= new(:$type);
#    }

#    when G_TYPE_POINTER { $p .= new(type => ); }
#    when G_TYPE_PARAM { $p .= new(type => ); }
#    when G_TYPE_VARIANT {$p .= new(type => ); }
#    when N-GObject {
#      $p .= new(type => G_TYPE_OBJECT);
#    }

    default {
      # if type is larger than the max of fundamental types (like G_TYPE_INT) it
      # is a type which is set when a GTK+ object is created. In Perl6 the
      # object type is stored in the class as $!gtk-class-gtype in
      # Gnome::GObject::Object and retrievable with .get-class-gtype()
      if $type > G_TYPE_MAKE_FUNDAMENTAL_MAX {
        $p .= new(:$type);
      }

      else { # ??
        $p .= new(type => $otype.get-class-gtype);
      }
    }
  }

  $p
}

#-------------------------------------------------------------------------------
#TM:1:g_type_name:
=begin pod
=head2 [g_] type_name

Get the unique name that is assigned to a type ID. Note that this function (like all other GType API) cannot cope with invalid type IDs. C<G_TYPE_INVALID> may be passed to this function, as may be any other validly registered type ID, but randomized type IDs should not be passed in and will most likely lead to a crash.

Returns: static type name or C<Any>

  method g_type_name ( UInt $type --> Str )

=end pod

sub g_type_name ( uint64 $type )
  returns Str
  is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
#TM:0:g_type_qname:
=begin pod
=head2 [g_] type_qname

Get the corresponding quark of the type IDs name.

Returns: the type names quark or 0

  method g_type_qname ( --> int32  )


=end pod

sub g_type_qname ( int32 $type )
  returns int32
  is native(&gobject-lib)
  { * }
}}

#-------------------------------------------------------------------------------
#TM:1:g_type_from_name:
=begin pod
=head2 [[g_] type_] from_name

Lookup the type ID from a given type name, returning 0 if no type has been registered under this name (this is the preferred method to find out by name whether a specific type has been registered yet).

Returns: corresponding type ID or 0

  method g_type_from_name ( Str $name --> UInt )

=item Str $name; type name to lookup

=end pod

sub g_type_from_name ( Str $name )
  returns uint64
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_type_parent:
=begin pod
=head2 [g_] type_parent

Return the direct parent type of the passed in type. If the passed
in type has no parent, i.e. is a fundamental type, 0 is returned.

Returns: the parent type

  method g_type_parent ( UInt --> UInt )

=end pod

sub g_type_parent ( uint64 $type )
  returns uint64
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_type_depth:
=begin pod
=head2 [g_] type_depth

Returns the length of the ancestry of the passed in type. This
includes the type itself, so that e.g. a fundamental type has depth 1.

Returns: the depth of I<type>

  method g_type_depth ( --> UInt  )


=end pod

sub g_type_depth ( uint64 $type )
  returns uint32
  is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
#TM:0:g_type_next_base:
=begin pod
=head2 [[g_] type_] next_base

Given a I<leaf_type> and a I<root_type> which is contained in its
anchestry, return the type that I<root_type> is the immediate parent
of. In other words, this function determines the type that is
derived directly from I<root_type> which is also a base class of
I<leaf_type>.  Given a root type and a leaf type, this function can
be used to determine the types and order in which the leaf type is
descended from the root type.

Returns: immediate child of I<root_type> and anchestor of I<leaf_type>

  method g_type_next_base ( int32 $root_type --> int32  )

=item int32 $root_type; immediate parent of the returned type

=end pod

sub g_type_next_base ( int32 $leaf_type, int32 $root_type )
  returns int32
  is native(&gobject-lib)
  { * }
}}

#-------------------------------------------------------------------------------
#TM:1:g_type_is_a:
=begin pod
=head2 [[g_] type_] is_a

If I<$is_a_type> is a derivable type, check whether I<$type> is a descendant of I<$is_a_type>. If I<$is_a_type> is an interface, check whether I<$type> conforms to it.

Returns: C<1> if I<$type> is a I<$is_a_type>.

  method g_type_is_a ( UInt $type, UInt $is_a_type --> Int  )

=item UInt $is_a_type; possible anchestor of I<$type> or interface that I<$type> could conform to.

=end pod

sub g_type_is_a ( uint64 $type, uint64 $is_a_type )
  returns int32
  is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
#TM:0:g_type_class_ref:
=begin pod
=head2 [[g_] type_] class_ref

Increments the reference count of the class structure belonging to
I<type>. This function will demand-create the class if it doesn't
exist already.

Returns: (type GObject.TypeClass) (transfer none): the I<N-GTypeClass>
structure for the given type ID

  method g_type_class_ref ( --> Pointer  )


=end pod

sub g_type_class_ref ( int32 $type )
  returns Pointer
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_class_peek:
=begin pod
=head2 [[g_] type_] class_peek

This function is essentially the same as C<g_type_class_ref()>,
except that the classes reference count isn't incremented.
As a consequence, this function may return C<Any> if the class
of the type passed in does not currently exist (hasn't been
referenced before).

Returns: (type GObject.TypeClass) (transfer none): the I<N-GTypeClass>
structure for the given type ID or C<Any> if the class does not
currently exist

  method g_type_class_peek ( --> Pointer  )


=end pod

sub g_type_class_peek ( int32 $type )
  returns Pointer
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_class_peek_static:
=begin pod
=head2 [[g_] type_] class_peek_static

A more efficient version of C<g_type_class_peek()> which works only for
static types.

Returns: (type GObject.TypeClass) (transfer none): the I<N-GTypeClass>
structure for the given type ID or C<Any> if the class does not
currently exist or is dynamically loaded

Since: 2.4

  method g_type_class_peek_static ( --> Pointer  )


=end pod

sub g_type_class_peek_static ( int32 $type )
  returns Pointer
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_class_unref:
=begin pod
=head2 [[g_] type_] class_unref

Decrements the reference count of the class structure being passed in.
Once the last reference count of a class has been released, classes
may be finalized by the type system, so further dereferencing of a
class pointer after C<g_type_class_unref()> are invalid.

  method g_type_class_unref ( Pointer $g_class )

=item Pointer $g_class; (type GObject.TypeClass): a I<N-GTypeClass> structure to unref

=end pod

sub g_type_class_unref ( Pointer $g_class )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_class_peek_parent:
=begin pod
=head2 [[g_] type_] class_peek_parent

This is a convenience function often needed in class initializers.
It returns the class structure of the immediate parent type of the
class passed in.  Since derived classes hold a reference count on
their parent classes as long as they are instantiated, the returned
class will always exist.

This function is essentially equivalent to:
g_type_class_peek (g_type_parent (G_TYPE_FROM_CLASS (g_class)))

Returns: (type GObject.TypeClass) (transfer none): the parent class
of I<g_class>

  method g_type_class_peek_parent ( Pointer $g_class --> Pointer  )

=item Pointer $g_class; (type GObject.TypeClass): the I<N-GTypeClass> structure to retrieve the parent class for

=end pod

sub g_type_class_peek_parent ( Pointer $g_class )
  returns Pointer
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_interface_peek:
=begin pod
=head2 [[g_] type_] interface_peek

Returns the I<GTypeInterface> structure of an interface to which the
passed in class conforms.

Returns: (type GObject.TypeInterface) (transfer none): the I<GTypeInterface>
structure of I<iface_type> if implemented by I<instance_class>, C<Any>
otherwise

  method g_type_interface_peek ( Pointer $instance_class, int32 $iface_type --> Pointer  )

=item Pointer $instance_class; (type GObject.TypeClass): a I<N-GTypeClass> structure
=item int32 $iface_type; an interface ID which this class conforms to

=end pod

sub g_type_interface_peek ( Pointer $instance_class, int32 $iface_type )
  returns Pointer
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_interface_peek_parent:
=begin pod
=head2 [[g_] type_] interface_peek_parent

Returns the corresponding I<GTypeInterface> structure of the parent type
of the instance type to which I<g_iface> belongs. This is useful when
deriving the implementation of an interface from the parent type and
then possibly overriding some methods.

Returns: (transfer none) (type GObject.TypeInterface): the
corresponding I<GTypeInterface> structure of the parent type of the
instance type to which I<g_iface> belongs, or C<Any> if the parent
type doesn't conform to the interface

  method g_type_interface_peek_parent ( Pointer $g_iface --> Pointer  )

=item Pointer $g_iface; (type GObject.TypeInterface): a I<GTypeInterface> structure

=end pod

sub g_type_interface_peek_parent ( Pointer $g_iface )
  returns Pointer
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_default_interface_ref:
=begin pod
=head2 [[g_] type_] default_interface_ref

Increments the reference count for the interface type I<g_type>,
and returns the default interface vtable for the type.

If the type is not currently in use, then the default vtable
for the type will be created and initalized by calling
the base interface init and default vtable init functions for
the type (the I<base_init> and I<class_init> members of I<GTypeInfo>).
Calling C<g_type_default_interface_ref()> is useful when you
want to make sure that signals and properties for an interface
have been installed.

Since: 2.4

Returns: (type GObject.TypeInterface) (transfer none): the default
vtable for the interface; call C<g_type_default_interface_unref()>
when you are done using the interface.

  method g_type_default_interface_ref ( --> Pointer  )


=end pod

sub g_type_default_interface_ref ( int32 $g_type )
  returns Pointer
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_default_interface_peek:
=begin pod
=head2 [[g_] type_] default_interface_peek

If the interface type I<g_type> is currently in use, returns its
default interface vtable.

Since: 2.4

Returns: (type GObject.TypeInterface) (transfer none): the default
vtable for the interface, or C<Any> if the type is not currently
in use

  method g_type_default_interface_peek ( --> Pointer  )


=end pod

sub g_type_default_interface_peek ( int32 $g_type )
  returns Pointer
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_default_interface_unref:
=begin pod
=head2 [[g_] type_] default_interface_unref

Decrements the reference count for the type corresponding to the
interface default vtable I<g_iface>. If the type is dynamic, then
when no one is using the interface and all references have
been released, the finalize function for the interface's default
vtable (the I<class_finalize> member of I<GTypeInfo>) will be called.

Since: 2.4

  method g_type_default_interface_unref ( Pointer $g_iface )

=item Pointer $g_iface; (type GObject.TypeInterface): the default vtable structure for a interface, as returned by C<g_type_default_interface_ref()>

=end pod

sub g_type_default_interface_unref ( Pointer $g_iface )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_children:
=begin pod
=head2 [g_] type_children

Return a newly allocated and 0-terminated array of type IDs, listing
the child types of I<type>.

Returns: (array length=n_children) (transfer full): Newly allocated
and 0-terminated array of child types, free with C<g_free()>

  method g_type_children ( UInt $n_children --> int32  )

=item UInt $n_children; (out) (optional): location to store the length of the returned array, or C<Any>

=end pod

sub g_type_children ( int32 $type, uint32 $n_children )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_interfaces:
=begin pod
=head2 [g_] type_interfaces

Return a newly allocated and 0-terminated array of type IDs, listing
the interface types that I<type> conforms to.

Returns: (array length=n_interfaces) (transfer full): Newly allocated
and 0-terminated array of interface types, free with C<g_free()>

  method g_type_interfaces ( UInt $n_interfaces --> int32  )

=item UInt $n_interfaces; (out) (optional): location to store the length of the returned array, or C<Any>

=end pod

sub g_type_interfaces ( int32 $type, uint32 $n_interfaces )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_set_qdata:
=begin pod
=head2 [[g_] type_] set_qdata

Attaches arbitrary data to a type.

  method g_type_set_qdata ( int32 $quark, Pointer $data )

=item int32 $quark; a I<GQuark> id to identify the data
=item Pointer $data; the data

=end pod

sub g_type_set_qdata ( int32 $type, int32 $quark, Pointer $data )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_get_qdata:
=begin pod
=head2 [[g_] type_] get_qdata

Obtains data which has previously been attached to I<type>
with C<g_type_set_qdata()>.

Note that this does not take subtyping into account; data
attached to one type with C<g_type_set_qdata()> cannot
be retrieved from a subtype using C<g_type_get_qdata()>.

Returns: (transfer none): the data, or C<Any> if no data was found

  method g_type_get_qdata ( int32 $quark --> Pointer  )

=item int32 $quark; a I<GQuark> id to identify the data

=end pod

sub g_type_get_qdata ( int32 $type, int32 $quark )
  returns Pointer
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_query:
=begin pod
=head2 [g_] type_query

Queries the type system for information about a specific type.
This function will fill in a user-provided structure to hold
type-specific information. If an invalid I<GType> is passed in, the
I<type> member of the I<GTypeQuery> is 0. All members filled into the
I<GTypeQuery> structure should be considered constant and have to be
left untouched.

  method g_type_query ( int32 $query )

=item int32 $query; (out caller-allocates): a user provided structure that is filled in with constant values upon success

=end pod

sub g_type_query ( int32 $type, int32 $query )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_get_instance_count:
=begin pod
=head2 [[g_] type_] get_instance_count

Returns the number of instances allocated of the particular type;
this is only available if GLib is built with debugging support and
the instance_count debug flag is set (by setting the GOBJECT_DEBUG
variable to include instance-count).

Returns: the number of instances allocated of the given type;
if instance counts are not available, returns 0.

Since: 2.44

  method g_type_get_instance_count ( --> int32  )


=end pod

sub g_type_get_instance_count ( int32 $type )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_register_static:
=begin pod
=head2 [[g_] type_] register_static

Registers I<type_name> as the name of a new static type derived from
I<parent_type>. The type system uses the information contained in the
I<GTypeInfo> structure pointed to by I<info> to manage the type and its
instances (if not abstract). The value of I<flags> determines the nature
(e.g. abstract or not) of the type.

Returns: the new type identifier

  method g_type_register_static ( Str $type_name, int32 $info, int32 $flags --> int32  )

=item Str $type_name; 0-terminated string used as the name of the new type
=item int32 $info; I<GTypeInfo> structure for this type
=item int32 $flags; bitwise combination of I<GTypeFlags> values

=end pod

sub g_type_register_static ( int32 $parent_type, Str $type_name, int32 $info, int32 $flags )
  returns int32
  is native(&gobject-lib)
  { * }
}}
#`{{
#-------------------------------------------------------------------------------
#TM:0:g_type_register_static_simple:
=begin pod
=head2 [[g_] type_] register_static_simple

Registers I<type_name> as the name of a new static type derived from
I<parent_type>.  The value of I<flags> determines the nature (e.g.
abstract or not) of the type. It works by filling a I<GTypeInfo>
struct and calling C<g_type_register_static()>.

Since: 2.12

Returns: the new type identifier

  method g_type_register_static_simple ( Str $type_name, UInt $class_size, GClassInitFunc $class_init, UInt $instance_size, GInstanceInitFunc $instance_init, int32 $flags --> int32  )

=item Str $type_name; 0-terminated string used as the name of the new type
=item UInt $class_size; size of the class structure (see I<GTypeInfo>)
=item GClassInitFunc $class_init; location of the class initialization function (see I<GTypeInfo>)
=item UInt $instance_size; size of the instance structure (see I<GTypeInfo>)
=item GInstanceInitFunc $instance_init; location of the instance initialization function (see I<GTypeInfo>)
=item int32 $flags; bitwise combination of I<GTypeFlags> values

=end pod

sub g_type_register_static_simple ( int32 $parent_type, Str $type_name, uint32 $class_size, GClassInitFunc $class_init, uint32 $instance_size, GInstanceInitFunc $instance_init, int32 $flags )
  returns int32
  is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
#TM:0:g_type_register_dynamic:
=begin pod
=head2 [[g_] type_] register_dynamic

Registers I<type_name> as the name of a new dynamic type derived from
I<parent_type>.  The type system uses the information contained in the
I<GTypePlugin> structure pointed to by I<plugin> to manage the type and its
instances (if not abstract).  The value of I<flags> determines the nature
(e.g. abstract or not) of the type.

Returns: the new type identifier or I<G_TYPE_INVALID> if registration failed

  method g_type_register_dynamic ( Str $type_name, int32 $plugin, int32 $flags --> int32  )

=item Str $type_name; 0-terminated string used as the name of the new type
=item int32 $plugin; I<GTypePlugin> structure to retrieve the I<GTypeInfo> from
=item int32 $flags; bitwise combination of I<GTypeFlags> values

=end pod

sub g_type_register_dynamic ( int32 $parent_type, Str $type_name, int32 $plugin, int32 $flags )
  returns int32
  is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
#TM:0:g_type_register_fundamental:
=begin pod
=head2 [[g_] type_] register_fundamental

Registers I<type_id> as the predefined identifier and I<type_name> as the
name of a fundamental type. If I<type_id> is already registered, or a
type named I<type_name> is already registered, the behaviour is undefined.
The type system uses the information contained in the I<GTypeInfo> structure
pointed to by I<info> and the I<GTypeFundamentalInfo> structure pointed to by
I<finfo> to manage the type and its instances. The value of I<flags> determines
additional characteristics of the fundamental type.

Returns: the predefined type identifier

  method g_type_register_fundamental ( Str $type_name, int32 $info, int32 $finfo, int32 $flags --> int32  )

=item Str $type_name; 0-terminated string used as the name of the new type
=item int32 $info; I<GTypeInfo> structure for this type
=item int32 $finfo; I<GTypeFundamentalInfo> structure for this type
=item int32 $flags; bitwise combination of I<GTypeFlags> values

=end pod

sub g_type_register_fundamental ( int32 $type_id, Str $type_name, int32 $info, int32 $finfo, int32 $flags )
  returns int32
  is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
#TM:0:g_type_add_interface_static:
=begin pod
=head2 [[g_] type_] add_interface_static

Adds the static I<interface_type> to I<instantiable_type>.
The information contained in the I<N-GInterfaceInfo> structure
pointed to by I<info> is used to manage the relationship.

  method g_type_add_interface_static ( int32 $interface_type, N-GInterfaceInfo $info )

=item int32 $interface_type; I<GType> value of an interface type
=item N-GInterfaceInfo $info; I<N-GInterfaceInfo> structure for this (I<instance_type>, I<interface_type>) combination

=end pod

sub g_type_add_interface_static ( int32 $instance_type, int32 $interface_type, N-GInterfaceInfo $info )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_add_interface_dynamic:
=begin pod
=head2 [[g_] type_] add_interface_dynamic

Adds the dynamic I<interface_type> to I<instantiable_type>. The information
contained in the I<GTypePlugin> structure pointed to by I<plugin>
is used to manage the relationship.

  method g_type_add_interface_dynamic ( int32 $interface_type, int32 $plugin )

=item int32 $interface_type; I<GType> value of an interface type
=item int32 $plugin; I<GTypePlugin> structure to retrieve the I<N-GInterfaceInfo> from

=end pod

sub g_type_add_interface_dynamic ( int32 $instance_type, int32 $interface_type, int32 $plugin )
  is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
#TM:0:g_type_interface_add_prerequisite:
=begin pod
=head2 [[g_] type_] interface_add_prerequisite

Adds I<prerequisite_type> to the list of prerequisites of I<interface_type>.
This means that any type implementing I<interface_type> must also implement
I<prerequisite_type>. Prerequisites can be thought of as an alternative to
interface derivation (which GType doesn't support). An interface can have
at most one instantiatable prerequisite type.

  method g_type_interface_add_prerequisite ( int32 $prerequisite_type )

=item int32 $prerequisite_type; I<GType> value of an interface or instantiatable type

=end pod

sub g_type_interface_add_prerequisite ( int32 $interface_type, int32 $prerequisite_type )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_interface_prerequisites:
=begin pod
=head2 [[g_] type_] interface_prerequisites

Returns the prerequisites of an interfaces type.

Since: 2.2

Returns: (array length=n_prerequisites) (transfer full): a
newly-allocated zero-terminated array of I<GType> containing
the prerequisites of I<interface_type>

  method g_type_interface_prerequisites ( UInt $n_prerequisites --> int32  )

=item UInt $n_prerequisites; (out) (optional): location to return the number of prerequisites, or C<Any>

=end pod

sub g_type_interface_prerequisites ( int32 $interface_type, uint32 $n_prerequisites )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_add_instance_private:
=begin pod
=head2 [[g_] type_] add_instance_private



  method g_type_add_instance_private ( UInt $private_size --> Int  )

=item UInt $private_size;

=end pod

sub g_type_add_instance_private ( int32 $class_type, uint64 $private_size )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_instance_get_private:
=begin pod
=head2 [[g_] type_] instance_get_private



  method g_type_instance_get_private ( int32 $instance, int32 $private_type --> Pointer  )

=item int32 $instance;
=item int32 $private_type;

=end pod

sub g_type_instance_get_private ( int32 $instance, int32 $private_type )
  returns Pointer
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_class_adjust_private_offset:
=begin pod
=head2 [[g_] type_] class_adjust_private_offset



  method g_type_class_adjust_private_offset ( Pointer $g_class, Int $private_size_or_offset )

=item Pointer $g_class;
=item Int $private_size_or_offset;

=end pod

sub g_type_class_adjust_private_offset ( Pointer $g_class, int32 $private_size_or_offset )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_add_class_private:
=begin pod
=head2 [[g_] type_] add_class_private

Registers a private class structure for a classed type;
when the class is allocated, the private structures for
the class and all of its parent types are allocated
sequentially in the same memory block as the public
structures, and are zero-filled.

This function should be called in the
type's C<get_type()> function after the type is registered.
The private structure can be retrieved using the
C<G_TYPE_CLASS_GET_PRIVATE()> macro.

Since: 2.24

  method g_type_add_class_private ( UInt $private_size )

=item UInt $private_size; size of private structure

=end pod

sub g_type_add_class_private ( int32 $class_type, uint64 $private_size )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_class_get_private:
=begin pod
=head2 [[g_] type_] class_get_private



  method g_type_class_get_private ( int32 $klass, int32 $private_type --> Pointer  )

=item int32 $klass;
=item int32 $private_type;

=end pod

sub g_type_class_get_private ( int32 $klass, int32 $private_type )
  returns Pointer
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_class_get_instance_private_offset:
=begin pod
=head2 [[g_] type_] class_get_instance_private_offset

Gets the offset of the private data for instances of I<g_class>.

This is how many bytes you should add to the instance pointer of a
class in order to get the private data for the type represented by
I<g_class>.

You can only call this function after you have registered a private
data area for I<g_class> using C<g_type_class_add_private()>.

Returns: the offset, in bytes

Since: 2.38

  method g_type_class_get_instance_private_offset ( Pointer $g_class --> Int  )

=item Pointer $g_class; (type GObject.TypeClass): a I<N-GTypeClass>

=end pod

sub g_type_class_get_instance_private_offset ( Pointer $g_class )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_ensure:
=begin pod
=head2 [g_] type_ensure

Ensures that the indicated I<type> has been registered with the
type system, and its C<_class_init()> method has been run.

In theory, simply calling the type's C<_get_type()> method (or using
the corresponding macro) is supposed take care of this. However,
C<_get_type()> methods are often marked C<G_GNUC_CONST> for performance
reasons, even though this is technically incorrect (since
C<G_GNUC_CONST> requires that the function not have side effects,
which C<_get_type()> methods do on the first call). As a result, if
you write a bare call to a C<_get_type()> macro, it may get optimized
out by the compiler. Using C<g_type_ensure()> guarantees that the
type's C<_get_type()> method is called.

Since: 2.34

  method g_type_ensure ( )


=end pod

sub g_type_ensure ( int32 $type )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_get_type_registration_serial:
=begin pod
=head2 [[g_] type_] get_type_registration_serial

Returns an opaque serial number that represents the state of the set
of registered types. Any time a type is registered this serial changes,
which means you can cache information based on type lookups (such as
C<g_type_from_name()>) and know if the cache is still valid at a later
time by comparing the current serial with the one at the type lookup.

Since: 2.36

Returns: An unsigned int, representing the state of type registrations

  method g_type_get_type_registration_serial ( --> UInt  )


=end pod

sub g_type_get_type_registration_serial (  )
  returns uint32
  is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
#TM:0:g_type_get_plugin:
=begin pod
=head2 [[g_] type_] get_plugin

Returns the I<GTypePlugin> structure for I<type>.

Returns: (transfer none): the corresponding plugin
if I<type> is a dynamic type, C<Any> otherwise

  method g_type_get_plugin ( --> int32  )


=end pod

sub g_type_get_plugin ( int32 $type )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_interface_get_plugin:
=begin pod
=head2 [[g_] type_] interface_get_plugin

Returns the I<GTypePlugin> structure for the dynamic interface
I<interface_type> which has been added to I<instance_type>, or C<Any>
if I<interface_type> has not been added to I<instance_type> or does
not have a I<GTypePlugin> structure. See C<g_type_add_interface_dynamic()>.

Returns: (transfer none): the I<GTypePlugin> for the dynamic
interface I<interface_type> of I<instance_type>

  method g_type_interface_get_plugin ( int32 $interface_type --> int32  )

=item int32 $interface_type; I<GType> of an interface type

=end pod

sub g_type_interface_get_plugin ( int32 $instance_type, int32 $interface_type )
  returns int32
  is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
#TM:0:g_type_fundamental_next:
=begin pod
=head2 [[g_] type_] fundamental_next

Returns the next free fundamental type id which can be used to
register a new fundamental type with C<g_type_register_fundamental()>.
The returned type ID represents the highest currently registered
fundamental type identifier.

Returns: the next available fundamental type ID to be registered,
or 0 if the type system ran out of fundamental type IDs

  method g_type_fundamental_next ( --> int32  )


=end pod

sub g_type_fundamental_next (  )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_fundamental:
=begin pod
=head2 [g_] type_fundamental

Internal function, used to extract the fundamental type ID portion.
Use C<G_TYPE_FUNDAMENTAL()> instead.

Returns: fundamental type ID

  method g_type_fundamental ( --> int32  )


=end pod

sub g_type_fundamental ( int32 $type_id )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_create_instance:
=begin pod
=head2 [[g_] type_] create_instance

Creates and initializes an instance of I<type> if I<type> is valid and
can be instantiated. The type system only performs basic allocation
and structure setups for instances: actual instance creation should
happen through functions supplied by the type's fundamental type
implementation.  So use of C<g_type_create_instance()> is reserved for
implementators of fundamental types only. E.g. instances of the
I<GObject> hierarchy should be created via C<g_object_new()> and never
directly through C<g_type_create_instance()> which doesn't handle things
like singleton objects or object construction.

The extended members of the returned instance are guaranteed to be filled
with zeros.

Note: Do not use this function, unless you're implementing a
fundamental type. Also language bindings should not use this
function, but C<g_object_new()> instead.

Returns: an allocated and initialized instance, subject to further
treatment by the fundamental type implementation

  method g_type_create_instance ( --> int32  )


=end pod

sub g_type_create_instance ( int32 $type )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_free_instance:
=begin pod
=head2 [[g_] type_] free_instance

Frees an instance of a type, returning it to the instance pool for
the type, if there is one.

Like C<g_type_create_instance()>, this function is reserved for
implementors of fundamental types.

  method g_type_free_instance ( int32 $instance )

=item int32 $instance; an instance of a type

=end pod

sub g_type_free_instance ( int32 $instance )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_add_class_cache_func:
=begin pod
=head2 [[g_] type_] add_class_cache_func

Adds a I<GTypeClassCacheFunc> to be called before the reference count of a
class goes from one to zero. This can be used to prevent premature class
destruction. All installed I<GTypeClassCacheFunc> functions will be chained
until one of them returns C<1>. The functions have to check the class id
passed in to figure whether they actually want to cache the class of this
type, since all classes are routed through the same I<GTypeClassCacheFunc>
chain.

  method g_type_add_class_cache_func ( Pointer $cache_data, int32 $cache_func )

=item Pointer $cache_data; data to be passed to I<cache_func>
=item int32 $cache_func; a I<GTypeClassCacheFunc>

=end pod

sub g_type_add_class_cache_func ( Pointer $cache_data, int32 $cache_func )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_remove_class_cache_func:
=begin pod
=head2 [[g_] type_] remove_class_cache_func

Removes a previously installed I<GTypeClassCacheFunc>. The cache
maintained by I<cache_func> has to be empty when calling
C<g_type_remove_class_cache_func()> to avoid leaks.

  method g_type_remove_class_cache_func ( Pointer $cache_data, int32 $cache_func )

=item Pointer $cache_data; data that was given when adding I<cache_func>
=item int32 $cache_func; a I<GTypeClassCacheFunc>

=end pod

sub g_type_remove_class_cache_func ( Pointer $cache_data, int32 $cache_func )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_class_unref_uncached:
=begin pod
=head2 [[g_] type_] class_unref_uncached

A variant of C<g_type_class_unref()> for use in I<GTypeClassCacheFunc>
implementations. It unreferences a class without consulting the chain
of I<GTypeClassCacheFuncs>, avoiding the recursion which would occur
otherwise.

  method g_type_class_unref_uncached ( Pointer $g_class )

=item Pointer $g_class; (type GObject.TypeClass): a I<N-GTypeClass> structure to unref

=end pod

sub g_type_class_unref_uncached ( Pointer $g_class )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_add_interface_check:
=begin pod
=head2 [[g_] type_] add_interface_check

Adds a function to be called after an interface vtable is
initialized for any class (i.e. after the I<interface_init>
member of I<GInterfaceInfo> has been called).

This function is useful when you want to check an invariant
that depends on the interfaces of a class. For instance, the
implementation of I<GObject> uses this facility to check that an
object implements all of the properties that are defined on its
interfaces.

Since: 2.4

  method g_type_add_interface_check ( Pointer $check_data, int32 $check_func )

=item Pointer $check_data; data to pass to I<check_func>
=item int32 $check_func; function to be called after each interface is initialized

=end pod

sub g_type_add_interface_check ( Pointer $check_data, int32 $check_func )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_remove_interface_check:
=begin pod
=head2 [[g_] type_] remove_interface_check

Removes an interface check function added with
C<g_type_add_interface_check()>.

Since: 2.4

  method g_type_remove_interface_check ( Pointer $check_data, int32 $check_func )

=item Pointer $check_data; callback data passed to C<g_type_add_interface_check()>
=item int32 $check_func; callback function passed to C<g_type_add_interface_check()>

=end pod

sub g_type_remove_interface_check ( Pointer $check_data, int32 $check_func )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_value_table_peek:
=begin pod
=head2 [[g_] type_] value_table_peek

Returns the location of the I<GTypeValueTable> associated with I<type>.

Note that this function should only be used from source code
that implements or has internal knowledge of the implementation of
I<type>.

Returns: location of the I<GTypeValueTable> associated with I<type> or
C<Any> if there is no I<GTypeValueTable> associated with I<type>

  method g_type_value_table_peek ( --> int32  )


=end pod

sub g_type_value_table_peek ( int32 $type )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_check_instance:
=begin pod
=head2 [[g_] type_] check_instance

Private helper function to aid implementation of the
C<G_TYPE_CHECK_INSTANCE()> macro.

Returns: C<1> if I<instance> is valid, C<0> otherwise

  method g_type_check_instance ( N-GTypeInstance $instance --> Int  )

=item N-GTypeInstance $instance; a valid I<GN-TypeInstance> structure

=end pod

sub g_type_check_instance ( N-GTypeInstance $instance )
  returns int32
  is native(&gobject-lib)
  { * }
}}

#-------------------------------------------------------------------------------
#TM:3:g_type_check_instance_cast:
=begin pod
=head2 [[g_] type_] check_instance_cast

Checks that instance is an instance of the type identified by g_type and issues a warning if this is not the case. Returns instance casted to a pointer to c_type.

No warning will be issued if instance is NULL, and NULL will be returned.

This macro should only be used in type implementations.

  method g_type_check_instance_cast (
    N-GObject $instance, UInt $iface_type
    --> N-GObject
  )

=item N-GObject $instance;
=item UInt $iface_type;

=end pod

sub g_type_check_instance_cast ( N-GObject $instance, uint64 $iface_type )
  returns N-GObject
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:g_type_check_instance_is_a:
=begin pod
=head2 [[g_] type_] check_instance_is_a

  method g_type_check_instance_is_a (
    N-GObject $instance, UInt $iface_type --> Int
  )

=item int32 $instance;
=item int32 $iface_type;

=end pod

sub g_type_check_instance_is_a ( N-GObject $instance, uint64 $iface_type )
  returns int32
  is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
#TM:0:g_type_check_instance_is_fundamentally_a:
=begin pod
=head2 [[g_] type_] check_instance_is_fundamentally_a



  method g_type_check_instance_is_fundamentally_a ( int32 $instance, int32 $fundamental_type --> Int  )

=item int32 $instance;
=item int32 $fundamental_type;

=end pod

sub g_type_check_instance_is_fundamentally_a ( int32 $instance, int32 $fundamental_type )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_check_class_cast:
=begin pod
=head2 [[g_] type_] check_class_cast



  method g_type_check_class_cast ( int32 $g_class, int32 $is_a_type --> int32  )

=item int32 $g_class;
=item int32 $is_a_type;

=end pod

sub g_type_check_class_cast ( int32 $g_class, int32 $is_a_type )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_check_class_is_a:
=begin pod
=head2 [[g_] type_] check_class_is_a



  method g_type_check_class_is_a ( int32 $g_class, int32 $is_a_type --> Int  )

=item int32 $g_class;
=item int32 $is_a_type;

=end pod

sub g_type_check_class_is_a ( int32 $g_class, int32 $is_a_type )
  returns int32
  is native(&gobject-lib)
  { * }
}}
#-------------------------------------------------------------------------------
#TM:0:g_type_check_value:
=begin pod
=head2 [[g_] type_] check_value

Checks if value has been initialized to hold values of type g_type.

  method g_type_check_value ( N-GObject $value --> Int  )

=item N-GObject $value;

=end pod

sub g_type_check_value ( N-GObject $value )
  returns int32
  is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
#TM:0:g_type_check_value_holds:
=begin pod
=head2 [[g_] type_] check_value_holds



  method g_type_check_value_holds ( N-GObject $value, int32 $type --> Int  )

=item N-GObject $value;
=item int32 $type;

=end pod

sub g_type_check_value_holds ( N-GObject $value, int32 $type )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_name_from_instance:
=begin pod
=head2 [[g_] type_] name_from_instance



  method g_type_name_from_instance ( int32 $instance --> Str  )

=item int32 $instance;

=end pod

sub g_type_name_from_instance ( int32 $instance )
  returns Str
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_type_name_from_class:
=begin pod
=head2 [[g_] type_] name_from_class



  method g_type_name_from_class ( int32 $g_class --> Str  )

=item int32 $g_class;

=end pod

sub g_type_name_from_class ( int32 $g_class )
  returns Str
  is native(&gobject-lib)
  { * }



}}





















=finish

#-------------------------------------------------------------------------------
Code from c-source to study casting

#define GTK_TYPE_MENU_SHELL             (gtk_menu_shell_get_type ())

GType    gtk_menu_shell_get_type       (void) G_GNUC_CONST;

===> my Gnome::GObject::Type $type .= new;
===> my int32 $gtype = $type.g_type_from_name('GtkMenuShell');


#define GTK_MENU_SHELL(obj)             (G_TYPE_CHECK_INSTANCE_CAST ((obj), GTK_TYPE_MENU_SHELL, GtkMenuShell))

#define G_TYPE_CHECK_INSTANCE_CAST(instance, g_type, c_type) \
        (_G_TYPE_CIC ((instance), (g_type), c_type))

#define _G_TYPE_CIC(ip, gt, ct) \
        ((ct*) g_type_check_instance_cast ((GTypeInstance*) ip, gt))

===> my Gnome::Gtk3::Menu $menu .= new;
===> my $type.check-instance-cast( $menu(), $gtype)
===> my Gnome::Gtk3::MenuShell $menu-shell .= new(
       :widget($type.check-instance-cast( $menu(), $gtype))
     );

===> $menu-shell.gtk_menu_shell_append($menu_item);


#-------------------------------------------------------------------------------
Study for creating new classes and types

G_DEFINE_TYPE(TN, t_n, T_P)
    ===> G_DEFINE_TYPE_EXTENDED (TN, t_n, T_P, 0, {})

 * @TN: The name of the new type, in Camel case. E.g. GtkMenuShell
 * @t_n: The name of the new type, in lowercase, with words
 *  separated by '_'. E.g. gtk_menu_shell
 * @T_P: The #GType of the parent type. E.g. type from GtkContainer

G_DEFINE_TYPE_EXTENDED(TN, t_n, T_P, _f_, _C_)
    ===> _G_DEFINE_TYPE_EXTENDED_BEGIN (TN, t_n, T_P, _f_) {_C_;}
         _G_DEFINE_TYPE_EXTENDED_END()

_G_DEFINE_TYPE_EXTENDED_BEGIN(TypeName, type_name, TYPE_PARENT, flags)
    ===> _G_DEFINE_TYPE_EXTENDED_BEGIN_PRE(TypeName, type_name, TYPE_PARENT)
         _G_DEFINE_TYPE_EXTENDED_BEGIN_REGISTER(TypeName, type_name, TYPE_PARENT, flags) \

#define _G_DEFINE_INTERFACE_EXTENDED_BEGIN(TypeName, type_name, TYPE_PREREQ) \
\
static void     type_name##_default_init        (TypeName##Interface *klass); \
\
GType \
type_name##_get_type (void) \
{ \
  static volatile gsize g_define_type_id__volatile = 0; \
  if (g_once_init_enter (&g_define_type_id__volatile))  \
    { \
      GType g_define_type_id = \
        g_type_register_static_simple (G_TYPE_INTERFACE, \
                                       g_intern_static_string (#TypeName), \
                                       sizeof (TypeName##Interface), \
                                       (GClassInitFunc)(void (*)(void)) type_name##_default_init, \
                                       0, \
                                       (GInstanceInitFunc)NULL, \
                                       (GTypeFlags) 0); \
      if (TYPE_PREREQ != G_TYPE_INVALID) \
        g_type_interface_add_prerequisite (g_define_type_id, TYPE_PREREQ); \
      { /* custom code follows */
#define _G_DEFINE_INTERFACE_EXTENDED_END()	\
        /* following custom code */		\
      }						\
      g_once_init_leave (&g_define_type_id__volatile, g_define_type_id); \
    }						\
  return g_define_type_id__volatile;			\
} /* closes type_name##_get_type() */

#define _G_DEFINE_TYPE_EXTENDED_BEGIN_PRE(TypeName, type_name, TYPE_PARENT) \
\
static void     type_name##_init              (TypeName        *self); \
static void     type_name##_class_init        (TypeName##Class *klass); \
static GType    type_name##_get_type_once     (void); \
static gpointer type_name##_parent_class = NULL; \
static gint     TypeName##_private_offset; \
\
_G_DEFINE_TYPE_EXTENDED_CLASS_INIT(TypeName, type_name) \
\
G_GNUC_UNUSED \
static inline gpointer \
type_name##_get_instance_private (TypeName *self) \
{ \
  return (G_STRUCT_MEMBER_P (self, TypeName##_private_offset)); \
} \
\
GType \
type_name##_get_type (void) \
{ \
  static volatile gsize g_define_type_id__volatile = 0;
  /* Prelude goes here */

/* Added for _G_DEFINE_TYPE_EXTENDED_WITH_PRELUDE */
#define _G_DEFINE_TYPE_EXTENDED_BEGIN_REGISTER(TypeName, type_name, TYPE_PARENT, flags) \
  if (g_once_init_enter (&g_define_type_id__volatile))  \
    { \
      GType g_define_type_id = type_name##_get_type_once (); \
      g_once_init_leave (&g_define_type_id__volatile, g_define_type_id); \
    }					\
  return g_define_type_id__volatile;	\
} /* closes type_name##_get_type() */ \
\
G_GNUC_NO_INLINE \
static GType \
type_name##_get_type_once (void) \
{ \
  GType g_define_type_id = \
        g_type_register_static_simple (TYPE_PARENT, \
                                       g_intern_static_string (#TypeName), \
                                       sizeof (TypeName##Class), \
                                       (GClassInitFunc)(void (*)(void)) type_name##_class_intern_init, \
                                       sizeof (TypeName), \
                                       (GInstanceInitFunc)(void (*)(void)) type_name##_init, \
                                       (GTypeFlags) flags); \
    { /* custom code follows */
#define _G_DEFINE_TYPE_EXTENDED_END()	\
      /* following custom code */	\
    }					\
  return g_define_type_id; \
} /* closes type_name##_get_type_once() */
