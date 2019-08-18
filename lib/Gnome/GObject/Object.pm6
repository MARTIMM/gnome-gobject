#TL:0:Gnome::GObject::Object:

use v6;
#-------------------------------------------------------------------------------
=begin pod

=TITLE Gnome::GObject::Object

=SUBTITLE The base object type

=head1 Description

GObject is the fundamental type providing the common attributes and methods for all object types in GTK+, Pango and other libraries based on GObject. The GObject class provides methods for object construction and destruction, property access methods, and signal support.

=begin comment

Signals are described in detail [here][gobject-Signals].

For a tutorial on implementing a new GObject class, see [How to define and
implement a new GObject][howto-gobject]. For a list of naming conventions for
GObjects and their methods, see the [GType conventions][gtype-conventions].
For the high-level concepts behind GObject, read [Instantiable classed types:
Objects][gtype-instantiable-classed].

=head2 Floating references

I<Gnome::GObject::InitiallyUnowned> is derived from I<Gnome::GObject::Object>. The only difference between the two is that the initial reference of a GInitiallyUnowned is flagged as a "floating" reference. This means that it is not specifically claimed to be "owned" by any code portion. The main motivation for providing floating references is C convenience. In particular, it allows code to be written as (in C):

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

Some object implementations may need to save an objects floating state across certain code portions (an example is I<Gnome::Gtk3::Menu>), to achieve this, the following sequence can be used:

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

=end comment

=head2 See Also

I<GParamSpecObject>, C<g_param_spec_object()>

=head1 Synopsis
=head2 Declaration

  unit class Gnome::GObject::Object;

=head2 Example

Top level class of almost all classes in the GTK, GDK and Glib libraries.

This object is almost never used directly. Most of the classes inherit from this class. The below example shows how label text is set on a button using properties. This can be made much simpler by setting this label directly in the init of C<Gnome::Gtk3::Button>. The purpose of this example, however, is that there might be other properties which can only be set this way.

  use Gnome::GObject::Object;
  use Gnome::GObject::Value;
  use Gnome::GObject::Type;
  use Gnome::Gtk3::Button;

  my Gnome::GObject::Value $gv .= new(:init(G_TYPE_STRING));

  my Gnome::Gtk3::Button $b .= new(:empty);
  $gv.g-value-set-string('Open file');
  $b.g-object-set-property( 'label', $gv);

=end pod

#-------------------------------------------------------------------------------
use NativeCall;

use Gnome::N::X;
use Gnome::N::NativeLib;
use Gnome::N::N-GObject;

use Gnome::Glib::Main;
use Gnome::GObject::Signal;
use Gnome::GObject::Type;
use Gnome::GObject::Value;

#-------------------------------------------------------------------------------
unit class Gnome::GObject::Object:auth<github:MARTIMM>;

#-------------------------------------------------------------------------------
my Hash $signal-types = {};
my Bool $signals-added = False;

has N-GObject $!g-object;
has Gnome::GObject::Signal $!g-signal;
has Int $!gtk-class-gtype;
has Str $!gtk-class-name;
has Str $!gtk-class-name-of-sub;

# type is Gnome::Gtk3::Builder. Cannot load module because of circular dep.
# attribute is set by GtkBuilder via set-builder(). There might be more than one
my Array $builders = [];
my Bool $gui-initialized = False;

has Bool $.gobject-is-valid = False;

#-------------------------------------------------------------------------------
# no pod. user does not have to know about it.
# this sub belongs to Gnome::Gtk3::Main but is needed here. To avoid
# dependencies, the sub is redeclared here for this purpose
sub _initialize_gtk ( CArray[int32] $argc, CArray[CArray[Str]] $argv )
  returns int32
  is native(&gtk-lib)
  is symbol('gtk_init_check')
  { * }

#-------------------------------------------------------------------------------
=begin pod
=head1 Methods
=head2 new
Please note that this class is mostly not instantiated directly but is used indirectly when child classes are instantiated.

=begin comment
=head3 multi method new ( :empty! )
Create an empty object
=end comment

=head3 multi method new ( :$widget! )

Create a Perl6 widget object using a native widget from elsewhere. $widget can be a N-GOBject or a Perl6 widget like C< Gnome::Gtk3::Button>.

  # Some set of radio buttons grouped together
  my Gnome::Gtk3::RadioButton $rb1 .= new(:label('Download everything'));
  my Gnome::Gtk3::RadioButton $rb2 .= new(
    :group-from($rb1), :label('Download core only')
  );

  # Get all radio buttons in the group of button $rb2
  my Gnome::GObject::SList $rb-list .= new(:gslist($rb2.get-group));
  loop ( Int $i = 0; $i < $rb-list.g_slist_length; $i++ ) {
    # Get button from the list
    my Gnome::Gtk3::RadioButton $rb .= new(
      :widget($rb-list.nth-data-gobject($i))
    );

    # If radio button is selected (=active) ...
    if $rb.get-active == 1 {
      ...

      last;
    }
  }

Another example is a difficult way to get a button.

  my Gnome::Gtk3::Button $start-button .= new(
    :widget(Gnome::Gtk3::Button.gtk_button_new_with_label('Start'))
  );

=head3 multi method new ( Str :$build-id! )

Create a Perl6 widget object using a C<Gnome::Gtk3::Builder>. The builder class will return its corresponding object address and it will be stored in the C<Gnome::GObject::Object>. It can then be used to search for id's defined in the GUI glade design.

  my Gnome::Gtk3::Builder $builder .= new(:filename<my-gui.glade>);
  my Gnome::Gtk3::Button $button .= new(:build-id<my-gui-button>);

Create a C<Gnome::GObject:Object> object. Rarely used directly.
=end pod

