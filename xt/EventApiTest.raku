# Test of event handler api to see if Object and Signal modules are working
# correctly to handle the coercion of arguments and named arguments. Also to
# see if the deprecation messages are ok.

use v6;

use Gnome::Gtk3::Window;
use Gnome::Gtk3::Tooltip;
use Gnome::Gtk3::Main;

use Gnome::N::NativeLib;
use Gnome::N::N-GObject;
use Gnome::N::GlibToRakuTypes;

#use Gnome::N::X;
#Gnome::N::debug(:on);

my Gnome::Gtk3::Main $m .= new;

class Handlers {
  method tooltip-query (
    gint $x, gint $y, gboolean $kb-mode, Gnome::Gtk3::Tooltip() $tooltip,
    Gnome::Gtk3::Window() :_native-object($button),
    Gnome::Gtk3::Window :$_widget
    --> gboolean
  ) {
    note "\n query-tooltip\nXY: $x, $y";
    note "keyboard mode: $kb-mode";

    note "tooltip available: $tooltip.get-class-name()";
    note "tooltip: ", $button.get-tooltip-text;

    0;
  }

  method exit-program ( Gnome::Gtk3::Window() :$_native-object ) {
    note "Destroy event, widget: ", $_native-object.get-name;
    $m.quit;
  }
}

my Handlers $h .= new;

with my Gnome::Gtk3::Window $w .= new {
  .set-tooltip-text('window');
  .register-signal( $h, 'exit-program', 'destroy');
  .register-signal( $h, 'tooltip-query', 'query-tooltip');
  .show-all;
}

$m.main;
