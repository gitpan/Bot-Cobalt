#!/usr/bin/env perl
use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(
  class => 'Bot::Cobalt::Builder',
  code => q{

    sub ACTION_release {
      my $self = shift;
      $self->dispatch('versionify');
      $self->dispatch('test');
      $self->dispatch('wikidocs');
      $self->dispatch('dist');
    }

    sub ACTION_wikidocs {
      my $self = shift;
      my $base = $self->base_dir;
      my $remote = $ENV{DOC_UPLOAD} || die "Need ENV DOC_UPLOAD";
      chdir($base."/tools/release/docs");
      $self->do_system(qw{"./pod2doku"});
      $self->do_system(
        'rsync',
        '-rv',
        '--stats',
        '--progress',
        'wikidoc/',
        $remote.
         ':public_html/docs/wiki/data/pages/bots/cobalt/docs',
      );
      chdir($base);
    }

    sub ACTION_versionify {
      my $self = shift;

      my $base = $self->base_dir;
      my $vers = $self->dist_version;

      ++$|;

      print "Versionifying ";
      require File::Find;
      File::Find->import('find');

      my $x;
      find(sub {
          if ($_ =~ /\.pm(.in)?$/) {
            my $path = $File::Find::name;
            open my $fh, '<', $path
              or die "open: $path $!";
            my @thisf = readline($fh);
            close $fh;

            my $package_l = $thisf[0] || return;
            my $pkg;
            unless (($pkg) = $package_l =~ /^package\s+(\S+)$/) {
              warn "\nSkipping, no package: $path\n";
              return
            }

            ++$x;
            print ". ";

            my $v_line = "our \$VERSION = '$vers';\n";

            if ($thisf[1] =~ /VERSION/) {
              $thisf[1] = $v_line
            }

            open $fh, '>', $path
              or die "open: $path $!";
            print $fh @thisf;
            close $fh;
          }
        },
        $base."/lib", $base."/tools"
      );
      print "\n$x modules\n";
    }

  },
);

my $build = $class->new(
  module_name   => 'Bot::Cobalt',
  dist_abstract => 'Pluggable IRC darkbot-alike',
  dist_author   => 'Jon Portnoy <avenj@cobaltirc.org>',
  license => 'perl',

  create_readme => 1,

  recursive_test_files => 1,

  ## A passthru-to-build makefile:
  create_makefile_pl => 'small',

  PL_files => {
    'lib/Bot/Cobalt/Lang.pm.PL' => 'lib/Bot/Cobalt/Lang.pm',
    'bin/cobalt2-installer.PL' => 'bin/cobalt2-installer',
  },

  configure_requires => {
    'Module::Build' => '0.40',
  },

  build_requires => {
    'Test::Exception' => 0,
    'Test::Cmd'  => 0,
    'Test::More' => 0,

    'Data::Dumper'   => 0,
    'File::Find'     => 0,
    'File::Spec'     => 0,
    'File::Temp'     => 0,
    'Try::Tiny'      => 0,
    'Fcntl' => 0,
  },

  requires => {
   ### Core set ###
      'perl' => '5.12.1',

      'Carp' => 0,
      'Cwd'  => 0,

      'Data::Dumper'     => 0,
      'DB_File'          => 0,

      'Exporter'         => 0,

      'Fcntl'            => 0,
      'File::Find'       => 0,
      'File::Spec'       => 0,
      'File::Path'       => 2.00,

      'Getopt::Long'     => 0,

      'IO::File'         => 0,

      'List::Util'       => 0,

      'Module::CoreList' => 0,

      'POSIX'            => 0,

      'Scalar::Util'     => 0,
      'Storable'         => 0,
      'strictures'       => 1,

      'Time::HiRes'      => 0,
      'Try::Tiny'        => 0,

      'overload'         => 0,

   ### Cobalt set ###
     # Crypt
      'App::bmkpasswd' => 1.06,

     # HTTP
      'HTTP::Request'  => 0,
      'HTTP::Response' => 0,
      'URI::Escape'    => 0,

     # Logging
      'Devel::StackTrace' => 1.27,

     # Moo + related
      'Moo'                    => 0.091009,
      'MooX::Types::MooseLike' => 0.08,
      'namespace::clean'       => 0,

     # Network
      'Net::IP::Minimal' => 0.04,

     # POE::
      'POE'              => 1.311,

       ## ::Resolver that doesn't fail w/ newer Socket::GetAddrInfo
       ## (Socket::GetAddrInfo is a bit unnecessary these days, it seems)
      'POE::Component::Resolver'     => 0.920,
       ## Above also applies to Client::HTTP:
      'POE::Component::Client::HTTP' => 0.947,
      'POE::Component::Client::Keepalive' => 0,
      'POE::Component::Client::DNS' => 0,
      'POE::Component::IRC::State'  => 6.78,
      'POE::Component::Syndicator'  => 0.06,
      'Object::Pluggable'           => 1.27,

     # Process
      'Proc::PID::File' => 1.26,

     # Serialization
      'JSON::XS'        => 2.00,
      'YAML::XS'        => 0.34,

     # Utils
      'List::Objects::WithUtils' => 0.002,
      'IRC::Utils'      => 0.12,
      'Term::ReadKey'   => 0,
  },

  recommends => {
    ### POE::
      'POE::Component::SSLify' => 1.006,

    ### Utils / misc
      # terminal interaction
#      'Term::ReadLine::Perl' => 0,

    ### Release tools, commented for now
#      'File::Basename'   => 0,
#      'Dir::Self' => 0,
     # templating (cpodconv/release tools)
#      'Template' => 0,
     # POD conversion
#      'Pod::Select' => 0,
#      'Pod::Find'   => 0,
#      'Pod::Simple::Wiki' => 0,
  },
);

$build->add_to_cleanup("lib/Bot/Cobalt/Lang.pm");
$build->add_to_cleanup("bin/cobalt2-installer");
$build->create_build_script;

__END__
Bacon.
