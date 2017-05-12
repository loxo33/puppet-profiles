# Manage Puppet agent
class profiles::puppet (
$dns_suffix = hiera(dns_suffix)
){
  coreos::unit {'puppet-agent':
    description  => 'puppet agent service',
    after        => 'docker.service',
    requires     => 'docker.service',
    execstartpre => "/bin/bash -c '/usr/bin/docker inspect %n &> /dev/null && /usr/bin/docker rm %n || :'",
    execstart    =>
        "/usr/bin/docker run \
        --name %n \
        --net=host \
        --privileged \
        -v /etc/systemd:/etc/systemd \
        -v /etc/puppetlabs:/etc/puppetlabs \
        -v /etc/sysconfig:/etc/sysconfig \
        -v /etc/environment:/etc/environment \
        -v /etc/os-release:/etc/os-release:ro \
        -v /etc/lsb-release:/etc/lsb-release:ro \
        -v /etc/coreos:/etc/coreos:rw \
        -v /media/staging:/opt/staging \
        -v /var/lib/puppet:/var/lib/puppet \
        -v /var/run/puppetlabs:/var/run/puppetlabs \
        -v /home/core:/home/core \
        -v /run:/run:ro \
        -v /usr/bin/systemctl:/usr/bin/systemctl:ro \
        -v /usr/lib/systemd:/usr/lib/systemd:ro \
        -v /usr/lib64/systemd:/usr/lib64/systemd:ro \
        -v /lib64:/lib64:ro \
        -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
        loxo33/puppet-in-docker \
        agent --no-daemonize --logdest=console --server=puppetmaster.${dns_suffix} --environment=production",
    restartsec   => '5s',
    restart      => 'always',
  }
}