submethod BUILD ( *%options ) {

  # check GTK+ init
  if not $gui-initialized {
    # must setup gtk otherwise perl6 will crash
    my $argc = CArray[int32].new;
    $argc[0] = 1 + @*ARGS.elems;

    my $arg_arr = CArray[Str].new;
    my Int $arg-count = 0;
    $arg_arr[$arg-count++] = $*PROGRAM.Str;
    for @*ARGS -> $arg {
      $arg_arr[$arg-count++] = $arg;
    }

    my $argv = CArray[CArray[Str]].new;
    $argv[0] = $arg_arr;

    # call gtk_init_check
    _initialize_gtk( $argc, $argv);
    $gui-initialized = True;
  }

  # add signal types
  unless $signals-added {
    $signals-added = self.add-signal-types( $?CLASS.^name, :GParamSpec<notify>);
  }

  # process options
  if ? %options<type> and ? %options<names> and ? %options<values> {
    if %options<names> ~~ Array and %options<values> ~~ Array and
       %options<names>.elems == %options<values>.elems {

      my CArray[Str] $n .= new;
      my CArray[N-GValue] $v .= new;

      loop ( my Int $i = 0; $i < ^ %options<names>.elems; $i++ ) {
        $n[$i] = %options<names>[$i];
        $v[$i] = %options<values>[$i];
      }

      self.native-gobject(
        g_object_new_with_properties(
          %options<type>, %options<names>.elems, $n, $v
        )
      );
    }

    else {

      if $!gobject-is-valid {
        g_object_unref(self.native-gobject());
        $!gobject-is-valid = False;
      }

      note 'names array wrong type'
        if $Gnome::N::x-debug and %options<names> !~~ Array;
      note 'values array wrong type'
        if $Gnome::N::x-debug and %options<values> !~~ Array;
      note 'names array not same length as values array'
        if $Gnome::N::x-debug and
           %options<names>.elems != %options<values>.elems;

      die X::Gnome.new(
        :message('One or all options type, names or values are wrong')
      );
    }
  }

  elsif ? %options<widget> {
    note "gobject widget: ", %options<widget> if $Gnome::N::x-debug;

    my $w = %options<widget>;
    if $w ~~ Gnome::GObject::Object {
      $w = $w();
      note "gobject widget converted: ", $w if $Gnome::N::x-debug;
    }

    if ?$w and $w ~~ N-GObject {
      if $!gobject-is-valid {
        g_object_unref(self.native-gobject());
        $!gobject-is-valid = False;
      }
      self.native-gobject($w);
      $!gobject-is-valid = True;
      note "gobject widget stored" if $Gnome::N::x-debug;
    }

    elsif ?$w and $w ~~ NativeCall::Types::Pointer {
      if $!gobject-is-valid {
        g_object_unref(self.native-gobject());
        $!gobject-is-valid = False;
      }
      self.native-gobject(nativecast( N-GObject, $w));
      $!gobject-is-valid = True;
      note "gobject widget cast to GObject" if $Gnome::N::x-debug;
    }

    else {
      note "wrong type or undefined widget" if $Gnome::N::x-debug;
      if $!gobject-is-valid {
        g_object_unref(self.native-gobject());
        $!gobject-is-valid = False;
      }
      die X::Gnome.new(:message('Wrong type or undefined widget'));
    }
  }

  elsif ? %options<build-id> {
    my N-GObject $widget;
    note "gobject build-id: %options<build-id>" if $Gnome::N::x-debug;
    my Array $builders = self.get-builders;
    for @$builders -> $builder {
      # this action does not increase object refcount, do it here.
      $widget = $builder.get-object(%options<build-id>);
      #TODO self.g_object_ref();
      last if ?$widget;
    }

    if ? $widget {
      note "store gobject widget: ", self.^name, ', ', $widget
        if $Gnome::N::x-debug;
      self.native-gobject($widget);
    }

    else {
      note "builder id '%options<build-id>' not found in any of the builders"
        if $Gnome::N::x-debug;
      if $!gobject-is-valid {
        g_object_unref(self.native-gobject());
        $!gobject-is-valid = False;
      }
      die X::Gnome.new(
        :message(
          "Builder id '%options<build-id>' not found in any of the builders"
        )
      );
    }
  }

  else {
    if %options.keys.elems == 0 {
      note 'No options used to create or set the native widget'
        if $Gnome::N::x-debug;
      if $!gobject-is-valid {
        g_object_unref(self.native-gobject());
        $!gobject-is-valid = False;
      }
      die X::Gnome.new(
        :message('No options used to create or set the native widget')
      );
    }
  }

  #TODO if %options<id> add id, %options<name> add name
  #cannot add id,seems to be a builder thing.
}

#-------------------------------------------------------------------------------
# no pod. user does not have to know about it.
#TODO destroy when overwritten? g_object_unref?
method CALL-ME ( N-GObject $widget? --> N-GObject ) {

  if ?$widget {
    # if native object exists it will be overwritten. unref object first.
    if ?$!g-object {
      #TODO self.g_object_unref();
    }
    $!g-object = $widget;
    #TODO self.g_object_ref();
  }

  $!g-object
}

#-------------------------------------------------------------------------------
# no pod. user does not have to know about it.
#
# Fallback method to find the native subs which then can be called as if it
# were a method. Each class must provide their own 'fallback' method which,
# when nothing found, must call the parents fallback with 'callsame'.
# The subs in some class all start with some prefix which can be left out too
# provided that the fallback functions must also test with an added prefix.
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

  # call the fallback functions of this classes children starting
  # at the bottom
  $s = self.fallback($native-sub);

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
}

#-------------------------------------------------------------------------------
# no pod. user does not have to know about it.
method fallback ( $native-sub --> Callable ) {

  my Callable $s;

  try { $s = &::($native-sub); }
  try { $s = &::("g_object_$native-sub"); } unless ?$s;


  # Try to solve sub names from the GSignal class
  unless ?$s {
    $!g-signal .= new(:$!g-object);
    note "GSignal look for $native-sub: ", $!g-signal if $Gnome::N::x-debug;

    $s = $!g-signal.FALLBACK( $native-sub, :return-sub-only);
  }

  self.set-class-name-of-sub('GObject');
  $s = callsame unless ?$s;

  $s
}

#-------------------------------------------------------------------------------
# no pod. user does not have to know about it.
method set-class-info ( Str:D $!gtk-class-name ) {
  $!gtk-class-gtype =
    Gnome::GObject::Type.new().g_type_from_name($!gtk-class-name);
}

#-------------------------------------------------------------------------------
# no pod. user does not have to know about it.
method set-class-name-of-sub ( Str:D $!gtk-class-name-of-sub ) { }

#-------------------------------------------------------------------------------
=begin pod
=head2 get-class-gtype

Return class's type code after registration. this is like calling Gnome::GObject::Type.new().g_type_from_name(GTK+ class type name).

  method get-class-gtype ( --> Int )
=end pod

method get-class-gtype ( --> Int ) {
  $!gtk-class-gtype
}

#-------------------------------------------------------------------------------
=begin pod
=head2 get-class-name

Return class name.

  method get-class-name ( --> Str )
=end pod

method get-class-name ( --> Str ) {
  $!gtk-class-name
}

#-------------------------------------------------------------------------------
# no pod. user does not have to know about it.
#TODO destroy when overwritten?
method native-gobject (
  N-GObject $widget?, Bool :$force = False --> N-GObject
) {
  if ?$widget and ( $force or !$!g-object ) {

    # if defined, setting is forced
    if ?$!g-object {
      #TODO self.g_object_unref();
    }
    $!g-object = $widget;
    #TODO self.g_object_ref();
  }

  # when object is set, create signal object too
  $!g-signal .= new(:$!g-object) if ?$!g-object;

  $!g-object
}

#-------------------------------------------------------------------------------
#TODO place in Gnome::Gtk3
# no pod. user does not have to know about it.
method set-builder ( $builder ) {
  $builders.push($builder);
}

