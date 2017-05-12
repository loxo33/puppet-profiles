# Install Kubernetes etcd backend
class profiles::etcd_server(
$dns_suffix   = hiera(dns_suffix),
$etcd_version = hiera(etcd_version),
$container_registry = hiera(container_registry),
$etcd_peers_container = hiera(etcd_peers_container),
) {
  coreos::unit {'etcd3':
    description  => 'etcd3',
    after        => 'etcd-peers.service',
    requires     => 'etcd-peers.service',
    execstartpre => "/usr/bin/docker pull quay.io/coreos/etcd:${etcd_version}",
    execstart    => "/usr/bin/docker run --name etcd3 \
                    -v /var/lib/etcd3:/var/lib/etcd3 \
                    -p 2379:2379 -p 2380:2380 \
                    --env-file /etc/sysconfig/etcd-peers \
                    --env-file /etc/sysconfig/etcd-vars \
                    quay.io/coreos/etcd:${etcd_version}",
    restartsec   => '5',
    restart      => 'always',
  }
  coreos::unit {'debug-etcd':
    description  => 'etcd debugging service',
    execstartpre => '/usr/bin/curl -sSL -o /opt/bin/jq http://stedolan.github.io/jq/download/linux64/jq && /usr/bin/chmod +x /opt/bin/jq',
    execstart    => '/usr/bin/bash -c "while true; do curl -sL http://127.0.0.1:4001/v2/stats/self | /opt/bin/jq . ; sleep 1 ; done"',
  }
  coreos::unit {'etcd-peers':
    description  => 'track etcd peer nodes',
    after        => 'docker.service',
    requires     => 'docker.service',
    execstartpre => "/usr/bin/docker pull ${container_registry}/${etcd_peers_container}",
    execstart    => "/usr/bin/docker run --rm=true -v /etc/sysconfig/:/etc/sysconfig/ ${container_registry}/${etcd_peers_container}",
    restartsec   => '10',
    restart      => 'on-failure',
  }

  file {'/etc/sysconfig':
    ensure  => directory,
    owner   => 0,
    group   => 0,
    mode    => '0755',
  }
  file {'/etc/sysconfig/environment':
    ensure  => file,
    owner   => 0,
    group   => 0,
    mode    => '0644',
    content => template('profiles/etc-environment.erb'),
    require => File['/etc/sysconfig'],
  }
  file {'/etc/sysconfig/etcd-vars':
    ensure  => file,
    owner   => 0,
    group   => 0,
    mode    => '0644',
    content => template('profiles/etcd-vars.erb'),
    require => File['/etc/sysconfig'],
  }
}
