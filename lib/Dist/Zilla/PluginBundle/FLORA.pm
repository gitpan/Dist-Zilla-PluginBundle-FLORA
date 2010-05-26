package Dist::Zilla::PluginBundle::FLORA;
BEGIN {
  $Dist::Zilla::PluginBundle::FLORA::AUTHORITY = 'cpan:FLORA';
}
BEGIN {
  $Dist::Zilla::PluginBundle::FLORA::VERSION = '0.09';
}
# ABSTRACT: Build your distributions like FLORA does

use Moose 1.00;
use Method::Signatures::Simple;
use Moose::Util::TypeConstraints;
use MooseX::Types::URI qw(Uri);
use MooseX::Types::Email qw(EmailAddress);
use MooseX::Types::Moose qw(Bool Str CodeRef);
use MooseX::Types::Structured 0.20 qw(Map Dict Optional);
use namespace::autoclean -also => 'lower';


has dist => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has authority => (
    is      => 'ro',
    isa     => Str,
    default => 'cpan:FLORA',
);

has auto_prereq => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

has is_task => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_is_task',
);

method _build_is_task {
    return $self->dist =~ /^Task-/ ? 1 : 0;
}

has disable_pod_coverage_tests => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has bugtracker_url => (
    isa     => Uri,
    coerce  => 1,
    lazy    => 1,
    builder => '_build_bugtracker_url',
    handles => {
        bugtracker_url => 'as_string',
    },
);

method _build_bugtracker_url {
    return sprintf $self->_rt_uri_pattern, $self->dist;
}

has bugtracker_email => (
    is      => 'ro',
    isa     => EmailAddress,
    lazy    => 1,
    builder => '_build_bugtracker_email',
);

method _build_bugtracker_email {
    return sprintf 'bug-%s@rt.cpan.org', $self->dist;
}

has _rt_uri_pattern => (
    is      => 'ro',
    isa     => Str,
    default => 'http://rt.cpan.org/Public/Dist/Display.html?Name=%s',
);

has homepage_url => (
    isa     => Uri,
    coerce  => 1,
    lazy    => 1,
    builder => '_build_homepage_url',
    handles => {
        homepage_url => 'as_string',
    },
);

method _build_homepage_url {
    return sprintf $self->_cpansearch_pattern, $self->dist;
}

has _cpansearch_pattern => (
    is      => 'ro',
    isa     => Str,
    default => 'http://search.cpan.org/dist/%s',
);

has repository => (
    isa     => Uri,
    coerce  => 1,
    lazy    => 1,
    builder => '_build_repository_url',
    handles => {
        repository_url    => 'as_string',
        repository_scheme => 'scheme',
    },
);

has repository_at => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_repository_at',
);

has github_user => (
    is      => 'ro',
    isa     => Str,
    default => 'rafl',
);

my $map_tc = Map[
    Str, Dict[
        pattern     => CodeRef,
        web_pattern => CodeRef,
        mangle      => Optional[CodeRef],
    ]
];

coerce $map_tc, from Map[
    Str, Dict[
        pattern     => Str|CodeRef,
        web_pattern => Str|CodeRef,
        mangle      => Optional[CodeRef],
    ]
], via {
    my %in = %{ $_ };
    return { map {
        my $k = $_;
        ($k => {
            %{ $in{$k} },
            (map {
                my $v = $_;
                (ref $in{$k}->{$v} ne 'CODE'
                     ? ($v => sub { $in{$k}->{$v} })
                     : ()),
            } qw(pattern web_pattern)),
        })
    } keys %in };
};

has _repository_host_map => (
    traits  => [qw(Hash)],
    isa     => $map_tc,
    coerce  => 1,
    lazy    => 1,
    builder => '_build__repository_host_map',
    handles => {
        _repository_data_for => 'get',
    },
);

sub lower { lc shift }

