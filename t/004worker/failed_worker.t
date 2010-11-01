use Qudo::Test;
use Mock::Qudo::Driver::DBI;
use Test::More;
use Test::Output;

run_tests(3, sub {
    my $driver = shift;
    my $master = test_master(
        driver_class => $driver,
    );

    my $manager = $master->manager;
    $manager->can_do('Worker::Test');
    $manager->enqueue("Worker::Test", { arg => 'arg', uniqkey => 'uniqkey'});
    $manager->work_once; # failed worker

    my $exception = $master->exception_list;
    my ($db, $rows) = %$exception;
    like $rows->[0]->{message}, qr/^failed worker/;
    is $rows->[0]->{arg}, 'arg';
    is scalar(@$rows), 1;

    teardown_dbs;
});

package Worker::Test;
use base 'Qudo::Worker';

sub work {
    my ($class, $job) = @_;
    die "failed worker";
}
