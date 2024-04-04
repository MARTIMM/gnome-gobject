#TL:1:Gnome::GObject::Signal:

use v6.d;
#-------------------------------------------------------------------------------
=begin pod

=head1 Gnome::GObject::Signal

A means for customization of object behaviour and a general purpose notification mechanism


=head1 Description

B<Gnome::GObject::Signal> is a role used by B<Gnome::GObject::Object> to provide a means to register signals or disconnect them.


=head1 Synopsis
=head2 Declaration

  unit role Gnome::GObject::Signal;


=head2 Uml Diagram

![](plantuml/Signal.svg)


=head2 Example

  use NativeCall;
  use Gnome::N::N-GObject:api<1>;
  use Gnome::Gdk3::Events:api<1>;
  use Gnome::Gtk3::Window:api<1>;

  # Create a window object
  my Gnome::Gtk3::Window $w .= new( … );

  # Define proper handler. The handler API must describe all arguments
  # and their types.
  my Callable $handler = sub (
    N-GObject $native-widget, N-GdkEvent $event, OpaquePointer $ignored
  ) {
    …
  }

  # Connect signal to the handler.
  $w.connect-object( 'button-press-event', $handler);

The other option to connect a signal is to use the C<register-signal()> method defined in B<Gnome::GObject::Object>. It all depends on how elaborate things are or your taste.

  use Gnome::Gdk3::Events:api<1>;
  use Gnome::Gtk3::Window:api<1>;

  class MyClass {
    # Define handler method. The handler API must describe all positional
    # arguments and their types.
    method mouse-event (
      N-GdkEvent $event,
      Gnome::Gtk3::Window() :$_native-object,
      Int :$_handler-id) { … }

    # Get a window object
    my Gnome::Gtk3::Window $w .= new( … );

    # Then register
    $w.register-signal( self, 'mouse-event', 'button-press-event');

    …
  }

When some of the primitive types are needed like C<gboolean> or C<guint>, you can just use the module B<Gnome::N::GlibToRakuTypes> and leave the types as they are found in the docs. It might be tricky to choose the proper type: e.g. is a C<guint> an C<unsigned int32> or C<unsigned int64>? By the way, enumerations can be typed C<GEnum>.

=end pod
#-------------------------------------------------------------------------------
use NativeCall;

use Gnome::N::X:api<1>;
use Gnome::N::NativeLib:api<1>;
use Gnome::N::N-GObject:api<1>;
use Gnome::N::GlibToRakuTypes:api<1>;

#-------------------------------------------------------------------------------
# See /usr/include/glib-2.0/gobject/gsignal.h
# /usr/include/glib-2.0/gobject/gobject.h
# https://developer.gnome.org/gobject/stable/gobject-Signals.html
unit role Gnome::GObject::Signal:auth<github:MARTIMM>:api<1>;

#-------------------------------------------------------------------------------
#has N-GObject $!g-object;

#-------------------------------------------------------------------------------
=begin pod
=head1 Methods
=end pod

#-------------------------------------------------------------------------------
# submethod BUILD ( *%options ) { }

#-------------------------------------------------------------------------------
#TM:2:connect-object:
=begin pod
=head2 connect-object

Connects a callback function to a signal for a particular object.

  method connect-object (
    Str $detailed-signal, Callable $handler
    --> Int
  )

=end pod

method connect-object ( Str $detailed-signal, Callable $handler --> Int ) {
  g_signal_connect_object(
    self._get-native-object-no-reffing, $detailed-signal, $handler
  )
}

sub g_signal_connect_object (
  N-GObject $instance, Str $detailed-signal, Callable $handler
  --> Int
) {

  # create parameter list
  my @parameterList = (
    Parameter.new(type => N-GObject),     # $instance
    Parameter.new(type => gchar-ptr),     # $detailed-signal
    Parameter.new(                        # $handler
      type => Callable,
      sub-signature => $handler.signature
    ),
    Parameter.new(type => gpointer),      # $data is ignored
    Parameter.new(type => GEnum)          # $connect-flags is ignored
  );

  # create signature
  my Signature $signature .= new(
    :params( |@parameterList ),
    :returns(gulong)
  );

  # get a pointer to the sub, then cast it to a sub with the proper
  # signature. after that, the sub can be called, returning a value.
  state $ptr = cglobal( &gobject-lib, 'g_signal_connect_object', Pointer);
  my Callable $f = nativecast( $signature, $ptr);

  # returns the signal id
  $f( $instance, $detailed-signal, $handler, gpointer, 0)
#  $f( $instance, $detailed-signal, $handler, Nil, 0)
}

