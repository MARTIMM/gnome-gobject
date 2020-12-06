use v6;
use NativeCall;
use Gnome::N::NativeLib;
use Gnome::N::N-GObject;
use Gnome::N::GlibToRakuTypes;

sub gtk_about_dialog_set_authors ( N-GObject $about, char-pptr $authors )
  is native(&gtk-lib)
  { * }


my Signature $s = &gtk_about_dialog_set_authors.signature;
note $s.params;
note $s.returns;
