#TL:1:Gnome::GObject::Object:

use v6;
#-------------------------------------------------------------------------------
=begin pod

=head1 Gnome::GObject::Object

The base object type

=head1 Description

Gnome::GObject::Object is the fundamental type providing the common attributes and methods for all object types in GTK+, Pango and other libraries based on GObject. The GObject class provides methods for object construction and destruction, property access methods, and signal support.


=begin comment
Signals are described in detail L<here|https://developer.gnome.org/gobject/stable/signal.html>.

For a tutorial on implementing a new GObject class, see [How to define and
implement a new GObject][howto-gobject]. For a list of naming conventions for
GObjects and their methods, see the [GType conventions][gtype-conventions].
For the high-level concepts behind GObject, read [Instantiable classed types:
Objects][gtype-instantiable-classed].

=head2 Floating references

B<Gnome::GObject::InitiallyUnowned> is derived from B<Gnome::GObject::Object>. The only difference between the two is that the initial reference of a GInitiallyUnowned is flagged as a "floating" reference. This means that it is not specifically claimed to be "owned" by any code portion. The main motivation for providing floating references is C convenience. In particular, it allows code to be written as (in C):

  container = $create_container();
  container_add_child (container, create_child());

If C<container_add_child()> calls C<g_object_ref_sink()> on the passed-in child, no reference of the newly created child is leaked. Without floating references, C<container_add_child()> can only C<g_object_ref()> the new child, so to implement this code without reference leaks, it would have to be written as:

  Child *child;
  container = create_container();
  child = create_child();
  container_add_child (container, child);
  g_object_unref (child);

The floating reference can be converted into an ordinary reference by calling C<g_object_ref_sink()>. For already sunken objects (objects that don't have a floating reference anymore), C<g_object_ref_sink()> is equivalent to C<g_object_ref()> and returns a new reference.

Since floating references are useful almost exclusively for C convenience, language bindings that provide automated reference and memory ownership maintenance (such as smart pointers or garbage collection) should not expose floating references in their API.

Some object implementations may need to save an objects floating state across certain code portions (an example is B<Gnome::Gtk3::Menu>), to achieve this, the following sequence can be used:

  // save floating state
  gboolean was_floating = g_object_is_floating (object);
  g_object_ref_sink (object);
  // protected code portion

  ...

  // restore floating state
  if (was_floating)
    g_object_force_floating (object);
  else
    g_object_unref (object); // release previously acquired reference


=head2 See Also

I<GParamSpecObject>, C<g_param_spec_object()>

=end comment

=head1 Synopsis
=head2 Declaration

  unit class Gnome::GObject::Object;
  also is Gnome::N::TopLevelClassSupport;
  also does Gnome::GObject::Signal;

=head2 Uml Diagram

![](plantuml/Object.svg)


=begin comment
=head2 Example

This object is almost never used directly. Many classes inherit from this class. The below example shows how label text is set on a button using properties. This can be made much simpler by setting this label directly in the init of B<Gnome::Gtk3::Button>. The purpose of this example, however, is that there might be other properties which can only be set this way.

  use Gnome::GObject::Object;
  use Gnome::GObject::Value;
  use Gnome::GObject::Type;
  use Gnome::Gtk3::Button;

  my Gnome::GObject::Value $gv .= new(:init(G_TYPE_STRING));

  my Gnome::Gtk3::Button $b .= new;
  $gv.g-value-set-string('Open file');
  $b.g-object-set-property( 'label', $gv);
  $gv.clear-object;

=end comment
=end pod

#-------------------------------------------------------------------------------
use NativeCall;

use Gnome::N::X;
use Gnome::N::NativeLib;
use Gnome::N::N-GObject;
use Gnome::N::TopLevelClassSupport;
use Gnome::N::GlibToRakuTypes;

use Gnome::Glib::MainLoop;
use Gnome::Glib::MainContext;

use Gnome::GObject::Signal;
use Gnome::GObject::Type;
use Gnome::GObject::Value;
use Gnome::GObject::Closure;
#use Gnome::GObject::Param;

#-------------------------------------------------------------------------------
unit class Gnome::GObject::Object:auth<github:MARTIMM>:ver<0.3.0>;
also is Gnome::N::TopLevelClassSupport;
also does Gnome::GObject::Signal;

#-------------------------------------------------------------------------------
my Hash $signal-types = {};
my Bool $signals-added = False;

#has Gnome::GObject::Signal $!g-signal;

# type is Gnome::Gtk3::Builder. Cannot load module because of circular dep.
# attribute is set by GtkBuilder via set-builder(). There might be more than one
my Array $builders = [];

# check on native library initialization. must be global to all of the
# TopLevelClassSupport classes. the
my Bool $gui-initialized = False;
my Bool $may-not-initialize-gui = False;

#-------------------------------------------------------------------------------
=begin pod
=head1 Methods
=head2 new

Create a Raku object using a B<Gnome::Gtk3::Builder>. The builder object will provide its object (self) to B<Gnome::GObject::Object> when the Builder is created. The Builder object is asked to search for id's defined in the GUI glade design.

  multi method new ( Str :$build-id! )

An example

  my Gnome::Gtk3::Builder $builder .= new(:filename<my-gui.glade>);
  my Gnome::Gtk3::Button $button .= new(:build-id<my-gui-button>);

=end pod

#TM:4:new():inheriting:*
#TM:4:new(:build-id):*
submethod BUILD ( *%options ) {

  # check GTK+ init except when GtkApplication / GApplication is used
  $may-not-initialize-gui = [or]
    $may-not-initialize-gui,
    $gui-initialized,
    # check for Application from Gio. that one inherits from Object.
    # Application from Gtk3 inherits from Gio, so this test is always ok.
    ?(self.^mro[0..*-3].gist ~~ m/'(Application) (Object)'/);

  unless $may-not-initialize-gui {
    if not $gui-initialized #`{{and !%options<skip-init>}} {
      # must setup gtk otherwise Raku will crash
      my $argc = int-ptr.new;
      $argc[0] = 1 + @*ARGS.elems;

      my $arg_arr = char-pptr.new;
      my Int $arg-count = 0;
      $arg_arr[$arg-count++] = $*PROGRAM.Str;
      for @*ARGS -> $arg {
        $arg_arr[$arg-count++] = $arg;
      }

      my $argv = char-ppptr.new;
      $argv[0] = $arg_arr;

      # call gtk_init_check
      _object_init_check( $argc, $argv);
      $gui-initialized = True;

      # now refill the ARGS list with left over commandline arguments
      @*ARGS = ();
      for ^$argc[0] -> $i {
        # skip first argument == programname
        next unless $i;
        @*ARGS.push: $argv[0][$i];
      }
    }
  }


  # add signal types
#  unless $signals-added {
#    $signals-added = self.add-signal-types(
#      $?CLASS.^name, :N-GParamSpec<notify>
#    );
#  }

  # test if native object has been set
  if self.is-valid { }
  elsif %options<native-object>:exists { }

  elsif ? %options<build-id> {
    my N-GObject $native-object;
    note "gobject build-id: %options<build-id>" if $Gnome::N::x-debug;
    my Array $builders = self._get-builders;
    for @$builders -> $builder {

      # this action does not increase object refcount, do it here.
      $native-object = $builder.get-object(%options<build-id>) // N-GObject;
      #TODO self.g_object_ref(); ?
      last if ?$native-object;
    }

    if ? $native-object {
      note "store native object: ", self.^name, ', ', $native-object
        if $Gnome::N::x-debug;

      self.set-native-object($native-object);
    }

    else {
      note "builder id '%options<build-id>' not found in any of the builders"
        if $Gnome::N::x-debug;

      die X::Gnome.new(
        :message(
          "Builder id '%options<build-id>' not found in any of the builders"
        )
      );
    }
  }
}

#-------------------------------------------------------------------------------
# no pod. user does not have to know about it.
method _fallback ( $native-sub --> Callable ) {

  my Callable $s;

  try { $s = &::("g_object_$native-sub"); };
  try { $s = &::("g_signal_$native-sub"); } unless ?$s;
  try { $s = &::("g_$native-sub"); } unless ?$s;
  try { $s = &::($native-sub); } if !$s and $native-sub ~~ m/^ 'g_' /;

  self.set-class-name-of-sub('GObject');

  $s
}

#-------------------------------------------------------------------------------
method set-native-object ( $n-native-object ) {
  if ? $n-native-object {
    # when object is set, create signal object too
    #$!g-signal .= new(:g-object($n-native-object));
  }

  # now call the one from TopLevelClassSupport
  callsame
}

#-------------------------------------------------------------------------------
method native-object-ref ( $n-native-object --> N-GObject ) {
  _g_object_ref($n-native-object)
}

#-------------------------------------------------------------------------------
method native-object-unref ( $n-native-object ) {
#  _g_object_free($n-native-object)
  _g_object_unref($n-native-object)
}

#-------------------------------------------------------------------------------
# no pod. user does not have to know about it.
method _set-builder ( $builder ) {
  $builders.push($builder);
}

#-------------------------------------------------------------------------------
# no pod. user does not have to know about it.
method _get-builders ( --> Array ) {
  $builders
}

#-------------------------------------------------------------------------------
# no pod. user does not have to know about it.
method add-signal-types ( Str $module-name, *%signal-descriptions --> Bool ) {

  # must store signal names under the class name because I found the use of
  # the same signal name with different handler signatures in different classes.
  $signal-types{$module-name} //= {};

  note "\nTest signal names for $module-name" if $Gnome::N::x-debug;
  for %signal-descriptions.kv -> $signal-type, $signal-names {
    my @names = $signal-names ~~ List ?? @$signal-names !! ($signal-names,);
    for @names -> $signal-name {
      if $signal-type ~~ any(<w0 w1 w2 w3 w4 w5 w6 w7 w8 w9 signal event nativewidget>) {
        note "  $module-name, $signal-name --> $signal-type"
          if $Gnome::N::x-debug;
        $signal-types{$module-name}{$signal-name} = $signal-type;
      }

      # TODO cleanup deprecated and not supported
      elsif $signal-type ~~ any(<deprecated>) {
        note "  $signal-name is deprecated" if $Gnome::N::x-debug;
      }

      elsif $signal-type ~~ any(<notsupported deprecated>) {
        note "  $signal-name is not supported" if $Gnome::N::x-debug;
      }

      else {
        note "  $signal-name is not yet supported" if $Gnome::N::x-debug;
      }
    }
  }

  True
}

#-------------------------------------------------------------------------------
#TM:2:get-data:xt/Object.t
=begin pod
=head2 get-data

Gets a named field from the objects table of associations. See C<set-data()> for several examples.

Returns: the data if found, or C<undefined> if no such data exists.

  method get-data ( Str $key, $type, Str :$widget-class --> Any )

=item Str $key; name of the key for that association
=item $type; specification of the type of data to return. The recognized types are; int*, uint*, num*, Buf, (U)Int, Num, Str, Bool and N-GObject. the native int and uint type are taken as int64 and uint64 respectively. In the case of N-GObject the method will try to create a raku object. When it was undefined, this is not possible and it will return an undefined N-GObject. The N-GObject type can be helped by specifying the named argument C<widget-class>. This should be a name of a raku class like for instance B<Gnome::Gtk3::Label>. When the return value was undefined, the result object will always have the raku class type but the call to <.is-valid()> returns False. Note that Int, UInt, and Num is transformed to their 32 bit representations.
=item Str :$widget-class; Create object of this type.

=end pod