#-------------------------------------------------------------------------------
# no pod. user does not have to know about it.
method get-builders ( --> Array ) {
  $builders;
}

#-------------------------------------------------------------------------------
# no pod. user does not have to know about it.
method add-signal-types ( Str $module-name, *%signal-descriptions --> Bool ) {

  # must store signal names under the class name because I found the use of
  # the same signal name with different handler signatures in different classes.
  $signal-types{$module-name} //= {};

  note "\nTest signal names for {$?CLASS.^name}" if $Gnome::N::x-debug;
  for %signal-descriptions.kv -> $signal-type, $signal-names {
    my @names = $signal-names ~~ List ?? @$signal-names !! ($signal-names,);
    for @names -> $signal-name {
      if $signal-type ~~ any(<signal event nativewidget>) {
        note "  $module-name, $signal-name --> $signal-type"
          if $Gnome::N::x-debug;
        $signal-types{$module-name}{$signal-name} = $signal-type;
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
# no pod. user does not have to know about it.
# pinched from Gnome::GObject::Signal
sub g_object_connect_object_signal(
  N-GObject $widget, Str $signal,
  Callable $handler ( N-GObject, OpaquePointer ),
  OpaquePointer $data, int32 $connect_flags
) returns uint64
  is native(&gobject-lib)
  is symbol('g_signal_connect_object')
  { * }

#-------------------------------------------------------------------------------
# no pod. user does not have to know about it.
# pinched from Gnome::GObject::Signal
sub g_object_connect_object_nativewidget(
  N-GObject $widget, Str $signal,
  Callable $handler ( N-GObject, N-GObject, OpaquePointer ),
  OpaquePointer $data, int32 $connect_flags
) returns uint64
  is native(&gobject-lib)
  is symbol('g_signal_connect_object')
  { * }

#-------------------------------------------------------------------------------
=begin pod
=head2 register-signal

Register a handler to process a signal or an event. There are several types of callbacks which can be handled by this regstration. They can be controlled by using a named argument with a special name.

  method register-signal (
    $handler-object, Str:D $handler-name,
    Str:D $signal-name, *%user-options
    --> Bool
  )

=begin item
$handler-object; The object wherein the handler is defined.
=end item

=begin item
$handler-name; The name of the method. Commonly used signatures for those
handlers are;

=begin code
  handler ( object: :$widget, :$user-option1, ..., :$user-optionN )
  handler (
    object: :$widget, :handler-arg0($event),
    :$user-option1, ..., :$user-optionN
  )
  handler (
    object: :$widget, :handler-arg0($nativewidget),
    :$user-option1, ..., :$user-optionN
  )
=end code

Other forms are explained in the widget documentations when signals are provided.
=end item


=begin item
$signal-name; The name of the event to be handled. Each gtk object has its own series of signals.
=end item

=begin item
%user-options; Any other user data in whatever type. These arguments are
provided to the user handler when an event for the handler is fired. There
will always be one named argument C<:$widget> which holds the class object
on which the signal was registered. The name 'widget' is therefore reserved.
An other reserved named argument is of course C<:$event>.
=end item


=begin code
  # create a class holding a handler method to process a click event
  # of a button.
  class X {
    method click-handler ( :widget($button), Array :$user-data ) {
      say $user-data.join(' ');
    }
  }

  # create a button and some data to send with the signal
  my Gnome::Gtk3::Button $button .= new(:label('xyz'));
  my Array $data = [<Hello World>];

  # register button signal
  my X $x .= new(:empty);
  $button.register-signal( $x, 'click-handler', 'clicked', :user-data($data));
=end code

=end pod

multi method register-signal (
  $handler-object, Str:D $handler-name, Str:D $signal-name, *%user-options
  --> Bool
) {

  my Callable $handler;

  # don't register if handler is not available
  my Method $sh = $handler-object.^lookup($handler-name) // Method;
  if ? $sh {
    note "\nregister $handler-object, $handler-name, options: ", %user-options
       if $Gnome::N::x-debug;

    # search for signal name defined by this class as well as its parent classes
    my Str $signal-type;
    my Str $module-name;
    my @module-names = self.^name, |(map( {.^name}, self.^parents));
    for @module-names -> $mn {
      note "  search in class: $mn, $signal-name" if $Gnome::N::x-debug;
      if $signal-types{$mn}:exists and ?$signal-types{$mn}{$signal-name} {
        $signal-type = $signal-types{$mn}{$signal-name};
        $module-name = $mn;
        note "  found type $signal-type for $mn" if $Gnome::N::x-debug;
        last;
      }
    }

    return False unless ?$signal-type;
    given $signal-type {
      when 'signal' {
        $handler = -> N-GObject $w, OpaquePointer $d {
          $handler-object."$handler-name"( :widget(self), |%user-options);
        }

        self.connect-object-signal(
          $signal-name, $handler, OpaquePointer, 0
        );
      }

      when 'event' {
        $handler = -> N-GObject $w, $event, OpaquePointer $d {
          $handler-object."$handler-name"(
             :widget(self), :$event, :handler-arg0($event), |%user-options
          );
        }

        self.connect-object-event(
          $signal-name, $handler, OpaquePointer, 0
        );
      }

      when 'nativewidget' {
        $handler = -> N-GObject $w, N-GObject $d1, OpaquePointer $d2 {
          $handler-object."$handler-name"(
             :widget(self), :nativewidget($d1), :handler-arg0($d1),
             |%user-options
          );
        }

        self.connect-object-nativewidget(
          $signal-name, $handler, OpaquePointer, 0
        );
      }

      when 'notsupported' {
        my Str $message = "Signal $signal-name used on $module-name" ~
          " is explicitly not supported by GTK or this package";
        note $message;
#        die X::Gnome::V3.new(:$message);
        return False;
      }

      when 'deprecated' {
        my Str $message = "Signal $signal-name used on $module-name" ~
          " is explicitly deprecated by GTK";
        note $message;
#        die X::Gnome::V3.new(:$message);
        return False;
      }

      default {
        my Str $message = "Signal $signal-name used on $module-name" ~
          " is not yet implemented";
        note $message;
        return False;
      }
    }

#`{{
    $!g-signal."_g_signal_connect_object_$signal-type"(
      $signal-name, $handler, OpaquePointer, 0
    );
}}
    True
  }

  else {
    False
  }
}

#-------------------------------------------------------------------------------
=begin pod
=head2 start-thread

Start a thread in such a way that the function can modify the user interface in a save way and that these updates are automatically made visible without explicitly process events queued and waiting in the main loop.

  method start-thread (
    $handler-object, Str:D $handler-name, Int $priority = G_PRIORITY_DEFAULT,
    Bool :$new-context = False, *%user-options
    --> Promise
  )

=item $handler-object is the object wherein the handler is defined.
=item $handler-name is name of the method.
=item $priority; The priority to which the handler is started. The default is G_PRIORITY_DEFAULT. These are constants defined in C<Gnome::GObject::GMain>.
=item $new-context; Whether to run the handler in a new context or to run it in the context of the main loop. Default is to run in the main loop.
=item *%user-options; Any name not used above is provided to the handler

Returns a C<Promise> object. If the call fails, the object is undefined.

The handlers signature is at least C<:$widget> of the object on which the call was made. Furthermore all users named arguments to the call defined in C<*%user-options>. The handler may return any value which becomes the result of the C<Promise> returned from C<start-thread>.

=end pod

method start-thread (
  $handler-object, Str:D $handler-name, Int $priority = G_PRIORITY_DEFAULT,
  Bool :$new-context = False, *%user-options
  --> Promise
) {

  # don't start thread if handler is not available
  my Method $sh = $handler-object.^lookup($handler-name) // Method;
  return Promise unless ? $sh;

  my Promise $p = start {

    my Gnome::Glib::Main $gmain .= new;

    # This part is important that it happens in the thread where the
    # function is invoked in that context!
    my $gmain-context;
    if $new-context {
      $gmain-context = $gmain.context-new;
      $gmain.context-push-thread-default($gmain-context);
    }

    else {
      $gmain-context = $gmain.context-get-thread-default;
    }

    my $return-value;
    $gmain.context-invoke-full(
      $gmain-context, $priority,
      -> OpaquePointer $d {
        $return-value = $handler-object."$handler-name"(
          :widget(self), |%user-options
        );

        G_SOURCE_REMOVE
      },
      OpaquePointer, OpaquePointer
    );

    if $new-context {
      $gmain.context-pop-thread-default($gmain-context);
    }

    $return-value
  }

  $p
}

#`{{ === other subs included from generated source
#-------------------------------------------------------------------------------
# Increases the reference count of $object. The new() methods will increase the
# reference count of the native object automatically and when destroyed or
# overwritten decreased.

# no pod. user does not have to know about it.
sub g_object_ref ( N-GObject $object )
  returns N-GObject
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# Decreases the reference count of object. When its reference count drops to 0,
# the object is finalized (i.e. its memory is freed). The widget classes will
# automatically decrease the reference count to the native object when
# destroyed or when overwritten.

# no pod. user does not have to know about it.
sub g_object_unref ( N-GObject $object )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# Increase the reference count of object , and possibly remove the floating
# reference. See also https://developer.gnome.org/gobject/unstable/gobject-The-Base-Object-Type.html#g-object-ref-sink.

# no pod. user does not have to know about it.
sub g_object_ref_sink ( N-GObject $object )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# Clears a reference to a GObject. The reference count of the object is
# decreased and the pointer is set to NULL.

# no pod. user does not have to know about it.
sub g_clear_object ( N-GObject $object )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# Checks whether object has a floating reference.

# no pod. user does not have to know about it.
sub g_object_is_floating ( N-GObject $object )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# This function is intended for GObject implementations to re-enforce a
# floating object reference. Doing this is seldom required: all
# GInitiallyUnowneds are created with a floating reference which usually just
# needs to be sunken by calling g_object_ref_sink().

# no pod. user does not have to know about it.
sub g_object_force_floating ( N-GObject $object )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
=begin pod
=head2 [g_object_] set_property

  method g_object_set_property (
    Str $property_name, Gnome::GObject::GValue $value
  )

Sets a property on an object.

=item $property_name; the name of the property to set.
=item $value; the value.

=end pod

sub g_object_set_property (
  N-GObject $object, Str $property_name, N-GValue $value
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
=begin pod
=head2 [g_object_] get_property

  method g_object_get_property (
    Str $property_name, Gnome::GObject::GValue $value is rw
  )

Gets a property of an object. value must have been initialized to the expected type of the property (or a type to which the expected type can be transformed) using g_value_init().

In general, a copy is made of the property contents and the caller is responsible for freeing the memory by calling g_value_unset().

=item $property_name; the name of the property to get.
=item $value; return location for the property value.

=end pod

sub g_object_get_property (
  N-GObject $object, Str $property_name, N-GValue $gvalue is rw
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
=begin pod
=head2 g_object_notify

  method g_object_notify ( Str $property_name )

Emits a C<notify> signal for the property C<property_name> on object .

When possible, e.g. when signaling a property change from within the class that registered the property, you should use C<g_object_notify_by_pspec()>(not supported yet) instead.

Note that emission of the notify signal may be blocked with C<g_object_freeze_notify()>. In this case, the signal emissions are queued and will be emitted (in reverse order) when C<g_object_thaw_notify()> is called.

=item $property_name; the name of a property installed on the class of object.

=end pod

sub g_object_notify ( N-GObject $object, Str $property_name)
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
=begin pod
=head2 [g_object_] freeze_notify

  method g_object_freeze_notify ( )

Increases the freeze count on object . If the freeze count is non-zero, the emission of C<notify> signals on object is stopped. The signals are queued until the freeze count is decreased to zero. Duplicate notifications are squashed so that at most one C<notify> signal is emitted for each property modified while the object is frozen.

This is necessary for accessors that modify multiple properties to prevent premature notification while the object is still being modified.

=end pod

sub g_object_freeze_notify ( N-GObject $object )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
=begin pod
=head2 [g_object_] thaw_notify

  method g_object_thaw_notify ( )

Reverts the effect of a previous call to C<g_object_freeze_notify()>. The freeze count is decreased on object and when it reaches zero, queued C<notify> signals are emitted.

Duplicate notifications for each property are squashed so that at most one C<notify> signal is emitted for each property, in the reverse order in which they have been queued.

It is an error to call this function when the freeze count is zero.
=end pod

sub g_object_thaw_notify ( N-GObject $object )
  is native(&gobject-lib)
  { * }
}}


#-------------------------------------------------------------------------------
#TM:0:g_initially_unowned_get_type:
=begin pod
=head2 g_initially_unowned_get_type



  method g_initially_unowned_get_type ( --> int32  )


=end pod

sub g_initially_unowned_get_type (  )
  returns int32
  is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
#TM:0:g_object_class_install_property:
=begin pod
=head2 [g_object_] class_install_property

Installs a new property.

All properties should be installed during the class initializer.  It
is possible to install properties after that, but doing so is not
recommend, and specifically, is not guaranteed to be thread-safe vs.
use of properties on the same type on other threads.

Note that it is possible to redefine a property in a derived class,
by installing a property with the same name. This can be useful at times,
e.g. to change the range of allowed values or the default value.

  method g_object_class_install_property ( GObjectClass $oclass, UInt $property_id, GParamSpec $pspec )

=item GObjectClass $oclass; a I<GObjectClass>
=item UInt $property_id; the id for the new property
=item GParamSpec $pspec; the I<GParamSpec> for the new property

=end pod

sub g_object_class_install_property ( GObjectClass $oclass, uint32 $property_id, GParamSpec $pspec )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_class_find_property:
=begin pod
=head2 [g_object_] class_find_property

Looks up the I<GParamSpec> for a property of a class.

Returns: (transfer none): the I<GParamSpec> for the property, or
C<Any> if the class doesn't have a property of that name

  method g_object_class_find_property ( GObjectClass $oclass, Str $property_name --> GParamSpec  )

=item GObjectClass $oclass; a I<GObjectClass>
=item Str $property_name; the name of the property to look up

=end pod

sub g_object_class_find_property ( GObjectClass $oclass, Str $property_name )
  returns GParamSpec
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_class_list_properties:
=begin pod
=head2 [g_object_] class_list_properties

Get an array of I<GParamSpec>* for all properties of a class.

Returns: (array length=n_properties) (transfer container): an array of
I<GParamSpec>* which should be freed after use

  method g_object_class_list_properties ( GObjectClass $oclass, UInt $n_properties --> GParamSpec  )

=item GObjectClass $oclass; a I<GObjectClass>
=item UInt $n_properties; (out): return location for the length of the returned array

=end pod

sub g_object_class_list_properties ( GObjectClass $oclass, uint32 $n_properties )
  returns GParamSpec
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_class_override_property:
=begin pod
=head2 [g_object_] class_override_property

Registers I<property_id> as referring to a property with the name
I<name> in a parent class or in an interface implemented by I<oclass>.
This allows this class to "override" a property implementation in
a parent class or to provide the implementation of a property from
an interface.

Internally, overriding is implemented by creating a property of type
I<GParamSpecOverride>; generally operations that query the properties of
the object class, such as C<g_object_class_find_property()> or
C<g_object_class_list_properties()> will return the overridden
property. However, in one case, the I<construct_properties> argument of
the I<constructor> virtual function, the I<GParamSpecOverride> is passed
instead, so that the I<param_id> field of the I<GParamSpec> will be
correct.  For virtually all uses, this makes no difference. If you
need to get the overridden property, you can call
C<g_param_spec_get_redirect_target()>.

Since: 2.4

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
=head2 [g_object_] class_install_properties

Installs new properties from an array of I<GParamSpecs>.

All properties should be installed during the class initializer.  It
is possible to install properties after that, but doing so is not
recommend, and specifically, is not guaranteed to be thread-safe vs.
use of properties on the same type on other threads.

The property id of each property is the index of each I<GParamSpec> in
the I<pspecs> array.

The property id of 0 is treated specially by I<GObject> and it should not
be used to store a I<GParamSpec>.

This function should be used if you plan to use a static array of
I<GParamSpecs> and C<g_object_notify_by_pspec()>. For instance, this
class initialization:

|[<!-- language="C" -->
enum {
PROP_0, PROP_FOO, PROP_BAR, N_PROPERTIES
};

static GParamSpec *obj_properties[N_PROPERTIES] = { NULL, };

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

Since: 2.26

  method g_object_class_install_properties ( GObjectClass $oclass, UInt $n_pspecs, GParamSpec $pspecs )

=item GObjectClass $oclass; a I<GObjectClass>
=item UInt $n_pspecs; the length of the I<GParamSpecs> array
=item GParamSpec $pspecs; (array length=n_pspecs): the I<GParamSpecs> array defining the new properties

=end pod

sub g_object_class_install_properties ( GObjectClass $oclass, uint32 $n_pspecs, GParamSpec $pspecs )
  is native(&gobject-lib)
  { * }
}}

#-------------------------------------------------------------------------------
#TM:0:g_object_interface_install_property:
=begin pod
=head2 [g_object_] interface_install_property

Add a property to an interface; this is only useful for interfaces
that are added to GObject-derived types. Adding a property to an
interface forces all objects classes with that interface to have a
compatible property. The compatible property could be a newly
created I<GParamSpec>, but normally
C<g_object_class_override_property()> will be used so that the object
class only needs to provide an implementation and inherits the
property description, default value, bounds, and so forth from the
interface property.

This function is meant to be called from the interface's default
vtable initialization function (the I<class_init> member of
I<GTypeInfo>.) It must not be called after after I<class_init> has
been called for any object types implementing this interface.

If I<pspec> is a floating reference, it will be consumed.

Since: 2.4

  method g_object_interface_install_property ( Pointer $g_iface, GParamSpec $pspec )

=item Pointer $g_iface; (type GObject.TypeInterface): any interface vtable for the interface, or the default vtable for the interface.
=item GParamSpec $pspec; the I<GParamSpec> for the new property

=end pod

sub g_object_interface_install_property ( Pointer $g_iface, GParamSpec $pspec )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_interface_find_property:
=begin pod
=head2 [g_object_] interface_find_property

Find the I<GParamSpec> with the given name for an
interface. Generally, the interface vtable passed in as I<g_iface>
will be the default vtable from C<g_type_default_interface_ref()>, or,
if you know the interface has already been loaded,
C<g_type_default_interface_peek()>.

Since: 2.4

Returns: (transfer none): the I<GParamSpec> for the property of the
interface with the name I<property_name>, or C<Any> if no
such property exists.

  method g_object_interface_find_property ( Pointer $g_iface, Str $property_name --> GParamSpec  )

=item Pointer $g_iface; (type GObject.TypeInterface): any interface vtable for the interface, or the default vtable for the interface
=item Str $property_name; name of a property to lookup.

=end pod

sub g_object_interface_find_property ( Pointer $g_iface, Str $property_name )
  returns GParamSpec
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_interface_list_properties:
=begin pod
=head2 [g_object_] interface_list_properties

Lists the properties of an interface.Generally, the interface
vtable passed in as I<g_iface> will be the default vtable from
C<g_type_default_interface_ref()>, or, if you know the interface has
already been loaded, C<g_type_default_interface_peek()>.

Since: 2.4

Returns: (array length=n_properties_p) (transfer container): a
pointer to an array of pointers to I<GParamSpec>
structures. The paramspecs are owned by GLib, but the
array should be freed with C<g_free()> when you are done with
it.

  method g_object_interface_list_properties ( Pointer $g_iface, UInt $n_properties_p --> GParamSpec  )

=item Pointer $g_iface; (type GObject.TypeInterface): any interface vtable for the interface, or the default vtable for the interface
=item UInt $n_properties_p; (out): location to store number of properties returned.

=end pod

sub g_object_interface_list_properties ( Pointer $g_iface, uint32 $n_properties_p )
  returns GParamSpec
  is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
#TM:0:g_object_new:
=begin pod
=head2 g_object_new

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

#-------------------------------------------------------------------------------
#TM:0:g_object_new_with_properties:
=begin pod
=head2 [g_object_] new_with_properties

Creates a new instance of a I<GObject> subtype and sets its properties using
the provided arrays. Both arrays must have exactly I<n_properties> elements,
and the names and values correspond by index.

Construction parameters (see C<G_PARAM_CONSTRUCT>, C<G_PARAM_CONSTRUCT_ONLY>)
which are not explicitly specified are set to their default values.

Returns: (type GObject.Object) (transfer full): a new instance of
I<object_type>

Since: 2.54

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

#-------------------------------------------------------------------------------
#TM:0:g_object_new_valist:
=begin pod
=head2 [g_object_] new_valist

Creates a new instance of a I<GObject> subtype and sets its properties.

Construction parameters (see I<G_PARAM_CONSTRUCT>, I<G_PARAM_CONSTRUCT_ONLY>)
which are not explicitly specified are set to their default values.

Returns: a new instance of I<object_type>

  method g_object_new_valist ( int32 $object_type, Str $first_property_name, va_list $var_args --> N-GObject  )

=item int32 $object_type; the type id of the I<GObject> subtype to instantiate
=item Str $first_property_name; the name of the first property
=item va_list $var_args; the value of the first property, followed optionally by more name/value pairs, followed by C<Any>

=end pod

sub g_object_new_valist ( int32 $object_type, Str $first_property_name, va_list $var_args )
  returns N-GObject
  is native(&gobject-lib)
  { * }

#`[[
#-------------------------------------------------------------------------------
#TM:0:g_object_set:
=begin pod
=head2 g_object_set

Sets properties on an object.

Note that the "notify" signals are queued and only emitted (in
reverse order) after all properties have been set. See
C<g_object_freeze_notify()>.

  method g_object_set ( Pointer $object, Str $first_property_name )

=item Pointer $object; (type GObject.Object): a I<GObject>
=item Str $first_property_name; name of the first property to set @...: value for the first property, followed optionally by more name/value pairs, followed by C<Any>

=end pod

sub g_object_set ( Pointer $object, Str $first_property_name, Any $any = Any )
  is native(&gobject-lib)
  { * }
]]

