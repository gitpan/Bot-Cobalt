use Test::More tests => 22;
use strict; use warnings;

use Try::Tiny;
use Fcntl qw/:flock/;
use File::Spec;
use File::Temp qw/ tempdir /;

BEGIN {
  use_ok( 'Bot::Cobalt::Conf' );
  use_ok( 'Bot::Cobalt::Core' );
  use_ok( 'Bot::Cobalt::Plugin::RDB::Database' );
}

my $workdir = File::Spec->tmpdir;
my $tempdir = tempdir( CLEANUP => 1, DIR => $workdir );

my $basedir;
use Module::Build;
try {
  $basedir = Module::Build->current->base_dir;
} catch {
  die 
    "\nFailed to retrieve base_dir() from Module::Build\n",
    " ... are you trying to run the test suite outside of `./Build`?\n",
};

my $etcdir = File::Spec->catdir( $basedir, 'etc' );
my $cfg = new_ok( 'Bot::Cobalt::Conf' => [
    etc => $etcdir,
  ],
);

my $core = Bot::Cobalt::Core->instance(
  cfg => $cfg,
  var => $tempdir,
);

my $rdb = new_ok( 'Bot::Cobalt::Plugin::RDB::Database' => [
    RDBDir => $tempdir,
    CacheKeys => 5,
  ]
);

ok( $rdb->createdb('test'), 'createdb()' );

ok( ! $rdb->get_keys('test'), 'empty db' );

my $newkey;

my $item_ref = [ 'things', time(), 'stuff' ];

ok( $newkey = $rdb->put('test', $item_ref ), 'Add key' );

is_deeply( $rdb->get('test', $newkey), $item_ref, 'Retrieve key' );

is_deeply( $rdb->random('test'), $item_ref, 'random()' );

is( ($rdb->get_keys('test'))[0], $newkey, 'get_keys()' );
cmp_ok( scalar $rdb->get_keys('test'), '==', 1, 'scalar get_keys()' );

ok( $rdb->del('test', $newkey), 'Del key' );

try { 
  $rdb->get('test', $newkey)
} catch {
  isa_ok( $_, 'Bot::Cobalt::Error' )
};

undef $newkey;

my $i;
for (1 .. 10) {
  ++$i;
  my $this_ref = [ 'item'.$i, 1, 'stuff'];
  $rdb->put('test', $this_ref)
}

cmp_ok( scalar $rdb->get_keys('test'), '==', 10, 'get_keys() == 10' );

ok( ref $rdb->search('test', 'item5') eq 'ARRAY', 'search()' );

my $item;
ok( $item = ($rdb->search('test', 'item4'))[0] );
is_deeply( 
  $rdb->get('test', $item),
  [ 'item4', 1, 'stuff' ],
);

my $resultref;
ok( $rdb->put('test', [ 'extra', 1, 'item' ]) );
ok( $resultref = $rdb->search('test', '*tem?'), 'glob search()' );
cmp_ok(@$resultref, '==', 10, 'search() returned expected count');

ok( $rdb->deldb('test'), 'deldb()' );