method get-data ( Str $key, Any $type, Str :$widget-class --> Any ) {

  my $data;
  my $odata = g_object_get_data( self._f('GObject'), $key);

  given $type.^name {
    when 'int8' {
      my CArray[int8] $d = nativecast( CArray[int8], $odata);
      $data = $d[0];
    }

    when /uint8 || byte/ {
      my CArray[byte] $d = nativecast( CArray[byte], $odata);
      $data = $d[0];
    }

    when 'int16' {
      my CArray[int16] $d = nativecast( CArray[int16], $odata);
      $data = $d[0];
    }

    when 'uint16' {
      my CArray[uint16] $d = nativecast( CArray[uint16], $odata);
      $data = $d[0];
    }

    when 'int32' {
      my CArray[int32] $d = nativecast( CArray[int32], $odata);
      $data = $d[0];
    }

    when 'uint32' {
      my CArray[uint32] $d = nativecast( CArray[uint32], $odata);
      $data = $d[0];
    }

    # int might be shorter but placed in longest possible, doesn't harm
    when /int '64'?/ {
      my CArray[int64] $d = nativecast( CArray[int64], $odata);
      $data = $d[0];
    }

    # int might be shorter but placed in longest possible, doesn't harm
    when /uint '64'?/ {
      my CArray[uint64] $d = nativecast( CArray[uint64], $odata);
      $data = $d[0];
    }

    when 'num32' {
      my CArray[num32] $d = nativecast( CArray[num32], $odata);
      $data = $d[0];
    }

    when 'num64' {
      my CArray[] $d = nativecast( CArray[], $odata);
      $data = $d[0];
    }

    when 'Pointer' {
      $data = $odata;
    }

    when 'Buf' {
      $data = nativecast( CArray[byte], $odata);
    }

    when 'UInt' {
      my CArray[int32] $d = nativecast( CArray[uint32], $odata);
      $data = $d[0];
    }

    when 'Int' {
      my CArray[int32] $d = nativecast( CArray[int32], $odata);
      $data = $d[0];
    }

    when 'Rat' {
      my CArray[num64] $d = nativecast( CArray[num64], $odata);
      $data = $d[0].Rat;
    }

    when 'Num' {
      my CArray[num32] $d = nativecast( CArray[num32], $odata);
      $data = $d[0];
    }

    when 'Str' {
      my CArray[Str] $d = nativecast( CArray[Str], $odata);
      $data = $d[0];
    }

    when 'Bool' {
      my CArray[gboolean] $d = nativecast( CArray[gboolean], $odata);
      $data = $d[0];
    }

    when 'N-GObject' {
      my CArray[N-GObject] $d = nativecast( CArray[N-GObject], $odata);
      if ?$widget-class {
        require ::($widget-class);
        my $class = ::($widget-class);
        $data = $class.new(:native-object($d[0]));
      }

      else {
        $data = $d[0].defined
          ?? self._wrap-native-type-from-no($d[0])
          !! N-GObject;
      }
    }

    default {
      die X::Gnome.new(:message("Type '$data.^name()' for key '$key' not supported"));
    }
  }

  $data
}

sub g_object_get_data ( N-GObject $object, Str $key --> Pointer )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:2:get-properties:xt/Object.t
=begin pod
=head2 get-properties

Gets properties of an object.

In general, a copy is made of the property contents and the caller is responsible for freeing the memory in the appropriate manner for the type, for instance by calling C<g_free()> or C<g_object_unref()>.

The method is defined as;

  method get-properties ( $prop-name, $prop-value-type, … --> List )

=item Str $prop-name; name of a property to set.
=item $prop-value-type; The type of the property to receive. It can be any of Str, Int, UInt, Num, Bool, int*, uint*, num*. (U)Int is converted to (u)int32 and Num to num32.

See C<.set()> for an example.
=end pod

method get-properties ( *@properties --> List ) {

  my @parameter-list = ( Parameter.new(:type(N-GObject)), );    # object
  my @pl = ( );                                                 # arguments

  for @properties -> Str $key, $v-type {
    @parameter-list.push: Parameter.new(:type(Str));            # prop name
    @pl.push: $key;                                             # name arg

    # prop type of value
    given $v-type.^name {

      when 'int8' {
        @parameter-list.push: Parameter.new(:type(CArray[int8]));
        @pl.push: CArray[int8].new(0);
      }

      when /uint8 || byte/ {
        @parameter-list.push: Parameter.new(:type(CArray[byte]));
        @pl.push: CArray[byte].new(0);
      }

      when 'int16' {
        @parameter-list.push: Parameter.new(:type(CArray[int16]));
        @pl.push: CArray[int16].new(0);
      }

      when 'uint16' {
        @parameter-list.push: Parameter.new(:type(CArray[uint16]));
        @pl.push: CArray[uint16].new(0);
      }

      when 'int32' {
        @parameter-list.push: Parameter.new(:type(CArray[int32]));
        @pl.push: CArray[int32].new(0);
      }

      when 'uint32' {
        @parameter-list.push: Parameter.new(:type(CArray[uint32]));
        @pl.push: CArray[uint32].new(0);
      }

      when /int '64'?/ {
        @parameter-list.push: Parameter.new(:type(CArray[int64]));
        @pl.push: CArray[int64].new(0);
      }

      when /uint '64'?/ {
        @parameter-list.push: Parameter.new(:type(CArray[uint64]));
        @pl.push: CArray[uint64].new(0);
      }

      when 'num32' {
        @parameter-list.push: Parameter.new(:type(CArray[num32]));
        @pl.push: CArray[num32].new(0e0);
      }

      when 'num64' {
        @parameter-list.push: Parameter.new(:type(CArray[num64]));
        @pl.push: CArray[num64].new(0e0);
      }

      when 'Int' {
        @parameter-list.push: Parameter.new(:type(CArray[int32]));
        @pl.push: CArray[int32].new(0);
      }

      when 'UInt' {
        @parameter-list.push: Parameter.new(:type(CArray[uint32]));
        @pl.push: CArray[uint32].new(0);
      }

      when 'Num' {
        @parameter-list.push: Parameter.new(:type(CArray[num32]));
        @pl.push: CArray[num32].new(0e0);
      }

      when 'Str' {
        @parameter-list.push: Parameter.new(:type(CArray[Str]));
        @pl.push: CArray[Str].new('');
      }

      when /Bool || gboolean/ {
        @parameter-list.push: Parameter.new(:type(CArray[gboolean]));
        @pl.push: CArray[gboolean].new(0);
      }

#`{{
      when 'N-GObject' {
        @parameter-list.push: Parameter.new(:type(CArray[N-GObject]));
        @pl.push: CArray[N-GObject].new(N-GObject);
      }

      when / '::N-GClosure' $/ {
        @parameter-list.push: Parameter.new(:type(CArray[N-GClosure]));
        @pl.push: CArray[N-GClosure].new(N-GClosure);
      }
}}

      default {
        @parameter-list.push: Parameter.new(:type(CArray[$v-type]));
        @pl.push: CArray[$v-type].new($v-type);
      }

#`{{
      default {
        die X::Gnome.new(
          :message("Type '{$v-type.raku}' for key '$key' not supported")
        );
      }
}}
    }
  }

  # to finish the list with 0
  @parameter-list.push: Parameter.new(type => Pointer);

  # create signature
  my Signature $signature .= new(
    :params(|@parameter-list),
    :returns(int32)
  );

  # get a pointer to the sub, then cast it to a sub with the proper
  # signature. after that, the sub can be called, returning a value.
  state $ptr = cglobal( &gtk-lib, 'g_object_get', Pointer);
  my Callable $f = nativecast( $signature, $ptr);

  $f( self.get-native-object-no-reffing, |@pl, Nil);

  my @ret-values = ();
  for @pl -> $key, $v {
    @ret-values.push: $v[0];
  }

  @ret-values
}

#-------------------------------------------------------------------------------
=begin pod
=head2 get-property

Gets a property of an object. The value must have been initialized to the expected type of the property (or a type to which the expected type can be transformed).

In general, a copy is made of the property contents and the caller is responsible for freeing the memory by calling C<clear-object()>.

Next signature is used when no B<Gnome::GObject::Value> is available. The routine will create the Value using C<$gtype>.

  multi method get-property (
    Str $property_name, Int $gtype
    --> Gnome::GObject::Value
  )

The following is used when a Value object is available.

  multi method get-property (
    Str $property_name, N-GValue $value
    --> Gnome::GObject::Value
  )

=item Str $property_name; the name of the property to get.
=item Int $gtype; the type of the value, e.g. G_TYPE_INT.
=item N-GValue $value; The value is stored in a N-GValue object. It is used to get the type of the object.

The methods always return a B<Gnome::GObject::Value> with the result.

  my Gnome::Gtk3::Label $label .= new;
  my Gnome::GObject::Value $gv .= new(:init(G_TYPE_STRING));
  $label.g-object-get-property( 'label', $gv);
  $gv.g-value-set-string('my text label');

=end pod

multi method get-property(
  gchar-ptr $property_name, Int $gtype --> Gnome::GObject::Value
) {
  my Gnome::GObject::Value $v .= new(:init($gtype));
  my N-GValue $nv = $v.get-native-object-no-reffing;
  _g_object_get_property(
    self.get-native-object-no-reffing, $property_name, $nv
  );

  $v
}

multi method get-property(
  gchar-ptr $property_name, $value is copy --> Gnome::GObject::Value
) {
  $value .= get-native-object-no-reffing unless $value ~~ N-GValue;

  my Gnome::GObject::Value $v .= new(:init($value.g-type));
  _g_object_get_property(
    self.get-native-object-no-reffing, $property_name, $value
  );
  $v.set-native-object($value);

  $v
}



proto sub g_object_get_property (
  N-GObject $object, gchar-ptr $property_name, |
) { * }

#TM:2:g_object_get-property(N-GObject,Prop,Int):xt/Object.t
multi sub g_object_get_property (
  $object, $property_name, Int $type
  --> Gnome::GObject::Value
) {
  my Gnome::GObject::Value $v .= new(:init($type));
  my N-GValue $nv = $v.get-native-object;
  _g_object_get_property( $object, $property_name, $nv);
#  $v.set-native-object($nv);

  $v
}

#TM:2:g_object_get_property(N-GObject,Str,N-GValue):xt/Object.t
multi sub g_object_get_property (
  $object, $property_name, N-GValue $nv
  --> Gnome::GObject::Value
) {
  my Gnome::GObject::Value $v .= new(:init($nv.g-type));
  _g_object_get_property( $object, $property_name, $nv);
  $v.set-native-object($nv);

  $v
}

#`{{
#TM:2:g_object_get_property(N-GObject,Str,Int):xt/Object.t
multi sub g_object_get_property (
  N-GObject $object, Str $property_name, Int $type
  --> Gnome::GObject::Value
) {
  my Gnome::GObject::Value $v .= new(:init($type));
  my N-GValue $nv = $v.get-native-object;
  _g_object_get_property( $object, $property_name, $nv);
  $v.set-native-object($nv);

  $v
}
}}

sub _g_object_get_property (
  N-GObject $object, gchar-ptr $property_name, N-GValue $gvalue is rw
) is native(&gobject-lib)
  is symbol('g_object_get_property')
  { * }

#-------------------------------------------------------------------------------
#TM:1:is-floating:
=begin pod
=head2 is-floating

Checks whether I<object> has a floating reference.

Returns: C<True> if I<object> has a floating reference

  method is-floating ( --> Bool )

=item Pointer $object; (type GObject.Object): a I<GObject>

=end pod
method is-floating ( --> Bool ) {
  g_object_is_floating(self.get-native-object-no-reffing).Bool
}

sub g_object_is_floating ( N-GObject $object --> gboolean )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:1:ref-sink:
=begin pod
=head2 ref-sink

Increase the reference count of this native I<object>, and possibly remove the floating reference, if I<object> has a floating reference.

In other words, if the object is floating, then this call "assumes ownership" of the floating reference, converting it to a normal reference by clearing the floating flag while leaving the reference count unchanged.  If the object is not floating, then this call adds a new normal reference increasing the reference count by one.

The type of I<object> will be propagated to the return type under the same conditions as for C<g_object_ref()>.

Returns: N-GObject

  method ref-sink ( --> N-GObject )

=end pod

method ref-sink ( --> N-GObject ) {
  g_object_ref_sink(self.get-native-object-no-reffing)
}

sub g_object_ref_sink ( N-GObject $object --> N-GObject )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:2:register-signal:
=begin pod
=head2 register-signal

Register a handler to process a signal or an event. There are several types of callbacks which can be handled by this regstration. They can be controlled by using a named argument with a special name.

  method register-signal (
    $handler-object, Str:D $handler-name,
    Str:D $signal-name, *%user-options
    --> Int
  )

=item $handler-object; The object wherein the handler is defined.
=item $handler-name; The name of the method.
=begin item
$signal-name; The name of the event to be handled. Each gtk object has its own series of signals.
=end item

=begin item
%user-options; Any other user data in whatever type provided as one or more named arguments. These arguments are provided to the user handler when an event for the handler is fired. The names starting with '_' are reserved to provide other info to the user.

The following reserved named arguments are available;
  =item C<:$_widget>; The instance which registered the signal
  =item C<:$_handler-id>; The handler id which is returned from the registration
  =item C<:$_native-object>; The native object provided by the caller. This object sometimes is usefull when the variable `$_widget` became invalid. An easy test and repair;
  =begin code
    method some-handler (
      …,
      Gnome::Gtk3::Button :_widget($button) is copy,
      N-GObject :_native-object($no)
    ) {
      $button .= new(:native-object($no)) unless $button.is-valid;
      …
    }
  =end code
=end item

The method returns a handler id which can be used for example to disconnect the callback later.

=head3 Callback handlers

=begin item
Simple handlers; e.g. a click event handler has only named arguments and are optional.
=end item

