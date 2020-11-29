# Test cannot run without Gnome::Gtk3! therefore cannot place in t directory

use v6;
use NativeCall;
use Test;

use Gnome::N::NativeLib;
use Gnome::N::N-GObject;

use Gnome::Glib::Quark;

use Gnome::GObject::Type;
use Gnome::GObject::Object;

use Gnome::Gtk3::Button;

#use Gnome::N::X;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
subtest 'ISA test', {
  my Gnome::GObject::Type $t .= new;
  isa-ok $t, Gnome::GObject::Type;
}

#-------------------------------------------------------------------------------
subtest 'Manipulations', {
  my Gnome::Gtk3::Button $b .= new(:label<stop>);
  my N-GObject $n-button = $b.get-native-object-no-reffing;
  isa-ok $n-button, N-GObject;

#note $n-button;
#  my N-GTypeInfo $info .= new(
#    :class_size(),
#    :instance_size(), :n_preallocs(0),
#  );

#Gnome::N::debug(:on);
#TODO no debug lines in Type module

  my Gnome::GObject::Type $t .= new;
#  $t.register-static( );
  my UInt $gtype = $t.from-name('GtkButton');
  is $t.type-name($gtype), 'GtkButton',
     "gtype 0x$gtype.base(16) is a GtkButton type";

  my UInt $x-gtype = $t.type-parent($gtype);
  is $t.type-name($x-gtype), 'GtkBin',
     "gtype 0x$x-gtype.base(16) is a GtkBin type";

  $x-gtype = $t.type-parent($x-gtype);
  is $t.type-name($x-gtype), 'GtkContainer',
     "gtype 0x$x-gtype.base(16) is a GtkContainer type";

  $x-gtype = $t.type-parent($x-gtype);
  is $t.type-name($x-gtype), 'GtkWidget',
     "gtype 0x$x-gtype.base(16) is a GtkWidget type";

  is $t.type-depth($gtype), 6, 'GtkButton typedepth is 6';
  is $t.type-depth($x-gtype), 3, 'GtkWidget typedepth is 3';

  # cast button object into a widget object (last $x-type is that of a widget)
  my N-GObject $cast-object = $t.check-instance-cast( $n-button, $x-gtype);
  is $t.check-instance-is-a( $cast-object, $x-gtype), 1,
     'new object is a GtkWidget';
  is $t.is-a( $gtype, $x-gtype), 1, 'GtkButton is a GtkWidget';


  my N-GTypeQuery $q = $t.type-query($gtype);
#  note "$q.type(), $q.class_size(), $q.instance_size()";
  is $q.type(), $gtype, '.type-query() .type()';
  my @b-items = ();
  my Int $i = 0;
  my $tn = $q.type_name;
  while $tn[$i] {
    @b-items.push: $tn[$i];
    $i++;
  }

  my Buf $buf .= new(|@b-items);
  is $buf.decode, 'GtkButton', '.type-query() .type-name()';

  my Gnome::Glib::Quark $quark;
  my UInt $quark-name = $t.type-qname($gtype);
  is $quark-name, $quark.try-string('GtkButton'), '.type-qname()';

  is $t.name-from-instance($n-button), 'GtkButton', '.name-from-instance()';
}

#-------------------------------------------------------------------------------
done-testing;
