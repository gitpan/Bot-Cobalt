package Bot::Cobalt;
our $VERSION = '0.005';

use 5.10.1;
use strictures 1;
use Carp;
use Moo;

use Bot::Cobalt::Core::Sugar;

use base 'Exporter';
our @EXPORT = @Bot::Cobalt::Core::Sugar::EXPORT;

sub import {
  __PACKAGE__->export_to_level(1, @_);
}

sub instance {
  require Bot::Cobalt::Core;
  if (@_) {
    ## Someone tried to create a new instance, but they really 
    ## wanted a Bot::Cobalt::Core.
    ## Behavior may change.
    return Bot::Cobalt::Core->instance(@_[1 .. $#_])
  }

  ## Be polite and offer up our Bot::Cobalt::Core if we have one
  unless (Bot::Cobalt::Core->has_instance) {
    carp "Tried to retrieve instance but no active Bot::Cobalt::Core found";
    return
  }

  return Bot::Cobalt::Core->instance 
}

sub new {
  croak "Bot::Cobalt is a stub; it cannot be constructed.\n"
    . "See the perldoc for Bot::Cobalt::Core\n";
}

1;
__END__

=pod

=head1 NAME

Bot::Cobalt - IRC darkbot-alike plus plugin authoring sugar

=head1 SYNOPSIS

  ## Set up example confs and a simple ~/.cobalt2rc :
  sh$ cobalt2-installer

  sh$ cobalt2 --help
  
  ## Launch in foreground:
  sh$ cobalt2 --nodetach
  
  ## Launch in background:
  sh$ cobalt2

=head1 DESCRIPTION

B<Bot::Cobalt> is the second generation of the (previously not released 
on CPAN) B<cobalt> IRC bot.

Cobalt was originally a Perl reimplementation of Jason Hamilton's 
B<darkbot> (darkbot's last release was in 2001).
Bot::Cobalt is a much-improved (and CPAN-able!) revision, providing a 
pluggable IRC bot framework coupled with a core set of plugins 
replicating classic darkbot and Cobalt behavior.

The included plugin set provides a wide range of functionality; see 
L</"Included plugins"> below.

IRC connectivity and protocol details are handled via 
L<POE::Component::IRC>; the bot can 
comfortably manage multiple servers/networks (referred to as 
"contexts").

Bot::Cobalt tries to be friendly to developers. The bridge to 
L<POE::Component::IRC> exists as a plugin and 
can be easily subclassed or replaced entirely; see L<Bot::Cobalt::IRC>.

Plugin authoring is intended to be as easy as possible. Modules are 
included to provide simple frontends to IRC-related 
utilities, logging, plugin configuration, asynchronous HTTP 
sessions, data serialization and on-disk databases, and more. See 
L<Bot::Cobalt::Manual::Plugins> for more about plugin authoring.

=head2 Initializing a new instance

A Cobalt instance needs its own I<etc/> and I<var/> directories. With 
the default frontend (C<cobalt2>), these are specified in a simple 
'rcfile' for each particular instance.

  sh$ cobalt2-installer

C<cobalt2-installer> will ask some questions, initialize a new rcfile 
for an instance and try to create the relevant directory layout with 
some example configuration files.

You can, of course, run multiple instances with the default frontend; 
each just needs its own rcfile:

  sh$ cobalt2-installer --rcfile=${HOME}/cobalts/mycobalt.rc
  sh$ cobalt2 --rcfile=${HOME}/cobalts/mycobalt.rc

After reviewing/editing the example configuration files, you should be 
ready to try starting your Cobalt instance:

  ## Launch in foreground with verbose debug output:
  sh$ cobalt2 --nodetach --debug
  
  ## Launch in background with configured log options:
  sh$ cobalt2

=head2 Included plugins

The example C<etc/plugins.conf> installed by C<cobalt2-installer> has 
most of these:

L<Bot::Cobalt::Plugin::Alarmclock> -- IRC highlight timers

L<Bot::Cobalt::Plugin::Auth> -- User authentication

L<Bot::Cobalt::Plugin::Games> -- Simple IRC games

L<Bot::Cobalt::Plugin::Info3> -- Flexible text-triggered responses

L<Bot::Cobalt::Plugin::Master> -- Simple bot control from IRC

L<Bot::Cobalt::Plugin::PluginMgr> -- Load/unload plugins from IRC

L<Bot::Cobalt::Plugin::RDB> -- "Random stuff" databases for quotebots 
or randomized chatter on a timer

L<Bot::Cobalt::Plugin::Extras::DNS> -- DNS lookups

L<Bot::Cobalt::Plugin::Extras::Karma> -- Karma bot

L<Bot::Cobalt::Plugin::Extras::Money> -- Currency conversion via 
WebServiceX

L<Bot::Cobalt::Plugin::Extras::Relay> -- Cross-network relay

L<Bot::Cobalt::Plugin::Extras::Shorten> -- Shorten URLs via Metamark

L<Bot::Cobalt::Plugin::Extras::TempConv> -- Temperature units conversion 

=head2 Extensions on CPAN

There are a few externally-distributed plugin sets available 
via CPAN:

L<Bot::Cobalt::Plugin::Calc> -- Simple calculator

L<Bot::Cobalt::Plugin::RSS> -- RSS feed aggregator

L<Bot::Cobalt::Plugin::Silly> -- Very silly plugin set

For debugging or playing with L<Bot::Cobalt::DB> databases, you may want 
to have a look at L<Bot::Cobalt::DB::Term>.

=head1 SEE ALSO

L<Bot::Cobalt::Manual::Plugins>

L<Bot::Cobalt::Core>

L<Bot::Cobalt::IRC>

The core pieces of Bot::Cobalt are essentially sugar over these two 
L<POE> Components:

L<POE::Component::IRC>

L<POE::Component::Syndicator> (and L<Object::Pluggable>)

Consult their documentation for all the gory details.

Logging facilities are provided by L<Log::Handler>.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>

Licensed under the same terms as Perl.

=cut