=begin item
Complex handlers (only a bit) also have positional arguments and B<MUST> be typed because they are checked to create a signature for the call to a native subroutine. You can use the raku native types like C<int32> but several types are automatically converted to native types. The types such as gboolean, etc are defined in B<Gnome::N::GlibToRakuTypes>.
  =begin table
  Raku type | Native type      | Native Raku type
  ===============================================
  Bool      | gboolean         | int32
  UInt      | guint            | uint32/uint64
  Int       | gint             | int32/int64
  Num       | gfloat           | num32
  Rat       | gdouble          | num64
  =end table
=end item

=begin item
Some handlers must return a value and is used by the calling process. You B<MUST> describe this too in the andlers API, otherwise the returned value is thrown away.
=end item

=begin item
Any user options are provided via named arguments from the call to C<register-signal()>.
=end item

=head3 Example 1

An example of a registration and the handlers signature to handle a button click event.

  # Handler class with callback methods
  class ButtonHandlers {
    method click-button ( :$_widget, :$_handler_id, :$my-option ) {
      …
    }
  }

  $button.register-signal(
    ButtonHandlers.new, 'click-button', 'clicked', :my-option(…)
  );


=head3 Example 2

An example where a keyboard press is handled.

  # Handler class with callback methods
  class KeyboardHandlers {
    method keyboard-handler (
      N-GdkEvent $event, :$_widget, :$_handler_id, :$my-option
      --> gboolean
    ) {
      …
    }
  }

  $window.register-signal(
    KeyboardHandlers.new, 'keyboard-handler',
    'key-press-event', :my-option(…)
  );


=end pod

method register-signal (
  $handler-object, Str:D $handler-name, Str:D $signal-name, *%user-options
  --> Int
) {

  my Int $handler-id = 0;

  # don't register if handler is not available
  my Method $sh = $handler-object.^lookup($handler-name) // Method;
  if ? $sh {
    if $Gnome::N::x-debug {
      note "\nregister $handler-object\.$handler-name\() for signal $signal-name, options are ", %user-options;
    }

    # search for signal name defined by this class as well as its parent classes
    my Str $signal-type;
    my Str $module-name;
    my @module-names = self.^name, |(map( {.^name}, self.^parents));
    for @module-names -> $mn {
      note "  search in class: $mn, $signal-name" if $Gnome::N::x-debug;
      if $signal-types{$mn}:exists and ?$signal-types{$mn}{$signal-name} {
        $signal-type = $signal-types{$mn}{$signal-name};
        $module-name = $mn;
        note "  found key '$signal-type' for $mn" if $Gnome::N::x-debug;
        last;
      }
    }

    return False unless ?$signal-type;

    # self can't be closed over
    my $current-object = self;

    # overwrite any user specified widget argument
    my %named-args = %user-options;
    %named-args<widget> := $current-object;
    %named-args<_widget> := $current-object;
    %named-args<_handler-id> := $handler-id;
#    Gnome::N::deprecate( 'callback(:widget)', 'callback(:_widget)', '0.16.8', '0.20.0');

    sub w0 ( N-GObject $w, gpointer $d ) is export {
      CATCH { default { .message.note; .backtrace.concise.note } }

      note "w0, $handler-name for $signal-name: %named-args.gist()"
        if $Gnome::N::x-debug;

      # Mu is not an accepted value for the NativeCall interface
      # _convert_g_signal_connect_object() in Signal makes it an gpointer
      my $retval = $handler-object."$handler-name"(|%named-args);

      if $sh.signature.returns.gist ~~ '(Mu)' {
        $retval = gpointer;
      }

      elsif $Gnome::N::x-debug {
        note "w0 handler result: $retval";
      }

      $retval
    }

    sub w1( N-GObject $w, $h0, gpointer $d ) is export {
      CATCH { default { .message.note; .backtrace.concise.note } }

      note "w1, $handler-name for $signal-name: $h0, %named-args.gist()"
        if $Gnome::N::x-debug;

#      my List @converted-args = self!check-args($h0);
#      $handler-object."$handler-name"( |@converted-args, |%named-args);
      %named-args<_native-object> := $w;
      my $retval = $handler-object."$handler-name"( $h0, |%named-args);

      if $sh.signature.returns.gist ~~ '(Mu)' {
        $retval = gpointer;
      }

      elsif $Gnome::N::x-debug {
        note "w1 handler result: $retval";
      }

      $retval
    }

    sub w2( N-GObject $w, $h0, $h1, gpointer $d ) is export {
      CATCH { default { .message.note; .backtrace.concise.note } }

      note "w2, $handler-name for $signal-name: $h0, $h1, %named-args.gist()"
        if $Gnome::N::x-debug;

#      my List @converted-args = self!check-args( $h0, $h1);
      %named-args<_native-object> := $w;
      my $retval = $handler-object."$handler-name"(
        $h0, $h1, |%named-args
      );

      if $sh.signature.returns.gist ~~ '(Mu)' {
        $retval = gpointer;
      }

      elsif $Gnome::N::x-debug {
        note "w2 handler result: $retval";
      }

      $retval
    }

    sub w3( N-GObject $w, $h0, $h1, $h2, gpointer $d ) is export {
      CATCH { default { .message.note; .backtrace.concise.note } }

      note "w3, $handler-name for $signal-name: $h0, $h1, $h2, %named-args.gist()" if $Gnome::N::x-debug;

#      my List @converted-args = self!check-args( $h0, $h1, $h2);
      %named-args<_native-object> := $w;
      my $retval = $handler-object."$handler-name"(
        $h0, $h1, $h2, |%named-args
      );

      if $sh.signature.returns.gist ~~ '(Mu)' {
        $retval = gpointer;
      }

      elsif $Gnome::N::x-debug {
        note "w3 handler result: $retval";
      }

      $retval
    }

    sub w4( N-GObject $w, $h0, $h1, $h2, $h3, gpointer $d ) is export {
      CATCH { default { .message.note; .backtrace.concise.note } }

      note "w4, $handler-name for $signal-name: $h0, $h1, $h2, $h3, %named-args.gist()" if $Gnome::N::x-debug;

#      my List @converted-args = self!check-args( $h0, $h1, $h2, $h3);
      %named-args<_native-object> := $w;
      my $retval = $handler-object."$handler-name"(
        $h0, $h1, $h2, $h3, |%named-args
      );

      if $sh.signature.returns.gist ~~ '(Mu)' {
        $retval = gpointer;
      }

      elsif $Gnome::N::x-debug {
        note "w4 handler result: $retval";
      }

      $retval
    }

    sub w5(
      N-GObject $w, $h0, $h1, $h2, $h3, $h4, gpointer $d
    ) is export {
      CATCH { default { .message.note; .backtrace.concise.note } }

      note "w5, $handler-name for $signal-name: $h0, $h1, $h2, $h3, $h4, %named-args.gist()" if $Gnome::N::x-debug;

#      my List @converted-args = self!check-args( $h0, $h1, $h2, $h3, $h4);
      %named-args<_native-object> := $w;
      my $retval = $handler-object."$handler-name"(
        $h0, $h1, $h2, $h3, $h4, |%named-args
      );

      if $sh.signature.returns.gist ~~ '(Mu)' {
        $retval = gpointer;
      }

      elsif $Gnome::N::x-debug {
        note "w5 handler result: $retval";
      }

      $retval
    }

    sub w6(
      N-GObject $w, $h0, $h1, $h2, $h3, $h4, $h5, gpointer $d
    ) is export {
      CATCH { default { .message.note; .backtrace.concise.note } }

      note "w6, $handler-name for $signal-name: $h0, $h1, $h2, $h3, $h4, $h5, %named-args.gist()" if $Gnome::N::x-debug;

#      my List @converted-args = self!check-args( $h0, $h1, $h2, $h3, $h4, $h5);
      %named-args<_native-object> := $w;
      my $retval = $handler-object."$handler-name"(
        $h0, $h1, $h2, $h3, $h4, $h5, |%named-args
      );

      if $sh.signature.returns.gist ~~ '(Mu)' {
        $retval = gpointer;
      }

      elsif $Gnome::N::x-debug {
        note "w6 handler result: $retval";
      }

      $retval
    }

    given $signal-type {
      # handle a widget, maybe other arguments and an ignorable data pointer
      when / w $<nbr-args> = (\d*) / {

        state %shkeys = %( :&w0, :&w1, :&w2, :&w3, :&w4, :&w5, :&w6);

        my $no = self.get-native-object-no-reffing;
        note "\nSignal type and name: $signal-type, $signal-name\nHandler: $sh.perl(),\n" if $Gnome::N::x-debug;

#        $handler-id = $!g-signal._convert_g_signal_connect_object(
        $handler-id = self._convert_g_signal_connect_object(
          $no, $signal-name, $sh, %shkeys{$signal-type}
        );
      }
    }
  }

  else {
    note "\nCannot register $handler-object, $handler-name, options: ",
      %user-options, ', method, not found' if $Gnome::N::x-debug;
  }

  $handler-id
}

#`{{
#-------------------------------------------------------------------------------
#TODO create Raku objects from the native objects
method !check-args( *@args --> List ) {

  my @new-args = ();

  for @args -> $h {
# wrong; $h is a native object!
    my Str $class = $h.^name;
    if $class ~~ m/^ 'Gnome::' [ Gtk || Gdk || G ] '::' / {
      try {
        require ::($class);
        my $no = ::($class).new(:widget($h));
        @new-args.push: $no;
        CATCH {
          default {
            if $Gnome::N::x-debug {
              once {note "\nQuerying interfaces for module $!gtk-class-name"};

              if .message ~~ m:s/$class/ {
                note "Interface $class not (yet) implemented";
              }

              elsif .message ~~ m:s/Could not find/ {
                note ".new() or ._interface() not defined";
              }

              else {
                note "Error: ", .message();
              }
            }
          }
        }
      }
    }

    else {
      @new-args.push: $h;
    }
  }

  @args
}
}}
#`{{
#-------------------------------------------------------------------------------
#TM:0:g_object_replace_data:
=begin pod
=head2 [[g_] object_] replace_data

Compares the user data for the key I<key> on I<object> with
I<oldval>, and if they are the same, replaces I<oldval> with
I<newval>.

This is like a typical atomic compare-and-exchange
operation, for user data on an object.

If the previous value was replaced then ownership of the
old value (I<oldval>) is passed to the caller, including
the registered destroy notify for it (passed out in I<old_destroy>).
It’s up to the caller to free this as needed, which may
or may not include using I<old_destroy> as sometimes replacement
should not destroy the object in the normal way.

Returns: C<1> if the existing value for I<key> was replaced
by I<newval>, C<0> otherwise.

  method g_object_replace_data (
    Str $key, Pointer $oldval, Pointer $newval,
    GDestroyNotify $destroy, GDestroyNotify $old_destroy
    --> Int
  )

=item Str $key; a string, naming the user data pointer
=item Pointer $oldval; (nullable): the old value to compare against
=item Pointer $newval; (nullable): the new value
=item GDestroyNotify $destroy; (nullable): a destroy notify for the new value
=item GDestroyNotify $old_destroy; (out) (optional): destroy notify for the existing value

=end pod

method replace-data ( Str $key, Pointer $data ) {
  g_object_set_data( self._f('GObject'), $key, $data);
}

sub g_object_replace_data ( N-GObject $object, Str $key, Pointer $oldval, Pointer $newval, GDestroyNotify $destroy, GDestroyNotify $old_destroy )
  returns int32
  is native(&gobject-lib)
  { * }
}}

#-------------------------------------------------------------------------------
#TM:2:set-data:xt/Object.t
=begin pod
=head2 set-data

Each object carries around a table of associations from strings to pointers.  This function lets you set an association.

If the object already had an association with that name, the old association will be destroyed.

  method set-data ( Str $key, $data )

=item Str $key; name of the key.
=item $data; data to associate with that key. Supported types are int*, uint*, num*, Pointer, Buf, Int, Num, Str, Bool and N-GObject. A raku widget object such as Gnome::Gdk3::Screen can also be given. The native object is retrieved from the raku widget and then stored as a N-GObject. Further is it important to note that Int, UInt, and Num is transformed to their 32 bit representations.

=head3 Example 1

Here is an example to show how to associate some data to an object and to retrieve it again. You must import the raku B<NativeCall> module to get access to some of the native types and routines.

  my Gnome::Gtk3::Button $button .= new(:label<Start>);
  my Gnome::Gtk3::Label $att-label .= new(:text<a-label>);
  $button.set-data( 'attached-label-data', $att-label);

  …

  my Gnome::Gtk3::Label $att-label2 =
    $button.get-data( 'attached-label-data', N-GObject);

or, if you want to be sure, add the C<widget-class> named argument;

  my Gnome::Gtk3::Label $att-label2 = $button.get-data(
    'attached-label-data', N-GObject,
    :widget-class<Gnome::Gtk3::Label>
  );

