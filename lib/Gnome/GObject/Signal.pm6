#TL:1:Gnome::GObject::Signal:

use v6.d;
#-------------------------------------------------------------------------------
=begin pod

=head1 Gnome::GObject::Signal

A means for customization of object behaviour and a general purpose notification mechanism

=head1 Description

=head1 Synopsis
=head2 Declaration

  unit role Gnome::GObject::Signal;


=head2 Uml Diagram

![](plantuml/Signal.svg)


=head2 Example

  use NativeCall;
  use Gnome::N::N-GObject;
  use Gnome::Gdk3::Events;
  use Gnome::Gtk3::Window;

  # Get a window object
  my Gnome::Gtk3::Window $w .= new( ... );

  # Define proper handler. The handler API must describe all arguments
  # and their types.
  my Callable $handler = sub (
    N-GObject $native-widget, N-GdkEvent $event, OpaquePointer $ignored
  ) {
    ...
  }

  # Connect signal to the handler.
  $w.connect-object( 'button-press-event', $handler);

The other option to connect a signal is to use the C<register-signal()> method defined in B<Gnome::GObject::Object>. It all depends on how elaborate things are or taste.

  use Gnome::Gdk3::Events;
  use Gnome::Gtk3::Window;

  # Define handler method. The handler API must describe all positional
  # arguments and their types.
  method mouse-event ( N-GdkEvent $event, :$_widget , :$_handler-id) { ... }

  # Get a window object
  my Gnome::Gtk3::Window $w .= new( ... );

  # Then register
  $w.register-signal( self, 'mouse-event', 'button-press-event');


When some of the primitive types are needed like C<gboolean> or C<guint>, you can just use the module B<Gnome::N::GlibToRakuTypes> and leave the types as they are found in the docs. It might be tricky to choose the proper type: e.g. is a C<guint> an C<unsigned int32> or C<unsigned int64>? By the way, enumerations can be typed C<GEnum>.

=end pod
#-------------------------------------------------------------------------------
use NativeCall;

use Gnome::N::X;
use Gnome::N::NativeLib;
use Gnome::N::N-GObject;
use Gnome::N::GlibToRakuTypes;

#-------------------------------------------------------------------------------
# See /usr/include/glib-2.0/gobject/gsignal.h
# /usr/include/glib-2.0/gobject/gobject.h
# https://developer.gnome.org/gobject/stable/gobject-Signals.html
unit role Gnome::GObject::Signal:auth<github:MARTIMM>;

#-------------------------------------------------------------------------------
#has N-GObject $!g-object;

#-------------------------------------------------------------------------------
=begin pod
=head1 Methods
=end pod

#-------------------------------------------------------------------------------
# Native object is handed over by a Gnome::GObject::Object object
#TM:2:new():Object
#submethod BUILD ( N-GObject:D :$!g-object ) { }
submethod BUILD ( *%options ) { }

#-------------------------------------------------------------------------------
# no pod. user does not have to know about it.
method _signal_interface ( Str $native-sub --> Callable ) {

  my Callable $s;
  try { $s = &::("g_signal_$native-sub"); } unless ?$s;
  try { $s = &::("g_$native-sub"); } unless ?$s;
  try { $s = &::($native-sub); } if !$s and $native-sub ~~ m/^ 'g_' /;

  $s
}

#-------------------------------------------------------------------------------
#TM:2:g_signal_connect_object:
=begin pod
=head2 [[g_] signal_] connect_object

Connects a callback function to a signal for a particular object.

  method g_signal_connect_object (
    N-GObject $instance, Str $detailed-signal, Callable $handler
    --> Int
  ) {

=end pod

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
#    Parameter.new(type => OpaquePointer), # $data is ignored
    Parameter.new(type => GEnum)          # $connect-flags is ignored
  );

  # create signature
  my Signature $signature .= new(
    :params( |@parameterList ),
    :returns(gulong)
  );

  # get a pointer to the sub, then cast it to a sub with the proper
  # signature. after that, the sub can be called, returning a value.
  state $ptr = cglobal( &gobject-lib, 'g_signal_connect_object', gpointer);
  my Callable $f = nativecast( $signature, $ptr);

  # returns the signal id
  $f( $instance, $detailed-signal, $handler, gpointer, 0)
