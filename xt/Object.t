use v6;

# Note that this test cannot be placed in ./t directory because of
# dependencies on Gtk modules to test out properties of those classes

#use lib '../gnome-gtk3/lib';
#use lib '../gnome-native/lib';
use NativeCall;
use Test;
#use trace;

use Gnome::N::N-GObject:api<1>;
use Gnome::N::GlibToRakuTypes:api<1>;

use Gnome::GObject::Type:api<1>;
use Gnome::GObject::Value:api<1>;
use Gnome::GObject::Closure:api<1>;

use Gnome::Gtk3::Window:api<1>;
use Gnome::Gtk3::Button:api<1>;
use Gnome::Gtk3::Image:api<1>;
use Gnome::Gtk3::Enums:api<1>;
use Gnome::Gtk3::Label:api<1>;
use Gnome::Gtk3::Adjustment:api<1>;

use Gnome::N::X:api<1>;
#Gnome::N::debug(:on);

use BSON;
use BSON::Document;

#-------------------------------------------------------------------------------
subtest 'object', {
  my Gnome::Gtk3::Button $b .= new(:label<Start>);
  ok $b.is-floating, '.is-floating() is floating no ownership';

  my Gnome::Gtk3::Window $w .= new;
  $w.add($b);
  ok !$b.is-floating, '.is-floating() not floating -> parent is window';
}

#-------------------------------------------------------------------------------
subtest 'properties', {
  #-----------------------------------------------------------------------------
  subtest 'set-property, get-property', {
    my Gnome::Gtk3::Button $b .= new(:label<Start>);

    my Gnome::GObject::Value $v = $b.get-property( 'label', G_TYPE_STRING);
    is $v.get-string, 'Start', '.get-property( \'label\', G_TYPE_STRING)';
    $v.clear-object;
    $v .= new(:init(G_TYPE_BOOLEAN));
    $b.get-property( 'use-underline', $v);
    is $v.get-boolean, False,
       '.get-property( \'use-underline\', Gnome::GObject::Value)';
    $v.clear-object;

    $v .= new( :type(G_TYPE_STRING), :value<stop>);
    $b.set-property( 'label', $v);
    $v.clear-object;
    is $b.get-label, 'stop', '.set-property( \'label\', Gnome::GObject::Value)';
  }

  #-----------------------------------------------------------------------------
  subtest 'set-properties, get-properties', {
    my Gnome::Gtk3::Button $button .= new(:label<Start>);
    my Gnome::Gtk3::Image $image .= new(
      :icon-name<audio-off>, :size(GTK_ICON_SIZE_BUTTON)
    );
    $image.set-name('bttnimg');
    $button.set-image($image);

    # Overwrite label and set underline
    $button.set-properties( :label<pep-toet>, :use-underline(True));

    # Now try the opposite of .set-properties().
    my @rv = $button.get-properties( 'label', Str, 'use-underline', Bool);
    is-deeply @rv, [ 'pep-toet', 1], '.get-properties(): Str, Bool';

    $button.set-properties(:use-underline(0));
    @rv = $button.get-properties( 'use-underline', Int);
    is-deeply @rv, [ 0,], '.get-properties(): Int';

    # Other types
    my Gnome::Gtk3::Adjustment $adj .= new(
      :value(10), :lower(-100), :upper(100), :step-increment(1),
      :page-increment(2), :page-size(5)
    );

    @rv = $adj.get-properties(
      'value', gdouble, 'lower', num64, 'upper', num64,
      'step-increment', gdouble, 'page-increment', gdouble,
      'page-size', num64
    );
    is-deeply @rv, [ 10e0, -100e0, 100e0, 1e0, 2e0, 5e0],
      '.get-properties(): Num, num64, gdouble';

    @rv = $button.get-properties( 'image', N-GObject);
    is Gnome::Gtk3::Image.new(:native-object(@rv[0])).get-name, 'bttnimg',
      '.get-properties(): N-GObject';

    # no such property 'abc'
    # (Object.t:253680): GLib-GObject-WARNING **: 21:21:50.970: g_object_get_is_valid_property: object class 'GtkAdjustment' has no property named 'abc'
    @rv = $adj.get-properties( 'abc', N-GClosure);
    nok @rv[0].defined, '.get-properties(): \'abc\' property undefined';
  }
}