method _build__repository_host_map {
    my $github_pattern = sub { sprintf 'git://github.com/%s/%%s.git', $self->github_user };
    my $github_web_pattern = sub { sprintf 'http://github.com/%s/%%s', $self->github_user };
    my $scsys_web_pattern_proto = sub {
        return sprintf 'http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=%s/%%s.git;a=summary', $_[0];
    };

    return {
        github => {
            pattern     => $github_pattern,
            web_pattern => $github_web_pattern,
            mangle      => \&lower,
        },
        GitHub => {
            pattern     => $github_pattern,
            web_pattern => $github_web_pattern,
        },
        gitmo => {
            pattern     => 'git://git.moose.perl.org/gitmo/%s.git',
            web_pattern => $scsys_web_pattern_proto->('gitmo'),
        },
        (map {
            ($_ => {
                pattern     => "git://git.shadowcat.co.uk/${_}/%s.git",
                web_pattern => $scsys_web_pattern_proto->($_),
            })
        } qw(catagits p5sagit dbsrgits)),
    };
}

method _build_repository_url {
    return $self->_resolve_repository_with($self->repository_at, 'pattern')
        if $self->has_repository_at;
    confess "Cannot determine repository url without repository_at. "
          . "Please provide either repository_at or repository."
}

has repository_web => (
    isa     => Uri,
    coerce  => 1,
    lazy    => 1,
    builder => '_build_repository_web',
    handles => {
        repository_web => 'as_string',
    },
);

method _build_repository_web {
    return $self->_resolve_repository_with($self->repository_at, 'web_pattern')
        if $self->has_repository_at;
    confess "Cannot determine repository web url without repository_at. "
          . "Please provide either repository_at or repository_web."
}

method _resolve_repository_with ($service, $thing) {
    my $dist = $self->dist;
    my $data = $self->_repository_data_for($service);
    confess "unknown repository service $service" unless $data;
    return sprintf $data->{$thing}->(),
        (exists $data->{mangle}
             ? $data->{mangle}->($dist)
             : $dist);
}

has repository_type => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    builder => '_build_repository_type',
);

method _build_repository_type {
    for my $vcs (qw(git svn)) {
        return $vcs if $self->repository_scheme eq $vcs;
    }

    confess "Unable to guess repository type based on the repository url. "
          . "Please provide repository_type.";
}

override BUILDARGS => method ($class:) {
    my $args = super;
    return { %{ $args->{payload} }, %{ $args } };
};

method configure {
    $self->add_bundle('@Basic');

    $self->add_plugins(qw(
        MetaConfig
        MetaJSON
        PkgVersion
        PodSyntaxTests
        SanityTests
    ));

    $self->add_plugins('PodCoverageTests')
        unless $self->disable_pod_coverage_tests;

    $self->add_plugins(
        [MetaResources => {
            'repository.type'   => $self->repository_type,
            'repository.url'    => $self->repository_url,
            'repository.web'    => $self->repository_web,
            'bugtracker.web'    => $self->bugtracker_url,
            'bugtracker.mailto' => $self->bugtracker_email,
            'homepage'          => $self->homepage_url,
        }],
        [Authority => {
            authority   => $self->authority,
            do_metadata => 1,
        }]
    );


    $self->is_task
        ? $self->add_plugins('TaskWeaver')
        : $self->add_plugins([ 'PodWeaver' => { config_plugin => '@FLORA' } ]);

    $self->add_plugins('AutoPrereq') if $self->auto_prereq;
}

with 'Dist::Zilla::Role::PluginBundle::Easy';

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

Dist::Zilla::PluginBundle::FLORA - Build your distributions like FLORA does

=head1 SYNOPSIS

In dist.ini:

  [@FLORA]
  dist = Distribution-Name
  repository_at = github

=head1 DESCRIPTION

This is the L<Dist::Zilla> configuration I use to build my
distributions.

It is roughly equivalent to:

  [@Filter]
  bundle = @Basic

  [MetaConfig]
  [MetaJSON]
  [PkgVersion]
  [PodSyntaxTests]
  [PodCoverageTests]
  [SanityTests]

  [MetaResources]
  repository = git://github.com/rafl/${lowercase_dist}
  bugtracker = http://rt.cpan.org/Public/Dist/Display.html?Name=${dist}
  homepage   = http://search.cpan.org/dist/${dist}

  [Authority]
  authority   = cpan:FLORA
  do_metadata = 1

  [PodWeaver]
  config_plugin = @FLORA

  [AutoPrereq]

=head1 AUTHOR

  Florian Ragwitz <rafl@debian.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