#`[[
#-------------------------------------------------------------------------------
#TM:0:g_object_get:
=begin pod
=head2 g_object_get

Gets properties of an object.

In general, a copy is made of the property contents and the caller
is responsible for freeing the memory in the appropriate manner for
the type, for instance by calling C<g_free()> or C<g_object_unref()>.

Here is an example of using C<g_object_get()> to get the contents
of three properties: an integer, a string and an object:
|[<!-- language="C" -->
gint intval;
gchar *strval;
GObject *objval;

g_object_get (my_object,
"int-property", &intval,
"str-property", &strval,
"obj-property", &objval,
NULL);

// Do something with intval, strval, objval

g_free (strval);
g_object_unref (objval);
]|

  method g_object_get ( Pointer $object, Str $first_property_name )

=item Pointer $object; (type GObject.Object): a I<GObject>
=item Str $first_property_name; name of the first property to get @...: return location for the first property, followed optionally by more name/return location pairs, followed by C<Any>

=end pod

sub g_object_get ( Pointer $object, Str $first_property_name, Any $any = Any )
  is native(&gobject-lib)
  { * }
]]

#`[[
#-------------------------------------------------------------------------------
#TM:0:g_object_connect:
=begin pod
=head2 g_object_connect

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
]]

#`[[
#-------------------------------------------------------------------------------
#TM:0:g_object_disconnect:
=begin pod
=head2 g_object_disconnect

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
]]

