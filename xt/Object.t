use v6;
#use lib '../gnome-gtk3/lib';
use NativeCall;
use Test;

use Gnome::N::N-GObject;

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
subtest 'properties', {

  my Gnome::Gtk3::Button $b .= new(:label<Start>);
  ok $b.is-floating, '.is-floating() is floating no ownership';

  my Gnome::Gtk3::Window $w .= new;
  $w.add($b);
  ok !$b.is-floating, '.is-floating() not floating -> parent is window';

  my Gnome::GObject::Value $v = $b.get-property( 'label', G_TYPE_STRING);
  is $v.get-string, 'Start', '.get-property( \'label\', G_TYPE_STRING)';
  $v.clear-object;
  $v .= new(:init(G_TYPE_BOOLEAN));
  $b.get-property( 'use-underline', $v);
  is $v.get-boolean, 0,
     '.get-property( \'use-underline\', Gnome::GObject::Value)';
  $v.clear-object;
#`{{
  $v = $b.g-object-get-property( 'always-show-image', G_TYPE_BOOLEAN);
  is $v.get-boolean, 1, '.g-object-get-property( Str, GType)';
  $v.clear-object;

  $v .= new(:init(G_TYPE_BOOLEAN));
  $b.g-object-get-property( 'label', $v);
  is $v.get-string, 'Start', '.g-object-get-property( Str, GValue)';
  $v.clear-object;
}}

  $v .= new( :type(G_TYPE_STRING), :value<stop>);
  $b.set-property( 'label', $v);
  $v.clear-object;
  $v .= new(:init(G_TYPE_STRING));
  $b.get-property( 'label', $v);
  is $v.get-string, 'stop', '.set-property( Str, Gnome::GObject::Value)';

#`{{
  my @pv = $b.g-object-get( 'label', 'use-underline', 'always-show-image');
  is @pv[0].string, 'stop', '.g-object-get() string';
  is @pv[0].bool, 1, '.g-object-get() boolean';
}}
}

#`{{ set works but get doesn't
#-------------------------------------------------------------------------------
subtest 'set, get', {
  my Gnome::Gtk3::Button $b .= new(:label<Start>);
  $b.set( :label<pep-toet>, :use-underline(True));
  is $b.get-label, 'pep-toet', '.set()';

  my Str $ret-lbl .= new;
  my Bool $ret-use .= new;
  $b.get( :label($ret-lbl), :use-underline($ret-use));
  note " $ret-lbl, $ret-use";
}
}}

#-------------------------------------------------------------------------------
subtest 'object data', {
  my Gnome::Gtk3::Button $b .= new(:label<Start>);
  my Gnome::Gtk3::Label $bl .= new(:text<a-label>);

  $b.set-data(
    'attached-label-data',
    nativecast( Pointer, $bl.get-native-object-no-reffing)
  );

  my Gnome::Gtk3::Label $att-bl .= new(
    :native-object( nativecast( N-GObject, $b.get-data('attached-label-data')))
  );
  is $att-bl.get-text, 'a-label', '.set-data() / .get-data()';

  $att-bl .= new(
    :native-object(
      nativecast( N-GObject, $b.steal-data('attached-label-data'))
    )
  );
  is $att-bl.get-text, 'a-label', '.steal-data()';

  $att-bl .= new(
    :native-object( nativecast( N-GObject, $b.get-data('attached-label-data')))
  );
  nok $att-bl.is-valid, 'stolen object data not found';


  # less cumbersome
  $bl .= new(:text<a-label-2nd-attempt>);
  $b.set-data( 'attached-label-data2', $bl.get-native-object-no-reffing);
  my $no = $b.get-data( 'attached-label-data2', :type(N-GObject));
  my Gnome::Gtk3::Label $att-bl2 .= new(:native-object($no));
  is $att-bl2.get-text, 'a-label-2nd-attempt', '2nd-attempt: .set-data() / .get-data()';

  # simple data
  $bl.set-data( 'my-text-key', 'my important text');
  is $bl.get-data( 'my-text-key', :type(Str)), 'my important text',
    'simple types Str: .set-data() / .get-data()';

  $bl.set-data( 'my-num-key', 0.23e-1);
  is $bl.get-data( 'my-num-key', :type(Num)), 23e-3,
    'simple types Num: .set-data() / .get-data()';

# Problem with buf is that there should be a length added to its data. Returning
# the data must make use of this data. So leave it to the user. Idea: use
# BSON::Document. First 4 bytes is the length of a BSON document!
#  # simple data Buf
#  $bl.set-data( 'my-buf-key', Buf.new(0xef, 0xfe));
#  my Buf $buf = $bl.get-data( 'my-buf-key', :type(Buf));
#  is $buf[1], 0xfe, 'simple types Buf: .set-data() / .get-data()';
  my BSON::Document $bson .= new: (
    :int-number(-10),
    :num-number(-2.34e-3),
    strings => BSON::Document.new(( :s1<abc>, :s2<def>, :s3<xyz> ))
  );
  note $bson.perl;
  my Buf $enc-bson = $bson.encode;
  $bl.set-data( 'my-buf-key', $enc-bson);

  my CArray[uint8] $ca8 = nativecast(
    CArray[uint8], $bl.get-data('my-buf-key')
  );
  my Buf $l-ca8 .= new($ca8[0..3]);
  my Int $doc-size = decode-int32( $l-ca8, 0);
  my Buf $b-ca8 .= new($ca8[0..($doc-size-1)]);
  my BSON::Document $bson2 .= new($b-ca8);
  is $bson2<int-number>, -10, 'bson Int';
  is $bson2<num-number>, -234e-5, 'bson Num';
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
