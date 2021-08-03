use v6;
#use lib '../gnome-gtk3/lib';
#use lib '../gnome-native/lib';
use NativeCall;
use Test;
#use trace;

use Gnome::N::N-GObject;
use Gnome::N::GlibToRakuTypes;

use Gnome::GObject::Type;
use Gnome::GObject::Value;

use Gnome::Gtk3::Window;
use Gnome::Gtk3::Button;
use Gnome::Gtk3::Label;

use Gnome::N::X;
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

    # Overwrite label and set underline
    $button.set-properties( :label<pep-toet>, :use-underline(True));

    # Now try the opposite of .set-properties().
    my @rv = $button.get-properties( 'label', Str, 'use-underline', Bool);
    is @rv[0], 'pep-toet', '.get-properties(): label = pep-toet';
    is @rv[1], 1, '.get-properties(): use-underline = 1';
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
  my $no = $b.get-data( 'attached-label-data2', N-GObject);
  $bl .= new(:native-object($no));
  is $bl.get-text, 'a-label-2nd-attempt', '2nd-attempt: .set-data() / .get-data()';

  # simple data
  $bl.set-data( 'my-text-key', 'my important text');
  is $bl.get-data( 'my-text-key', Str), 'my important text',
    'simple types Str: .set-data() / .get-data()';

  $bl.set-data( 'my-gulong-key', my gulong $x = 1_000_000_000);
  is $bl.get-data( 'my-gulong-key', gulong), 1_000_000_000,
    'simple types gulong: .set-data() / .get-data()';

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
    strings => BSON::Document.new(( :s1<abc>, :s2<def>, :s3<xyz> ))
  );
  diag $bson.perl;
  # Encode and set the data in the Label object
  my Buf $enc-bson = $bson.encode;
  $bl.set-data( 'my-buf-key', $enc-bson);

  my CArray[byte] $ca8 = $bl.get-data( 'my-buf-key', Buf);

  my Buf $l-ca8 .= new($ca8[0..3]);
  my Int $doc-size = decode-int32( $l-ca8, 0);
  my Buf $b-ca8 .= new($ca8[0..($doc-size-1)]);
  my BSON::Document $bson2 .= new($b-ca8);
  is $bson2<int-number>, -10, 'bson Int';
  is-approx $bson2<num-number>, -234e-5, 'bson Num';
  is $bson2<strings><s2>, 'def', 'bson Str';
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
