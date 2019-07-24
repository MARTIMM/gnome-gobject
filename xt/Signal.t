use v6;
use Test;
use NativeCall;

#use Gnome::N::NativeLib;
use Gnome::N::N-GObject;
use Gnome::Glib::Main;
use Gnome::GObject::Signal;
use Gnome::Gtk3::Window;
use Gnome::Gtk3::Button;
use Gnome::Gtk3::Main;

#use Gnome::N::X;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
# used later on in tests
my Gnome::Gtk3::Main $main .= new;

class X {
  method do-x ( :widget($w) ) {
    say "do-x called";
  }
}

my Gnome::Gtk3::Window $w .= new(:title<window>);
my Gnome::Gtk3::Button $b .= new(:label<button>);
my Gnome::GObject::Signal $sig .= new(:g-object($b()));

#-------------------------------------------------------------------------------
subtest 'ISA test', {
  isa-ok $sig, Gnome::GObject::Signal;
  isa-ok $w, Gnome::GObject::Object;
  isa-ok $b, Gnome::GObject::Object;

  my X $x .= new;
  my Callable $handler =
    sub ( N-GObject $ignore-native-widget, OpaquePointer $ignore-user-data ) {
      $x.do-x( :widget($b) );
    };

  my Int $hid = $sig.connect-object( 'clicked', $handler);
  note "hid: $hid";
  my Promise $p = fire-event( $b, 'clicked');

  is $main.gtk-main-level, 0, "loop level 0";
  $main.gtk-main;
  is $main.gtk-main-level, 0, "loop level is 0 again";

  is $p.result, 'test done', 'promise result ok';
}

#-------------------------------------------------------------------------------
done-testing;

sub fire-event (
  Gnome::GObject::Object $object, Str $event-name
  --> Promise
) {

  my Promise $p = start {

    # wait for loop to start
    sleep(2.1);

    is $main.gtk-main-level, 1, "loop level now 1";

    my Gnome::Glib::Main $gmain .= new;
    my $gmain-context = $gmain.context-get-thread-default;

    $gmain.context-invoke(
      $gmain-context,
      -> $d {
        #$button.emit-by-name( 'clicked', $button);
        $sig.emit-by-name( $event-name, $object());

        sleep(1.0);
        $main.gtk-main-quit;

        0
      },
      OpaquePointer
    );

    'test done'
  }

  $p
}
