use v6;
use NativeCall;
use Test;

use Gnome::GObject::Value:api<1>;
use Gnome::GObject::Type:api<1>;

use Gnome::N::NativeLib:api<1>;
use Gnome::N::GlibToRakuTypes:api<1>;
use Gnome::N::N-GObject:api<1>;

use Gnome::Gtk3::Label:api<1>;
use Gnome::Gtk3::Entry:api<1>;
use Gnome::Gtk3::Enums:api<1>;

#use Gnome::N::X:api<1>;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
my Gnome::GObject::Value $v .= new(:init(G_TYPE_STRING));
my Gnome::Gtk3::Label $l1 .= new(:text<Start>);
gtk_label_set_ellipsize( $l1._get-native-object-no-reffing, 2);

my Gnome::GObject::Value $gv .= new(:init(G_TYPE_ENUM));
$l1.get-property( 'ellipsize', $gv);
is $gv.get-enum, 2, '.get-enum()';

$gv.set-enum(1);
$l1.set-property( 'ellipsize', $gv);
is gtk_label_get_ellipsize($l1._get-native-object-no-reffing), 1, '.set-enum()';



my Gnome::Gtk3::Entry $e .= new(:label<Start>);
my GFlag $ih = GTK_INPUT_HINT_SPELLCHECK +| GTK_INPUT_HINT_LOWERCASE +|
               GTK_INPUT_HINT_EMOJI;
$e.set-input-hints($ih);

$gv .= new(:init(G_TYPE_FLAGS));
$e.get-property( 'input-hints', $gv);
is $ih, $gv.get-flags, '.get-flags()';

$ih = GTK_INPUT_HINT_UPPERCASE_SENTENCES;
$gv.set-flags($ih);
$e.set-property( 'input-hints', $gv);
is $e.get-input-hints, $ih, '.set-flags()';

#-------------------------------------------------------------------------------
# methods not yet implemented in Gnome::Gtk3::Label because
# Pango isn't there yet
sub gtk_label_set_ellipsize ( N-GObject $label, GEnum $mode )
  is native(&gtk-lib)
  { * }

sub gtk_label_get_ellipsize ( N-GObject $label --> GEnum )
  is native(&gtk-lib)
  { * }