=head3 Example 2

Other types can be used as well to store data. The next example shows what is possible;

  $button.set-data( 'my-text-key', 'my important text');
  $button.set-data( 'my-uint32-key', my uint32 $x = 12345);

  …

  my Str $text = $button.get-data( 'my-text-key', Str);
  my Int $number = $button.get-data( 'my-uint32-key', uint32);


=head3 Example 3

An elaborate example of more complex data can be used with BSON. This is an implementation of a JSON like structure but is serialized into a binary representation. It is used for transport to and from a mongodb server. Here we use it to attach complex data in serialized form to an B<Gnome::GObject::Object>. (Please note that the BSON package must be of version 0.13.2 or higher. More [documenation at](https://martimm.github.io/raku-mongodb-driver/content-docs/reference/BSON/Document.html))

  # Create the data structure
  my BSON::Document $bson .= new: (
    :int-number(-10),
    :num-number(-2.34e-3),
    :strings( :s1<abc>, :s2<def>, :s3<xyz> )
  );

  # And store it on a label
  my Gnome::Gtk3::Label $bl .= new(:text<a-label>);
  $bl.set-data( 'my-buf-key', $bson.encode);

  …

  # Later, we want to access the data again,
  my BSON::Document $bson2 .= new($bl.get-data( 'my-buf-key', Buf));

  # Now you can use the data again.
  say $bson2<int-number>;  # -10
  say $bson2<num-number>;  # -234e-5
  say $bson2<strings><s2>; # 'def'

=end pod

method set-data ( Str $key, $data is copy ) {

  # if $data is a raku widget (Gnome::GObject::Object), get the native object
  $data .= get-native-object if $data.^can('get-native-object');

  my $d;
  given $data.^name {

    when 'int8' {
      $d = CArray[int8].new($data);
    }

    when /uint8 || byte/ {
      $d = CArray[byte].new($data);
    }

    when 'int16' {
      $d = CArray[int16].new($data);
    }

    when 'uint16' {
      $d = CArray[uint16].new($data);
    }

    when 'int32' {
      $d = CArray[int32].new($data);
    }

    when 'uint32' {
      $d = CArray[uint32].new($data);
    }

    when /int '64'?/ {
      $d = CArray[int64].new($data);
    }

    when /uint '64'?/ {
      $d = CArray[uint64].new($data);
    }

    when 'num32' {
      $d = CArray[num32].new($data);
    }

    when 'num64' {
      $d = CArray[num64].new($data);
    }

    when 'Pointer' {
      $d = CArray[Pointer].new($data);
    }

    when 'Buf' {
      $d = CArray[byte].new($data);
    }

    when 'Int' {
      $d = CArray[int32].new($data);
    }

    when 'Num' {
      $d = CArray[num32].new($data);
    }

    when 'Rat' {
      $d = CArray[num64].new($data.Num);
    }

    when 'Str' {
      $d = CArray[Str].new($data);
    }

    when 'Bool' {
      $d = CArray[gboolean].new($data);
    }

#    when Gnome::GObject::Object {
#      $d = CArray[N-GObject].new($data.get-native-object);
#    }

    when 'N-GObject' {
      $d = CArray[N-GObject].new($data);
    }

    default {
      die X::Gnome.new(:message("Type '$data.^name()' for key '$key' not supported"));
    }
  }

  g_object_set_data(
    self._f('GObject'), $key,
    $data ~~ Pointer ?? $data !! nativecast( Pointer, $d)
  );
}

sub g_object_set_data ( N-GObject $object, Str $key, Pointer $data )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:2:set-properties:xt/Object.t
=begin pod
=head2 set-properties

Sets properties on an object.

Note that the "notify" signals are queued and only emitted (in reverse order) after all properties have been set.
=comment See C<g_object_freeze_notify()>.

  method set-properties ( Str $prop-name, $prop-value, … )

=item Str $prop-name; name of a property to set.
=item $prop-value; The value of the property to set. Its type can be any of Str, Int, Num, Bool, int8, int16, int32, int64, num32, num64, GEnum, GFlag, GQuark, GType, gboolean, gchar, guchar, gdouble, gfloat, gint, gint8, gint16, gint32, gint64, glong, gshort, guint, guint8, guint16, guint32, guint64, gulong, gushort, gsize, gssize, gpointer or time_t. Int is converted to int32 and Num to num32. You must use B<Gnome::N::GlibToRakuTypes> to have the g* types and time_t.

=head3 Example

A button has e.g. the properties C<label> and C<use-underline>. To set those and retrieve them, do the following

  my Gnome::Gtk3::Button $b .= new(:label<?>);
  $button.set-properties( :label<_Start>, :use-underline(True));
  …

  method my-button-click-event-handler (
    Gnome::Gtk3::Button :_widget($button)
  ) {
    # Get the properties set elsewhere on the button
    my @rv = $button.get-properties( 'label', Str, 'use-underline', Bool);

    # Do something with intval, strval, objval
    say @rv[0];   # _Start
    say @rv[1];   # 1
    …

Note that boolean values from C are integers which are 0 or 1.

=end pod

method set-properties ( *%properties ) {

  my @parameter-list = ( Parameter.new(:type(N-GObject)), );    # object
  my @pl = ( );                                                 # arguments

  for %properties.kv -> $key, $v {
    @parameter-list.push: Parameter.new(:type(Str));            # prop name
    @pl.push: $key;                                             # name arg

    @pl.push: $v;                                               # value arg

    # prop type of value arg
    given $v.^name {

      when 'int8' {
        @parameter-list.push: Parameter.new(:type(CArray[int8]));
      }

      when /uint8 || byte/ {
        @parameter-list.push: Parameter.new(:type(CArray[byte]));
      }

      when 'int16' {
        @parameter-list.push: Parameter.new(:type(CArray[int16]));
      }

      when 'uint16' {
        @parameter-list.push: Parameter.new(:type(CArray[uint16]));
      }

      when 'int32' {
        @parameter-list.push: Parameter.new(:type(CArray[int32]));
      }

      when 'uint32' {
        @parameter-list.push: Parameter.new(:type(CArray[uint32]));
      }

      when /int '64'?/ {
        @parameter-list.push: Parameter.new(:type(CArray[int64]));
      }

      when /uint '64'?/ {
        @parameter-list.push: Parameter.new(:type(CArray[uint64]));
      }

      when 'num32' {
        @parameter-list.push: Parameter.new(:type(CArray[num32]));
      }

      when 'num64' {
        @parameter-list.push: Parameter.new(:type(CArray[num64]));
      }

      when 'UInt' {
        # 32bit more common?
        @parameter-list.push: Parameter.new(:type(uint32));
      }

      when 'Int' {
        # 32bit more common?
        @parameter-list.push: Parameter.new(:type(int32));
      }

      when 'Num' {
        # 32bit more common?
        @parameter-list.push: Parameter.new(:type(num32));
      }

      when 'Str' {
        @parameter-list.push: Parameter.new(:type(Str));
      }

      when /Bool || gboolean/ {
        @parameter-list.push: Parameter.new(:type(gboolean));
      }

#`{{
      when 'N-GObject' {
        @parameter-list.push: Parameter.new(:type(N-GObject));
      }

      default {
        die X::Gnome.new(
          :message("Type {.^name} for key $key not supported")
        );
      }
}}

      default {
        @parameter-list.push: Parameter.new(:type($v.WHAT));
      }
    }
  }

  # to finish the list with 0
  @parameter-list.push: Parameter.new(type => Pointer);

  # create signature
  my Signature $signature .= new(
    :params(|@parameter-list),
    :returns(int32)
  );


  # get a pointer to the sub, then cast it to a sub with the proper
  # signature. after that, the sub can be called, returning a value.
  state $ptr = cglobal( &gtk-lib, 'g_object_set', Pointer);
  my Callable $f = nativecast( $signature, $ptr);

  $f( self.get-native-object-no-reffing, |@pl, Nil);
}

#-------------------------------------------------------------------------------
#TM:2:set-property:xt/Object.t
=begin pod
=head2 set-property

Sets a property on an object.

  method set-property ( Str $property_name, N-GValue $value )

=item Str $property_name; the name of the property to set
=item N-GObject $value; the value

=end pod

method set-property ( gchar-ptr $property_name, $value is copy ) {
  $value .= get-native-object-no-reffing unless $value ~~ N-GValue;

  g_object_set_property(
    self.get-native-object-no-reffing, $property_name, $value
  );
}

sub g_object_set_property (
  N-GObject $object, gchar-ptr $property_name, N-GValue $value
) is native(&gobject-lib)
  is symbol('g_object_set_property')
  { * }

#-------------------------------------------------------------------------------
#TM:4:start-thread:Gtk3 stress tests
=begin pod
=head2 start-thread

Start a thread in such a way that the function can modify the user interface in a save way and that these updates are automatically made visible without explicitly process events queued and waiting in the main loop.

  method start-thread (
    $handler-object, Str:D $handler-name,
    Bool :$new-context = False, Num :$start-time = now + 1,
    *%user-options
    --> Promise
  )

=item $handler-object is the object wherein the handler is defined.
=item $handler-name is name of the method.
=item $new-context; Whether to run the handler in a new context or to run it in the context of the main loop. Default is to run in the main loop.
=item $start-time. Start time of thread. Default is now + 1 sec. Most of the time a thread starts too fast when some widget are not ready yet. All depends of course what the thread has to do.

=begin item
%user-options; Any other user data in whatever type provided as one or more named arguments except for :start-time and :new-context. These arguments are provided to the user handler when the callback is invoked.

There will always be one named argument C<:$widget> which holds the class object on which the thread is started. The name 'widget' is therefore reserved.

The named attribute C<:$widget> will be deprecated in the future. The name will be changed into C<:$_widget> to give the user a free hand in user provided named arguments. The names starting with '_' will then be reserved to provide special info to the user.

The following named arguments can be used in the callback handler next to the other user definable options;

  =item C<:$_widget>; The instance which registered the signal.
=end item

Returns a C<Promise> object. If the call fails, the object is undefined.

The handlers signature holds at least C<:$_widget> extended with all provided named arguments to the call defined in C<*%user-options>. The handler may return any value which becomes the result of the C<Promise> returned from C<start-thread>.

=end pod

method start-thread (
  Any:D $handler-object, Str:D $handler-name,
  Bool :$new-context = False, Instant :$start-time = now + 1, *%user-options
  --> Promise
) {

  # don't start thread if handler is not available
  my Method $sh = $handler-object.^lookup($handler-name) // Method;
  die X::Gnome.new(
    :message("Method '$handler-name' not available in object")
  ) unless ? $sh;

  my Promise $p = Promise.at($start-time).then( {

#    CATCH { default { .message.note; .backtrace.concise.note } }

    # This part is important that it happens in the thread where the
      # function is invoked in that context!
      my Gnome::Glib::MainContext $gmain-context;
      if $new-context {
        $gmain-context .= new;
        $gmain-context.push-thread-default;
      }

      else {
        # when invoke is called and context is undefined, it takes the default
        $gmain-context .= new(:thread-default);
      }

      my $return-value;
      $gmain-context.invoke-raw(
        -> gpointer $d {

          CATCH { default { .message.note; .backtrace.concise.note } }

          $return-value = $handler-object."$handler-name"(
            :widget(self), :_widget(self), |%user-options
          );

          G_SOURCE_REMOVE
        },
      );

      if $new-context {
        $gmain-context.pop-thread-default;
      }

      $return-value
    }
  );

  $p
}

#-------------------------------------------------------------------------------
#TM:2:steal-data:xt/Object.t
=begin pod
=head2 steal-data

Remove a specified datum from the object's data associations, without invoking the association's destroy handler.

Returns: the data if found, or C<Any> if no such data exists.

  method steal-data ( Str $key --> Pointer )

=item Str $key; name of the key

=end pod

#`{{
method steal-data ( Str $key --> Pointer ) {
  g_object_steal_data( self.get-native-object-no-reffing, $key);
}
}}


