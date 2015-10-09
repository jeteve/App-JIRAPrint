package App::JIRAPrint;
# ABSTRACT: Print JIRA Tickets on Postit sheets

use Moose;
use Log::Any qw/$log/;

use autodie qw/:all/;
use Cwd;
use File::Spec;
use Hash::Merge;


# Config stuff.
has 'config' => ( is => 'ro', isa => 'HashRef', lazy_build => 1);

has 'config_files' => ( is => 'ro' , isa => 'ArrayRef[Str]' , lazy_build => 1);

sub _build_config{
    my ($self) = @_;
    my $config = {};
    my $merge = Hash::Merge->new( 'RETAINMENT_PRECEDENT' );
    foreach my $config_file ( reverse @{$self->config_files} ){
        $log->info("Loading $config_file");
        my $file_config =  do $config_file ;
        unless( $file_config ){
            $log->warn("Cannot read $config_file");
            $file_config = {};
        }
        $config = $merge->merge( $config, $file_config );
    }
    return $config;
}

sub _build_config_files{
    my ($self) = @_;
    my @candidates = (
        File::Spec->catfile( getcwd() , '.jiraprint.conf' ),
        File::Spec->catfile( $ENV{HOME} , '.jiraprint.conf' ),
        File::Spec->catfile( '/' , 'etc' , 'jiraprint.conf' )
      );
    my @files = ();
    foreach my $candidate ( @candidates ){
        if( -r $candidate ){
            $log->info("Found config file '$candidate'");
            push @files , $candidate;
        }
    }
    unless( @files ){
        $log->warn("Cannot find any config files amongst ".join(', ' , @candidates ).". Relying only on command line switches");
    }
    return \@files;
}


1;
