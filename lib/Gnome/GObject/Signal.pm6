#TL:1:Gnome::GObject::Signal:

use v6.d;
#-------------------------------------------------------------------------------
=begin pod

=head1 Gnome::GObject::Signal

A means for customization of object behaviour and a general purpose notification mechanism

=head1 Description

=head1 Synopsis
=head2 Declaration

  unit class Gnome::GObject::Signal;

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
    N-GObject $native-widget, GdkEvent $event, OpaquePointer $ignore-d
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
  method mouse-event ( GdkEvent $event, :$widget ) { ... }

  # Get a window object
  my Gnome::Gtk3::Window $w .= new( ... );

  # Then register
  $w.register-signal( self, 'mouse-event', 'button-press-event');

=end pod
#-------------------------------------------------------------------------------
use NativeCall;

use Gnome::N::X;
use Gnome::N::NativeLib;
use Gnome::N::N-GObject;

#-------------------------------------------------------------------------------
# See /usr/include/glib-2.0/gobject/gsignal.h
# /usr/include/glib-2.0/gobject/gobject.h
# https://developer.gnome.org/gobject/stable/gobject-Signals.html
unit class Gnome::GObject::Signal:auth<github:MARTIMM>;

#-------------------------------------------------------------------------------
has N-GObject $!g-object;

#-------------------------------------------------------------------------------
=begin pod
=head1 Methods
=end pod

#-------------------------------------------------------------------------------
# Native object is handed over by a Gnome::GObject::Object object
#TM:2:new():Object
submethod BUILD ( N-GObject:D :$!g-object ) { }

#-------------------------------------------------------------------------------
# no pod. user does not have to know about it.
method FALLBACK ( $native-sub is copy, Bool :$return-sub-only = False, |c ) {

#  CATCH { test-catch-exception( $_, $native-sub); }
  CATCH { .note; die; }

  $native-sub ~~ s:g/ '-' /_/ if $native-sub.index('-').defined;
#`{{
  die X::Gnome.new(:message(
      "Native sub name '$native-sub' made too short. Keep at least one '-' or '_'."
    )
  ) unless $native-sub.index('_') >= 0;
}}

  my Callable $s;
#note "s s0: $native-sub, ", $s;
  try { $s = &::($native-sub); }
#note "s s1: g_signal_$native-sub, ", $s unless ?$s;
  try { $s = &::("g_signal_$native-sub"); } unless ?$s;
#note "s s2: ==> ", $s;

  #test-call-without-natobj( $s, |c)
  $return-sub-only ?? $s !! $s( $!g-object, |c)
}

#-------------------------------------------------------------------------------
#TM:2:g_signal_connect_object:
=begin pod
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
    Parameter.new(type => Str),           # $detailed-signal
    Parameter.new(                        # $handler
      type => Callable,
      sub-signature => $handler.signature
    ),
    Parameter.new(type => OpaquePointer), # $data is ignored
    Parameter.new(type => int32)          # $connect-flags is ignored
  );

  # create signature
  my Signature $signature .= new(
    :params( |@parameterList ),
    :returns(uint64)
  );

  # get a pointer to the sub, then cast it to a sub with the proper
  # signature. after that, the sub can be called, returning a value.
  state $ptr = cglobal( &gobject-lib, 'g_signal_connect_object', Pointer);
  my Callable $f = nativecast( $signature, $ptr);

  # returns the signal id
  $f( $instance, $detailed-signal, $handler, OpaquePointer, 0)
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

  # then process all parameters of the callback.
  for $user-handler.signature.params -> $p {

    next if $p.name ~~ Nil;       # seems to be between it in the list
    next if $p.name eq '%_';      # only at the end I think
    next if $p.named;             # named argument

    my $ha-type = $p.type;
    $ha-type = uint32 if $ha-type ~~ UInt;
    $ha-type = int32 if $ha-type ~~ Int;
    $ha-type = num32 if $ha-type ~~ Num;
    @sub-parameter-list.push(     # next signal arguments
      Parameter.new(type => $ha-type),
    );
  }

  # finish with data pointer argument
  @sub-parameter-list.push(
    Parameter.new(type => OpaquePointer), # data pointer which is ignored
  );

  # create signature, test for return value
  my Signature $sub-signature;
  if $user-handler.signature.returns ~~ Mu {
    $sub-signature .= new(
      :params( |@sub-parameter-list ),
      :returns(int32)
    );
  }

  else {
    $sub-signature .= new(
      :params( |@sub-parameter-list ),
      :returns($user-handler.signature.returns)
    );
  }

  # create parameter list for call to g_signal_connect_object
  my @parameterList = (
    Parameter.new(type => N-GObject),     # $instance
    Parameter.new(type => Str),           # $detailed-signal
    Parameter.new(                        # $user-handler
      :type(Callable),
      :$sub-signature
    ),
    Parameter.new(type => OpaquePointer), # $data is ignored
    Parameter.new(type => int32)          # $connect-flags is ignored
  );

  # create signature for call to g_signal_connect_object
  my Signature $signature .= new(
    :params( |@parameterList ),
    :returns(uint64)
  );

  # get a pointer to the sub, then cast it to a sub with the created
  # signature. after that, the sub can be called, returning a value.
  state $ptr = cglobal( gobject-lib(), 'g_signal_connect_object', Pointer);

  my Callable $f = nativecast( $signature, $ptr);

  # returns the signal id
  $f( $instance, $detailed-signal, $provided-handler, OpaquePointer, 0)
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