method steal-data ( Str $key, Any $type, Str :$widget-class --> Any ) {

  my $data;
  my $odata = g_object_steal_data( self._f('GObject'), $key);
  given $type.^name {

    when 'int8' {
      my CArray[int8] $d = nativecast( CArray[int8], $odata);
      $data = $d[0];
    }

    when /uint8 || byte/ {
      my CArray[byte] $d = nativecast( CArray[byte], $odata);
      $data = $d[0];
    }

    when 'int16' {
      my CArray[int16] $d = nativecast( CArray[int16], $odata);
      $data = $d[0];
    }

    when 'uint16' {
      my CArray[uint16] $d = nativecast( CArray[uint16], $odata);
      $data = $d[0];
    }

    when 'int32' {
      my CArray[int32] $d = nativecast( CArray[int32], $odata);
      $data = $d[0];
    }

    when 'uint32' {
      my CArray[uint32] $d = nativecast( CArray[uint32], $odata);
      $data = $d[0];
    }

    # (g)int might be shorter but placed in longest possible, doesn't harm
    when 'int64' {
      my CArray[int64] $d = nativecast( CArray[int64], $odata);
      $data = $d[0];
    }

    when 'uint64' {
      my CArray[uint64] $d = nativecast( CArray[uint64], $odata);
      $data = $d[0];
    }

    when 'num32' {
      my CArray[num32] $d = nativecast( CArray[num32], $odata);
      $data = $d[0];
    }

    when 'num64' {
      my CArray[] $d = nativecast( CArray[], $odata);
      $data = $d[0];
    }

    when 'Pointer' {
      $data = $odata;
    }

    when 'Buf' {
      $data = nativecast( CArray[byte], $odata);
    }

    when 'Int' {
      my CArray[int32] $d = nativecast( CArray[int32], $odata);
      $data = $d[0];
    }

    when 'Num' {
      my CArray[num32] $d = nativecast( CArray[num32], $odata);
      $data = $d[0];
    }

    when 'Str' {
      my CArray[Str] $d = nativecast( CArray[Str], $odata);
      $data = $d[0];
    }

    when 'Bool' {
      my CArray[gboolean] $d = nativecast( CArray[gboolean], $odata);
      $data = $d[0];
    }

    when 'N-GObject' {
      my CArray[N-GObject] $d = nativecast( CArray[N-GObject], $odata);
      if ?$widget-class {
        require ::($widget-class);
        my $class = ::($widget-class);
        $data = $class.new(:native-object($d[0]));
      }

      else {
        $data = $d[0].defined
          ?? self._wrap-native-type-from-no($d[0])
          !! N-GObject;
      }
    }

    default {
      die X::Gnome.new(:message("Type of key '$key' not supported"));
    }
  }

  $data
}

sub g_object_steal_data ( N-GObject $object, Str $key --> Pointer )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# this sub belongs to Gnome::Gtk3::Main but is needed here to avoid
# circular dependencies,
sub _object_init_check (
#  CArray[int32] $argc, CArray[CArray[Str]] $argv
  int-ptr $argc, char-ppptr $argv
  --> int32
) is native(&gtk-lib)
  is symbol('gtk_init_check')
  { * }

#-------------------------------------------------------------------------------
#TM:1:_g_object_ref:
#`{{
=begin pod
=head2 [g_] object_ref

Increases the reference count of this object and returns the same object.

  method g_object_ref ( --> N-GObject )

=end pod
}}

sub _g_object_ref ( N-GObject $object --> N-GObject )
  is native(&gobject-lib)
  is symbol('g_object_ref')
  { * }

#-------------------------------------------------------------------------------
#TM:1:_g_object_unref:
#`{{
=begin pod
=head2 [g_] object_unref

Decreases the reference count of the native object. When its reference count drops to 0, the object is finalized (i.e. its memory is freed).

When the object has a floating reference because it is not added to a container or it is not a toplevel window, the reference is first sunk followed by C<g_object_unref()>.

  method g_object_unref ( )

=item N-GObject $object; a native I<GObject>.

=end pod

sub g_object_unref ( N-GObject $object is copy ) {

  $object = g_object_ref_sink($object) if g_object_is_floating($object);
  _g_object_unref($object)
}
}}

sub _g_object_unref ( N-GObject $object )
  is native(&gobject-lib)
  is symbol('g_object_unref')
  { * }























=finish

#-------------------------------------------------------------------------------
#TM:0:g_initially_unowned_get_type:
=begin pod
=head2 [g_] initially_unowned_get_type

  method g_initially_unowned_get_type ( --> int32  )

=end pod

sub g_initially_unowned_get_type (  )
  returns int32
  is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
#TM:0:g_object_setv:
=begin pod
=head2 [g_] object_setv

Sets I<$n_properties> properties for this object. Properties to be set will be taken from I<$values>. All properties must be valid. Warnings will be emitted and undefined behaviour may result if invalid properties are passed in.


  method g_object_setv ( @names, @values )

=item Str @names; the names of each property to be set
=item N-GValue @values; the values of each property to be set

=end pod

method g-object-setv ( Array $names, Array $values ) {

  my Int $l = $names.elems;

  die X::Gnome.new(:message("Arrays do not have equal length"))
      unless $l == $values.elems;

  my CArray[Str] $n .= new;
  my CArray[N-GValue] $v .= new;
  loop ( my $i = 0; $i < $l; $i++ ) {
    $n[$i] = $names[$i];
    $v[$i] = $values[$i];
  }

  _g_object_setv( self.get-native-object, $l, $n, $v)
}

sub _g_object_setv (
  N-GObject $object, uint32 $n_properties,
  CArray[Str] $names, CArray[N-GValue] $values
) is native(&gobject-lib)
  is symbol('g_object_setv')
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_set_valist:
=begin pod
=head2 [[g_] object_] set_valist

Sets properties on an object.

  method g_object_set_valist (
    Str $first_property_name, CArray[N-GValue] $var_args
  )

=item Str $first_property_name; name of the first property to set
=item CArray[N-GValue] $var_args; value for the first property, followed optionally by more name/value pairs, followed by C<Any>

=end pod

sub g_object_set_valist ( N-GObject $object, Str $first_property_name, CArray[N-GValue] $var_args )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_getv:
=begin pod
=head2 [g_] object_getv

Gets I<n_properties> properties for an I<object>.
Obtained properties will be set to I<values>. All properties must be valid.
Warnings will be emitted and undefined behaviour may result if invalid
properties are passed in.


  method g_object_getv (
    UInt $n_properties, CArray[Str] $names, CArray[N-GValue] $values )

=item UInt $n_properties; the number of properties
=item CArray[Str] $names; (array length=n_properties): the names of each property to get
=item CArray[N-GValue] $values; (array length=n_properties): the values of each property to get

=end pod

sub g_object_getv ( N-GObject $object, uint32 $n_properties, CArray[Str] $names, CArray[N-GValue] $values)
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_get_valist:
=begin pod
=head2 [[g_] object_] get_valist

Gets properties of an object.

In general, a copy is made of the property contents and the caller
is responsible for freeing the memory in the appropriate manner for
the type, for instance by calling C<g_free()> or C<g_object_unref()>.

See C<g_object_get()>.

  method g_object_get_valist (
    Str $first_property_name, CArray[N-GValue] $var_args
  )

=item Str $first_property_name; name of the first property to get
=item CArray[N-GValue] $var_args; return location for the first property, followed optionally by more name/return location pairs, followed by C<Any>

=end pod

sub g_object_get_valist ( N-GObject $object, Str $first_property_name, CArray[N-GValue] $var_args )
  is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
#TM:0:g_object_class_install_property:
=begin pod
=head2 [[g_] object_] class_install_property

Installs a new property.

All properties should be installed during the class initializer.  It
is possible to install properties after that, but doing so is not
recommend, and specifically, is not guaranteed to be thread-safe vs.
use of properties on the same type on other threads.

Note that it is possible to redefine a property in a derived class,
by installing a property with the same name. This can be useful at times,
e.g. to change the range of allowed values or the default value.

  method g_object_class_install_property ( GObjectClass $oclass, UInt $property_id, N-GParamSpec $pspec )

=item GObjectClass $oclass; a I<GObjectClass>
=item UInt $property_id; the id for the new property
=item N-GParamSpec $pspec; the I<N-GParamSpec> for the new property

=end pod

sub g_object_class_install_property ( GObjectClass $oclass, uint32 $property_id, N-GParamSpec $pspec )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_class_find_property:
=begin pod
=head2 [[g_] object_] class_find_property

Looks up the I<N-GParamSpec> for a property of a class.

Returns: (transfer none): the I<N-GParamSpec> for the property, or
C<Any> if the class doesn't have a property of that name

  method g_object_class_find_property ( GObjectClass $oclass, Str $property_name --> N-GParamSpec  )

=item GObjectClass $oclass; a I<GObjectClass>
=item Str $property_name; the name of the property to look up

=end pod

sub g_object_class_find_property ( GObjectClass $oclass, Str $property_name )
  returns N-GParamSpec
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_class_list_properties:
=begin pod
=head2 [[g_] object_] class_list_properties

Get an array of I<N-GParamSpec>* for all properties of a class.

Returns: (array length=n_properties) (transfer container): an array of
I<N-GParamSpec>* which should be freed after use

  method g_object_class_list_properties ( GObjectClass $oclass, UInt $n_properties --> N-GParamSpec  )

=item GObjectClass $oclass; a I<GObjectClass>
=item UInt $n_properties; (out): return location for the length of the returned array

=end pod

sub g_object_class_list_properties ( GObjectClass $oclass, uint32 $n_properties )
  returns N-GParamSpec
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_class_override_property:
=begin pod
=head2 [[g_] object_] class_override_property

Registers I<property_id> as referring to a property with the name
I<name> in a parent class or in an interface implemented by I<oclass>.
This allows this class to "override" a property implementation in
a parent class or to provide the implementation of a property from
an interface.

Internally, overriding is implemented by creating a property of type
I<N-GParamSpecOverride>; generally operations that query the properties of
the object class, such as C<g_object_class_find_property()> or
C<g_object_class_list_properties()> will return the overridden
property. However, in one case, the I<construct_properties> argument of
the I<constructor> virtual function, the I<N-GParamSpecOverride> is passed
instead, so that the I<param_id> field of the I<N-GParamSpec> will be
correct.  For virtually all uses, this makes no difference. If you
need to get the overridden property, you can call
C<g_param_spec_get_redirect_target()>.


  method g_object_class_override_property ( GObjectClass $oclass, UInt $property_id, Str $name )

=item GObjectClass $oclass; a I<GObjectClass>
=item UInt $property_id; the new property ID
=item Str $name; the name of a property registered in a parent class or in an interface of this class.

=end pod

sub g_object_class_override_property ( GObjectClass $oclass, uint32 $property_id, Str $name )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_class_install_properties:
=begin pod
=head2 [[g_] object_] class_install_properties

Installs new properties from an array of I<N-GParamSpecs>.

All properties should be installed during the class initializer.  It
is possible to install properties after that, but doing so is not
recommend, and specifically, is not guaranteed to be thread-safe vs.
use of properties on the same type on other threads.

The property id of each property is the index of each I<N-GParamSpec> in
the I<pspecs> array.

The property id of 0 is treated specially by I<GObject> and it should not
be used to store a I<N-GParamSpec>.

This function should be used if you plan to use a static array of
I<N-GParamSpecs> and C<g_object_notify_by_pspec()>. For instance, this
class initialization:

|[<!-- language="C" -->
enum {
PROP_0, PROP_FOO, PROP_BAR, N_PROPERTIES
};

static N-GParamSpec *obj_properties[N_PROPERTIES] = { NULL, };

static void
my_object_class_init (MyObjectClass *klass)
{
GObjectClass *gobject_class = G_OBJECT_CLASS (klass);

obj_properties[PROP_FOO] =
g_param_spec_int ("foo", "Foo", "Foo",
-1, G_MAXINT,
0,
G_PARAM_READWRITE);

obj_properties[PROP_BAR] =
g_param_spec_string ("bar", "Bar", "Bar",
NULL,
G_PARAM_READWRITE);

gobject_class->set_property = my_object_set_property;
gobject_class->get_property = my_object_get_property;
g_object_class_install_properties (gobject_class,
N_PROPERTIES,
obj_properties);
}
]|

allows calling C<g_object_notify_by_pspec()> to notify of property changes:

|[<!-- language="C" -->
void
my_object_set_foo (MyObject *self, gint foo)
{
if (self->foo != foo)
{
self->foo = foo;
g_object_notify_by_pspec (G_OBJECT (self), obj_properties[PROP_FOO]);
}
}
]|


  method g_object_class_install_properties ( GObjectClass $oclass, UInt $n_pspecs, N-GParamSpec $pspecs )

=item GObjectClass $oclass; a I<GObjectClass>
=item UInt $n_pspecs; the length of the I<N-GParamSpecs> array
=item N-GParamSpec $pspecs; (array length=n_pspecs): the I<N-GParamSpecs> array defining the new properties

=end pod

sub g_object_class_install_properties ( GObjectClass $oclass, uint32 $n_pspecs, N-GParamSpec $pspecs )
  is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
#TM:0:g_object_interface_install_property:
=begin pod
=head2 [[g_] object_] interface_install_property

