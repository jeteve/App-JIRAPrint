#! perl -w

use Test::More;
use Test::MockModule;

use App::JIRAPrint;
# use Log::Any::Adapter qw/Stderr/;


my $j = App::JIRAPrint->new({ url => 'https://something.atlassian.net', username => 'blabla', password => 'blablabla', project => 'BLA', 'sprint' => '123' });
ok( $j->jira() , "Ok got jira client");

{
    my $jira = Test::MockModule->new('JIRA::REST');
    $jira->mock( POST =>  sub{ return { issues => [  { foo => 1 , bar => 'a' } ] } ; } );
    ok( $j->fetch_issues() , "Ok got issues");
}

done_testing();
