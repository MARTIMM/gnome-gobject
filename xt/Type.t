# Test cannot run without Gnome::Gtk3! therefore cannot place in t directory

use v6;
use NativeCall;
use Test;

use Gnome::N::NativeLib:api<1>;
use Gnome::N::N-GObject:api<1>;

use Gnome::Glib::Quark:api<1>;

use Gnome::GObject::Type:api<1>;
use Gnome::GObject::Object:api<1>;

use Gnome::Gtk3::Button:api<1>;

#use Gnome::N::X:api<1>;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
subtest 'ISA test', {
  my Gnome::GObject::Type $t .= new;
  isa-ok $t, Gnome::GObject::Type;
}

#-------------------------------------------------------------------------------
unless %*ENV<raku_test_all>:exists {
  done-testing;
  exit;
}

#-------------------------------------------------------------------------------
subtest 'Manipulations', {
  my Gnome::Gtk3::Button $b .= new(:label<stop>);
  my N-GObject $n-button = $b._get-native-object-no-reffing;
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
  is $t.name($gtype), 'GtkButton',
     "gtype 0x$gtype.base(16) is a GtkButton type";

  lives-ok {
    diag "Quark of GtkButton type 0x$gtype.base(16): " ~ $t.qname($gtype);
  }, ".qname()";

  my UInt $x-gtype = $t.parent($gtype);
  is $t.name($x-gtype), 'GtkBin',
     "gtype 0x$x-gtype.base(16) is a GtkBin type";

  $x-gtype = $t.parent($x-gtype);
  is $t.name($x-gtype), 'GtkContainer',
     "gtype 0x$x-gtype.base(16) is a GtkContainer type";

  $x-gtype = $t.parent($x-gtype);
  is $t.name($x-gtype), 'GtkWidget',
     "gtype 0x$x-gtype.base(16) is a GtkWidget type";

  is $t.depth($gtype), 6, 'GtkButton typedepth is 6';
  is $t.depth($x-gtype), 3, 'GtkWidget typedepth is 3';

  # cast button object into a widget object (last $x-type is that of a widget)
  my N-GObject $cast-object = $t.check-instance-cast( $n-button, $x-gtype);
  is $t.check-instance-is-a( $cast-object, $x-gtype), True,
     'new object is a GtkWidget';
  is $t.is-a( $gtype, $x-gtype), True, 'GtkButton is a GtkWidget';


  my N-GTypeQuery $q = $t.query($gtype);
#note "$q.type(), $q.class_size(), $q.instance_size()";
  is $q.type(), $gtype, '.query.type()';
#  my @b-items = ();
#  my Int $i = 0;
#  my $tn = $q.type_name;
#  while $tn[$i] {
#note "item: $tn[$i]";
#    @b-items.push: $tn[$i];
#    $i++;
#  }

#  my Buf $buf .= new(|@b-items);
  is $q.type_name, 'GtkButton', '.query() .name()';

  my Gnome::Glib::Quark $quark;
  my UInt $quark-name = $t.qname($gtype);
  is $quark-name, $quark.try-string('GtkButton'), '.qname()';

  is $t.name-from-instance($n-button), 'GtkButton', '.name-from-instance()';
}

#-------------------------------------------------------------------------------
done-testing;