Add a property to an interface; this is only useful for interfaces
that are added to GObject-derived types. Adding a property to an
interface forces all objects classes with that interface to have a
compatible property. The compatible property could be a newly
created I<N-GParamSpec>, but normally
C<g_object_class_override_property()> will be used so that the object
class only needs to provide an implementation and inherits the
property description, default value, bounds, and so forth from the
interface property.

This function is meant to be called from the interface's default
vtable initialization function (the I<class_init> member of
I<GTypeInfo>.) It must not be called after after I<class_init> has
been called for any object types implementing this interface.

If I<pspec> is a floating reference, it will be consumed.


  method g_object_interface_install_property ( Pointer $g_iface, N-GParamSpec $pspec )

=item Pointer $g_iface; (type GObject.TypeInterface): any interface vtable for the interface, or the default vtable for the interface.
=item N-GParamSpec $pspec; the I<N-GParamSpec> for the new property

=end pod

sub g_object_interface_install_property ( Pointer $g_iface, N-GParamSpec $pspec )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_interface_find_property:
=begin pod
=head2 [[g_] object_] interface_find_property

Find the I<N-GParamSpec> with the given name for an
interface. Generally, the interface vtable passed in as I<g_iface>
will be the default vtable from C<g_type_default_interface_ref()>, or,
if you know the interface has already been loaded,
C<g_type_default_interface_peek()>.


Returns: (transfer none): the I<N-GParamSpec> for the property of the
interface with the name I<property_name>, or C<Any> if no
such property exists.

  method g_object_interface_find_property ( Pointer $g_iface, Str $property_name --> N-GParamSpec  )

=item Pointer $g_iface; (type GObject.TypeInterface): any interface vtable for the interface, or the default vtable for the interface
=item Str $property_name; name of a property to lookup.

=end pod

sub g_object_interface_find_property ( Pointer $g_iface, Str $property_name )
  returns N-GParamSpec
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_interface_list_properties:
=begin pod
=head2 [[g_] object_] interface_list_properties

Lists the properties of an interface.Generally, the interface
vtable passed in as I<g_iface> will be the default vtable from
C<g_type_default_interface_ref()>, or, if you know the interface has
already been loaded, C<g_type_default_interface_peek()>.


Returns: (array length=n_properties_p) (transfer container): a
pointer to an array of pointers to I<N-GParamSpec>
structures. The paramspecs are owned by GLib, but the
array should be freed with C<g_free()> when you are done with
it.

  method g_object_interface_list_properties ( Pointer $g_iface, UInt $n_properties_p --> N-GParamSpec  )

=item Pointer $g_iface; (type GObject.TypeInterface): any interface vtable for the interface, or the default vtable for the interface
=item UInt $n_properties_p; (out): location to store number of properties returned.

=end pod

sub g_object_interface_list_properties ( Pointer $g_iface, uint32 $n_properties_p )
  returns N-GParamSpec
  is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
#TM:0:g_object_new:
=begin pod
=head2 [g_] object_new

Creates a new instance of a I<GObject> subtype and sets its properties.

Construction parameters (see I<G_PARAM_CONSTRUCT>, I<G_PARAM_CONSTRUCT_ONLY>)
which are not explicitly specified are set to their default values.

Returns: (transfer full) (type GObject.Object): a new instance of
I<object_type>

  method g_object_new ( int32 $object_type, Str $first_property_name --> Pointer  )

=item int32 $object_type; the type id of the I<GObject> subtype to instantiate
=item Str $first_property_name; the name of the first property @...: the value of the first property, followed optionally by more name/value pairs, followed by C<Any>

=end pod

sub g_object_new ( int32 $object_type, Str $first_property_name, Any $any = Any )
  returns Pointer
  is native(&gobject-lib)
  { * }
}}


}}
#-------------------------------------------------------------------------------
#TM:0:g_object_new_with_properties:
=begin pod
=head2 [[g_] object_] new_with_properties

Creates a new instance of a I<GObject> subtype and sets its properties using
the provided arrays. Both arrays must have exactly I<n_properties> elements,
and the names and values correspond by index.

Construction parameters (see C<G_PARAM_CONSTRUCT>, C<G_PARAM_CONSTRUCT_ONLY>)
which are not explicitly specified are set to their default values.

Returns: (type GObject.Object) (transfer full): a new instance of
I<object_type>


  method g_object_new_with_properties (
    int32 $object_type, UInt $n_properties,
    CArray[Str] $names, CArray[N-GValue] $values
    --> N-GObject
  )

=item int32 $object_type; the object type to instantiate
=item UInt $n_properties; the number of properties
=item CArray[Str] $names; (array length=n_properties): the names of each property to be set
=item CArray[N-GValue] $values; (array length=n_properties): the values of each property to be set

=end pod

sub g_object_new_with_properties (
  int32 $object_type, uint32 $n_properties,
  CArray[Str] $names, CArray[N-GValue] $values
) returns N-GObject
  is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
#TM:0:g_object_new_valist:
=begin pod
=head2 [[g_] object_] new_valist

Creates a new instance of a I<GObject> subtype and sets its properties.

Construction parameters (see I<G_PARAM_CONSTRUCT>, I<G_PARAM_CONSTRUCT_ONLY>)
which are not explicitly specified are set to their default values.

Returns: a new instance of I<object_type>

  method g_object_new_valist ( int32 $object_type, Str $first_property_name, va_list $var_args --> N-GObject  )

=item int32 $object_type; the type id of the I<GObject> subtype to instantiate
=item Str $first_property_name; the name of the first property
=item va_list $var_args; the value of the first property, followed optionally by more name/value pairs, followed by C<Any>

=end pod

sub g_object_new_valist (
  int32 $object_type, Str $first_property_name, va_list $var_args
) returns N-GObject
  is native(&gobject-lib)
  { * }
}}


#`{{
#-------------------------------------------------------------------------------
#TM:0:g_object_connect:
=begin pod
=head2 [g_] object_connect

A convenience function to connect multiple signals at once.

The signal specs expected by this function have the form
"modifier::signal_name", where modifier can be one of the following:
* - signal: equivalent to g_signal_connect_data (..., NULL, 0)
- object-signal, object_signal: equivalent to g_signal_connect_object (..., 0)
- swapped-signal, swapped_signal: equivalent to g_signal_connect_data (..., NULL, G_CONNECT_SWAPPED)
- swapped_object_signal, swapped-object-signal: equivalent to g_signal_connect_object (..., G_CONNECT_SWAPPED)
- signal_after, signal-after: equivalent to g_signal_connect_data (..., NULL, G_CONNECT_AFTER)
- object_signal_after, object-signal-after: equivalent to g_signal_connect_object (..., G_CONNECT_AFTER)
- swapped_signal_after, swapped-signal-after: equivalent to g_signal_connect_data (..., NULL, G_CONNECT_SWAPPED | G_CONNECT_AFTER)
- swapped_object_signal_after, swapped-object-signal-after: equivalent to g_signal_connect_object (..., G_CONNECT_SWAPPED | G_CONNECT_AFTER)

|[<!-- language="C" -->
menu->toplevel = g_object_connect (g_object_new (GTK_TYPE_WINDOW,
"type", GTK_WINDOW_POPUP,
"child", menu,
NULL),
"signal::event", gtk_menu_window_event, menu,
"signal::size_request", gtk_menu_window_size_request, menu,
"signal::destroy", gtk_widget_destroyed, &menu->toplevel,
NULL);
]|

Returns: (transfer none) (type GObject.Object): I<object>

  method g_object_connect ( Pointer $object, Str $signal_spec --> Pointer  )

=item Pointer $object; (type GObject.Object): a I<GObject>
=item Str $signal_spec; the spec for the first signal @...: I<GCallback> for the first signal, followed by data for the first signal, followed optionally by more signal spec/callback/data triples, followed by C<Any>

=end pod

sub g_object_connect ( Pointer $object, Str $signal_spec, Any $any = Any )
  returns Pointer
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_disconnect:
=begin pod
=head2 [g_] object_disconnect

A convenience function to disconnect multiple signals at once.

The signal specs expected by this function have the form
"any_signal", which means to disconnect any signal with matching
callback and data, or "any_signal::signal_name", which only
disconnects the signal named "signal_name".

  method g_object_disconnect ( Pointer $object, Str $signal_spec )

=item Pointer $object; (type GObject.Object): a I<GObject>
=item Str $signal_spec; the spec for the first signal @...: I<GCallback> for the first signal, followed by data for the first signal, followed optionally by more signal spec/callback/data triples, followed by C<Any>

=end pod

sub g_object_disconnect ( Pointer $object, Str $signal_spec, Any $any = Any )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_freeze_notify:
=begin pod
=head2 [[g_] object_] freeze_notify

Increases the freeze count on I<object>. If the freeze count is
non-zero, the emission of "notify" signals on I<object> is
stopped. The signals are queued until the freeze count is decreased
to zero. Duplicate notifications are squashed so that at most one
prop I<notify> signal is emitted for each property modified while the
object is frozen.

This is necessary for accessors that modify multiple properties to prevent
premature notification while the object is still being modified.

  method g_object_freeze_notify ( )


=end pod

sub g_object_freeze_notify ( N-GObject $object )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_notify:
=begin pod
=head2 [g_] object_notify

Emits a "notify" signal for the property I<property_name> on I<object>.

When possible, eg. when signaling a property change from within the class
that registered the property, you should use C<g_object_notify_by_pspec()>
instead.

Note that emission of the notify signal may be blocked with
C<g_object_freeze_notify()>. In this case, the signal emissions are queued
and will be emitted (in reverse order) when C<g_object_thaw_notify()> is
called.

  method g_object_notify ( Str $property_name )

=item Str $property_name; the name of a property installed on the class of I<object>.

=end pod

sub g_object_notify ( N-GObject $object, Str $property_name )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_notify_by_pspec:
=begin pod
=head2 [[g_] object_] notify_by_pspec

Emits a "notify" signal for the property specified by I<pspec> on I<object>.

This function omits the property name lookup, hence it is faster than
C<g_object_notify()>.

One way to avoid using C<g_object_notify()> from within the
class that registered the properties, and using C<g_object_notify_by_pspec()>
instead, is to store the N-GParamSpec used with
C<g_object_class_install_property()> inside a static array, e.g.:

enum
{
PROP_0,
PROP_FOO,
PROP_LAST
};

static N-GParamSpec *properties[PROP_LAST];

static void
my_object_class_init (MyObjectClass *klass)
{
properties[PROP_FOO] = g_param_spec_int ("foo", "Foo", "The foo",
0, 100,
50,
G_PARAM_READWRITE);
g_object_class_install_property (gobject_class,
PROP_FOO,
properties[PROP_FOO]);
}
]|

and then notify a change on the "foo" property with:

|[<!-- language="C" -->
g_object_notify_by_pspec (self, properties[PROP_FOO]);
]|


  method g_object_notify_by_pspec ( N-GParamSpec $pspec )

=item N-GParamSpec $pspec; the I<N-GParamSpec> of a property installed on the class of I<object>.

=end pod

sub g_object_notify_by_pspec ( N-GObject $object, N-GParamSpec $pspec )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_thaw_notify:
=begin pod
=head2 [[g_] object_] thaw_notify

Reverts the effect of a previous call to
C<g_object_freeze_notify()>. The freeze count is decreased on I<object>
and when it reaches zero, queued "notify" signals are emitted.

Duplicate notifications for each property are squashed so that at most one
prop I<notify> signal is emitted for each property, in the reverse order
in which they have been queued.

It is an error to call this function when the freeze count is zero.

  method g_object_thaw_notify ( )


=end pod

sub g_object_thaw_notify ( N-GObject $object )
  is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
#TM:0:g_object_weak_ref:
=begin pod
=head2 [[g_] object_] weak_ref

Adds a weak reference callback to an object. Weak references are
used for notification when an object is finalized. They are called
"weak references" because they allow you to safely hold a pointer
to an object without calling C<g_object_ref()> (C<g_object_ref()> adds a
strong reference, that is, forces the object to stay alive).

Note that the weak references created by this method are not
thread-safe: they cannot safely be used in one thread if the
object's last C<g_object_unref()> might happen in another thread.
Use I<GWeakRef> if thread-safety is required.

  method g_object_weak_ref ( GWeakNotify $notify, Pointer $data )

=item GWeakNotify $notify; callback to invoke before the object is freed
=item Pointer $data; extra data to pass to notify

=end pod

sub g_object_weak_ref ( N-GObject $object, GWeakNotify $notify, Pointer $data )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_weak_unref:
=begin pod
=head2 [[g_] object_] weak_unref

Removes a weak reference callback to an object.

  method g_object_weak_unref ( GWeakNotify $notify, Pointer $data )

=item GWeakNotify $notify; callback to search for
=item Pointer $data; data to search for

=end pod