#-------------------------------------------------------------------------------
# sub with conversion of user callback. $user-handler is used to get the types
# from, while the $provided-handler is an intermediate between native and user.
method _convert_g_signal_connect_object (
  N-GObject $instance, Str $detailed-signal,
  Callable $user-handler, Callable $provided-handler
  --> gulong
) {

  # create callback handlers signature using the users callback.
  # first argument is always a native widget.
  my @sub-parameter-list = (
    Parameter.new(type => N-GObject),     # object which received the signal
  );

  # then process all parameters of the callback. Skip the first which is the
  # instance which is not needed in the argument list to the handler.
  for $user-handler.signature.params[1..*-1] -> $p {

    # named argument. test for '$_widget` and deprecate the use of it. then skip
    if $p.named {
      Gnome::N::deprecate(
        'named argument :$_widget', ':$_native-object', '0.19.8', '0.21.0'
      ) if $p.name eq '$_widget';

      next;
    }

    next if $p.name ~~ Nil;       # seems to be possible
    next if $p.name eq '%_';      # only at the end I think

    @sub-parameter-list.push(self!convert-type($p.type));
  }

  # finish with data pointer argument which is ignored
#  @sub-parameter-list.push(Parameter.new(type => gpointer));
  @sub-parameter-list.push(self!convert-type(gpointer));

  # create signature from user handler, test for return value
  my Signature $sub-signature;

  # Mu is not an accepted value for the NativeCall interface make it
  # an OpaquePointer.
  if $user-handler.signature.returns.gist ~~ '(Mu)' {
    $sub-signature .= new(
      :params( |@sub-parameter-list ),
      :returns(gpointer)
    );
  }

  else {
    $sub-signature .= new(
      :params( |@sub-parameter-list ),
      :returns(self!convert-type( $user-handler.signature.returns, :type-only))
    );
  }

  # create parameter list for call to g_signal_connect_object
  my @parameterList = (
    Parameter.new(type => N-GObject),     # $instance
    Parameter.new(type => Str),           # $detailed-signal
    Parameter.new(                        # wrapper around $user-handler
      :type(Callable),
      :$sub-signature
    ),
    Parameter.new(type => gpointer),      # $data is ignored
    Parameter.new(type => GEnum)          # $connect-flags is ignored
  );

  # create signature for call to g_signal_connect_object
  my Signature $signature .= new(
    :params( |@parameterList ),
    :returns(gulong)
  );

  # get a pointer to the sub, then cast it to a sub with the created
  # signature. after that, the sub can be called, returning a value.
  state $ptr = cglobal( gobject-lib(), 'g_signal_connect_object', Pointer);

  my Callable $f = nativecast( $signature, $ptr);
#note "F: $f.gist()";

  note [~] "Calling: .g_signal_connect_object\(\n",
    "  $instance.perl(),\n",
    "  '$detailed-signal',\n",
    "  $provided-handler.perl(),\n",
    "  gpointer,\n",
#    "  OpaquePointer,\n",
    "  0\n",
    ');'  if $Gnome::N::x-debug;

  # returns the signal id

#note "F: $instance.gist(), $detailed-signal, $provided-handler.gist()";
  $f( $instance, $detailed-signal, $provided-handler, gpointer, 0)
}

#-------------------------------------------------------------------------------
method !convert-type ( $type, Bool :$type-only = False --> Any ) {
  my $converted-type;

#note 'type: ', $type.^name;
  given $type.^name {
    when Bool { $converted-type = gboolean; }
    when UInt { $converted-type = guint; }
    when Int { $converted-type = gint; }
    when Num { $converted-type = gfloat; }
    when Rat { $converted-type = gdouble; }
    when /^ Gnome '::' / { $converted-type = N-GObject; }
    default { $converted-type = $type; }
  }

  if $type-only {
    $converted-type
  }

  else {
    Parameter.new(type => $converted-type)
  }
}

#-------------------------------------------------------------------------------
# Handlers above provided to the signal connect calls are having 2 arguments
# a widget and data. So the provided extra arguments are then those 2
# plus a return value
#TM:2:emit-by-name:*.t
=begin pod
=head2 emit-by-name