#  $f( $instance, $detailed-signal, $handler, OpaquePointer, 0)
}

#-------------------------------------------------------------------------------
# sub with conversion of user callback. $user-handler is used to get the types
# from, while the $provided-handler is an intermediate between native and user.
method _convert_g_signal_connect_object (
  N-GObject $instance, Str $detailed-signal,
  Callable $user-handler, Callable $provided-handler
  --> Int
) {

  # create callback handlers signature using the users callback.
  # first argument is always a native widget.
  my @sub-parameter-list = (
    Parameter.new(type => N-GObject),     # object which received the signal
  );

  # then process all parameters of the callback. Skip the first which is the
  # instance which is not needed in the argument list to the handler.
  for $user-handler.signature.params[1..*-1] -> $p {
#note "\$p: $p.perl()";

    next if $p.name ~~ Nil;       # seems to be between it in the list
    next if $p.name eq '%_';      # only at the end I think
    next if $p.named;             # named argument

    my $ha-type = $p.type;
    given $ha-type {
      when UInt {
        @sub-parameter-list.push(Parameter.new(type => guint));
      }

      when Int {
        @sub-parameter-list.push(Parameter.new(type => gint));
      }

      when Num {
        @sub-parameter-list.push(Parameter.new(type => gfloat));
      }

      default {
        @sub-parameter-list.push(Parameter.new(type => $ha-type));
      }
    }
  }

  # finish with data pointer argument
  @sub-parameter-list.push(
    Parameter.new(type => gpointer), # data pointer which is ignored
#    Parameter.new(type => OpaquePointer), # data pointer which is ignored
  );
#note "Subpar: @sub-parameter-list.perl()";

  # create signature from user handler, test for return value
  my Signature $sub-signature;

  # Mu is not an accepted value for the NativeCall interface make it
  # an OpaquePointer.
  if $user-handler.signature.returns.gist ~~ '(Mu)' {
    $sub-signature .= new(
      :params( |@sub-parameter-list ),
      :returns(gpointer)
#      :returns(OpaquePointer)
    );
  }

  else {
    $sub-signature .= new(
      :params( |@sub-parameter-list ),
      :returns($user-handler.signature.returns)
    );
  }
#note "Sub: $sub-signature.perl()";

  # create parameter list for call to g_signal_connect_object
  my @parameterList = (
    Parameter.new(type => N-GObject),     # $instance
    Parameter.new(type => Str),           # $detailed-signal
    Parameter.new(                        # wrapper around $user-handler
      :type(Callable),
      :$sub-signature
    ),
    Parameter.new(type => gpointer), # $data is ignored
#    Parameter.new(type => OpaquePointer), # $data is ignored
    Parameter.new(type => GEnum)          # $connect-flags is ignored
  );
#note "Par: @parameterList.perl()";

  # create signature for call to g_signal_connect_object
  my Signature $signature .= new(
    :params( |@parameterList ),
    :returns(gulong)
  );
#note "Sig: $signature.perl()";

  # get a pointer to the sub, then cast it to a sub with the created
  # signature. after that, the sub can be called, returning a value.
  state $ptr = cglobal( gobject-lib(), 'g_signal_connect_object', Pointer);

  my Callable $f = nativecast( $signature, $ptr);
#note "F: $f.perl()";

  note [~] "Calling: .g_signal_connect_object\(\n",
    "  $instance.perl(),\n",
    "  '$detailed-signal',\n",
    "  $provided-handler.perl(),\n",
    "  gpointer,\n",
#    "  OpaquePointer,\n",
    "  0\n",
    ');'  if $Gnome::N::x-debug;

  # returns the signal id
#note "F: $instance.perl(), $detailed-signal, $provided-handler.perl()";
  $f( $instance, $detailed-signal, $provided-handler, gpointer, 0)
#  $f( $instance, $detailed-signal, $provided-handler, OpaquePointer, 0)
}

