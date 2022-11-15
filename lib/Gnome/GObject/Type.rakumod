#TL:1:Gnome::GObject::Type:

use v6;

#-------------------------------------------------------------------------------
=begin pod

=head1 Gnome::GObject::Type

The GLib Runtime type identification and management system

I<B<Note: The methods described here are mostly used internally and is not of much interest for the normal Raku user.>>

=head1 Description

The GType API is the foundation of the GObject system. It provides the facilities for registering and managing all fundamental data types. To have a type stored next to its value. The class B<Gnome::GObject::Value> serves as a vehicle to get values in and out of an object. This class controls a C<N-GValue> object which has a type and a value.

The Glib types such as C<gint> and C<gfloat> are used to type variables and functions directly and are compiled to the proper sizes when used in code. These types are mapped to the C types like C<int> and C<float>. In the module B<Gnome::N::GlibToRakuTypes>, a mapping is made to be able to map the Glib types to the Raku types.

=comment , user-defined object and interface types.

=begin comment
For type creation and registration purposes, all types fall into one of two categories: static or dynamic. Static types are never loaded or unloaded at run-time as dynamic types may be.

Static types are created with C<g_type_register_static()> that gets type specific information passed in via a I<GTypeInfo> structure.

Dynamic types are created with C<g_type_register_dynamic()> which takes a I<GTypePlugin> structure instead. The remaining type information (the I<GTypeInfo> structure) is retrieved during runtime through I<GTypePlugin> and the g_type_plugin_*() API.

These registration functions are usually called only once from a function whose only purpose is to return the type identifier for a specific class. Once the type (or class or interface) is registered, it may be instantiated, inherited, or implemented depending on exactly what sort of type it is.

There is also a third registration function for registering fundamental types called C<g_type_register_fundamental()> which requires both a I<GTypeInfo> structure and a I<GTypeFundamentalInfo> structure but it is seldom used since most fundamental types are predefined rather than user-defined.

Type instance and class structs are limited to a total of 64 KiB, including all parent types. Similarly, type instances' private data (as created by C<G_ADD_PRIVATE()>) are limited to a total of 64 KiB. If a type instance needs a large static buffer, allocate it separately (typically by using I<GArray> or I<GPtrArray>) and put a pointer to the buffer in the structure.

As mentioned in the [GType conventions](https://developer.gnome.org/gobject/stable/gtype-conventions.html), type names must be at least three characters long. There is no upper length limit. The first character must be a letter (a–z or A–Z) or an underscore (‘_’). Subsequent characters can be letters, numbers or any of ‘-_+’.
=end comment


=head1 Synopsis
=head2 Declaration

  unit class Gnome::GObject::Type;


=comment '=head2 Example'

=end pod
#-------------------------------------------------------------------------------
use NativeCall;

#use Gnome::N::X;
use Gnome::N::NativeLib;
use Gnome::N::N-GObject;
use Gnome::N::GlibToRakuTypes;

#use Gnome::GObject::Value;

#-------------------------------------------------------------------------------
unit class Gnome::GObject::Type:auth<github:MARTIMM>;

#-------------------------------------------------------------------------------
#`{{
=begin pod
=head2 class N-GTypeInstance

An opaque structure used as the base of all type instances.

=end pod

# TT:0:N-GTypeInstance:
class N-GTypeInstance is repr('CPointer') is export { }
}}

#`{{
#-------------------------------------------------------------------------------
=begin pod
=head2 class N-GTypeInterface

An opaque structure used as the base of all interface types.

=end pod

# TT:0:N-GTypeInterface:
class N-GTypeInterface is repr('CPointer') is export { }
}}

#`{{
#-------------------------------------------------------------------------------
=begin pod
=head2 class N-GTypeClass

An opaque structure used as the base of all type instances.

=end pod

# TT:0::N-GTypeClass
class N-GTypeClass is repr('CPointer') is export { }
}}

#-------------------------------------------------------------------------------
=begin pod
=head2 class N-GTypeQuery

A structure holding information for a specific type. It is filled in by the C<query()> function.

=item UInt $.type: the GType value of the type.
=item Str $.type_name: the name of the type.
=item UInt $.class_size: the size of the class structure.
=item UInt $.instance_size: the size of the instance structure.

=end pod

#TT:2:N-GTypeQuery:
class N-GTypeQuery is export is repr('CStruct') {
  has GType $.type;
  has gchar-ptr $.type_name;
  has guint $.class_size;
  has guint $.instance_size;
}

#`{{
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


# TT:0:N-GTypeInfo:
class N-GTypeInfo
  is repr('CPointer')
  is export
  { }


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
  has Pointer $.value_table;
}
}}

#`{{
#-------------------------------------------------------------------------------
=begin pod
=head2 class N-GTypeFundamentalInfo

A structure that provides information to the type system which is used specifically for managing fundamental types.

=item int32 $.type_flags: I<N-GTypeFundamentalFlags> describing the characteristics of the fundamental type

=end pod

# TT:0:N-GTypeFundamentalInfo:
class N-GTypeFundamentalInfo is export is repr('CStruct') {
  has GFlag $.type_flags;
}
}}

#`{{
#-------------------------------------------------------------------------------
=begin pod
=head2 enum N-GTypeFundamentalFlags

Bit masks used to check or determine specific characteristics of a fundamental type.

=item G_TYPE_FLAG_CLASSED; Indicates a classed type
=item G_TYPE_FLAG_INSTANTIATABLE; Indicates an instantiable type (implies classed)
=item G_TYPE_FLAG_DERIVABLE; Indicates a flat derivable type
=item G_TYPE_FLAG_DEEP_DERIVABLE; Indicates a deep derivable type (implies derivable)

=end pod

# TT:0::N-GTypeFundamentalFlags
enum N-GTypeFundamentalFlags is export <
  G_TYPE_FLAG_CLASSED G_TYPE_FLAG_INSTANTIATABLE
  G_TYPE_FLAG_DERIVABLE G_TYPE_FLAG_DEEP_DERIVABLE
>;
}}

#`{{
#-------------------------------------------------------------------------------
=begin pod
=head2 class N-GInterfaceInfo

A structure that provides information to the type system which is used specifically for managing interface types.

=item GInterfaceInitFunc $.interface_init: location of the interface initialization function
=item GInterfaceFinalizeFunc $.interface_finalize: location of the interface finalization function
=item Pointer $.interface_data: user-supplied data passed to the interface init/finalize functions

=end pod

# TT:0:N-GInterfaceInfo:
class N-GInterface!build-types-conversion-moduleInfo is export is repr('CStruct') {
  has Pointer $.interface_init;     #has GInterfaceInitFunc $.interface_init;
  has Pointer $.interface_finalize; #has GInterfaceFinalizeFunc $.interface_finalize;
  has Pointer $.interface_data;
}
}}

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

# TT:0:N-GTypeValueTable:
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
=begin pod
=head2 Type names

=item G_TYPE_CHAR; An 8 bit integer.
=item G_TYPE_UCHAR; An 8 bit unsigned integer.
=item G_TYPE_BOOLEAN; A boolean. This is the size of an int32.
=item G_TYPE_INT; An integer, also the size of an int32.
=item G_TYPE_UINT; An unsigned integer.
=item G_TYPE_LONG; A larger type integer.
=item G_TYPE_ULONG; A larger type unsigned integer.
=item G_TYPE_INT64; A larger type integer.
=item G_TYPE_UINT64; A larger type unsigned integer.
=item G_TYPE_ENUM; An integer used for C enumerations.
=item G_TYPE_FLAGS; An integer used for bitmap flags.
=item G_TYPE_FLOAT; A floating point value.
=item G_TYPE_DOUBLE; A large floating point value.
=item G_TYPE_STRING; A string.
=comment item G_TYPE_POINTER. 
=comment item G_TYPE_BOXED
=comment item G_TYPE_PARAM
=item G_TYPE_OBJECT; A gnome object.
=item G_TYPE_VARIANT; A variant.

To show the glib types together with the Raku types and the type names mentioned above a small table is shown below;

=begin table
  Type name       | Glib type | Raku type
  =======================================
  G_TYPE_CHAR     | gchar     | int8
  G_TYPE_UCHAR    | guchar    | uint8
  G_TYPE_BOOLEAN  | gboolean  | int32
  G_TYPE_INT      | gint      | int32
  G_TYPE_UINT     | guint     | uint32
  G_TYPE_LONG     | glong     | int64
  G_TYPE_ULONG    | gulong    | uint64
  G_TYPE_INT64    | gint64    | int64
  G_TYPE_UINT64   | guint64   | uint64
  G_TYPE_ENUM     | GEnum     | int32
  G_TYPE_FLAGS    | GFlag     | uint32
  G_TYPE_FLOAT    | gfloat    | num32
  G_TYPE_DOUBLE   | gdouble   | num64
  G_TYPE_STRING   | gchar-ptr | Str
  G_TYPE_OBJECT   | -         | Gnome::GObject::Object
  G_TYPE_VARIANT  | -         | Gnome::Glib::Variant
=end table

Some types might have a longer or shorter size depending on the OS Raku is running on. It is a reflection of the C macro types of the C compiler include files. So to use the proper types, always use the glib type instead of the Raku type which are generated in the B<Gnome::N::GlibToRakuTypes> module at Build time when C<Gnome::N> is installed.

=end pod

#define	G_TYPE_FUNDAMENTAL_SHIFT (2)
constant G_TYPE_FUNDAMENTAL_SHIFT = 2;

#define	G_TYPE_FUNDAMENTAL_MAX		(255 << G_TYPE_FUNDAMENTAL_SHIFT)
constant G_TYPE_MAKE_FUNDAMENTAL_MAX is export =
         255 +< G_TYPE_FUNDAMENTAL_SHIFT;

#define	G_TYPE_MAKE_FUNDAMENTAL(x)	((GType) ((x) << G_TYPE_FUNDAMENTAL_SHIFT))
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
  has int $.enum;           # G_TYPE_ENUM
  has int $.flags;          # G_TYPE_FLAGS
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
=head3 default, no options

Create a new plain object. In contrast with other objects, this class doesn't wrap a native object, so therefore no options to specify something.