sub g_object_weak_unref ( N-GObject $object, GWeakNotify $notify, Pointer $data )
  is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
#TM:0:g_object_add_weak_pointer:
=begin pod
=head2 [[g_] object_] add_weak_pointer

Adds a weak reference from weak_pointer to I<object> to indicate that
the pointer located at I<weak_pointer_location> is only valid during
the lifetime of I<object>. When the I<object> is finalized,
I<weak_pointer> will be set to C<Any>.

Note that as with C<g_object_weak_ref()>, the weak references created by
this method are not thread-safe: they cannot safely be used in one
thread if the object's last C<g_object_unref()> might happen in another
thread. Use I<GWeakRef> if thread-safety is required.

  method g_object_add_weak_pointer ( Pointer $weak_pointer_location )

=item Pointer $weak_pointer_location; (inout) (not optional): The memory address of a pointer.

=end pod

sub g_object_add_weak_pointer ( N-GObject $object, Pointer $weak_pointer_location )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_remove_weak_pointer:
=begin pod
=head2 [[g_] object_] remove_weak_pointer

Removes a weak reference from I<object> that was previously added
using C<g_object_add_weak_pointer()>. The I<weak_pointer_location> has
to match the one used with C<g_object_add_weak_pointer()>.

  method g_object_remove_weak_pointer ( Pointer $weak_pointer_location )

=item Pointer $weak_pointer_location; (inout) (not optional): The memory address of a pointer.

=end pod

sub g_object_remove_weak_pointer ( N-GObject $object, Pointer $weak_pointer_location )
  is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
#TM:0:g_object_add_toggle_ref:
=begin pod
=head2 [[g_] object_] add_toggle_ref

Increases the reference count of the object by one and sets a
callback to be called when all other references to the object are
dropped, or when this is already the last reference to the object
and another reference is established.

This functionality is intended for binding I<object> to a proxy
object managed by another memory manager. This is done with two
paired references: the strong reference added by
C<g_object_add_toggle_ref()> and a reverse reference to the proxy
object which is either a strong reference or weak reference.

The setup is that when there are no other references to I<object>,
only a weak reference is held in the reverse direction from I<object>
to the proxy object, but when there are other references held to
I<object>, a strong reference is held. The I<notify> callback is called
when the reference from I<object> to the proxy object should be
"toggled" from strong to weak (I<is_last_ref> true) or weak to strong
(I<is_last_ref> false).

Since a (normal) reference must be held to the object before
calling C<g_object_add_toggle_ref()>, the initial state of the reverse
link is always strong.

Multiple toggle references may be added to the same gobject,
however if there are multiple toggle references to an object, none
of them will ever be notified until all but one are removed.  For
this reason, you should only ever use a toggle reference if there
is important state in the proxy object.


  method g_object_add_toggle_ref ( GToggleNotify $notify, Pointer $data )

=item GToggleNotify $notify; a function to call when this reference is the last reference to the object, or is no longer the last reference.
=item Pointer $data; data to pass to I<notify>

=end pod

sub g_object_add_toggle_ref ( N-GObject $object, GToggleNotify $notify, Pointer $data )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_remove_toggle_ref:
=begin pod
=head2 [[g_] object_] remove_toggle_ref

Removes a reference added with C<g_object_add_toggle_ref()>. The
reference count of the object is decreased by one.


  method g_object_remove_toggle_ref ( GToggleNotify $notify, Pointer $data )

=item GToggleNotify $notify; a function to call when this reference is the last reference to the object, or is no longer the last reference.
=item Pointer $data; data to pass to I<notify>

=end pod

sub g_object_remove_toggle_ref ( N-GObject $object, GToggleNotify $notify, Pointer $data )
  is native(&gobject-lib)
  { * }
}}
#`{{
#-------------------------------------------------------------------------------
#TM:0:g_object_get_qdata:
=begin pod
=head2 [[g_] object_] get_qdata

This function gets back user data pointers stored via
C<g_object_set_qdata()>.

Returns: (transfer none) (nullable): The user data pointer set, or C<Any>

  method g_object_get_qdata ( int32 $quark --> Pointer  )

=item int32 $quark; A I<GQuark>, naming the user data pointer

=end pod

sub g_object_get_qdata ( N-GObject $object, int32 $quark )
  returns Pointer
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_set_qdata:
=begin pod
=head2 [[g_] object_] set_qdata

This sets an opaque, named pointer on an object.
The name is specified through a I<GQuark> (retrived e.g. via
C<g_quark_from_static_string()>), and the pointer
can be gotten back from the I<object> with C<g_object_get_qdata()>
until the I<object> is finalized.
Setting a previously set user data pointer, overrides (frees)
the old pointer set, using I<NULL> as pointer essentially
removes the data stored.

  method g_object_set_qdata ( int32 $quark, Pointer $data )

=item int32 $quark; A I<GQuark>, naming the user data pointer
=item Pointer $data; (nullable): An opaque user data pointer

=end pod

sub g_object_set_qdata ( N-GObject $object, int32 $quark, Pointer $data )
  is native(&gobject-lib)
  { * }
}}
#`{{
#-------------------------------------------------------------------------------
#TM:0:g_object_set_qdata_full:
=begin pod
=head2 [[g_] object_] set_qdata_full

This function works like C<g_object_set_qdata()>, but in addition,
a void (*destroy) (gpointer) function may be specified which is
called with I<data> as argument when the I<object> is finalized, or
the data is being overwritten by a call to C<g_object_set_qdata()>
with the same I<quark>.

  method g_object_set_qdata_full ( int32 $quark, Pointer $data, GDestroyNotify $destroy )

=item int32 $quark; A I<GQuark>, naming the user data pointer
=item Pointer $data; (nullable): An opaque user data pointer
=item GDestroyNotify $destroy; (nullable): Function to invoke with I<data> as argument, when I<data> needs to be freed

=end pod

sub g_object_set_qdata_full ( N-GObject $object, int32 $quark, Pointer $data, GDestroyNotify $destroy )
  is native(&gobject-lib)
  { * }
}}
#`{{
#-------------------------------------------------------------------------------
#TM:0:g_object_steal_qdata:
=begin pod
=head2 [[g_] object_] steal_qdata

This function gets back user data pointers stored via
C<g_object_set_qdata()> and removes the I<data> from object
without invoking its C<destroy()> function (if any was
set).
Usually, calling this function is only required to update
user data pointers with a destroy notifier, for example:
|[<!-- language="C" -->
void
object_add_to_user_list (GObject     *object,
const gchar *new_string)
{
// the quark, naming the object data
GQuark quark_string_list = g_quark_from_static_string ("my-string-list");
// retrive the old string list
GList *list = g_object_steal_qdata (object, quark_string_list);

// prepend new string
list = g_list_prepend (list, g_strdup (new_string));
// this changed 'list', so we need to set it again
g_object_set_qdata_full (object, quark_string_list, list, free_string_list);
}
static void
free_string_list (gpointer data)
{
GList *node, *list = data;

for (node = list; node; node = node->next)
g_free (node->data);
g_list_free (list);
}
]|
Using C<g_object_get_qdata()> in the above example, instead of
C<g_object_steal_qdata()> would have left the destroy function set,
and thus the partial string list would have been freed upon
C<g_object_set_qdata_full()>.

Returns: (transfer full) (nullable): The user data pointer set, or C<Any>

  method g_object_steal_qdata ( int32 $quark --> Pointer  )

=item int32 $quark; A I<GQuark>, naming the user data pointer

=end pod

sub g_object_steal_qdata ( N-GObject $object, int32 $quark )
  returns Pointer
  is native(&gobject-lib)
  { * }
}}
#`{{
#-------------------------------------------------------------------------------
#TM:0:g_object_dup_qdata:
=begin pod
=head2 [[g_] object_] dup_qdata

This is a variant of C<g_object_get_qdata()> which returns
a 'duplicate' of the value. I<dup_func> defines the
meaning of 'duplicate' in this context, it could e.g.
take a reference on a ref-counted object.

If the I<quark> is not set on the object then I<dup_func>
will be called with a C<Any> argument.

Note that I<dup_func> is called while user data of I<object>
is locked.

This function can be useful to avoid races when multiple
threads are using object data on the same key on the same
object.

Returns: the result of calling I<dup_func> on the value
associated with I<quark> on I<object>, or C<Any> if not set.
If I<dup_func> is C<Any>, the value is returned
unmodified.


  method g_object_dup_qdata ( int32 $quark, GDuplicateFunc $dup_func, Pointer $user_data --> Pointer  )

=item int32 $quark; a I<GQuark>, naming the user data pointer
=item GDuplicateFunc $dup_func; (nullable): function to dup the value
=item Pointer $user_data; (nullable): passed as user_data to I<dup_func>

=end pod

sub g_object_dup_qdata ( N-GObject $object, int32 $quark, GDuplicateFunc $dup_func, Pointer $user_data )
  returns Pointer
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_replace_qdata:
=begin pod
=head2 [[g_] object_] replace_qdata

Compares the user data for the key I<quark> on I<object> with
I<oldval>, and if they are the same, replaces I<oldval> with
I<newval>.

This is like a typical atomic compare-and-exchange
operation, for user data on an object.

If the previous value was replaced then ownership of the
old value (I<oldval>) is passed to the caller, including
the registered destroy notify for it (passed out in I<old_destroy>).
It’s up to the caller to free this as needed, which may
or may not include using I<old_destroy> as sometimes replacement
should not destroy the object in the normal way.

Returns: C<1> if the existing value for I<quark> was replaced
by I<newval>, C<0> otherwise.


  method g_object_replace_qdata ( int32 $quark, Pointer $oldval, Pointer $newval, GDestroyNotify $destroy, GDestroyNotify $old_destroy --> Int  )

=item int32 $quark; a I<GQuark>, naming the user data pointer
=item Pointer $oldval; (nullable): the old value to compare against
=item Pointer $newval; (nullable): the new value
=item GDestroyNotify $destroy; (nullable): a destroy notify for the new value
=item GDestroyNotify $old_destroy; (out) (optional): destroy notify for the existing value

=end pod

sub g_object_replace_qdata ( N-GObject $object, int32 $quark, Pointer $oldval, Pointer $newval, GDestroyNotify $destroy, GDestroyNotify $old_destroy )
  returns int32
  is native(&gobject-lib)
  { * }
}}
#`{{
#-------------------------------------------------------------------------------
#TM:0:g_object_set_data_full:
=begin pod
=head2 [[g_] object_] set_data_full

Like C<g_object_set_data()> except it adds notification
for when the association is destroyed, either by setting it
to a different value or when the object is destroyed.

Note that the I<destroy> callback is not called if I<data> is C<Any>.

  method g_object_set_data_full ( Str $key, Pointer $data, GDestroyNotify $destroy )

=item Str $key; name of the key
=item Pointer $data; (nullable): data to associate with that key
=item GDestroyNotify $destroy; (nullable): function to call when the association is destroyed

=end pod

sub g_object_set_data_full ( N-GObject $object, Str $key, Pointer $data, GDestroyNotify $destroy )
  is native(&gobject-lib)
  { * }
}}
#`{{


#-------------------------------------------------------------------------------
#TM:0:g_object_dup_data:
=begin pod
=head2 [[g_] object_] dup_data

This is a variant of C<g_object_get_data()> which returns
a 'duplicate' of the value. I<dup_func> defines the
meaning of 'duplicate' in this context, it could e.g.
take a reference on a ref-counted object.

If the I<key> is not set on the object then I<dup_func>
will be called with a C<Any> argument.

Note that I<dup_func> is called while user data of I<object>
is locked.

This function can be useful to avoid races when multiple
threads are using object data on the same key on the same
object.

Returns: the result of calling I<dup_func> on the value
associated with I<key> on I<object>, or C<Any> if not set.
If I<dup_func> is C<Any>, the value is returned
unmodified.


  method g_object_dup_data ( Str $key, GDuplicateFunc $dup_func, Pointer $user_data --> Pointer  )

=item Str $key; a string, naming the user data pointer
=item GDuplicateFunc $dup_func; (nullable): function to dup the value
=item Pointer $user_data; (nullable): passed as user_data to I<dup_func>

=end pod

sub g_object_dup_data ( N-GObject $object, Str $key, GDuplicateFunc $dup_func, Pointer $user_data )
  returns Pointer
  is native(&gobject-lib)
  { * }
}}

#`{{
}}
#`{{
#-------------------------------------------------------------------------------
#TM:0:g_object_watch_closure:
=begin pod
=head2 [[g_] object_] watch_closure