#-------------------------------------------------------------------------------
subtest 'object data', {
  my Gnome::Gtk3::Button $b .= new(:label<Start>);
  my Gnome::Gtk3::Label $bl .= new(:text<a-label>);

  $b.set-data( 'attached-label-data', $bl);
  $bl.clear-object;
  $bl = Nil;

  $bl = $b.get-data( 'attached-label-data', N-GObject);

  is $bl.get-text, 'a-label', '.set-data() / .get-data()';

  $bl = $b.steal-data( 'attached-label-data', N-GObject);
  is $bl.get-text, 'a-label', '.steal-data()';

  $bl = $b.get-data(
    'attached-label-data', N-GObject, :widget-class<Gnome::Gtk3::Label>
  );
  nok $bl.is-valid, 'stolen object data not found';


  # less cumbersome
  $bl .= new(:text<a-label-2nd-attempt>);
  $b.set-data( 'attached-label-data2', $bl);
  $bl = $b.get-data( 'attached-label-data2', N-GObject);
  is $bl.get-text, 'a-label-2nd-attempt',
     '2nd-attempt: .set-data() / .get-data()';

  # simple data
  $bl.set-data( 'my-text-key', 'my important text');
  is $bl.get-data( 'my-text-key', Str), 'my important text',
    'simple types Str: .set-data() / .get-data()';

  $bl.set-data( 'my-gulong-key', my gulong $x = 1_000_000_000);
  is $bl.get-data( 'my-gulong-key', gulong), 1_000_000_000,
    'simple types gulong: .set-data() / .get-data()';

  $bl.set-data( 'my-rat-key', 1/3);
  is $bl.get-data( 'my-rat-key', Rat), 1/3,
    'simple types Rat: .set-data() / .get-data()';

  $bl.set-data( 'my-num-key', 0.23e-1);
  is-approx $bl.get-data( 'my-num-key', Num), 23e-3,
    'simple types Num: .set-data() / .get-data()';

  # Problem with buf is that there should be a length added to its data.
  # Returning the data must make use of this length. So this must be left to
  # the user. As an idea, one can use a BSON::Document. When encoded, the first
  # 4 bytes is the length of a complete BSON document!
  my BSON::Document $bson .= new: (
    :int-number(-10),
    :num-number(-2.34e-3),
    :strings( :s1<abc>, :s2<def>, :s3<xyz>)
  );
#note $bson.raku;

  # Encode and set the data in the Label object
  $bl.set-data( 'my-buf-key', $bson.encode);

  # Get data back
  my BSON::Document $bson2 .= new($bl.get-data( 'my-buf-key', Buf));

  # Use it
  is-deeply
    ( $bson2<int-number>, $bson2<num-number>, $bson2<strings><s2>),
    ( -10, -234e-5, 'def'),
    'complex data BSON::document: .set-data() / .get-data()';
}

#-------------------------------------------------------------------------------
class X {
  method cb ( N-GObject $nw, :$test = '???' ) {
    my Gnome::Gtk3::Widget $w .= new(:native-object($nw));
    if $w.widget-get-name() eq 'GtkLabel' {
      ok 1, 'the one and only widget in a button';

      my Gnome::Gtk3::Label $l .= new(:native-object($nw));
      is $l.get-text, $test, 'label is ok';
    }
  }

  method click ( :_widget($w) ) {
    note 'clicked ...';
  }
}

subtest 'container', {
  my Gnome::Gtk3::Button $b .= new(:label<Start>);
  $b.container-foreach( X.new, 'cb', :test<Start>, :test2<x>, :test3<y>);

  # button was floating and causes an error when cleared. Sink it will
  # increase ref or remove floats. in below call, returned object is thrown.
  $b.ref-sink;
  $b.clear-object;
  ok !$b.is-valid, '.clear-object() object cleared';
}

#`{{
#-------------------------------------------------------------------------------
subtest 'signals', {

  my Gnome::Gtk3::Button $b .= new(:label<Start>);
  my Int $hid = $b.register-signal( X.new, 'click', 'clicked');
  my Int $sid = $b.g_signal_lookup('clicked');
  is $sid, $hid, '.signal-lookup(): ' ~ $hid;
  $b.emit-by-name('clicked');
  is $b.signal-name($sid), 'clicked', '.signal-name()';
  $b.handler_disconnect($hid);

  $hid = $b.register-signal( X.new, 'click', 'clicked');
  is $b.g_signal_lookup('clicked'), $hid, '.signal-lookup(): ' ~ $hid;
Gnome::N::debug(:on);
  is $b.signal-lookup('clicked'), $hid, '.signal-lookup(): ' ~ $hid;
}
}}

#-------------------------------------------------------------------------------
done-testing;
