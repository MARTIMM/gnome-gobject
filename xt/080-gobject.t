use v6;
#use lib 'lib', '../gnome-glib/lib';

use NativeCall;
use Test;

use Gnome::GObject::Value:api<1>;
use Gnome::GObject::Type:api<1>;
use Gnome::Gtk3::Label:api<1>;

#use Gnome::N::X:api<1>;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
my Gnome::GObject::Type $gt;
my Gnome::GObject::Value $gv;

#-------------------------------------------------------------------------------
subtest 'properties of label', {

  $gt .= new;
  $gv .= new(:init(G_TYPE_STRING));
#  is $gt.g-type-check-value($gv), 1, 'value initialized';

  my Gnome::Gtk3::Label $label1 .= new(:text('abc def'));
  is $label1.gtk-label-get-text, 'abc def', 'label text set';

  $label1.g-object-get-property( 'label', $gv);
  is $gv.g-value-get-string, 'abc def', 'label property matches with text';

  $gv.g-value-set-string('pqr xyz');
  $label1.g-object-set-property( 'label', $gv);
  is $label1.gtk-label-get-text, 'pqr xyz',
     'label text modified using property ';

  $gv.clear-object;

  $gv .= new(:init(G_TYPE_INT));
  $label1.get-property( 'lines', $gv);
  is $gv.get-int, -1, 'default lines property set to -1';

  $gv.clear-object;
}

#`{{
#-------------------------------------------------------------------------------
subtest 'properties of screen', {


}
}}

#-------------------------------------------------------------------------------
done-testing;
