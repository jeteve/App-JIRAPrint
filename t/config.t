#! perl -w

use Test::More;

use App::JIRAPrint;

{
    my $j = App::JIRAPrint->new({ config_files => [ 't/config1.conf' ,  't/config2.conf' ] });
    is_deeply( $j->config() , { foo => [ 'bar2' , 'bar1' ] } );
    is( $j->config_place() , 'in config files: '.join(', ' , @{[ 't/config1.conf',  't/config2.conf'] } ) );
}

{
    my $j = App::JIRAPrint->new({ config => {} });
    is( $j->config_place() , 'in memory config' );
}


done_testing();