#-------------------------------------------------------------------------------
#TM:0:g_object_setv:
=begin pod
=head2 g_object_setv

Sets I<n_properties> properties for an I<object>.
Properties to be set will be taken from I<values>. All properties must be
valid. Warnings will be emitted and undefined behaviour may result if invalid
properties are passed in.

Since: 2.54

  method g_object_setv ( UInt $n_properties,  $const gchar *names[],  $const GValue values[] )

=item UInt $n_properties; the number of properties
=item  $const gchar *names[]; (array length=n_properties): the names of each property to be set
=item  $const GValue values[]; (array length=n_properties): the values of each property to be set

=end pod

sub g_object_setv ( N-GObject $object, uint32 $n_properties,  $const gchar *names[],  $const GValue values[] )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_set_valist:
=begin pod
=head2 [g_object_] set_valist

Sets properties on an object.

  method g_object_set_valist ( Str $first_property_name, va_list $var_args )

=item Str $first_property_name; name of the first property to set
=item va_list $var_args; value for the first property, followed optionally by more name/value pairs, followed by C<Any>

=end pod

sub g_object_set_valist ( N-GObject $object, Str $first_property_name, va_list $var_args )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_getv:
=begin pod
=head2 g_object_getv

Gets I<n_properties> properties for an I<object>.
Obtained properties will be set to I<values>. All properties must be valid.
Warnings will be emitted and undefined behaviour may result if invalid
properties are passed in.