=end pod

#TM:1:new():
submethod BUILD ( *%options ) {

  if %options.keys.elems {
    die X::Gnome.new(
      :message('Unsupported options for ' ~ self.^name ~
               ': ' ~ %options.keys.join(', ') ~
               ', cannot have any arguments'
              )
    );
  }
}

#-------------------------------------------------------------------------------
method FALLBACK ( $native-sub is copy, |c ) {

  CATCH { .note; die; }

#`{{
  $native-sub ~~ s:g/ '-' /_/ if $native-sub.index('-');
  die X::Gnome.new(:message(
    "Native sub name '$native-sub' made too short. Keep at least one '-' or '_'."
    )
  ) unless $native-sub.index('_') >= 0;
}}

  my Str $new-patt = $native-sub.subst( '_', '-', :g);

  my Callable $s;
  try { $s = &::("g_type_$native-sub"); };
  if ?$s {
    Gnome::N::deprecate(
      "g_type_$native-sub", $new-patt, '0.19.11', '0.20.0'
    );
  }

  else {
    try { $s = &::("g_$native-sub") } unless ?$s;
    if ?$s {
      Gnome::N::deprecate(
        "g_$native-sub", $new-patt.subst('type-'),
        '0.19.11', '0.20.0'
      );
    }

    else {
      try { $s = &::($native-sub); } if !$s and $native-sub ~~ m/^ 'g_' /;
      if ?$s {
        Gnome::N::deprecate(
          "$native-sub", $new-patt.subst('g-type-'),
          '0.19.11', '0.20.0'
        );
      }
    }
  }

  $s(|c)
}

#-------------------------------------------------------------------------------
# conveniance method to convert a type to a Raku parameter
#TM:4:get-parameter:Gnome::Gtk3::ListStore
method get-parameter( UInt $type, :$otype --> Parameter ) {

  # tests showed elsewhere that types can come in negative. this should be
  # trapped at the generated spot but it could be anywhere so here it
  # should be converted in any case. It is caused by returned types with
  # 32th bit set which is seen as negative. remedy is to take a two's
  # complement of the negative value.
  #$type = ^+ $type if $type < 0;

  my Parameter $p;
  given $type {
    when G_TYPE_CHAR    { $p .= new(type => gchar); }
    when G_TYPE_UCHAR   { $p .= new(type => guchar); }
    when G_TYPE_BOOLEAN { $p .= new(type => gboolean); }
    when G_TYPE_INT     { $p .= new(type => gint); }
    when G_TYPE_UINT    { $p .= new(type => guint); }
    when G_TYPE_LONG    { $p .= new(type => glong); }
    when G_TYPE_ULONG   { $p .= new(type => gulong); }
    when G_TYPE_INT64   { $p .= new(type => gint64); }
    when G_TYPE_UINT64  { $p .= new(type => guint64); }
    when G_TYPE_ENUM    { $p .= new(type => gint); }
    when G_TYPE_FLAGS   { $p .= new(type => gint); }
    when G_TYPE_FLOAT   { $p .= new(type => gfloat); }
    when G_TYPE_DOUBLE  { $p .= new(type => gdouble); }
    when G_TYPE_STRING  { $p .= new(type => gchar-ptr); }

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
      # is a type which is set when a GTK+ object is created. In Raku the
      # object type is stored in the class as $!class-gtype in
      # Gnome::N::TopLevelSupport and retrievable with .get-class-gtype()
      if $type > G_TYPE_MAKE_FUNDAMENTAL_MAX {
        $p .= new(:$type);
      }

      elsif ?$otype {
        $p .= new(type => $otype.get-class-gtype);
      }

      else {
        die X::Gnome.new(
          :message("Unknown basic type $type and \$otype is undefined")
        );
      }
    }
  }

  $p
}



#`{{
#-------------------------------------------------------------------------------
# TM:0:add-class-cache-func:
=begin pod
=head2 add-class-cache-func

Adds a B<Gnome::GObject::TypeClassCacheFunc> to be called before the reference count of a class goes from one to zero. This can be used to prevent premature class destruction. All installed B<Gnome::GObject::TypeClassCacheFunc> functions will be chained until one of them returns C<True>. The functions have to check the class id passed in to figure whether they actually want to cache the class of this type, since all classes are routed through the same B<Gnome::GObject::TypeClassCacheFunc> chain.

  method add-class-cache-func ( Pointer $cache_data, GTypeClassCacheFunc $cache_func )

=item Pointer $cache_data; data to be passed to I<cache-func>
=item GTypeClassCacheFunc $cache_func; a B<Gnome::GObject::TypeClassCacheFunc>
=end pod

method add-class-cache-func ( Pointer $cache_data, GTypeClassCacheFunc $cache_func ) {

  g_type_add_class_cache_func(
    self._get-native-object-no-reffing, $cache_data, $cache_func
  );
}

