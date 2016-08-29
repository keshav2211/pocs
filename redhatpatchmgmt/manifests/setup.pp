class redhatpatchmgmt::setup (
  $prefix = '/usr/local/bin',
  $owner  = 'root',
  $group  = 'root',
  $mode   = '0755',
) {

file { $redhatpatchmgmt::reportpath:
  ensure  => directory,
  }

file { "${prefix}/rhpm.py":
  owner  => $owner,
  group  => $group,
  mode   => $mode,
  source => 'puppet:///modules/redhatpatchmgmt/rhpm.py',
  }

class { 'python':
  version => 'system',
  pip     => 'present',
  }

python::pip { 'XlsxWriter':
  pkgname => 'XlsxWriter',
  ensure  => 'present',
  }

python::pip { 'pyyaml':
  pkgname => 'pyyaml',
  ensure  => 'present',
  }
}