Since: 2.54

  method g_object_getv ( UInt $n_properties,  $const gchar *names[],  $GValue values[] )

=item UInt $n_properties; the number of properties
=item  $const gchar *names[]; (array length=n_properties): the names of each property to get
=item  $GValue values[]; (array length=n_properties): the values of each property to get

=end pod

sub g_object_getv ( N-GObject $object, uint32 $n_properties,  $const gchar *names[],  $GValue values[] )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_get_valist:
=begin pod
=head2 [g_object_] get_valist

Gets properties of an object.

In general, a copy is made of the property contents and the caller
is responsible for freeing the memory in the appropriate manner for
the type, for instance by calling C<g_free()> or C<g_object_unref()>.

See C<g_object_get()>.

  method g_object_get_valist ( Str $first_property_name, va_list $var_args )

=item Str $first_property_name; name of the first property to get
=item va_list $var_args; return location for the first property, followed optionally by more name/return location pairs, followed by C<Any>

=end pod

sub g_object_get_valist ( N-GObject $object, Str $first_property_name, va_list $var_args )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_set_property:
=begin pod
=head2 [g_object_] set_property

Sets a property on an object.

  method g_object_set_property ( Str $property_name, N-GObject $value )

=item Str $property_name; the name of the property to set
=item N-GObject $value; the value

=end pod

sub g_object_set_property ( N-GObject $object, Str $property_name, N-GObject $value )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_get_property:
=begin pod
=head2 [g_object_] get_property

Gets a property of an object. I<value> must have been initialized to the
expected type of the property (or a type to which the expected type can be
transformed) using C<g_value_init()>.

In general, a copy is made of the property contents and the caller is
responsible for freeing the memory by calling C<g_value_unset()>.

Note that C<g_object_get_property()> is really intended for language
bindings, C<g_object_get()> is much more convenient for C programming.

  method g_object_get_property ( Str $property_name, N-GObject $value )

=item Str $property_name; the name of the property to get
=item N-GObject $value; return location for the property value

=end pod

