use v6.d;

# for new signal key specs
#use lib '../../lib', 'lib';

use NativeCall;
use Gnome::N::N-GObject;
use Gnome::N::GlibToRakuTypes;

use Gnome::Gtk3::Main;
use Gnome::Gtk3::Enums;
use Gnome::Gtk3::Window;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::Button;
use Gnome::Gtk3::Tooltip;

use Gnome::Gdk3::Events;
use Gnome::Gdk3::Types;
use Gnome::Gdk3::Keysyms;


my Gnome::Gtk3::Main $m .= new;

#use Gnome::N::X;
#Gnome::N::debug(:on);

class AppSignalHandlers {

  # Focus handling
  method focus-handle (
    GEnum $direction, :$_native-object, Str :$my-arg0, Str :$my-arg1 --> gboolean
  ) {
    note "Focus event, widget: ", $_native-object.().get-name;
    note "Dir type: ", GtkDirectionType($direction);
    note "User args: $my-arg0, $my-arg1";

    1;
  }

  # Click button
  method click-button1 (
    Gnome::Gtk3::Button() :_native-object($button), :$some-arg
  ) {
    note "Click 1 event, widget: ", $button.get-name, ", $some-arg";
  }

  # Click button
  method click-button2 (
    Gnome::Gtk3::Button() :_native-object($button), :$some-arg
  ) {
    note "Click 2 event, widget: ", $button.get-name, ", $some-arg";
  }

  # Handle window managers 'close app' button
  method exit-program ( Gnome::Gtk3::Window() :$_native-object ) {
    note "Destroy event, widget: ", $_native-object.get-name;
    $m.gtk-main-quit;
  }

  # Handle keyboard event
  method keyboard-event (
    N-GdkEvent $event, :$time, Gnome::Gtk3::Window() :_native-object($window),
    --> gboolean
  ) {

    my N-GdkEventKey $event-key := $event.event-key;
    note "\nevent type: ", GdkEventType($event-key.type);
    note "state: ", $event-key.state.base(2);
    for 0,1,2,4,8 ... 2**(32-1) -> $mask-bit {
      if $event-key.state +& $mask-bit {
        note "Found in state: ", GdkModifierType($mask-bit);
      }
    }

    note "key: ", $event-key.keyval.fmt('0x%04x');
    note "Return pressed" if $event-key.keyval == GDK_KEY_Return;
    note "KP Enter pressed" if $event-key.keyval == GDK_KEY_KP_Enter;

    note "hw key: ", $event-key.hardware_keycode;

    # let the key be handled by lower layers. characters are also used
    # by other widgets, e.g. <tab> to go to next button or field.
    0;
  }

  #-----------------------------------------------------------------------------
  method mouse-event (
    N-GdkEvent $event, Gnome::Gtk3::Window() :_native-object($window)
    --> gboolean
  ) {

    my GdkEventType $t = GdkEventType($event.event-any.type);
    note "\nevent type: $t";
    my N-GdkEventButton $event-button := $event.event-button;
    note "x, y: ", $event-button.x, ', ', $event-button.y;
    note "Root x, y: ", $event-button.x_root, ', ', $event-button.y_root;
    for 0,1,2,4,8 ... 2**(32-1) -> $m {
      if $event-button.state +& $m {
        note "Found in state: ", GdkModifierType($m);
      }
    }

    note "Button: ", $event-button.button;

    0;
  }

  #-----------------------------------------------------------------------------
  method handle-query (
    gint $x, gint $y, gboolean $kb-mode, N-GObject $no-tooltip,
    Gnome::Gtk3::Button() :_native-object($button)
    --> gboolean
  ) {
    note "\nquery-tooltip\nXY: $x, $y";
    note "keyboard mode: $kb-mode";

    note "tooltip available: ", ?$no-tooltip;
    if ? $no-tooltip {
      my Gnome::Gtk3::Tooltip() $tooltip = $no-tooltip;
      note "tooltip: ", $button.get-tooltip-text;
    }

    0;
  }
}

my Gnome::Gtk3::Window $top-window .= new(:title('Window'));
$top-window.set-border-width(20);
#$top-window.set-position(GTK_WIN_POS_MOUSE);

my Gnome::Gtk3::Grid $grid .= new;
$top-window.add($grid);

my Gnome::Gtk3::Button $b1 .= new(:label('Long Button 1 Text Blurp'));
$grid.gtk-grid-attach( $b1, 0, 0, 1, 1);
$b1.set-tooltip-text('button 1 tooltip text');
my Gnome::Gtk3::Button $b2 .= new(:label('Long Button 2 Text Blurp'));
$grid.gtk-grid-attach( $b2, 0, 1, 1, 1);

# Instantiate the event handler class and register signals
my AppSignalHandlers $ash .= new(:$top-window);
$b1.register-signal(
  $ash, 'click-button1', 'clicked', :some-arg('lets click it')
);

$b1.register-signal(
  $ash, 'focus-handle', 'focus', :my-arg0<b1-arg2>, :my-arg1<b1-arg3>
);

$b1.register-signal( $ash, 'handle-query', 'query-tooltip');

$b2.register-signal(
  $ash, 'click-button2', 'clicked', :some-arg('lets click it')
);

$b2.register-signal(
  $ash, 'focus-handle', 'focus', :my-arg0<b2-arg2>, :my-arg1<b2-arg3>
);

$top-window.register-signal( $ash, 'exit-program', 'destroy');
$top-window.register-signal(
  $ash, 'focus-handle', 'focus', :my-arg0<arg0>, :my-arg1<arg1>
);

$top-window.register-signal(
  $ash, 'keyboard-event', 'key-press-event', :time(now)
);

# the difficult way; a) provide handler, b) connect, c) define unused arguments
my Callable $handler = sub (
  N-GObject $ignore-w, N-GdkEvent $event, OpaquePointer $ignore-d
  --> gboolean
) {
  $ash.mouse-event( $event, :widget($top-window))
};
$top-window.connect-object( 'button-press-event', $handler);

$top-window.show-all;

$m.gtk-main;