sub g_type_add_class_cache_func (
  gpointer $cache_data, GTypeClassCacheFunc $cache_func
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:add-class-private:
=begin pod
=head2 add-class-private

Registers a private class structure for a classed type; when the class is allocated, the private structures for the class and all of its parent types are allocated sequentially in the same memory block as the public structures, and are zero-filled.

This function should be called in the type's C<get-type()> function after the type is registered. The private structure can be retrieved using the C<G-TYPE-CLASS-GET-PRIVATE()> macro.

  method add-class-private ( UInt $private_size )

=item UInt $private_size; size of private structure
=end pod

method add-class-private ( UInt $private_size ) {

  g_type_add_class_private(
    self._get-native-object-no-reffing, $private_size
  );
}

sub g_type_add_class_private (
  N-GObject $class_type, gsize $private_size
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:add-instance-private:
=begin pod
=head2 add-instance-private



  method add-instance-private ( UInt $private_size --> Int )

=item UInt $private_size;
=end pod

method add-instance-private ( UInt $private_size --> Int ) {

  g_type_add_instance_private(
    self._get-native-object-no-reffing, $private_size
  )
}

sub g_type_add_instance_private (
  N-GObject $class_type, gsize $private_size --> gint
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:add-interface-check:
=begin pod
=head2 add-interface-check

Adds a function to be called after an interface vtable is initialized for any class (i.e. after the I<interface-init> member of B<Gnome::GObject::InterfaceInfo> has been called).

This function is useful when you want to check an invariant that depends on the interfaces of a class. For instance, the implementation of B<Gnome::GObject::Object> uses this facility to check that an object implements all of the properties that are defined on its interfaces.

  method add-interface-check ( Pointer $check_data, GTypeInterfaceCheckFunc $check_func )

=item Pointer $check_data; data to pass to I<check-func>
=item GTypeInterfaceCheckFunc $check_func; function to be called after each interface is initialized
=end pod

method add-interface-check ( Pointer $check_data, GTypeInterfaceCheckFunc $check_func ) {

  g_type_add_interface_check(
    self._get-native-object-no-reffing, $check_data, $check_func
  );
}

sub g_type_add_interface_check (
  gpointer $check_data, GTypeInterfaceCheckFunc $check_func
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:add-interface-dynamic:
=begin pod
=head2 add-interface-dynamic

Adds the dynamic I<interface-type> to I<instantiable-type>. The information contained in the B<Gnome::GObject::TypePlugin> structure pointed to by I<plugin> is used to manage the relationship.

  method add-interface-dynamic ( N-GObject $interface_type, N-GObject $plugin )

=item N-GObject $interface_type; B<Gnome::GObject::Type> value of an interface type
=item N-GObject $plugin; B<Gnome::GObject::TypePlugin> structure to retrieve the B<Gnome::GObject::InterfaceInfo> from
=end pod

method add-interface-dynamic ( $interface_type is copy, $plugin is copy ) {
  $interface_type .= _get-native-object-no-reffing unless $interface_type ~~ N-GObject;
  $plugin .= _get-native-object-no-reffing unless $plugin ~~ N-GObject;

  g_type_add_interface_dynamic(
    self._get-native-object-no-reffing, $interface_type, $plugin
  );
}

sub g_type_add_interface_dynamic (
  N-GObject $instance_type, N-GObject $interface_type, N-GObject $plugin
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:add-interface-static:
=begin pod
=head2 add-interface-static

Adds the static I<interface-type> to I<instantiable-type>. The information contained in the B<Gnome::GObject::InterfaceInfo> structure pointed to by I<info> is used to manage the relationship.

  method add-interface-static ( N-GObject $interface_type, GInterfaceInfo $info )

=item N-GObject $interface_type; B<Gnome::GObject::Type> value of an interface type
=item GInterfaceInfo $info; B<Gnome::GObject::InterfaceInfo> structure for this (I<instance-type>, I<interface-type>) combination
=end pod

method add-interface-static ( $interface_type is copy, GInterfaceInfo $info ) {
  $interface_type .= _get-native-object-no-reffing unless $interface_type ~~ N-GObject;

  g_type_add_interface_static(
    self._get-native-object-no-reffing, $interface_type, $info
  );
}

sub g_type_add_interface_static (
  N-GObject $instance_type, N-GObject $interface_type, GInterfaceInfo $info
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:check-class-cast:
=begin pod
=head2 check-class-cast



  method check-class-cast ( GTypeClass $g_class, N-GObject $is_a_type --> GTypeClass )

=item GTypeClass $g_class;
=item N-GObject $is_a_type;
=end pod

method check-class-cast ( GTypeClass $g_class, $is_a_type is copy --> GTypeClass ) {
  $is_a_type .= _get-native-object-no-reffing unless $is_a_type ~~ N-GObject;

  g_type_check_class_cast(
    self._get-native-object-no-reffing, $g_class, $is_a_type
  )
}

sub g_type_check_class_cast (
  GTypeClass $g_class, N-GObject $is_a_type --> GTypeClass
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:check-class-is-a:
=begin pod
=head2 check-class-is-a



  method check-class-is-a ( GTypeClass $g_class, N-GObject $is_a_type --> Bool )

=item GTypeClass $g_class;
=item N-GObject $is_a_type;
=end pod

method check-class-is-a ( GTypeClass $g_class, $is_a_type is copy --> Bool ) {
  $is_a_type .= _get-native-object-no-reffing unless $is_a_type ~~ N-GObject;

  g_type_check_class_is_a(
    self._get-native-object-no-reffing, $g_class, $is_a_type
  ).Bool
}

sub g_type_check_class_is_a (
  GTypeClass $g_class, N-GObject $is_a_type --> gboolean
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:check-instance:
=begin pod
=head2 check-instance

Private helper function to aid implementation of the C<G-TYPE-CHECK-INSTANCE()> macro.

Returns: C<True> if I<instance> is valid, C<False> otherwise

  method check-instance ( GTypeInstance $instance --> Bool )

=item GTypeInstance $instance; a valid B<Gnome::GObject::TypeInstance> structure
=end pod

method check-instance ( GTypeInstance $instance --> Bool ) {

  g_type_check_instance(
    self._get-native-object-no-reffing, $instance
  ).Bool
}

sub g_type_check_instance (
  GTypeInstance $instance --> gboolean
) is native(&gobject-lib)
  { * }
}}

#-------------------------------------------------------------------------------
#TM:2:check-instance-cast:
=begin pod
=head2 check-instance-cast

Checks that instance is an instance of the type identified by g_type and issues a warning if this is not the case. Returns instance casted to a pointer to c_type.

No warning will be issued if instance is NULL, and NULL will be returned.

  method check-instance-cast (
    N-GObject $instance, UInt $iface_type --> N-GObject
  )

=item N-GObject $instance;
=item UInt $iface_type;
=end pod

method check-instance-cast (
  $instance is copy, UInt $iface_gtype --> N-GObject
) {
  $instance .= _get-native-object-no-reffing unless $instance ~~ N-GObject;
  g_type_check_instance_cast( $instance, $iface_gtype)
}

sub g_type_check_instance_cast (
  N-GObject $instance, GType $iface_type --> N-GObject
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:2:check-instance-is-a:
=begin pod
=head2 check-instance-is-a

Check if an instance is of type C<$iface-gtype>. Returns True if it is.

  method check-instance-is-a (
    N-GObject $instance, UInt $iface_gtype --> Bool
  )

=item N-GObject $instance;
=item UInt $iface_type;
=end pod

method check-instance-is-a (
  $instance is copy, UInt $iface_gtype --> Bool
) {
  $instance .= _get-native-object-no-reffing unless $instance ~~ N-GObject;
  g_type_check_instance_is_a( $instance, $iface_gtype).Bool
}

sub g_type_check_instance_is_a (
  N-GObject $instance, GType $iface_gtype --> gboolean
) is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
# TM:0:check-instance-is-fundamentally-a:
=begin pod
=head2 check-instance-is-fundamentally-a



  method check-instance-is-fundamentally-a ( GTypeInstance $instance, N-GObject $fundamental_type --> Bool )

=item GTypeInstance $instance;
=item N-GObject $fundamental_type;
=end pod

method check-instance-is-fundamentally-a ( GTypeInstance $instance, $fundamental_type is copy --> Bool ) {
  $fundamental_type .= _get-native-object-no-reffing unless $fundamental_type ~~ N-GObject;

  g_type_check_instance_is_fundamentally_a(
    self._get-native-object-no-reffing, $instance, $fundamental_type
  ).Bool
}

sub g_type_check_instance_is_fundamentally_a (
  GTypeInstance $instance, N-GObject $fundamental_type --> gboolean
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:check-value:
=begin pod
=head2 check-value



  method check-value ( N-GObject $value --> Bool )

=item N-GObject $value;
=end pod

method check-value ( $value is copy --> Bool ) {
  $value .= _get-native-object-no-reffing unless $value ~~ N-GObject;

  g_type_check_value(
    self._get-native-object-no-reffing, $value
  ).Bool
}

sub g_type_check_value (
  N-GObject $value --> gboolean
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:check-value-holds:
=begin pod
=head2 check-value-holds



  method check-value-holds ( N-GObject $value, N-GObject $type --> Bool )

=item N-GObject $value;
=item N-GObject $type;
=end pod

method check-value-holds ( $value is copy, $type is copy --> Bool ) {
  $value .= _get-native-object-no-reffing unless $value ~~ N-GObject;
  $type .= _get-native-object-no-reffing unless $type ~~ N-GObject;

  g_type_check_value_holds(
    self._get-native-object-no-reffing, $value, $type
  ).Bool
}

sub g_type_check_value_holds (
  N-GObject $value, N-GObject $type --> gboolean
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:children:
=begin pod
=head2 children

Return a newly allocated and 0-terminated array of type IDs, listing the child types of I<type>.

Returns: (array length=n-children) : Newly allocated and 0-terminated array of child types, free with C<g-free()>

  method children ( guInt-ptr $n_children --> N-GObject )

=item guInt-ptr $n_children; location to store the length of the returned array, or C<undefined>
=end pod

method children ( guInt-ptr $n_children --> N-GObject ) {

  g_type_children(
    self._get-native-object-no-reffing, $n_children
  )
}

sub g_type_children (
  N-GObject $type, gugint-ptr $n_children --> N-GObject
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:class-adjust-private-offset:
=begin pod
=head2 class-adjust-private-offset



  method class-adjust-private-offset ( Pointer $g_class )

=item Pointer $g_class;
=item Int $private_size_or_offset;
=end pod

method class-adjust-private-offset ( Pointer $g_class ) {

  g_type_class_adjust_private_offset(
    self._get-native-object-no-reffing, $g_class, my gint $private_size_or_offset
  );
}

sub g_type_class_adjust_private_offset (
  gpointer $g_class, gint $private_size_or_offset is rw
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:class-get-instance-private-offset:
=begin pod
=head2 class-get-instance-private-offset

Gets the offset of the private data for instances of I<g-class>.

This is how many bytes you should add to the instance pointer of a class in order to get the private data for the type represented by I<g-class>.

You can only call this function after you have registered a private data area for I<g-class> using C<class-add-private()>.

Returns: the offset, in bytes

  method class-get-instance-private-offset ( Pointer $g_class --> Int )

=item Pointer $g_class; (type GObject.TypeClass): a B<Gnome::GObject::TypeClass>
=end pod

method class-get-instance-private-offset ( Pointer $g_class --> Int ) {

  g_type_class_get_instance_private_offset(
    self._get-native-object-no-reffing, $g_class
  )
}

sub g_type_class_get_instance_private_offset (
  gpointer $g_class --> gint
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:class-get-private:
=begin pod
=head2 class-get-private



  method class-get-private ( GTypeClass $klass, N-GObject $private_type --> Pointer )

=item GTypeClass $klass;
=item N-GObject $private_type;
=end pod

method class-get-private ( GTypeClass $klass, $private_type is copy --> Pointer ) {
  $private_type .= _get-native-object-no-reffing unless $private_type ~~ N-GObject;

  g_type_class_get_private(
    self._get-native-object-no-reffing, $klass, $private_type
  )
}

sub g_type_class_get_private (
  GTypeClass $klass, N-GObject $private_type --> gpointer
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:class-peek:
=begin pod
=head2 class-peek

This function is essentially the same as C<class-ref()>, except that the classes reference count isn't incremented. As a consequence, this function may return C<undefined> if the class of the type passed in does not currently exist (hasn't been referenced before).

Returns: (type GObject.TypeClass) : the B<Gnome::GObject::TypeClass> structure for the given type ID or C<undefined> if the class does not currently exist

  method class-peek ( --> Pointer )

=end pod

method class-peek ( --> Pointer ) {

  g_type_class_peek(
    self._get-native-object-no-reffing,
  )
}

sub g_type_class_peek (
  N-GObject $type --> gpointer
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:class-peek-parent:
=begin pod
=head2 class-peek-parent

This is a convenience function often needed in class initializers. It returns the class structure of the immediate parent type of the class passed in. Since derived classes hold a reference count on their parent classes as long as they are instantiated, the returned class will always exist.

This function is essentially equivalent to: class-peek (g-type-parent (G-TYPE-FROM-CLASS (g-class)))

Returns: (type GObject.TypeClass) : the parent class of I<g-class>

  method class-peek-parent ( Pointer $g_class --> Pointer )

=item Pointer $g_class; (type GObject.TypeClass): the B<Gnome::GObject::TypeClass> structure to retrieve the parent class for
=end pod

method class-peek-parent ( Pointer $g_class --> Pointer ) {

  g_type_class_peek_parent(
    self._get-native-object-no-reffing, $g_class
  )
}

sub g_type_class_peek_parent (
  gpointer $g_class --> gpointer
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:class-peek-static:
=begin pod
=head2 class-peek-static

A more efficient version of C<class-peek()> which works only for static types.

Returns: (type GObject.TypeClass) : the B<Gnome::GObject::TypeClass> structure for the given type ID or C<undefined> if the class does not currently exist or is dynamically loaded

  method class-peek-static ( --> Pointer )

=end pod

method class-peek-static ( --> Pointer ) {

  g_type_class_peek_static(
    self._get-native-object-no-reffing,
  )
}

sub g_type_class_peek_static (
  N-GObject $type --> gpointer
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:class-ref:
=begin pod
=head2 class-ref

Increments the reference count of the class structure belonging to I<type>. This function will demand-create the class if it doesn't exist already.

Returns: (type GObject.TypeClass) : the B<Gnome::GObject::TypeClass> structure for the given type ID

  method class-ref ( --> Pointer )

=end pod

method class-ref ( --> Pointer ) {

  g_type_class_ref(
    self._get-native-object-no-reffing,
  )
}

sub g_type_class_ref (
  N-GObject $type --> gpointer
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:class-unref:
=begin pod
=head2 class-unref

Decrements the reference count of the class structure being passed in. Once the last reference count of a class has been released, classes may be finalized by the type system, so further dereferencing of a class pointer after C<class-unref()> are invalid.

  method class-unref ( Pointer $g_class )

=item Pointer $g_class; (type GObject.TypeClass): a B<Gnome::GObject::TypeClass> structure to unref
=end pod

method class-unref ( Pointer $g_class ) {

  g_type_class_unref(
    self._get-native-object-no-reffing, $g_class
  );
}

sub g_type_class_unref (
  gpointer $g_class
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:class-unref-uncached:
=begin pod
=head2 class-unref-uncached

A variant of C<class-unref()> for use in B<Gnome::GObject::TypeClassCacheFunc> implementations. It unreferences a class without consulting the chain of B<Gnome::GObject::TypeClassCacheFuncs>, avoiding the recursion which would occur otherwise.

  method class-unref-uncached ( Pointer $g_class )

=item Pointer $g_class; (type GObject.TypeClass): a B<Gnome::GObject::TypeClass> structure to unref
=end pod

method class-unref-uncached ( Pointer $g_class ) {

  g_type_class_unref_uncached(
    self._get-native-object-no-reffing, $g_class
  );
}

sub g_type_class_unref_uncached (
  gpointer $g_class
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:create-instance:
=begin pod
=head2 create-instance

Creates and initializes an instance of I<type> if I<type> is valid and can be instantiated. The type system only performs basic allocation and structure setups for instances: actual instance creation should happen through functions supplied by the type's fundamental type implementation. So use of C<create-instance()> is reserved for implementators of fundamental types only. E.g. instances of the B<Gnome::GObject::Object> hierarchy should be created via C<g-object-new()> and never directly through C<g-type-create-instance()> which doesn't handle things like singleton objects or object construction.

The extended members of the returned instance are guaranteed to be filled with zeros.

Note: Do not use this function, unless you're implementing a fundamental type. Also language bindings should not use this function, but C<g-object-new()> instead.

Returns: an allocated and initialized instance, subject to further treatment by the fundamental type implementation

  method create-instance ( --> GTypeInstance )

=end pod

method create-instance ( --> GTypeInstance ) {

  g_type_create_instance(
    self._get-native-object-no-reffing,
  )
}

sub g_type_create_instance (
  N-GObject $type --> GTypeInstance
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:default-interface-peek:
=begin pod
=head2 default-interface-peek

If the interface type I<g-type> is currently in use, returns its default interface vtable.

Returns: (type GObject.TypeInterface) : the default vtable for the interface, or C<undefined> if the type is not currently in use

  method default-interface-peek ( --> Pointer )

=end pod

method default-interface-peek ( --> Pointer ) {

  g_type_default_interface_peek(
    self._get-native-object-no-reffing,
  )
}

sub g_type_default_interface_peek (
  N-GObject $g_type --> gpointer
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:default-interface-ref:
=begin pod
=head2 default-interface-ref

Increments the reference count for the interface type I<g-type>, and returns the default interface vtable for the type.

If the type is not currently in use, then the default vtable for the type will be created and initalized by calling the base interface init and default vtable init functions for the type (the I<base-init> and I<class-init> members of B<Gnome::GObject::TypeInfo>). Calling C<default-interface-ref()> is useful when you want to make sure that signals and properties for an interface have been installed.

Returns: (type GObject.TypeInterface) : the default vtable for the interface; call C<g-type-default-interface-unref()> when you are done using the interface.

  method default-interface-ref ( --> Pointer )

=end pod

method default-interface-ref ( --> Pointer ) {

  g_type_default_interface_ref(
    self._get-native-object-no-reffing,
  )
}

sub g_type_default_interface_ref (
  N-GObject $g_type --> gpointer
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:default-interface-unref:
=begin pod
=head2 default-interface-unref

Decrements the reference count for the type corresponding to the interface default vtable I<g-iface>. If the type is dynamic, then when no one is using the interface and all references have been released, the finalize function for the interface's default vtable (the I<class-finalize> member of B<Gnome::GObject::TypeInfo>) will be called.

  method default-interface-unref ( Pointer $g_iface )

=item Pointer $g_iface; (type GObject.TypeInterface): the default vtable structure for a interface, as returned by C<default-interface-ref()>
=end pod

method default-interface-unref ( Pointer $g_iface ) {

  g_type_default_interface_unref(
    self._get-native-object-no-reffing, $g_iface
  );
}

sub g_type_default_interface_unref (
  gpointer $g_iface
) is native(&gobject-lib)
  { * }
}}

#-------------------------------------------------------------------------------
#TM:2:depth:
=begin pod
=head2 depth

Returns the length of the ancestry of the passed in type. This includes the type itself, so that e.g. a fundamental type has depth 1.

Returns: the depth of I<$gtype>

  method depth ( UInt $gtype --> UInt )

=end pod

method depth ( UInt $gtype --> UInt ) {
  g_type_depth($gtype)
}

sub g_type_depth (
  GType $type --> guint
) is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
# TM:0:ensure:
=begin pod
=head2 ensure

Ensures that the indicated I<type> has been registered with the type system, and its C<-class-init()> method has been run.

In theory, simply calling the type's C<-get-type()> method (or using the corresponding macro) is supposed take care of this. However, C<-get-type()> methods are often marked C<G-GNUC-CONST> for performance reasons, even though this is technically incorrect (since C<G-GNUC-CONST> requires that the function not have side effects, which C<-get-type()> methods do on the first call). As a result, if you write a bare call to a C<-get-type()> macro, it may get optimized out by the compiler. Using C<ensure()> guarantees that the type's C<-get-type()> method is called.

  method ensure ( )

=end pod

method ensure ( ) {

  g_type_ensure(
    self._get-native-object-no-reffing,
  );
}

sub g_type_ensure (
  N-GObject $type
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:free-instance:
=begin pod
=head2 free-instance

Frees an instance of a type, returning it to the instance pool for the type, if there is one.

Like C<create-instance()>, this function is reserved for implementors of fundamental types.

  method free-instance ( GTypeInstance $instance )

=item GTypeInstance $instance; an instance of a type
=end pod

method free-instance ( GTypeInstance $instance ) {

  g_type_free_instance(
    self._get-native-object-no-reffing, $instance
  );
}

sub g_type_free_instance (
  GTypeInstance $instance
) is native(&gobject-lib)
  { * }
}}

#-------------------------------------------------------------------------------
#TM:2:from-name:
=begin pod
=head2 from-name

Lookup the type ID from a given type name, returning 0 if no type has been registered under this name (this is the preferred method to find out by name whether a specific type has been registered yet).

Returns: corresponding type ID or 0

  method from-name ( Str $name --> UInt )

=item Str $name; type name to lookup
=end pod

method from-name ( Str $name --> UInt ) {
  g_type_from_name($name)
}

sub g_type_from_name (
  gchar-ptr $name --> GType
) is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
# TM:0:fundamental:
=begin pod
=head2 fundamental

Internal function, used to extract the fundamental type ID portion. Use C<G-TYPE-FUNDAMENTAL()> instead.

Returns: fundamental type ID

  method fundamental ( --> N-GObject )

=end pod

method fundamental ( --> N-GObject ) {

  g_type_fundamental(
    self._get-native-object-no-reffing,
  )
}

sub g_type_fundamental (
  N-GObject $type_id --> N-GObject
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:fundamental-next:
=begin pod
=head2 fundamental-next

Returns the next free fundamental type id which can be used to register a new fundamental type with C<register-fundamental()>. The returned type ID represents the highest currently registered fundamental type identifier.

Returns: the next available fundamental type ID to be registered, or 0 if the type system ran out of fundamental type IDs

  method fundamental-next ( --> N-GObject )

=end pod

method fundamental-next ( --> N-GObject ) {

  g_type_fundamental_next(
    self._get-native-object-no-reffing,
  )
}

sub g_type_fundamental_next (
   --> N-GObject
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:get-instance-count:
=begin pod
=head2 get-instance-count

Returns the number of instances allocated of the particular type; this is only available if GLib is built with debugging support and the instance-count debug flag is set (by setting the GOBJECT-DEBUG variable to include instance-count).

Returns: the number of instances allocated of the given type; if instance counts are not available, returns 0.

  method get-instance-count ( --> Int )

=end pod

method get-instance-count ( --> Int ) {

  g_type_get_instance_count(
    self._get-native-object-no-reffing,
  )
}

sub g_type_get_instance_count (
  N-GObject $type --> int
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:get-plugin:
=begin pod
=head2 get-plugin

Returns the B<Gnome::GObject::TypePlugin> structure for I<type>.

Returns: the corresponding plugin if I<type> is a dynamic type, C<undefined> otherwise

  method get-plugin ( --> N-GObject )

=end pod

method get-plugin ( --> N-GObject ) {

  g_type_get_plugin(
    self._get-native-object-no-reffing,
  )
}

sub g_type_get_plugin (
  N-GObject $type --> N-GObject
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:get-qdata:
=begin pod
=head2 get-qdata

Obtains data which has previously been attached to I<type> with C<set-qdata()>.

Note that this does not take subtyping into account; data attached to one type with C<g-type-set-qdata()> cannot be retrieved from a subtype using C<g-type-get-qdata()>.

Returns: the data, or C<undefined> if no data was found

  method get-qdata ( UInt $quark --> Pointer )

=item UInt $quark; a B<Gnome::GObject::Quark> id to identify the data
=end pod

method get-qdata ( UInt $quark --> Pointer ) {

  g_type_get_qdata(
    self._get-native-object-no-reffing, $quark
  )
}

sub g_type_get_qdata (
  N-GObject $type, GQuark $quark --> gpointer
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:get-type-registration-serial:
=begin pod
=head2 get-type-registration-serial

Returns an opaque serial number that represents the state of the set of registered types. Any time a type is registered this serial changes, which means you can cache information based on type lookups (such as C<from-name()>) and know if the cache is still valid at a later time by comparing the current serial with the one at the type lookup.

Returns: An unsigned int, representing the state of type registrations

  method get-type-registration-serial ( --> UInt )

=end pod

method get-type-registration-serial ( --> UInt ) {

  g_type_get_type_registration_serial(
    self._get-native-object-no-reffing,
  )
}

sub g_type_get_type_registration_serial (
   --> guint
) is native(&gobject-lib)
  { * }
}}

#-------------------------------------------------------------------------------
#TM:2:gtype-get-type:t/Value.t
=begin pod
=head2 gtype-get-type

Get dynamic type for a GTyped value. In C there is this name G_TYPE_GTYPE.

  method gtype_get_type ( --> UInt )

=end pod

method gtype-get-type ( --> UInt ) {
  g_gtype_get_type
}

sub g_gtype_get_type (  --> GType )
  is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
# TM:0:instance-get-private:
=begin pod
=head2 instance-get-private



  method instance-get-private ( GTypeInstance $instance, N-GObject $private_type --> Pointer )

=item GTypeInstance $instance;
=item N-GObject $private_type;
=end pod

method instance-get-private ( GTypeInstance $instance, $private_type is copy --> Pointer ) {
  $private_type .= _get-native-object-no-reffing unless $private_type ~~ N-GObject;

  g_type_instance_get_private(
    self._get-native-object-no-reffing, $instance, $private_type
  )
}

sub g_type_instance_get_private (
  GTypeInstance $instance, N-GObject $private_type --> gpointer
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:interface-add-prerequisite:
=begin pod
=head2 interface-add-prerequisite

Adds I<prerequisite-type> to the list of prerequisites of I<interface-type>. This means that any type implementing I<interface-type> must also implement I<prerequisite-type>. Prerequisites can be thought of as an alternative to interface derivation (which GType doesn't support). An interface can have at most one instantiatable prerequisite type.

  method interface-add-prerequisite ( N-GObject $prerequisite_type )

=item N-GObject $prerequisite_type; B<Gnome::GObject::Type> value of an interface or instantiatable type
=end pod

method interface-add-prerequisite ( $prerequisite_type is copy ) {
  $prerequisite_type .= _get-native-object-no-reffing unless $prerequisite_type ~~ N-GObject;

  g_type_interface_add_prerequisite(
    self._get-native-object-no-reffing, $prerequisite_type
  );
}

sub g_type_interface_add_prerequisite (
  N-GObject $interface_type, N-GObject $prerequisite_type
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:interface-get-plugin:
=begin pod
=head2 interface-get-plugin

Returns the B<Gnome::GObject::TypePlugin> structure for the dynamic interface I<interface-type> which has been added to I<instance-type>, or C<undefined> if I<interface-type> has not been added to I<instance-type> or does not have a B<Gnome::GObject::TypePlugin> structure. See C<add-interface-dynamic()>.

Returns: the B<Gnome::GObject::TypePlugin> for the dynamic interface I<interface-type> of I<instance-type>

  method interface-get-plugin ( N-GObject $interface_type --> N-GObject )

=item N-GObject $interface_type; B<Gnome::GObject::Type> of an interface type
=end pod

method interface-get-plugin ( $interface_type is copy --> N-GObject ) {
  $interface_type .= _get-native-object-no-reffing unless $interface_type ~~ N-GObject;

  g_type_interface_get_plugin(
    self._get-native-object-no-reffing, $interface_type
  )
}

sub g_type_interface_get_plugin (
  N-GObject $instance_type, N-GObject $interface_type --> N-GObject
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:interface-peek:
=begin pod
=head2 interface-peek

Returns the B<Gnome::GObject::TypeInterface> structure of an interface to which the passed in class conforms.

Returns: (type GObject.TypeInterface) : the B<Gnome::GObject::TypeInterface> structure of I<iface-type> if implemented by I<instance-class>, C<undefined> otherwise

  method interface-peek ( Pointer $instance_class, N-GObject $iface_type --> Pointer )

=item Pointer $instance_class; (type GObject.TypeClass): a B<Gnome::GObject::TypeClass> structure
=item N-GObject $iface_type; an interface ID which this class conforms to
=end pod

method interface-peek ( Pointer $instance_class, $iface_type is copy --> Pointer ) {
  $iface_type .= _get-native-object-no-reffing unless $iface_type ~~ N-GObject;

  g_type_interface_peek(
    self._get-native-object-no-reffing, $instance_class, $iface_type
  )
}

sub g_type_interface_peek (
  gpointer $instance_class, N-GObject $iface_type --> gpointer
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:interface-peek-parent:
=begin pod
=head2 interface-peek-parent

Returns the corresponding B<Gnome::GObject::TypeInterface> structure of the parent type of the instance type to which I<g-iface> belongs. This is useful when deriving the implementation of an interface from the parent type and then possibly overriding some methods.

Returns:  (type GObject.TypeInterface): the corresponding B<Gnome::GObject::TypeInterface> structure of the parent type of the instance type to which I<g-iface> belongs, or C<undefined> if the parent type doesn't conform to the interface

  method interface-peek-parent ( Pointer $g_iface --> Pointer )

=item Pointer $g_iface; (type GObject.TypeInterface): a B<Gnome::GObject::TypeInterface> structure
=end pod

method interface-peek-parent ( Pointer $g_iface --> Pointer ) {

  g_type_interface_peek_parent(
    self._get-native-object-no-reffing, $g_iface
  )
}

sub g_type_interface_peek_parent (
  gpointer $g_iface --> gpointer
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:interface-prerequisites:
=begin pod
=head2 interface-prerequisites

Returns the prerequisites of an interfaces type.

Returns: (array length=n-prerequisites) : a newly-allocated zero-terminated array of B<Gnome::GObject::Type> containing the prerequisites of I<interface-type>

  method interface-prerequisites ( guInt-ptr $n_prerequisites --> N-GObject )

=item guInt-ptr $n_prerequisites; location to return the number of prerequisites, or C<undefined>
=end pod

method interface-prerequisites ( guInt-ptr $n_prerequisites --> N-GObject ) {

  g_type_interface_prerequisites(
    self._get-native-object-no-reffing, $n_prerequisites
  )
}

sub g_type_interface_prerequisites (
  N-GObject $interface_type, gugint-ptr $n_prerequisites --> N-GObject
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:interfaces:
=begin pod
=head2 interfaces

Return a newly allocated and 0-terminated array of type IDs, listing the interface types that I<type> conforms to.

Returns: (array length=n-interfaces) : Newly allocated and 0-terminated array of interface types, free with C<g-free()>

  method interfaces ( guInt-ptr $n_interfaces --> N-GObject )

=item guInt-ptr $n_interfaces; location to store the length of the returned array, or C<undefined>
=end pod

method interfaces ( guInt-ptr $n_interfaces --> N-GObject ) {

  g_type_interfaces(
    self._get-native-object-no-reffing, $n_interfaces
  )
}

sub g_type_interfaces (
  N-GObject $type, gugint-ptr $n_interfaces --> N-GObject
) is native(&gobject-lib)
  { * }
}}

#-------------------------------------------------------------------------------
#TM:2:is-a:
=begin pod
=head2 is-a

If I<$is-a-gtype> is a derivable type, check whether I<$gtype> is a descendant of I<$is-a-gtype>. If I<$is-a-gtype> is an interface, check whether I<$gtype> conforms to it.

Returns: C<True> if I<$gtype> is a I<$is-a-gtype>

  method is-a ( UInt $gtype, UInt $is_a_gtype --> Bool )

=item UInt $is_a_gtype; possible anchestor of I<$gtype> or interface that I<$gtype> could conform to
=end pod

method is-a ( UInt $gtype, $is_a_type --> Bool ) {
  g_type_is_a( $gtype, $is_a_type).Bool
}

sub g_type_is_a (
  GType $type, GType $is_a_type --> gboolean
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:2:name:
=begin pod
=head2 name

Get the unique name that is assigned to a type ID. Note that this function (like all other GType API) cannot cope with invalid type IDs. C<G-TYPE-INVALID> may be passed to this function, as may be any other validly registered type ID, but randomized type IDs should not be passed in and will most likely lead to a crash.

Returns: static type name or C<undefined>

  method name ( UInt $gtype --> Str )

=end pod

method name ( UInt $gtype --> Str ) {
  g_type_name($gtype)
}

sub g_type_name (
  GType $type --> gchar-ptr
) is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
# TM:0:name-from-class:
=begin pod
=head2 name-from-class



  method name-from-class ( GTypeClass $g_class --> Str )

=item GTypeClass $g_class;
=end pod

method name-from-class ( GTypeClass $g_class --> Str ) {

  g_type_name_from_class(
    self._get-native-object-no-reffing, $g_class
  )
}

sub g_type_name_from_class (
  GTypeClass $g_class --> gchar-ptr
) is native(&gobject-lib)
  { * }
}}

#-------------------------------------------------------------------------------
#TM:2:name-from-instance:
=begin pod
=head2 name-from-instance

Get name of type from the instance.

  method name-from-instance ( N-GObject $instance --> Str )

=item N-GObject $instance;
=end pod

method name-from-instance ( N-GObject $instance --> Str ) {
  g_type_name_from_instance($instance)
}

sub g_type_name_from_instance (
  N-GObject $instance --> gchar-ptr
) is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
# TM:0:next-base:
=begin pod
=head2 next-base

Given a I<leaf-type> and a I<root-type> which is contained in its anchestry, return the type that I<root-type> is the immediate parent of. In other words, this function determines the type that is derived directly from I<root-type> which is also a base class of I<leaf-type>. Given a root type and a leaf type, this function can be used to determine the types and order in which the leaf type is descended from the root type.

Returns: immediate child of I<root-type> and anchestor of I<leaf-type>

  method next-base ( N-GObject $root_type --> N-GObject )

=item N-GObject $root_type; immediate parent of the returned type
=end pod

method next-base ( $root_type is copy --> N-GObject ) {
  $root_type .= _get-native-object-no-reffing unless $root_type ~~ N-GObject;

  g_type_next_base(
    self._get-native-object-no-reffing, $root_type
  )
}

sub g_type_next_base (
  N-GObject $leaf_type, N-GObject $root_type --> N-GObject
) is native(&gobject-lib)
  { * }
}}

#-------------------------------------------------------------------------------
#TM:2:parent:
=begin pod
=head2 parent

Return the direct parent type of the passed in type. If the passed in type has no parent, i.e. is a fundamental type, 0 is returned.

Returns: the parent type

  method parent ( UInt $parent-gtype --> UInt )

=end pod

method parent ( UInt $parent-gtype --> UInt ) {
  g_type_parent($parent-gtype)
}

sub g_type_parent (
  GType $type --> GType
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:2:qname:
=begin pod
=head2 qname

Get the corresponding quark of the type IDs name.

Returns: the type names quark or 0

  method qname ( UInt $gtype --> UInt )

=end pod

method qname ( UInt $gtype --> UInt ) {
  g_type_qname($gtype)
}

sub g_type_qname (
  GType $type --> GQuark
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:2:query:
=begin pod
=head2 query

Queries the type system for information about a specific type. This function will fill in a user-provided structure to hold type-specific information. If an invalid B<Gnome::GObject::Type> is passed in, the I<$type> member of the B<N-GTypeQuery> is 0. All members filled into the B<N-GTypeQuery> structure should be considered constant and have to be left untouched.

  method query ( UInt $gtype --> N-GTypeQuery )

=end pod

method query ( UInt $gtype --> N-GTypeQuery ) {
  my N-GTypeQuery $query .= new;
  g_type_query( $gtype, $query);

  $query
}

sub g_type_query (
  GType $gtype, N-GTypeQuery $query
) is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
# TM:0:register-dynamic:
=begin pod
=head2 register-dynamic

Registers I<type-name> as the name of a new dynamic type derived from I<parent-type>. The type system uses the information contained in the B<Gnome::GObject::TypePlugin> structure pointed to by I<plugin> to manage the type and its instances (if not abstract). The value of I<flags> determines the nature (e.g. abstract or not) of the type.

Returns: the new type identifier or B<Gnome::GObject::-TYPE-INVALID> if registration failed

  method register-dynamic ( Str $type_name, N-GObject $plugin, GTypeFlags $flags --> N-GObject )

=item Str $type_name; 0-terminated string used as the name of the new type
=item N-GObject $plugin; B<Gnome::GObject::TypePlugin> structure to retrieve the B<Gnome::GObject::TypeInfo> from
=item GTypeFlags $flags; bitwise combination of B<Gnome::GObject::TypeFlags> values
=end pod

method register-dynamic ( Str $type_name, $plugin is copy, GTypeFlags $flags --> N-GObject ) {
  $plugin .= _get-native-object-no-reffing unless $plugin ~~ N-GObject;

  g_type_register_dynamic(
    self._get-native-object-no-reffing, $type_name, $plugin, $flags
  )
}

sub g_type_register_dynamic (
  N-GObject $parent_type, gchar-ptr $type_name, N-GObject $plugin, GTypeFlags $flags --> N-GObject
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:register-fundamental:
=begin pod
=head2 register-fundamental

Registers I<type-id> as the predefined identifier and I<type-name> as the name of a fundamental type. If I<type-id> is already registered, or a type named I<type-name> is already registered, the behaviour is undefined. The type system uses the information contained in the B<Gnome::GObject::TypeInfo> structure pointed to by I<info> and the B<Gnome::GObject::TypeFundamentalInfo> structure pointed to by I<finfo> to manage the type and its instances. The value of I<flags> determines additional characteristics of the fundamental type.

Returns: the predefined type identifier

  method register-fundamental ( Str $type_name, GTypeInfo $info, GTypeFundamentalInfo $finfo, GTypeFlags $flags --> N-GObject )

=item Str $type_name; 0-terminated string used as the name of the new type
=item GTypeInfo $info; B<Gnome::GObject::TypeInfo> structure for this type
=item GTypeFundamentalInfo $finfo; B<Gnome::GObject::TypeFundamentalInfo> structure for this type
=item GTypeFlags $flags; bitwise combination of B<Gnome::GObject::TypeFlags> values
=end pod

method register-fundamental ( Str $type_name, GTypeInfo $info, GTypeFundamentalInfo $finfo, GTypeFlags $flags --> N-GObject ) {

  g_type_register_fundamental(
    self._get-native-object-no-reffing, $type_name, $info, $finfo, $flags
  )
}

sub g_type_register_fundamental (
  N-GObject $type_id, gchar-ptr $type_name, GTypeInfo $info, GTypeFundamentalInfo $finfo, GTypeFlags $flags --> N-GObject
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:register-static:
=begin pod
=head2 register-static

Registers I<type-name> as the name of a new static type derived from I<parent-type>. The type system uses the information contained in the B<Gnome::GObject::TypeInfo> structure pointed to by I<info> to manage the type and its instances (if not abstract). The value of I<flags> determines the nature (e.g. abstract or not) of the type.

Returns: the new type identifier

  method register-static ( Str $type_name, GTypeInfo $info, GTypeFlags $flags --> N-GObject )

=item Str $type_name; 0-terminated string used as the name of the new type
=item GTypeInfo $info; B<Gnome::GObject::TypeInfo> structure for this type
=item GTypeFlags $flags; bitwise combination of B<Gnome::GObject::TypeFlags> values
=end pod

method register-static ( Str $type_name, GTypeInfo $info, GTypeFlags $flags --> N-GObject ) {

  g_type_register_static(
    self._get-native-object-no-reffing, $type_name, $info, $flags
  )
}

sub g_type_register_static (
  N-GObject $parent_type, gchar-ptr $type_name, GTypeInfo $info, GTypeFlags $flags --> N-GObject
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:register-static-simple:
=begin pod
=head2 register-static-simple

Registers I<type-name> as the name of a new static type derived from I<parent-type>. The value of I<flags> determines the nature (e.g. abstract or not) of the type. It works by filling a B<Gnome::GObject::TypeInfo> struct and calling C<register-static()>.

Returns: the new type identifier

  method register-static-simple ( Str $type_name, UInt $class_size, GClassInitFunc $class_init, UInt $instance_size, GInstanceInitFunc $instance_init, GTypeFlags $flags --> N-GObject )

=item Str $type_name; 0-terminated string used as the name of the new type
=item UInt $class_size; size of the class structure (see B<Gnome::GObject::TypeInfo>)
=item GClassInitFunc $class_init; location of the class initialization function (see B<Gnome::GObject::TypeInfo>)
=item UInt $instance_size; size of the instance structure (see B<Gnome::GObject::TypeInfo>)
=item GInstanceInitFunc $instance_init; location of the instance initialization function (see B<Gnome::GObject::TypeInfo>)
=item GTypeFlags $flags; bitwise combination of B<Gnome::GObject::TypeFlags> values
=end pod

method register-static-simple ( Str $type_name, UInt $class_size, GClassInitFunc $class_init, UInt $instance_size, GInstanceInitFunc $instance_init, GTypeFlags $flags --> N-GObject ) {

  g_type_register_static_simple(
    self._get-native-object-no-reffing, $type_name, $class_size, $class_init, $instance_size, $instance_init, $flags
  )
}

sub g_type_register_static_simple (
  N-GObject $parent_type, gchar-ptr $type_name, guint $class_size, GClassInitFunc $class_init, guint $instance_size, GInstanceInitFunc $instance_init, GTypeFlags $flags --> N-GObject
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:remove-class-cache-func:
=begin pod
=head2 remove-class-cache-func

Removes a previously installed B<Gnome::GObject::TypeClassCacheFunc>. The cache maintained by I<cache-func> has to be empty when calling C<remove-class-cache-func()> to avoid leaks.

  method remove-class-cache-func ( Pointer $cache_data, GTypeClassCacheFunc $cache_func )

=item Pointer $cache_data; data that was given when adding I<cache-func>
=item GTypeClassCacheFunc $cache_func; a B<Gnome::GObject::TypeClassCacheFunc>
=end pod

method remove-class-cache-func ( Pointer $cache_data, GTypeClassCacheFunc $cache_func ) {

  g_type_remove_class_cache_func(
    self._get-native-object-no-reffing, $cache_data, $cache_func
  );
}

sub g_type_remove_class_cache_func (
  gpointer $cache_data, GTypeClassCacheFunc $cache_func
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:remove-interface-check:
=begin pod
=head2 remove-interface-check

Removes an interface check function added with C<add-interface-check()>.

  method remove-interface-check ( Pointer $check_data, GTypeInterfaceCheckFunc $check_func )

=item Pointer $check_data; callback data passed to C<add-interface-check()>
=item GTypeInterfaceCheckFunc $check_func; callback function passed to C<add-interface-check()>
=end pod

method remove-interface-check ( Pointer $check_data, GTypeInterfaceCheckFunc $check_func ) {

  g_type_remove_interface_check(
    self._get-native-object-no-reffing, $check_data, $check_func
  );
}

sub g_type_remove_interface_check (
  gpointer $check_data, GTypeInterfaceCheckFunc $check_func
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:set-qdata:
=begin pod
=head2 set-qdata

Attaches arbitrary data to a type.

  method set-qdata ( UInt $quark, Pointer $data )

=item UInt $quark; a B<Gnome::GObject::Quark> id to identify the data
=item Pointer $data; the data
=end pod

method set-qdata ( UInt $quark, Pointer $data ) {

  g_type_set_qdata(
    self._get-native-object-no-reffing, $quark, $data
  );
}

sub g_type_set_qdata (
  N-GObject $type, GQuark $quark, gpointer $data
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:value-table-peek:
=begin pod
=head2 value-table-peek

Returns the location of the B<Gnome::GObject::TypeValueTable> associated with I<type>.

Note that this function should only be used from source code that implements or has internal knowledge of the implementation of I<type>.

Returns: location of the B<Gnome::GObject::TypeValueTable> associated with I<type> or C<undefined> if there is no B<Gnome::GObject::TypeValueTable> associated with I<type>

  method value-table-peek ( --> GTypeValueTable )

=end pod

method value-table-peek ( --> GTypeValueTable ) {

  g_type_value_table_peek(
    self._get-native-object-no-reffing,
  )
}

sub g_type_value_table_peek (
  N-GObject $type --> GTypeValueTable
) is native(&gobject-lib)
  { * }
}}












































=finish
#-------------------------------------------------------------------------------
#TM:2:g_type_name:xt/Type.t
=begin pod
=head2 [g_] type_name

Get the unique name that is assigned to a type ID. Note that this function (like all other GType API) cannot cope with invalid type IDs. C<G_TYPE_INVALID> may be passed to this function, as may be any other validly registered type ID, but randomized type IDs should not be passed in and will most likely lead to a crash.

Returns: static type name or undefined

  method g_type_name ( UInt $gtype --> Str )

=end pod

sub g_type_name ( GType $type --> Str )
  is native(&gobject-lib)
  { * }

#`{{
}}
#-------------------------------------------------------------------------------
#TM:2:g_type_qname:xt/Type.t
=begin pod
=head2 [g_] type_qname

Get the corresponding quark of the type IDs name.

Returns: the type names quark or 0

  method g_type_qname ( UInt $gtype --> UInt  )

=end pod

sub g_type_qname ( GType $type --> GQuark )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:2:g_type_from_name:xt/Type.t
=begin pod
=head2 [[g_] type_] from_name

Lookup the type ID from a given type name, returning 0 if no type has been registered under this name (this is the preferred method to find out by name whether a specific type has been registered yet).

Returns: corresponding type ID or 0

  method g_type_from_name ( Str $name --> UInt )

=item Str $name; type name to lookup

=end pod

sub g_type_from_name ( Str $name --> GType )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:2:g_type_parent:xt/Type.t
=begin pod
=head2 [g_] type_parent

Return the direct parent type of the passed in type. If the passed in type has no parent, i.e. is a fundamental type, 0 is returned.

Returns: the parent type

  method g_type_parent ( UInt $parent-type --> UInt )

=end pod

sub g_type_parent ( GType $type --> GType )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:2:g_type_depth:xt/Type.t
=begin pod
=head2 [g_] type_depth

Returns the length of the ancestry of the passed in type. This includes the type itself, so that e.g. a fundamental type has depth 1.

Returns: the depth of I<$type>

  method g_type_depth ( UInt $type --> UInt  )


=end pod

sub g_type_depth ( GType $type --> guint )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:2:g_type_is_a:xt/Type.t
=begin pod
=head2 [[g_] type_] is_a

If I<$is_a_type> is a derivable type, check whether I<$type> is a descendant of I<$is_a_type>. If I<$is_a_type> is an interface, check whether I<$type> conforms to it.

Returns: C<1> if I<$type> is a I<$is_a_type>.

  method g_type_is_a ( UInt $type, UInt $is_a_type --> Int )

=item UInt $is_a_type; possible anchestor of I<$type> or interface that I<$type> could conform to.

=end pod

sub g_type_is_a ( GType $type, GType $is_a_type --> gboolean )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:2:g_type_query:xt/Type.t
=begin pod
=head2 [g_] type_query

Queries the type system for information about a specific type. This function will fill in a user-provided structure to hold type-specific information. If an invalid I<GType> is passed in, the I<$type> member of the I<N-GTypeQuery> is 0. All members filled into the I<N-GTypeQuery> structure should be considered constant and have to be left untouched.

  method g_type_query ( int32 $type --> N-GTypeQuery )

=item N-GTypeQuery $query; a structure that is filled in with constant values upon success

=end pod

sub g_type_query ( GType $type --> N-GTypeQuery ) {
  my N-GTypeQuery $query .= new;
  _g_type_query( $type, $query);

  $query
}

sub _g_type_query ( GType $type, N-GTypeQuery $query is rw )
  is native(&gobject-lib)
  is symbol('g_type_query')
  { * }

#-------------------------------------------------------------------------------
#TM:2:g_type_check_instance_cast:xt/Type.t
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

sub g_type_check_instance_cast ( N-GObject $instance, GType $iface_type --> N-GObject )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:2:g_type_check_instance_is_a:xt/Type.t
=begin pod
=head2 [[g_] type_] check_instance_is_a

  method g_type_check_instance_is_a (
    N-GObject $instance, UInt $iface_type --> Int
  )

=item N-GObject $instance; the native object to check.
=item UInt $iface_type; the gtype the instance is inheriting from.

=end pod

sub g_type_check_instance_is_a (
  N-GObject $instance, GType $iface_type --> int32
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:6:g_type_name_from_instance:Gnome::Gtk3::Builder
=begin pod
=head2 [[g_] type_] name_from_instance

Get name of type from the instance.

  method g_type_name_from_instance ( N-GObject $instance --> Str  )

=item int32 $instance;

Returns the name of the instance.

=end pod

sub g_type_name_from_instance ( N-GObject $instance --> Str )
  is native(&gobject-lib)
  { * }


#-------------------------------------------------------------------------------
#TM:2:g_gtype_get_type:t/Value.t
=begin pod
=head2 [g_] gtype_get_type

Get dynamic type for a GTyped value. In C there is this name G_TYPE_GTYPE.

  method g_gtype_get_type ( --> UInt  )

=end pod

sub g_gtype_get_type (  --> GType )
  is native(&gobject-lib)
  { * }





=finish

#-------------------------------------------------------------------------------
#--[ Unused code of subs ]------------------------------------------------------
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# TM:0:g_type_name_from_class:
=begin pod
=head2 [[g_] type_] name_from_class



  method g_type_name_from_class ( int32 $g_class --> Str  )

=item int32 $g_class;

=end pod

sub g_type_name_from_class ( int32 $g_class --> Str )
  is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
# TM:0:g_type_check_instance_is_fundamentally_a:
=begin pod
=head2 [[g_] type_] check_instance_is_fundamentally_a



  method g_type_check_instance_is_fundamentally_a ( int32 $instance, int32 $fundamental_type --> Int  )

=item int32 $instance;
=item int32 $fundamental_type;

=end pod

sub g_type_check_instance_is_fundamentally_a ( int32 $instance, int32 $fundamental_type --> int32 )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_type_check_class_cast:
=begin pod
=head2 [[g_] type_] check_class_cast



  method g_type_check_class_cast ( int32 $g_class, int32 $is_a_type --> int32  )

=item int32 $g_class;
=item int32 $is_a_type;

=end pod

sub g_type_check_class_cast ( int32 $g_class, int32 $is_a_type --> int32 )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_type_check_class_is_a:
=begin pod
=head2 [[g_] type_] check_class_is_a



  method g_type_check_class_is_a ( int32 $g_class, int32 $is_a_type --> Int  )

=item int32 $g_class;
=item int32 $is_a_type;

=end pod

sub g_type_check_class_is_a ( int32 $g_class, int32 $is_a_type --> int32 )
  is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
# TM:0:g_type_check_value:
=begin pod
=head2 [[g_] type_] check_value

Checks if value has been initialized to hold values of type g_type.

  method g_type_check_value ( N-GObject $value --> Int  )

=item N-GObject $value;

=end pod

sub g_type_check_value ( N-GObject $value --> int32 )
  is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
# TM:0:g_type_check_value_holds:
=begin pod
=head2 [[g_] type_] check_value_holds



  method g_type_check_value_holds ( N-GObject $value, int32 $type --> Int  )

=item N-GObject $value;
=item int32 $type;

=end pod

sub g_type_check_value_holds ( N-GObject $value, int32 $type --> int32 )
  is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
# TM:0:g_type_get_instance_count:
=begin pod
=head2 [[g_] type_] get_instance_count

Returns the number of instances allocated of the particular type;
this is only available if GLib is built with debugging support and
the instance_count debug flag is set (by setting the GOBJECT_DEBUG
variable to include instance-count).

Returns: the number of instances allocated of the given type;
if instance counts are not available, returns 0.

  method g_type_get_instance_count ( --> int32  )


=end pod

sub g_type_get_instance_count ( int32 $type --> int32 )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_type_register_static:
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

sub g_type_register_static ( int32 $parent_type, Str $type_name, int32 $info, int32 $flags --> int32 )
  is native(&gobject-lib)
  { * }
}}
#`{{
#-------------------------------------------------------------------------------
# TM:0:g_type_register_static_simple:
=begin pod
=head2 [[g_] type_] register_static_simple

Registers I<type_name> as the name of a new static type derived from
I<parent_type>.  The value of I<flags> determines the nature (e.g.
abstract or not) of the type. It works by filling a I<GTypeInfo>
struct and calling C<g_type_register_static()>.

Returns: the new type identifier

  method g_type_register_static_simple ( Str $type_name, UInt $class_size, GClassInitFunc $class_init, UInt $instance_size, GInstanceInitFunc $instance_init, int32 $flags --> int32  )

=item Str $type_name; 0-terminated string used as the name of the new type
=item UInt $class_size; size of the class structure (see I<GTypeInfo>)
=item GClassInitFunc $class_init; location of the class initialization function (see I<GTypeInfo>)
=item UInt $instance_size; size of the instance structure (see I<GTypeInfo>)
=item GInstanceInitFunc $instance_init; location of the instance initialization function (see I<GTypeInfo>)
=item int32 $flags; bitwise combination of I<GTypeFlags> values

=end pod

sub g_type_register_static_simple ( int32 $parent_type, Str $type_name, uint32 $class_size, GClassInitFunc $class_init, uint32 $instance_size, GInstanceInitFunc $instance_init, int32 $flags --> int32 )
  is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
# TM:0:g_type_register_dynamic:
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

sub g_type_register_dynamic ( int32 $parent_type, Str $type_name, int32 $plugin, int32 $flags --> int32 )
  is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
# TM:0:g_type_register_fundamental:
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

sub g_type_register_fundamental ( int32 $type_id, Str $type_name, int32 $info, int32 $finfo, int32 $flags --> int32 )
  is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
# TM:0:g_type_add_interface_static:
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
# TM:0:g_type_add_interface_dynamic:
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
# TM:0:g_type_interface_add_prerequisite:
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
# TM:0:g_type_interface_prerequisites:
=begin pod
=head2 [[g_] type_] interface_prerequisites

Returns the prerequisites of an interfaces type.

Returns: (array length=n_prerequisites) (transfer full): a
newly-allocated zero-terminated array of I<GType> containing
the prerequisites of I<interface_type>

  method g_type_interface_prerequisites ( UInt $n_prerequisites --> int32  )

=item UInt $n_prerequisites; (out) (optional): location to return the number of prerequisites, or C<Any>

=end pod

sub g_type_interface_prerequisites ( int32 $interface_type, uint32 $n_prerequisites --> int32 )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_type_add_instance_private:
=begin pod
=head2 [[g_] type_] add_instance_private



  method g_type_add_instance_private ( UInt $private_size --> Int  )

=item UInt $private_size;

=end pod

sub g_type_add_instance_private ( int32 $class_type, uint64 $private_size --> int32 )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_type_instance_get_private:
=begin pod
=head2 [[g_] type_] instance_get_private



  method g_type_instance_get_private ( int32 $instance, int32 $private_type --> Pointer  )

=item int32 $instance;
=item int32 $private_type;

=end pod

sub g_type_instance_get_private ( int32 $instance, int32 $private_type --> Pointer )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_type_class_adjust_private_offset:
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
# TM:0:g_type_add_class_private:
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

  method g_type_add_class_private ( UInt $private_size )

=item UInt $private_size; size of private structure

=end pod

sub g_type_add_class_private ( int32 $class_type, uint64 $private_size )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_type_class_get_private:
=begin pod
=head2 [[g_] type_] class_get_private



  method g_type_class_get_private ( int32 $klass, int32 $private_type --> Pointer  )

=item int32 $klass;
=item int32 $private_type;

=end pod

sub g_type_class_get_private ( int32 $klass, int32 $private_type --> Pointer )
  is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
# TM:0:g_type_class_get_instance_private_offset:
=begin pod
=head2 [[g_] type_] class_get_instance_private_offset

Gets the offset of the private data for instances of I<g_class>.

This is how many bytes you should add to the instance pointer of a
class in order to get the private data for the type represented by
I<g_class>.

You can only call this function after you have registered a private
data area for I<g_class> using C<g_type_class_add_private()>.

Returns: the offset, in bytes

  method g_type_class_get_instance_private_offset ( Pointer $g_class --> Int  )

=item Pointer $g_class; (type GObject.TypeClass): a I<N-GTypeClass>

=end pod

sub g_type_class_get_instance_private_offset ( Pointer $g_class --> int32 )
  is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
# TM:0:g_type_ensure:
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

  method g_type_ensure ( )


=end pod

sub g_type_ensure ( int32 $type )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_type_get_type_registration_serial:
=begin pod
=head2 [[g_] type_] get_type_registration_serial

Returns an opaque serial number that represents the state of the set
of registered types. Any time a type is registered this serial changes,
which means you can cache information based on type lookups (such as
C<g_type_from_name()>) and know if the cache is still valid at a later
time by comparing the current serial with the one at the type lookup.

Returns: An unsigned int, representing the state of type registrations

  method g_type_get_type_registration_serial ( --> UInt  )


=end pod

sub g_type_get_type_registration_serial (  --> uint32 )
  is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
# TM:0:g_type_get_plugin:
=begin pod
=head2 [[g_] type_] get_plugin

Returns the I<GTypePlugin> structure for I<type>.

Returns: (transfer none): the corresponding plugin
if I<type> is a dynamic type, C<Any> otherwise

  method g_type_get_plugin ( --> int32  )


=end pod

sub g_type_get_plugin ( int32 $type --> int32 )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_type_interface_get_plugin:
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

sub g_type_interface_get_plugin ( int32 $instance_type, int32 $interface_type --> int32 )
  is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
# TM:0:g_type_fundamental_next:
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

sub g_type_fundamental_next (  --> int32 )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_type_fundamental:
=begin pod
=head2 [g_] type_fundamental

Internal function, used to extract the fundamental type ID portion.
Use C<G_TYPE_FUNDAMENTAL()> instead.

Returns: fundamental type ID

  method g_type_fundamental ( --> int32  )


=end pod

sub g_type_fundamental ( int32 $type_id --> int32 )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_type_create_instance:
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

sub g_type_create_instance ( int32 $type --> int32 )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_type_free_instance:
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
# TM:0:g_type_add_class_cache_func:
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
# TM:0:g_type_remove_class_cache_func:
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
}}

#`{{
#-------------------------------------------------------------------------------
# TM:0:g_type_class_unref_uncached:
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
}}

#`{{
#-------------------------------------------------------------------------------
# TM:0:g_type_add_interface_check:
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

  method g_type_add_interface_check ( Pointer $check_data, int32 $check_func )

=item Pointer $check_data; data to pass to I<check_func>
=item int32 $check_func; function to be called after each interface is initialized

=end pod

sub g_type_add_interface_check ( Pointer $check_data, int32 $check_func )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_type_remove_interface_check:
=begin pod
=head2 [[g_] type_] remove_interface_check

Removes an interface check function added with
C<g_type_add_interface_check()>.

  method g_type_remove_interface_check ( Pointer $check_data, int32 $check_func )

=item Pointer $check_data; callback data passed to C<g_type_add_interface_check()>
=item int32 $check_func; callback function passed to C<g_type_add_interface_check()>

=end pod

sub g_type_remove_interface_check ( Pointer $check_data, int32 $check_func )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_type_value_table_peek:
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

sub g_type_value_table_peek ( int32 $type --> int32 )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_type_check_instance:
=begin pod
=head2 [[g_] type_] check_instance

Private helper function to aid implementation of the
C<G_TYPE_CHECK_INSTANCE()> macro.

Returns: C<1> if I<instance> is valid, C<0> otherwise

  method g_type_check_instance ( N-GTypeInstance $instance --> Int  )

=item N-GTypeInstance $instance; a valid I<GN-TypeInstance> structure

=end pod

sub g_type_check_instance ( N-GTypeInstance $instance --> int32 )
  is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
# TM:0:g_type_class_ref:
=begin pod
=head2 [[g_] type_] class_ref

Increments the reference count of the class structure belonging to
I<type>. This function will demand-create the class if it doesn't
exist already.

Returns: (type GObject.TypeClass) (transfer none): the I<N-GTypeClass>
structure for the given type ID

  method g_type_class_ref ( --> Pointer  )


=end pod

sub g_type_class_ref ( int32 $type --> Pointer )
  is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
# TM:0:g_type_class_peek:
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

sub g_type_class_peek ( int32 $type --> Pointer )
  is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
# TM:0:g_type_class_peek_static:
=begin pod
=head2 [[g_] type_] class_peek_static

A more efficient version of C<g_type_class_peek()> which works only for
static types.

Returns: (type GObject.TypeClass) (transfer none): the I<N-GTypeClass>
structure for the given type ID or C<Any> if the class does not
currently exist or is dynamically loaded

  method g_type_class_peek_static ( --> Pointer  )


=end pod

sub g_type_class_peek_static ( int32 $type --> Pointer )
  is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
# TM:0:g_type_class_unref:
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
}}

#`{{
#-------------------------------------------------------------------------------
# TM:0:g_type_class_peek_parent:
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

sub g_type_class_peek_parent ( Pointer $g_class --> Pointer )
  is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
# TM:0:g_type_interface_peek:
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

sub g_type_interface_peek ( Pointer $instance_class, int32 $iface_type --> Pointer )
  is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
# TM:0:g_type_interface_peek_parent:
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

sub g_type_interface_peek_parent ( Pointer $g_iface --> Pointer )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_type_default_interface_ref:
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

Returns: (type GObject.TypeInterface) (transfer none): the default
vtable for the interface; call C<g_type_default_interface_unref()>
when you are done using the interface.

  method g_type_default_interface_ref ( --> Pointer  )


=end pod

sub g_type_default_interface_ref ( int32 $g_type --> Pointer )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_type_default_interface_peek:
=begin pod
=head2 [[g_] type_] default_interface_peek

If the interface type I<g_type> is currently in use, returns its
default interface vtable.

Returns: (type GObject.TypeInterface) (transfer none): the default
vtable for the interface, or C<Any> if the type is not currently
in use

  method g_type_default_interface_peek ( --> Pointer  )


=end pod

sub g_type_default_interface_peek ( int32 $g_type --> Pointer )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_type_default_interface_unref:
=begin pod
=head2 [[g_] type_] default_interface_unref

Decrements the reference count for the type corresponding to the
interface default vtable I<g_iface>. If the type is dynamic, then
when no one is using the interface and all references have
been released, the finalize function for the interface's default
vtable (the I<class_finalize> member of I<GTypeInfo>) will be called.

  method g_type_default_interface_unref ( Pointer $g_iface )

=item Pointer $g_iface; (type GObject.TypeInterface): the default vtable structure for a interface, as returned by C<g_type_default_interface_ref()>

=end pod

sub g_type_default_interface_unref ( Pointer $g_iface )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_type_children:
=begin pod
=head2 [g_] type_children

Return a newly allocated and 0-terminated array of type IDs, listing
the child types of I<type>.

Returns: (array length=n_children) (transfer full): Newly allocated
and 0-terminated array of child types, free with C<g_free()>

  method g_type_children ( UInt $n_children --> int32  )

=item UInt $n_children; (out) (optional): location to store the length of the returned array, or C<Any>

=end pod

sub g_type_children ( int32 $type, uint32 $n_children --> int32 )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_type_interfaces:
=begin pod
=head2 [g_] type_interfaces

Return a newly allocated and 0-terminated array of type IDs, listing
the interface types that I<type> conforms to.

Returns: (array length=n_interfaces) (transfer full): Newly allocated
and 0-terminated array of interface types, free with C<g_free()>

  method g_type_interfaces ( UInt $n_interfaces --> int32  )

=item UInt $n_interfaces; (out) (optional): location to store the length of the returned array, or C<Any>

=end pod

sub g_type_interfaces ( int32 $type, uint32 $n_interfaces --> int32 )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:g_type_set_qdata:
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
# TM:0:g_type_get_qdata:
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

sub g_type_get_qdata ( int32 $type, int32 $quark --> Pointer )
  is native(&gobject-lib)
  { * }
}}


#`{{
#-------------------------------------------------------------------------------
# TM:0:g_type_next_base:
=begin pod
=head2 [[g_] type_] next_base

Given a I<$leaf_type> and a I<$root_type> which is contained in its anchestry, return the type that I<$root_type> is the immediate parent of. In other words, this function determines the type that is derived directly from I<$root_type> which is also a base class of I<$leaf_type>. Given a root type and a leaf type, this function can be used to determine the types and order in which the leaf type is descended from the root type.

Returns: immediate child of I<$root_type> and anchestor of I<$leaf_type>

  method g_type_next_base ( Int $root_type --> UInt )

=item int32 $root_type; immediate parent of the returned type

=end pod

sub g_type_next_base ( ulong $leaf_type, ulong $root_type --> ulong )
  is native(&gobject-lib)
  { * }
}}
