use v6;
#-------------------------------------------------------------------------------
=begin pod

=head1 Gnome::GObject::Boxed

A mechanism to wrap opaque C structures registered by the type system

=head1 Description

GBoxed is a generic wrapper mechanism for arbitrary C structures. The only thing the type system needs to know about the structures is how to copy and  free them, beyond that they are treated as opaque chunks of memory.

Boxed types are useful for simple value-holder structures like rectangles or points. They can also be used for wrapping structures defined in non-GObject based libraries.

=begin comment
Boxed types are useful for simple value-holder structures like rectangles or points. They can also be used for wrapping structures defined in non-GObject based libraries. They allow arbitrary structures to be handled in a uniform way, allowing uniform copying (or referencing) and freeing (or unreferencing) of them, and uniform representation of the type of the contained structure. In turn, this allows any type which can be boxed to be set as the data in a GValue, which allows for polymorphic handling of a much wider range of data types, and hence usage of such types as GObject property values.

GBoxed is designed so that reference counted types can be boxed. Use the type’s ‘ref’ function as the GBoxedCopyFunc, and its ‘unref’ function as the GBoxedFreeFunc. For example, for GBytes, the GBoxedCopyFunc is g_bytes_ref(), and the GBoxedFreeFunc is g_bytes_unref().
=end comment

=head1 Synopsis
=head2 Declaration

  unit class Gnome::GObject::Boxed:auth<github:MARTIMM>;
  also is Gnome::N::TopLevelClassSupport;


=head2 Uml Diagram

![](plantuml/Boxed.svg)


=comment head2 Example

=end pod
#-------------------------------------------------------------------------------
use NativeCall;

use Gnome::N::X;
use Gnome::N::NativeLib;
#use Gnome::N::N-GObject;
use Gnome::N::TopLevelClassSupport;

#-------------------------------------------------------------------------------
# See /usr/include/glib-2.0/glib/gboxed.h
# https://developer.gnome.org/gobject/stable/gobject-Boxed-Types.html
unit class Gnome::GObject::Boxed:auth<github:MARTIMM>;
also is Gnome::N::TopLevelClassSupport;

#-------------------------------------------------------------------------------
# no pod. user does not have to know about it.
method _fallback ( $native-sub is copy --> Callable ) {

  my Callable $s;
  try { $s = &::("g_boxed_$native-sub"); };
  try { $s = &::("g_$native-sub"); } unless ?$s;
  try { $s = &::($native-sub); } if !$s and $native-sub ~~ m/^ 'g_' /;

#  self._set-class-name-of-sub('GBoxed');
#  $s = callsame unless ?$s;

  $s;
}

#-------------------------------------------------------------------------------
#TODO destroy when overwritten?
method native-gboxed ( Any:D $g-boxed --> Any ) {

  Gnome::N::deprecate(
    '.native-gboxed()', '.set-native-object()', '0.15.10', '0.18.0'
  );

  #$!n-native-object = $g-boxed;
  #$!n-native-object
  self.set-native-object($g-boxed);
  $g-boxed
}

#-------------------------------------------------------------------------------
method get-native-gboxed ( --> Any ) {

  Gnome::N::deprecate(
    '.get-native-gboxed()', '.get-native-object()', '0.15.10', '0.18.0'
  );

  #$!n-native-object
  self.get-native-object
}






=finish

#`{{
#-------------------------------------------------------------------------------
#TM:0:g_boxed_copy:
=begin pod
=head2 g_boxed_copy

Provide a copy of a boxed structure I<src_boxed> which is of type I<boxed_type>.

Returns: (transfer full) (not nullable): The newly created copy of the boxed
structure.

  method g_boxed_copy ( UInt $boxed_type, Pointer $src_boxed --> Pointer )

=item UInt $boxed_type; The type of I<src_boxed>.
=item Pointer $src_boxed; (not nullable): The boxed structure to be copied.

=end pod

sub g_boxed_copy ( uint64 $boxed_type, Pointer $src_boxed --> Pointer )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_boxed_free:
=begin pod
=head2 g_boxed_free