This function essentially limits the life time of the I<closure> to
the life time of the object. That is, when the object is finalized,
the I<closure> is invalidated by calling C<g_closure_invalidate()> on
it, in order to prevent invocations of the closure with a finalized
(nonexisting) object. Also, C<g_object_ref()> and C<g_object_unref()> are
added as marshal guards to the I<closure>, to ensure that an extra
reference count is held on I<object> during invocation of the
I<closure>.  Usually, this function will be called on closures that
use this I<object> as closure data.

  method g_object_watch_closure ( N-GObject $closure )

=item N-GObject $closure; I<GClosure> to watch

=end pod

sub g_object_watch_closure ( N-GObject $object, N-GObject $closure )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_cclosure_new_object:
=begin pod
=head2 [g_] cclosure_new_object

A variant of C<g_cclosure_new()> which uses I<object> as I<user_data> and
calls C<g_object_watch_closure()> on I<object> and the created
closure. This function is useful when you have a callback closely
associated with a I<GObject>, and want the callback to no longer run
after the object is is freed.

Returns: a new I<GCClosure>

  method g_cclosure_new_object ( GCallback $callback_func, N-GObject $object --> N-GObject  )

=item GCallback $callback_func; the function to invoke
=item N-GObject $object; a I<GObject> pointer to pass to I<callback_func>

=end pod

sub g_cclosure_new_object ( GCallback $callback_func, N-GObject $object )
  returns N-GObject
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_cclosure_new_object_swap:
=begin pod
=head2 [g_] cclosure_new_object_swap

A variant of C<g_cclosure_new_swap()> which uses I<object> as I<user_data>
and calls C<g_object_watch_closure()> on I<object> and the created
closure. This function is useful when you have a callback closely
associated with a I<GObject>, and want the callback to no longer run
after the object is is freed.

Returns: a new I<GCClosure>

  method g_cclosure_new_object_swap ( GCallback $callback_func, N-GObject $object --> N-GObject  )

=item GCallback $callback_func; the function to invoke
=item N-GObject $object; a I<GObject> pointer to pass to I<callback_func>

=end pod

sub g_cclosure_new_object_swap ( GCallback $callback_func, N-GObject $object )
  returns N-GObject
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_closure_new_object:
=begin pod
=head2 [g_] closure_new_object

A variant of C<g_closure_new_simple()> which stores I<object> in the
I<data> field of the closure and calls C<g_object_watch_closure()> on
I<object> and the created closure. This function is mainly useful
when implementing new types of closures.

Returns: (transfer full): a newly allocated I<GClosure>

  method g_closure_new_object ( UInt $sizeof_closure, N-GObject $object --> N-GObject  )

=item UInt $sizeof_closure; the size of the structure to allocate, must be at least `sizeof (GClosure)`
=item N-GObject $object; a I<GObject> pointer to store in the I<data> field of the newly allocated I<GClosure>

=end pod

sub g_closure_new_object ( uint32 $sizeof_closure, N-GObject $object )
  returns N-GObject
  is native(&gobject-lib)
  { * }
}}
#`{{
#-------------------------------------------------------------------------------
#TM:0:g_value_set_object:
=begin pod
=head2 [g_] value_set_object

Set the contents of a C<G_TYPE_OBJECT> derived I<GValue> to I<v_object>.

C<g_value_set_object()> increases the reference count of I<v_object>
(the I<GValue> holds a reference to I<v_object>).  If you do not wish
to increase the reference count of the object (i.e. you wish to
pass your current reference to the I<GValue> because you no longer
need it), use C<g_value_take_object()> instead.

It is important that your I<GValue> holds a reference to I<v_object> (either its
own, or one it has taken) to ensure that the object won't be destroyed while
the I<GValue> still exists).

  method g_value_set_object ( N-GObject $value, Pointer $v_object )

=item N-GObject $value; a valid I<GValue> of C<G_TYPE_OBJECT> derived type
=item Pointer $v_object; (type GObject.Object) (nullable): object value to be set

=end pod

sub g_value_set_object ( N-GObject $value, Pointer $v_object )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_get_object:
=begin pod
=head2 [g_] value_get_object

Get the contents of a C<G_TYPE_OBJECT> derived I<GValue>.

Returns: (type GObject.Object) (transfer none): object contents of I<value>

  method g_value_get_object ( N-GObject $value --> Pointer  )

=item N-GObject $value; a valid I<GValue> of C<G_TYPE_OBJECT> derived type

=end pod

sub g_value_get_object ( N-GObject $value )
  returns Pointer
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_dup_object:
=begin pod
=head2 [g_] value_dup_object

Get the contents of a C<G_TYPE_OBJECT> derived I<GValue>, increasing
its reference count. If the contents of the I<GValue> are C<Any>, then
C<Any> will be returned.

Returns: (type GObject.Object) (transfer full): object content of I<value>,
should be unreferenced when no longer needed.

  method g_value_dup_object ( N-GObject $value --> Pointer  )

=item N-GObject $value; a valid I<GValue> whose type is derived from C<G_TYPE_OBJECT>

=end pod

sub g_value_dup_object ( N-GObject $value )
  returns Pointer
  is native(&gobject-lib)
  { * }
}}
#`{{
#-------------------------------------------------------------------------------
#TM:0:g_signal_connect_object:
=begin pod
=head2 [g_] signal_connect_object

This is similar to C<g_signal_connect_data()>, but uses a closure which
ensures that the I<gobject> stays alive during the call to I<c_handler>
by temporarily adding a reference count to I<gobject>.

When the I<gobject> is destroyed the signal handler will be automatically
disconnected.  Note that this is not currently threadsafe (ie:
emitting a signal while I<gobject> is being destroyed in another thread
is not safe).

Returns: the handler id.

  method g_signal_connect_object ( Pointer $instance, Str $detailed_signal, GCallback $c_handler, Pointer $gobject, GConnectFlags $connect_flags --> UInt  )

=item Pointer $instance; (type GObject.TypeInstance): the instance to connect to.
=item Str $detailed_signal; a string of the form "signal-name::detail".
=item GCallback $c_handler; the I<GCallback> to connect.
=item Pointer $gobject; (type GObject.Object) (nullable): the object to pass as data to I<c_handler>.
=item GConnectFlags $connect_flags; a combination of I<GConnectFlags>.

=end pod

sub g_signal_connect_object ( Pointer $instance, Str $detailed_signal, GCallback $c_handler, Pointer $gobject, int32 $connect_flags )
  returns uint64
  is native(&gobject-lib)
  { * }
}}
#`{{
#-------------------------------------------------------------------------------
#TM:0:g_object_force_floating:
=begin pod
=head2 [[g_] object_] force_floating

This function is intended for I<GObject> implementations to re-enforce
a [floating][floating-ref] object reference. Doing this is seldom
required: all I<GInitiallyUnowneds> are created with a floating reference
which usually just needs to be sunken by calling C<g_object_ref_sink()>.


  method g_object_force_floating ( )


=end pod

sub g_object_force_floating ( N-GObject $object )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_run_dispose:
=begin pod
=head2 [[g_] object_] run_dispose

Releases all references to other objects. This can be used to break
reference cycles.

This function should only be called from object system implementations.

  method g_object_run_dispose ( )


=end pod

sub g_object_run_dispose ( N-GObject $object )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_value_take_object:
=begin pod
=head2 [g_] value_take_object

Sets the contents of a C<G_TYPE_OBJECT> derived I<GValue> to I<v_object>
and takes over the ownership of the callers reference to I<v_object>;
the caller doesn't have to unref it any more (i.e. the reference
count of the object is not increased).

If you want the I<GValue> to hold its own reference to I<v_object>, use
C<g_value_set_object()> instead.


  method g_value_take_object ( N-GObject $value, Pointer $v_object )

=item N-GObject $value; a valid I<GValue> of C<G_TYPE_OBJECT> derived type
=item Pointer $v_object; (nullable): object value to be set

=end pod

sub g_value_take_object ( N-GObject $value, Pointer $v_object )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_clear_object:
=begin pod
=head2 [g_] clear_object

Clears a reference to a I<GObject>.

I<object_ptr> must not be C<Any>.

If the reference is C<Any> then this function does nothing.
Otherwise, the reference count of the object is decreased and the
pointer is set to C<Any>.

A macro is also included that allows this function to be used without
pointer casts.


  method g_clear_object ( )


=end pod

sub g_clear_object ( N-GObject $object_ptr )
  is native(&gobject-lib)
  { * }
}}
#`{{
#-------------------------------------------------------------------------------
#TM:0:g_weak_ref_init:
=begin pod
=head2 [g_] weak_ref_init

Initialise a non-statically-allocated I<GWeakRef>.

This function also calls C<g_weak_ref_set()> with I<object> on the
freshly-initialised weak reference.

This function should always be matched with a call to
C<g_weak_ref_clear()>.  It is not necessary to use this function for a
I<GWeakRef> in static storage because it will already be
properly initialised.  Just use C<g_weak_ref_set()> directly.


  method g_weak_ref_init ( GWeakRef $weak_ref, Pointer $object )

=item GWeakRef $weak_ref; (inout): uninitialized or empty location for a weak reference
=item Pointer $object; (type GObject.Object) (nullable): a I<GObject> or C<Any>

=end pod

sub g_weak_ref_init ( GWeakRef $weak_ref, Pointer $object )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_weak_ref_clear:
=begin pod
=head2 [g_] weak_ref_clear

Frees resources associated with a non-statically-allocated I<GWeakRef>.
After this call, the I<GWeakRef> is left in an undefined state.

You should only call this on a I<GWeakRef> that previously had
C<g_weak_ref_init()> called on it.


  method g_weak_ref_clear ( GWeakRef $weak_ref )

=item GWeakRef $weak_ref; (inout): location of a weak reference, which may be empty

=end pod

sub g_weak_ref_clear ( GWeakRef $weak_ref )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_weak_ref_get:
=begin pod
=head2 [g_] weak_ref_get

If I<weak_ref> is not empty, atomically acquire a strong
reference to the object it points to, and return that reference.

This function is needed because of the potential race between taking
the pointer value and C<g_object_ref()> on it, if the object was losing
its last reference at the same time in a different thread.

The caller should release the resulting reference in the usual way,
by using C<g_object_unref()>.

Returns: (transfer full) (type GObject.Object): the object pointed to
by I<weak_ref>, or C<Any> if it was empty


  method g_weak_ref_get ( GWeakRef $weak_ref --> Pointer  )

=item GWeakRef $weak_ref; (inout): location of a weak reference to a I<GObject>

=end pod

sub g_weak_ref_get ( GWeakRef $weak_ref )
  returns Pointer
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_weak_ref_set:
=begin pod
=head2 [g_] weak_ref_set

Change the object to which I<weak_ref> points, or set it to
C<Any>.

You must own a strong reference on I<object> while calling this
function.


  method g_weak_ref_set ( GWeakRef $weak_ref, Pointer $object )

=item GWeakRef $weak_ref; location for a weak reference
=item Pointer $object; (type GObject.Object) (nullable): a I<GObject> or C<Any>

=end pod

sub g_weak_ref_set ( GWeakRef $weak_ref, Pointer $object )
  is native(&gobject-lib)
  { * }
}}

#-------------------------------------------------------------------------------
=begin pod
=head1 Signals

Registering example

  class MyHandlers {
    method my-click-handler ( :$widget, :$my-data ) { ... }
  }

  # elsewhere
  my MyHandlers $mh .= new;
  $button.register-signal( $mh, 'click-handler', 'clicked', :$my-data);

See also method C<register-signal> in Gnome::GObject::Object.

=head2 Not yet supported signals
=head3 notify

The notify signal is emitted on an object when one of its properties has its value set through g_object_set_property(), g_object_set(), et al.

Note that getting this signal doesn’t itself guarantee that the value of the property has actually changed. When it is emitted is determined by the derived GObject class. If the implementor did not create the property with C<G_PARAM_EXPLICIT_NOTIFY>, then any call to g_object_set_property() results in C<notify> being emitted, even if the new value is the same as the old. If they did pass C<G_PARAM_EXPLICIT_NOTIFY>, then this signal is emitted only when they explicitly call C<g_object_notify()> or C<g_object_notify_by_pspec()>, and common practice is to do that only when the value has actually changed.

=begin comment
This signal is typically used to obtain change notification for a single property, by specifying the property name as a detail in the C<g_signal_connect()> call, like this:

  g_signal_connect(
    text_view->buffer, "notify::paste-target-list",
    G_CALLBACK (gtk_text_view_target_list_notify), text_view
  );

It is important to note that you must use [canonical parameter names][canonical-parameter-names] as detail strings for the notify signal.
=end comment

  method handler (
    Int :$_handler_id,
    Gnome::GObject::Object :_widget($gobject),
    :handler-arg0($pspec),
    :$user-option1, ..., :$user-optionN
  );

=item $gobject; the object which received the signal.
=item $pspec; the I<N-GParamSpec> of the property which changed.

=end pod