#`{{
#-------------------------------------------------------------------------------
=begin pod
=head1 Methods

=head2 [g_] signal_connect

In this project it uses C<g_signal_connect_object()> explained below.

  method g_signal_connect( Str $signal, Callable $handler --> uint64 )

=item $signal; a string of the form C<signal-name::detail>.
=item $handler; the callback to connect.

=end pod

sub g_signal_connect (
  N-GObject $widget, Str $signal, Callable $handler
  --> uint64
) is inlinable {
  g_signal_connect_object( $widget, $signal, $handler)
}
}}
#-------------------------------------------------------------------------------
#`{{
=begin pod
=head2 [[g_] signal_] connect_data

Connects a callback function to a signal for a particular object. Similar to C<g_signal_connect()>, but allows to provide a GClosureNotify for the data which will be called when the signal handler is disconnected and no longer used.

  method g_signal_connect_data ( Str $signal, Callable $handler --> uint64 )

=item $signal; a string of the form "signal-name::detail".
=item $handler; callback function to connect.

=end pod
sub g_signal_connect_data(
  N-GObject $widget, Str $signal, Callable $handler,
  --> uint64
) {

  # OpaquePointer for userdata which will never be send around
  # 0 for connect_flags which cannot be used for G_CONNECT_AFTER
  #   nor G_CONNECT_SWAPPED
  # Callable for closure notify to cleanup data after disconnection.
  #   The user data is not passed around, so, no cleanup.
  my Callable $destroy_data = -> OpaquePointer, OpaquePointer {};
  my @args = $widget, $signal, $handler, OpaquePointer, $destroy_data, 0;

  given $handler.signature {
    when $signal-type { _g_signal_connect_data_signal(|@args) }
    when $event-type { _g_signal_connect_data_event(|@args) }
    when $nativewidget-type { _g_signal_connect_data_nativewidget(|@args) }

    default {
      die X::Gnome.new(:message('Handler doesn\'t have proper signature'));
    }
  }
}

sub _g_signal_connect_data_signal (
  N-GObject $widget, Str $signal,
  Callable $handler ( N-GObject, OpaquePointer ), OpaquePointer $data,
  Callable $destroy_data ( OpaquePointer, OpaquePointer ),
  int32 $connect_flags = 0
) returns int64
  is native(&gobject-lib)
  { * }

sub _g_signal_connect_data_event (
  N-GObject $widget, Str $signal,
  Callable $handler ( N-GObject, Pointer, OpaquePointer ),
  OpaquePointer $data,
  Callable $destroy_data ( OpaquePointer, OpaquePointer ),
  int32 $connect_flags = 0
) returns int64
  is native(&gobject-lib)
  { * }

sub _g_signal_connect_data_nativewidget (
  N-GObject $widget, Str $signal,
  Callable $handler ( N-GObject, OpaquePointer, OpaquePointer ),
  OpaquePointer $data,
  Callable $destroy_data ( OpaquePointer, OpaquePointer ),
  int32 $connect_flags = 0
) returns int64
  is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
sub g_signal_connect_after (
  N-GObject $widget, Str $signal, Callable $handler, OpaquePointer
) {
  g_signal_connect_data(
    $widget, $signal, $handler, OpaquePointer, Any, G_CONNECT_AFTER
  );
}

#-------------------------------------------------------------------------------
sub g_signal_connect_swapped (
  N-GObject $widget, Str $signal, Callable $handler, OpaquePointer
) {
  g_signal_connect_data(
    $widget, $signal, $handler, OpaquePointer, Any, G_CONNECT_SWAPPED
  );
}
}}

#`{{
#-------------------------------------------------------------------------------
# a GQuark is a guint32, $detail is a quark
# See https://developer.gnome.org/glib/stable/glib-Quarks.html
#TM:0:g_signal_emit:
=begin pod
=head2 [[g_] signal_] emit

