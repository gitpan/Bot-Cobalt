package Bot::Cobalt::Plugin::Extras::DNS;
our $VERSION = '0.001';

## Mostly borrowed from POE::Component::IRC::Plugin::QueryDNS by BinGOs

use 5.10.1;

use Bot::Cobalt;
use Bot::Cobalt::Common;

use POE;
use POE::Component::Client::DNS;

use Net::IP::Minimal qw/ip_is_ipv4 ip_is_ipv6/;

sub new { bless {}, shift }

sub Cobalt_register {
  my ($self, $core) = splice @_, 0, 2;
  
  POE::Session->create(
    object_states => [
      $self => [
        '_start',
        'dns_resp_recv',
        'dns_issue_query',
      ],
    ],
  );

  $core->plugin_register( $self, 'SERVER',
    [ 'public_cmd_dns', 'public_cmd_nslookup' ],
  );
  
  $core->log->info("Loaded: dns nslookup");
  return PLUGIN_EAT_NONE
}

sub Cobalt_unregister {
  my ($self, $core) = splice @_, 0, 2;
  $poe_kernel->alias_remove( 'p_'.$core->get_plugin_alias($self) );
  $core->log->info("Unloaded");
  return PLUGIN_EAT_NONE  
}

sub Bot_public_cmd_nslookup { Bot_public_cmd_dns(@_) }
sub Bot_public_cmd_dns {
  my ($self, $core) = splice @_, 0, 2;
  my $msg     = ${ $_[0] };
  my $context = $msg->context;
  
  my $channel = $msg->channel;
  
  my ($host, $type) = @{ $msg->message_array };
  
  $self->_run_query($context, $channel, $host, $type);
  
  return PLUGIN_EAT_ALL
}

sub _start {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  $kernel->alias_set( 'p_'. core()->get_plugin_alias($self) );
  $self->{Resolver} = POE::Component::Client::DNS->spawn(
    Alias => 'named'. core()->get_plugin_alias($self),
  );
  logger->debug("Resolver session spawned");
}

sub dns_resp_recv {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  my $response = $_[ARG0];
  my $hints    = $response->{context};

  my $context = $hints->{Context};
  my $channel = $hints->{Channel};

  my $nsresp;
  unless ($nsresp = $response->{response}) {
    broadcast( 'message', $context, $channel,
      "DNS error."
    );
    return
  }
  
  my @send;
  for my $ans ( $nsresp->answer() ) {
    given ($ans->type()) {

      when ("SOA") {
        push(@send, 
          'SOA=' . join(':', 
            $ans->mname, $ans->rname, 
            $ans->serial, $ans->refresh, 
            $ans->retry, $ans->expire, 
            $ans->minimum
           )
        );
      }
      
      default {
        push(@send, join('=', $ans->type(), $ans->rdatastr() ) );
      }
    
    }
  }
  
  my $str;
  my $host = $response->{host};
  if (@send) {
    $str = "nslookup: $host: ".join ' ', @send;
  } else {
    $str = "nslookup: No answer for $host";
  }
  
  broadcast('message', $context, $channel, $str) if $str;
}

sub _run_query {
  my ($self, $context, $channel, $host, $type) = @_;
  
  $type = 'A' unless $type 
    and $type =~ /^(A|CNAME|NS|MX|PTR|TXT|AAAA|SRV|SOA)$/i;
  
  $type = 'PTR' if ip_is_ipv4($host) or ip_is_ipv6($host);
  
  logger->debug("issuing dns request: $host");
  $poe_kernel->post( 'p_'. core()->get_plugin_alias($self), 
    'dns_issue_query',
    $context, $channel, $host, $type
  );
}  

sub dns_issue_query {
  my ($self, $kernel) = @_[OBJECT, KERNEL];
  my ($context, $channel, $host, $type) = @_[ARG0 .. $#_];
 
  my $resp = $self->{Resolver}->resolve(
    event => 'dns_resp_recv',
    host  => $host,
    type  => $type,
    context => { Context => $context, Channel => $channel },
  );
  POE::Kernel->yield('dns_resp_recv', $resp) if $resp;
  return 1
}

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Plugin::Extras::DNS - Issue DNS queries from IRC

=head1 SYNOPSIS

   !dns www.cobaltirc.org
  
  ## Same as:
   !nslookup www.cobaltirc.org
  
  ## Optionally specify a type:
   !dns irc.cobaltirc.org aaaa

=head1 DESCRIPTION

A Cobalt plugin providing DNS query results on IRC.

Uses L<POE::Component::Client::DNS> for asynchronous lookups.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>

=cut