Emits a signal. Note that C<g_signal_emit_by_name()> resets the return value to the default if no handlers are connected.

  emit-by-name (
    Str $detailed-signal, *@handler-arguments,
    Array :$parameters, :$return-type
  )

=item $detailed-signal; a string of the form "signal-name::detail". '::detail' part is mostly not defined such as a button click signal called 'clicked'.
=item *@handler-arguments; a series of arguments needed for the signal handler.
=item :parameters([type, ...]); a series of types, one for each argument.
=item :return-type(type); specifies the type of the return value. When there is no return value, you can omit this.


=head3 An example

=begin code
  use Gnome::N::GlibToRakuTypes:api<1>;
  ...

  # The extra argument here is $toggle
  method enable-debugging-handler (
    gboolean $toggle, Gnome::Gtk3::Window() :$_native-object
    --> gboolean
  ) {
    ...
    1
  }

  $window.register-signal(
    self, 'enable-debugging-handler', 'enable-debugging'
  );

  ... loop started ...
  ... in another thread ...
  my Gnome::Gtk3::Main $main .= new;
  while $main.gtk-events-pending() { $main.iteration-do(False); }
  $window.emit-by-name(
    'enable-debugging', 1,
    :parameters([gboolean,]), :return-type(gboolean)
  );

  ...
=end code

=end pod


method emit-by-name (
  Str $detailed_signal, *@handler-arguments, *%options --> Any
) {
  g_signal_emit_by_name(
    self._get-native-object-no-reffing,
    $detailed_signal, |@handler-arguments, |%options
  )
}

#TODO merge later as a methpd when deprecating _fallback
sub g_signal_emit_by_name (
  N-GObject $instance, Str $detailed_signal, *@handler-arguments, *%options
  --> Any
) {

  my Array $parameters = %options<parameters> // [];

  # create parameter list and start with inserting fixed arguments
  my @parameterList = (
    Parameter.new(type => N-GObject),   # $instance
    Parameter.new(type => gchar-ptr),   # $signal name
  );

  # rest of the arguments can be converted to natives if any
  my @new-args = ();
  for @handler-arguments -> $arg {
    my $a = $arg;
    $a .= _get-native-object-no-reffing
        if $a.^can('_get-native-object-no-reffing');

    my $t = $parameters.elems ?? shift $parameters !! $a.WHAT;
    @parameterList.push(Parameter.new(type => $t));
    @new-args.push($a);
  }

  # add a location for a return value if needed
  my $rv;
  if %options<return-type>:exists {
    @parameterList.push(Parameter.new(type => CArray));
    $rv = CArray[%options<return-type>].new;
    @new-args.push($rv);
  }

  # create signature
  my Signature $signature .= new( :params(|@parameterList), :returns(gint));

  # get a pointer to the sub, then cast it to a sub with the proper
  # signature. after that, the sub can be called, returning a value.
  state $ptr = cglobal( &gobject-lib, 'g_signal_emit_by_name', gpointer);
  my Callable $f = nativecast( $signature, $ptr);

  $f( $instance, $detailed_signal, |@new-args);
  $rv[0] if $rv.defined
}

#-------------------------------------------------------------------------------
#TM:4:handler-disconnect:Gnome::Gtk3 ex-signal.pl6
=begin pod
=head2 handler-disconnect

Disconnects a handler from an instance so it will not be called during any future or currently ongoing emissions of the signal it has been connected to. The handler_id becomes invalid and may be reused.

The C<$handler-id> has to be a valid signal handler id, connected to a signal of instance.

  handler-disconnect ( Int $handler-id )

=item $handler_id; Handler id of the handler to be disconnected.
=end pod

method handler-disconnect ( Int $handler-id ) {
  g_signal_handler_disconnect( self._f, $handler-id);
}

sub g_signal_handler_disconnect( N-GObject $widget, gulong $handler-id )
  is native(&gobject-lib)
  is export # temporary
  { * }

#-------------------------------------------------------------------------------
#TM:2:signal-name:xt/Object.t
=begin pod
=head2 signal-name

Given the signal's identifier, finds its name. Two different signals may have the same name, if they have differing types.

  signal-name( UInt $signal-id --> Str )

=item $signal-id; the signal's identifying number.

Returns the signal name, or NULL if the signal number was invalid.

=end pod

method signal-name ( Int $signal-id --> Str ) {
  g_signal_name( self._f, $signal-id)
}

sub g_signal_name( guint $signal-id --> Str )
  is native(&gobject-lib)
#  is export # temporary
  { * }