Emits a signal.

Note that C<g_signal_emit()> resets the return value to the default if no handlers are connected.

  g_signal_emit ( Str $signal, N-GObject $widget )

=item $signal; a string of the form "signal-name::detail".
=item $widget; widget to pass to the handler.

=end pod

sub g_signal_emit (
  N-GObject $instance, uint32 $signal_id, uint32 $detail,
  N-GObject $widget, Str $data, Str $return-value is rw
) is native(&gobject-lib)
  { * }
}}

#-------------------------------------------------------------------------------
# Handlers above provided to the signal connect calls are having 2 arguments
# a widget and data. So the provided extra arguments are then those 2
# plus a return value
#TM:2:g_signal_emit_by_name:*.t
=begin pod
=head2 [[g_] signal_] emit_by_name

Emits a signal. Note that C<g_signal_emit_by_name()> resets the return value to the default if no handlers are connected.

  g_signal_emit_by_name (
    Str $detailed-signal, *@handler-arguments,
    Array :$parameters, :$return-type
  )

=item $detailed-signal; a string of the form "signal-name::detail". '::detail' part is mostly not defined such as a button click signal called 'clicked'.
=item *@handler-arguments; a series of arguments needed for the signal handler.
=item :parameters([type, ...]); a series of types, one for each argument.
=item :return-type(type); specifies the type of the return value. When there is no return value, you can omit this.


=head3 An example

=begin code
  use Gnome::N::GlibToRakuTypes;
  ...

  # The extra argument here is $toggle
  method enable-debugging-handler (
    gboolean $toggle, Gnome::Gtk3::Window :$_widget
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
    $a .= get-native-object-no-reffing
        if $a.^can('get-native-object-no-reffing');

    my $t = $parameters.elems
            ?? shift $parameters
            !! $a.WHAT;
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
#TM:4:g_signal_handler_disconnect:Gnome::Gtk3 ex-signal.pl6
=begin pod
=head2 [[g_] signal_] handler_disconnect

Disconnects a handler from an instance so it will not be called during any future or currently ongoing emissions of the signal it has been connected to. The handler_id becomes invalid and may be reused.

The handler_id has to be a valid signal handler id, connected to a signal of instance.

  g_signal_handler_disconnect( Int $handler_id )

=item $handler_id; Handler id of the handler to be disconnected.
=end pod

sub g_signal_handler_disconnect( N-GObject $widget, gulong $handler_id )
  is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
# TM:2:g_signal_lookup:xt/Object.t
=begin pod
=head2 [g_] signal_lookup

Given the name of the signal and the type of object it connects to, gets the signal's identifying integer.
=comment Emitting the signal by number is somewhat faster than using the name each time.

Also tries the ancestors of the given widget (the native one, held within).

The widget must already have been instantiated for this function to work, as signals are always installed during class initialization.

  g_signal_lookup( Str $signal-name --> Int )

=item $signal-name; the signal's name.
=end pod

sub g_signal_lookup ( N-GObject $widget, Str $signal-name --> Int ) {

  my Int $widget-type = tlcs_type_from_name;
  _g_signal_lookup( $signal-name, $widget-type)
}

sub _g_signal_lookup ( Str $name, int32 $itype --> uint32 )
  is native(&gobject-lib)
  is symbol('g_signal_lookup')
  { * }
}}

#-------------------------------------------------------------------------------
#TM:2:g_signal_name:xt/Object.t
=begin pod
=head2 [g_] signal_name

Given the signal's identifier, finds its name. Two different signals may have the same name, if they have differing types.

  g_signal_name( UInt $signal-id --> Str )

=item $signal-id; the signal's identifying number.

Returns the signal name, or NULL if the signal number was invalid.

=end pod

sub g_signal_name( guint $signal_id --> Str )
  is native(&gobject-lib)
#  is symbol('g_signal_name')
  { * }