sub g_object_get_property ( N-GObject $object, Str $property_name, N-GObject $value )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_freeze_notify:
=begin pod
=head2 [g_object_] freeze_notify

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
=head2 g_object_notify

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
=head2 [g_object_] notify_by_pspec

Emits a "notify" signal for the property specified by I<pspec> on I<object>.

This function omits the property name lookup, hence it is faster than
C<g_object_notify()>.

One way to avoid using C<g_object_notify()> from within the
class that registered the properties, and using C<g_object_notify_by_pspec()>
instead, is to store the GParamSpec used with
C<g_object_class_install_property()> inside a static array, e.g.:

enum
{
PROP_0,
PROP_FOO,
PROP_LAST
};

static GParamSpec *properties[PROP_LAST];

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

Since: 2.26

  method g_object_notify_by_pspec ( GParamSpec $pspec )

=item GParamSpec $pspec; the I<GParamSpec> of a property installed on the class of I<object>.

=end pod

sub g_object_notify_by_pspec ( N-GObject $object, GParamSpec $pspec )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_thaw_notify:
=begin pod
=head2 [g_object_] thaw_notify

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

#-------------------------------------------------------------------------------
#TM:0:g_object_is_floating:
=begin pod
=head2 [g_object_] is_floating

Checks whether I<object> has a [floating][floating-ref] reference.

Since: 2.10

Returns: C<1> if I<object> has a floating reference

  method g_object_is_floating ( Pointer $object --> Int  )

=item Pointer $object; (type GObject.Object): a I<GObject>

=end pod

sub g_object_is_floating ( Pointer $object )
  returns int32
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_ref_sink:
=begin pod
=head2 [g_object_] ref_sink

Increase the reference count of I<object>, and possibly remove the
[floating][floating-ref] reference, if I<object> has a floating reference.

In other words, if the object is floating, then this call "assumes
ownership" of the floating reference, converting it to a normal
reference by clearing the floating flag while leaving the reference
count unchanged.  If the object is not floating, then this call
adds a new normal reference increasing the reference count by one.

Since GLib 2.56, the type of I<object> will be propagated to the return type
under the same conditions as for C<g_object_ref()>.

Since: 2.10

Returns: (type GObject.Object) (transfer none): I<object>

  method g_object_ref_sink ( Pointer $object --> Pointer  )

=item Pointer $object; (type GObject.Object): a I<GObject>

=end pod

sub g_object_ref_sink ( Pointer $object )
  returns Pointer
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_ref:
=begin pod
=head2 g_object_ref

Increases the reference count of I<object>.

Since GLib 2.56, if `GLIB_VERSION_MAX_ALLOWED` is 2.56 or greater, the type
of I<object> will be propagated to the return type (using the GCC C<typeof()>
extension), so any casting the caller needs to do on the return type must be
explicit.

Returns: (type GObject.Object) (transfer none): the same I<object>

  method g_object_ref ( Pointer $object --> Pointer  )

=item Pointer $object; (type GObject.Object): a I<GObject>

=end pod

sub g_object_ref ( Pointer $object )
  returns Pointer
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_unref:
=begin pod
=head2 g_object_unref

Decreases the reference count of I<object>. When its reference count
drops to 0, the object is finalized (i.e. its memory is freed).

If the pointer to the I<GObject> may be reused in future (for example, if it is
an instance variable of another object), it is recommended to clear the
pointer to C<Any> rather than retain a dangling pointer to a potentially
invalid I<GObject> instance. Use C<g_clear_object()> for this.

  method g_object_unref ( Pointer $object )

=item Pointer $object; (type GObject.Object): a I<GObject>

=end pod

sub g_object_unref ( Pointer $object )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_weak_ref:
=begin pod
=head2 [g_object_] weak_ref

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
=head2 [g_object_] weak_unref

Removes a weak reference callback to an object.

  method g_object_weak_unref ( GWeakNotify $notify, Pointer $data )

=item GWeakNotify $notify; callback to search for
=item Pointer $data; data to search for

=end pod

sub g_object_weak_unref ( N-GObject $object, GWeakNotify $notify, Pointer $data )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_add_weak_pointer:
=begin pod
=head2 [g_object_] add_weak_pointer

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
=head2 [g_object_] remove_weak_pointer

Removes a weak reference from I<object> that was previously added
using C<g_object_add_weak_pointer()>. The I<weak_pointer_location> has
to match the one used with C<g_object_add_weak_pointer()>.

  method g_object_remove_weak_pointer ( Pointer $weak_pointer_location )

=item Pointer $weak_pointer_location; (inout) (not optional): The memory address of a pointer.

=end pod

sub g_object_remove_weak_pointer ( N-GObject $object, Pointer $weak_pointer_location )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_add_toggle_ref:
=begin pod
=head2 [g_object_] add_toggle_ref

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

Since: 2.8

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
=head2 [g_object_] remove_toggle_ref

Removes a reference added with C<g_object_add_toggle_ref()>. The
reference count of the object is decreased by one.

Since: 2.8

  method g_object_remove_toggle_ref ( GToggleNotify $notify, Pointer $data )

=item GToggleNotify $notify; a function to call when this reference is the last reference to the object, or is no longer the last reference.
=item Pointer $data; data to pass to I<notify>

=end pod

sub g_object_remove_toggle_ref ( N-GObject $object, GToggleNotify $notify, Pointer $data )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_get_qdata:
=begin pod
=head2 [g_object_] get_qdata

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
=head2 [g_object_] set_qdata

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

#-------------------------------------------------------------------------------
#TM:0:g_object_set_qdata_full:
=begin pod
=head2 [g_object_] set_qdata_full

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

#-------------------------------------------------------------------------------
#TM:0:g_object_steal_qdata:
=begin pod
=head2 [g_object_] steal_qdata

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

#-------------------------------------------------------------------------------
#TM:0:g_object_dup_qdata:
=begin pod
=head2 [g_object_] dup_qdata

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

Since: 2.34

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
=head2 [g_object_] replace_qdata

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

Since: 2.34

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

#-------------------------------------------------------------------------------
#TM:0:g_object_get_data:
=begin pod
=head2 [g_object_] get_data

Gets a named field from the objects table of associations (see C<g_object_set_data()>).

Returns: (transfer none) (nullable): the data if found,
or C<Any> if no such data exists.

  method g_object_get_data ( Str $key --> Pointer  )

=item Str $key; name of the key for that association

=end pod

sub g_object_get_data ( N-GObject $object, Str $key )
  returns Pointer
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_set_data:
=begin pod
=head2 [g_object_] set_data

Each object carries around a table of associations from
strings to pointers.  This function lets you set an association.

If the object already had an association with that name,
the old association will be destroyed.

  method g_object_set_data ( Str $key, Pointer $data )

=item Str $key; name of the key
=item Pointer $data; (nullable): data to associate with that key

=end pod

