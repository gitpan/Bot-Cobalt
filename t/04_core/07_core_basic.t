use Test::More tests => 29;
use strict; use warnings;

BEGIN {
  use_ok( 'Bot::Cobalt::Common' );
  use_ok( 'Bot::Cobalt::Conf' );
  use_ok( 'Bot::Cobalt::Core' );
  use_ok( 'Bot::Cobalt::Core::Loader' );
}

can_ok( 'Bot::Cobalt::Core', 'init' );

can_ok( 'Bot::Cobalt::Core::Loader',
  qw/
    load
    unload
    is_reloadable
  /
);

use Module::Build;
use File::Spec;
use File::Temp qw/tempdir/;

my $workdir = File::Spec->tmpdir;
my $tempdir = tempdir( CLEANUP => 1, DIR => $workdir );

my $basedir;

use Try::Tiny;
try { 
  $basedir = Module::Build->current->base_dir
} catch {
  die "\n! Failed to retrieve base_dir() from Module::Build\n"
     ."...are you trying to run the test suite outside of `./Build`?\n"
};

my $etcdir  = File::Spec->catdir( $basedir, 'etc' );
my $cfg = new_ok( 'Bot::Cobalt::Conf' => [
    etc => $etcdir,
  ],
);

my $core;
ok( 
  $core = Bot::Cobalt::Core->instance(
    cfg => $cfg,
    var => $tempdir,
  ),
  'instance() a Bot::Cobalt::Core',
);

ok( $core->has_instance, 'Core has_instance' );

my $second;
ok( $second = Bot::Cobalt::Core->instance, 'Retrieve instance' );
is( "$core", "$second", 'instances match' );

for my $meth (qw/debug info warn error/) {
  ok( $core->log->can($meth), "Have log method $meth" );
}

isa_ok( $core->auth, 'Bot::Cobalt::Core::ContextMeta::Auth' );
isa_ok( $core->ignore, 'Bot::Cobalt::Core::ContextMeta::Ignore' );

ok( keys %{ $core->lang }, 'lang() has keys' );

## Did we get expected roles, here?
can_ok( $core,

  ## EasyAccessors:
  qw/
    get_plugin_alias
    get_core_cfg
    get_channels_cfg
    get_plugin_cfg
  /,
  
  ## IRC:
  qw/
    is_connected
    get_irc_context
    get_irc_object
    get_irc_casemap
  /,
  
  ## Timers:
  qw/
    timer_set
    timer_del
    timer_del_alias
    timer_get
    timer_get_alias
  /,
  
);

ok( $core->get_core_cfg, 'get_core_cfg()' );
isa_ok( $core->get_core_cfg, 'Bot::Cobalt::Conf::File::Core' );

ok( 
  ref $core->get_channels_cfg('Main') eq 'HASH', 
  'get_channels_cfg(Main)' 
);
ok( 
  ref $core->get_plugin_cfg('None') eq 'HASH',
  'get_plugin_cfg(None)' 
);

ok( !$core->is_connected('Main'),    'is_connected(Main)' );
ok( !$core->get_irc_context('Main'), 'get_irc_context(Main)' );
ok( !$core->get_irc_object('Main'),  'get_irc_object(Main)' );
ok( !$core->get_irc_casemap('Main'), 'get_irc_casemap(Main)' );

ok( $core->clear_instance, 'clear_instance()' );
ok( ! $core->has_instance, 'has_instance() false after clear' );