#-------------------------------------------------------------------------------
#`{{
# a GQuark is a guint32, $detail is a quark
# See https://developer.gnome.org/glib/stable/glib-Quarks.html
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
#TM:0:emit_by_name:
=begin pod
=head2 [[g_] signal_] emit_by_name

Emits a signal.

Note that C<g_signal_emit_by_name()> resets the return value to the default if no handlers are connected.

  g_signal_emit_by_name ( Str $signal, N-GObject $widget )

=item $signal; a string of the form "signal-name::detail".
=item $widget; widget to pass to the handler.

=end pod

sub g_signal_emit_by_name (
  N-GObject $instance, Str $detailed_signal, *@handler-arguments
) {

  # create parameter list and start with inserting fixed arguments
  my @parameterList = (
    Parameter.new(type => N-GObject),   # $instance
    Parameter.new(type => Str),         # $signal name
  );

  # Rest of the arguments
  my @new-args .= new;
  for @handler-arguments -> $arg {
    my $a = $arg;
    $a .= get-native-object-no-reffing
        if $a.^can('get-native-object-no-reffing');
    @parameterList.push(Parameter.new(type => $a.WHAT));
    @new-args.push($a);
  }

  # create signature
  my Signature $signature .= new(
    :params(|@parameterList),
    :returns(int32)
  );

  # get a pointer to the sub, then cast it to a sub with the proper
  # signature. after that, the sub can be called, returning a value.
  state $ptr = cglobal( &gobject-lib, 'g_signal_emit_by_name', Pointer);
  my Callable $f = nativecast( $signature, $ptr);

  $f( $instance, $detailed_signal, |@new-args)

#  _g_signal_emit_by_name( $instance, $detailed_signal, $widget, OpaquePointer);
}

#`{{
sub _g_signal_emit_by_name (
  # first two are obligatory by definition
  N-GObject $instance, Str $detailed_signal,
  # The rest depends on the handler defined when connecting
  # There is no return value from the handler
  N-GObject $widget, OpaquePointer
) is native(&gobject-lib)
  is symbol('g_signal_emit_by_name')
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
method _unregister ( $instance, $detailed-signal, $user-handler ) {

  # stored like;
  # $handler-ids{$handler-id} = [ $instance, $detailed-signal, $user-handler];
  for $handler-ids.kv -> Str $k, Array $v {
    if $v[0] ~~ $instance and $v[1] ~~ $detailed-signal and
       $v[2] ~~ $user-handler {

      g_signal_handler_disconnect( $instance, $k.Int);
      last;
    }
  }
}
}}

#-------------------------------------------------------------------------------
#TM:4:g_signal_handler_disconnect:Gnome::Gtk3 ex-signal.pl6
=begin pod
=head2 [[g_] signal_] handler_disconnect

Disconnects a handler from an instance so it will not be called during any future or currently ongoing emissions of the signal it has been connected to. The handler_id becomes invalid and may be reused.

The handler_id has to be a valid signal handler id, connected to a signal of instance.

  g_signal_handler_disconnect( Int $handler_id )

=item $handler_id; Handler id of the handler to be disconnected.
=end pod

sub g_signal_handler_disconnect( N-GObject $widget, uint64 $handler_id )
  is native(&gobject-lib)
  { * }