sub g_object_set_data ( N-GObject $object, Str $key, Pointer $data )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_set_data_full:
=begin pod
=head2 [g_object_] set_data_full

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

#-------------------------------------------------------------------------------
#TM:0:g_object_steal_data:
=begin pod
=head2 [g_object_] steal_data

Remove a specified datum from the object's data associations,
without invoking the association's destroy handler.

Returns: (transfer full) (nullable): the data if found, or C<Any>
if no such data exists.

  method g_object_steal_data ( Str $key --> Pointer  )

=item Str $key; name of the key

=end pod

sub g_object_steal_data ( N-GObject $object, Str $key )
  returns Pointer
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_dup_data:
=begin pod
=head2 [g_object_] dup_data

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

Since: 2.34

  method g_object_dup_data ( Str $key, GDuplicateFunc $dup_func, Pointer $user_data --> Pointer  )

=item Str $key; a string, naming the user data pointer
=item GDuplicateFunc $dup_func; (nullable): function to dup the value
=item Pointer $user_data; (nullable): passed as user_data to I<dup_func>

=end pod

sub g_object_dup_data ( N-GObject $object, Str $key, GDuplicateFunc $dup_func, Pointer $user_data )
  returns Pointer
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_replace_data:
=begin pod
=head2 [g_object_] replace_data

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

Since: 2.34

  method g_object_replace_data ( Str $key, Pointer $oldval, Pointer $newval, GDestroyNotify $destroy, GDestroyNotify $old_destroy --> Int  )

=item Str $key; a string, naming the user data pointer
=item Pointer $oldval; (nullable): the old value to compare against
=item Pointer $newval; (nullable): the new value
=item GDestroyNotify $destroy; (nullable): a destroy notify for the new value
=item GDestroyNotify $old_destroy; (out) (optional): destroy notify for the existing value

=end pod

sub g_object_replace_data ( N-GObject $object, Str $key, Pointer $oldval, Pointer $newval, GDestroyNotify $destroy, GDestroyNotify $old_destroy )
  returns int32
  is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
#TM:0:g_object_watch_closure:
=begin pod
=head2 [g_object_] watch_closure

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
=head2 g_cclosure_new_object

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
=head2 g_cclosure_new_object_swap

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
=head2 g_closure_new_object

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

#-------------------------------------------------------------------------------
#TM:0:g_value_set_object:
=begin pod
=head2 g_value_set_object

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
=head2 g_value_get_object

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
=head2 g_value_dup_object

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

#`{{
#-------------------------------------------------------------------------------
#TM:0:g_signal_connect_object:
=begin pod
=head2 g_signal_connect_object

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

#-------------------------------------------------------------------------------
#TM:0:g_object_force_floating:
=begin pod
=head2 [g_object_] force_floating

This function is intended for I<GObject> implementations to re-enforce
a [floating][floating-ref] object reference. Doing this is seldom
required: all I<GInitiallyUnowneds> are created with a floating reference
which usually just needs to be sunken by calling C<g_object_ref_sink()>.

Since: 2.10

  method g_object_force_floating ( )


=end pod

sub g_object_force_floating ( N-GObject $object )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_object_run_dispose:
=begin pod
=head2 [g_object_] run_dispose

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
=head2 g_value_take_object

Sets the contents of a C<G_TYPE_OBJECT> derived I<GValue> to I<v_object>
and takes over the ownership of the callers reference to I<v_object>;
the caller doesn't have to unref it any more (i.e. the reference
count of the object is not increased).

If you want the I<GValue> to hold its own reference to I<v_object>, use
C<g_value_set_object()> instead.

Since: 2.4

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
=head2 g_clear_object

Clears a reference to a I<GObject>.

I<object_ptr> must not be C<Any>.

If the reference is C<Any> then this function does nothing.
Otherwise, the reference count of the object is decreased and the
pointer is set to C<Any>.

A macro is also included that allows this function to be used without
pointer casts.

Since: 2.28

  method g_clear_object ( )


=end pod

sub g_clear_object ( N-GObject $object_ptr )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_weak_ref_init:
=begin pod
=head2 g_weak_ref_init

Initialise a non-statically-allocated I<GWeakRef>.

This function also calls C<g_weak_ref_set()> with I<object> on the
freshly-initialised weak reference.

This function should always be matched with a call to
C<g_weak_ref_clear()>.  It is not necessary to use this function for a
I<GWeakRef> in static storage because it will already be
properly initialised.  Just use C<g_weak_ref_set()> directly.

Since: 2.32

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
=head2 g_weak_ref_clear

Frees resources associated with a non-statically-allocated I<GWeakRef>.
After this call, the I<GWeakRef> is left in an undefined state.

You should only call this on a I<GWeakRef> that previously had
C<g_weak_ref_init()> called on it.

Since: 2.32

  method g_weak_ref_clear ( GWeakRef $weak_ref )

=item GWeakRef $weak_ref; (inout): location of a weak reference, which may be empty

=end pod

sub g_weak_ref_clear ( GWeakRef $weak_ref )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
#TM:0:g_weak_ref_get:
=begin pod
=head2 g_weak_ref_get

If I<weak_ref> is not empty, atomically acquire a strong
reference to the object it points to, and return that reference.

This function is needed because of the potential race between taking
the pointer value and C<g_object_ref()> on it, if the object was losing
its last reference at the same time in a different thread.

The caller should release the resulting reference in the usual way,
by using C<g_object_unref()>.

Returns: (transfer full) (type GObject.Object): the object pointed to
by I<weak_ref>, or C<Any> if it was empty

Since: 2.32

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
=head2 g_weak_ref_set

Change the object to which I<weak_ref> points, or set it to
C<Any>.

You must own a strong reference on I<object> while calling this
function.

Since: 2.32

  method g_weak_ref_set ( GWeakRef $weak_ref, Pointer $object )

=item GWeakRef $weak_ref; location for a weak reference
=item Pointer $object; (type GObject.Object) (nullable): a I<GObject> or C<Any>

=end pod

sub g_weak_ref_set ( GWeakRef $weak_ref, Pointer $object )
  is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
=begin pod
=begin comment

=head1 Not yet implemented methods
g_object_new
g_object_class_install_property
g_object_class_find_property
g_object_class_list_properties
g_object_class_override_property
g_object_class_install_properties
g_object_watch_closure
g_cclosure_new_object
g_cclosure_new_object_swap
g_closure_new_object
g_signal_connect_object
g_object_connect

=head3 method  ( ... )

=end comment
=end pod

#-------------------------------------------------------------------------------
=begin pod
=begin comment

=head1 Not implemented methods

=head3 method  ( ... )

=end comment
=end pod

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
    Gnome::GObject::Object :widget($gobject),
    :handler-arg0($pspec),
    :$user-option1, ..., :$user-optionN
  );

=item $gobject; the object which received the signal.
=item $pspec; the I<GParamSpec> of the property which changed.

=end pod
