package App::JIRAPrint;
# ABSTRACT: Print JIRA Tickets on Postit sheets

use Moose;
use Log::Any qw/$log/;

=head1 NAME

App::JIRAPrint - Print JIRA Tickets on post it sheets

=head1 INSTALLATION

  cpan -i App::JIRAPrint

Or

  cpanm App::JIRAPrint

=head1 SYNOPSIS

  jiraprint

=cut

use autodie qw/:all/;
use Cwd;
use Data::Dumper;
use File::Spec;
use Hash::Merge;
use JIRA::REST;


# Config stuff.
has 'config' => ( is => 'ro', isa => 'HashRef', lazy_build => 1);
has 'config_files' => ( is => 'ro' , isa => 'ArrayRef[Str]' , lazy_build => 1);

# Operation properties
has 'url' => ( is => 'ro', isa => 'Str', lazy_build => 1 );
has 'username' => ( is => 'ro', isa => 'Str' , lazy_build => 1);
has 'password' => ( is => 'ro', isa => 'Str' , lazy_build => 1);

has 'project' => ( is => 'ro', isa => 'Str' , lazy_build => 1 );
has 'sprint'  => ( is => 'ro', isa => 'Str' , lazy_build => 1 );
has 'maxissues' => ( is => 'ro', isa => 'Int' , lazy_build => 1);

has 'jql' => ( is => 'ro', isa => 'Str', lazy_build => 1);
has 'fields' => ( is => 'ro', isa => 'ArrayRef[Str]', lazy_build => 1 );

# Objects
has 'jira' => ( is => 'ro', isa => 'JIRA::REST', lazy_build => 1);

sub _build_jira{
    my ($self) = @_;
    $log->info("Accessing JIRA At ".$self->url()." as '".$self->username()."' (+password)");
    return JIRA::REST->new( $self->url() , $self->username() , $self->password() );
}

sub _build_fields{
    my ($self) = @_;
    return $self->config()->{fields} // [ qw/key status summary assignee/ ];
}

sub _build_maxissues{
    my ($self) = @_;
    return $self->config()->{maxissues} // 50;
}

sub _build_url{
    my ($self) = @_;
    return $self->config()->{url} // die "Missing url ".$self->config_place()."\n";
}

sub _build_username{
    my ($self) = @_;
    return $self->config()->{username} // die "Missing username ".$self->config_place()."\n";
}

sub _build_password{
    my ($self) = @_;
    return $self->config()->{password} // die "Missing password ".$self->config_place()."\n";
}

sub _build_project{
    my ($self) = @_;
    return $self->config()->{project} // die "Missing project ".$self->config_place()."\n";
}

sub _build_sprint{
    my ($self) = @_;
    return $self->config()->{sprint} // die "Missing sprint ".$self->config_place()."\n";
}

sub _build_jql{
    my ($self) = @_;
    return $self->config()->{jql} //
        'project = "'.$self->project().'" and Sprint = "'.$self->sprint().'" ORDER BY status, assignee, created'
}

sub config_place{
    my ($self) = @_;
    if( $self->has_config_files() && @{ $self->config_files() } ){
        return 'in config files: '.join(', ', @{$self->config_files()} );
    }
    return 'in memory config';
}

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
        $log->debug("Looking for $candidate");
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

=head2 fetch_fields

Returns the list of available fiels at this (url, username, password, project)

Usage:

 my $fields = $this->fetch_fields();

=cut

sub fetch_fields{
    my ($self) = @_;
    return $self->jira->GET('/field');
}

=head2 fetch_issues

Fetches issues from JIRA Using this object properties (url, username, password, project, maxissues, fields)

Usage:

 my $issues = $this->fetch_issues();

=cut

sub fetch_issues{
    my ($self) = @_;
    my $issues = $self->jira()->POST('/search', undef , {
        jql => $self->jql(),
        startAt => 0,
        maxResults => $self->maxissues(),
        fields => $self->fields()
    });

    $log->debug(&{
        (sub{
             return "Issues ".( Data::Dumper->new([ $issues ])->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump );
         })
    }() ) if $log->is_debug();
    return $issues;
}

1;
