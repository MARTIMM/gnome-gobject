use v6;
use NativeCall;
use Gnome::N::NativeLib:api<1>;
use Gnome::N::N-GObject:api<1>;
use Gnome::N::GlibToRakuTypes:api<1>;

sub gtk_about_dialog_set_authors ( N-GObject $about, char-pptr $authors )
  is native(&gtk-lib)
  { * }


my Signature $s = &gtk_about_dialog_set_authors.signature;
note $s.params;
note $s.returns;
