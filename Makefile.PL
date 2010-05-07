
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Dist::Zilla::PluginBundle::FLORA',
                       'DISTNAME' => 'Dist-Zilla-PluginBundle-FLORA',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.31'
                                               },
                       'AUTHOR' => 'Florian Ragwitz <rafl@debian.org>',
                       'BUILD_REQUIRES' => {
                                             'Test::More' => '0'
                                           },
                       'ABSTRACT' => 'Build your distributions like FLORA does',
                       'EXE_FILES' => [],
                       'VERSION' => '0.02',
                       'PREREQ_PM' => {
                                        'MooseX::Types::Moose' => '0',
                                        'Dist::Zilla::Plugin::PodWeaver' => '0',
                                        'Pod::Weaver::PluginBundle::FLORA' => '0',
                                        'MooseX::Types::Structured' => '0.20',
                                        'Dist::Zilla::Role::PluginBundle::Easy' => '0',
                                        'MooseX::Types::URI' => '0',
                                        'Dist::Zilla::Plugin::MetaConfig' => '0',
                                        'Dist::Zilla::PluginBundle::Filter' => '0',
                                        'Dist::Zilla::Plugin::MetaResources' => '0',
                                        'Moose' => '1.00',
                                        'namespace::autoclean' => '0',
                                        'Method::Signatures::Simple' => '0',
                                        'Dist::Zilla::Plugin::AutoPrereq' => '0',
                                        'Dist::Zilla::PluginBundle::Classic' => '0',
                                        'Dist::Zilla::Plugin::Authority' => '0',
                                        'Dist::Zilla::Plugin::MetaJSON' => '0',
                                        'Dist::Zilla::Plugin::TaskWeaver' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM}; 
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod}; 
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



