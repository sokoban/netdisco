package App::Netdisco::Worker::Plugin::Macsuck;

use Dancer ':syntax';
use App::Netdisco::Worker::Plugin;
use aliased 'App::Netdisco::Worker::Status';

use App::Netdisco::Util::Device 'is_macsuckable_now';
use App::Netdisco::Transport::SNMP ();

register_worker({ primary => true }, sub {
  my ($job, $workerconf) = @_;
  my $device = $job->device;

  return Status->error('macsuck failed: unable to interpret device param')
    unless defined $device;

  my $host = $device->ip;

  return Status->done("macsuck skipped: $host not yet discovered")
    unless $device->in_storage;

  return Status->defer("macsuck skipped: $host is pseudo-device")
    if $device->vendor and $device->vendor eq 'netdisco';

  return Status->defer("macsuck deferred: $host is not macsuckable")
    unless is_macsuckable_now($device);

  return Status->done('Macsuck is able to run.');
});

true;
