#! perl -w

use Test::More;

use App::JIRAPrint;

my $j = App::JIRAPrint->new({ config_files => [ 't/config1.conf' ,  't/config2.conf' ] });
is_deeply( $j->config() , { foo => [ 'bar2' , 'bar1' ] } );

done_testing();