Free the boxed structure I<boxed> which is of type I<boxed_type>.

  method g_boxed_free ( UInt $boxed_type, Pointer $boxed )

=item UInt $boxed_type; The type of I<boxed>.
=item Pointer $boxed; (not nullable): The boxed structure to be freed.

=end pod

sub g_boxed_free ( uint64 $boxed_type, Pointer $boxed  )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_set_boxed:
=begin pod
=head2 g_value_set_boxed

Set the contents of a C<G_TYPE_BOXED> derived B<GValue> to I<v_boxed>.

  method g_value_set_boxed ( N-GObject $value, Pointer $v_boxed )

=item N-GObject $value; a valid B<GValue> of C<G_TYPE_BOXED> derived type
=item Pointer $v_boxed; (nullable): boxed value to be set

=end pod

sub g_value_set_boxed ( N-GObject $value, Pointer $v_boxed  )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_set_static_boxed:
=begin pod
=head2 g_value_set_static_boxed

Set the contents of a C<G_TYPE_BOXED> derived B<GValue> to I<v_boxed>.
The boxed value is assumed to be static, and is thus not duplicated
when setting the B<GValue>.

  method g_value_set_static_boxed ( N-GObject $value, Pointer $v_boxed )

=item N-GObject $value; a valid B<GValue> of C<G_TYPE_BOXED> derived type
=item Pointer $v_boxed; (nullable): static boxed value to be set

=end pod

sub g_value_set_static_boxed ( N-GObject $value, Pointer $v_boxed  )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_take_boxed:
=begin pod
=head2 g_value_take_boxed

Sets the contents of a C<G_TYPE_BOXED> derived B<GValue> to I<v_boxed>
and takes over the ownership of the callers reference to I<v_boxed>;
the caller doesn't have to unref it any more.

Since: 2.4

  method g_value_take_boxed ( N-GObject $value, Pointer $v_boxed )

=item N-GObject $value; a valid B<GValue> of C<G_TYPE_BOXED> derived type
=item Pointer $v_boxed; (nullable): duplicated unowned boxed value to be set

=end pod

sub g_value_take_boxed ( N-GObject $value, Pointer $v_boxed  )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_get_boxed:
=begin pod
=head2 g_value_get_boxed

Get the contents of a C<G_TYPE_BOXED> derived B<GValue>.

Returns: (transfer none): boxed contents of I<value>

  method g_value_get_boxed ( N-GObject $value --> Pointer )

=item N-GObject $value; a valid B<GValue> of C<G_TYPE_BOXED> derived type

=end pod

sub g_value_get_boxed ( N-GObject $value --> Pointer )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_dup_boxed:
=begin pod
=head2 g_value_dup_boxed

Get the contents of a C<G_TYPE_BOXED> derived B<GValue>.  Upon getting,
the boxed value is duplicated and needs to be later freed with
C<g_boxed_free()>, e.g. like: g_boxed_free (G_VALUE_TYPE (I<value>),
return_value);

Returns: boxed contents of I<value>

  method g_value_dup_boxed ( N-GObject $value --> Pointer )

=item N-GObject $value; a valid B<GValue> of C<G_TYPE_BOXED> derived type

=end pod

sub g_value_dup_boxed ( N-GObject $value --> Pointer )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_boxed_type_register_static:
=begin pod
=head2 [g_boxed_] type_register_static

This function creates a new C<G_TY✓PE_BOXED> derived type id for a new
boxed type with name I<name>. Boxed type handling functions have to be
provided to copy and free opaque boxed structures of this type.

Returns: New C<G_TYPE_BOXED> derived type id for I<name>.

  method g_boxed_type_register_static ( Str $name, GBoxedCopyFunc $boxed_copy, GBoxedFreeFunc $boxed_free --> UInt )

=item Str $name; Name of the new boxed type.
=item GBoxedCopyFunc $boxed_copy; Boxed structure copy function.
=item GBoxedFreeFunc $boxed_free; Boxed structure free function.

=end pod

sub g_boxed_type_register_static ( Str $name, GBoxedCopyFunc $boxed_copy, GBoxedFreeFunc $boxed_free --> uint64 )
  is native(&gobject-lib)
  { * }
}}
