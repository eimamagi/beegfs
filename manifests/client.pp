#
# = Class: beegfs::client
#
# This module manages BeeGFS client. 
# Mountpoints are defined with beegfs::mount resource.
#

class beegfs::client (
  $version           = $beegfs::version,
  $kernel_module     = "puppet:///modules/beegfs/${::kernelrelease}/${::beegfsversion}/${rdma_path}/beegfs.ko",
  $beegfs_mount_hash, 
) inherits beegfs {
  package { 'beegfs-helperd':
    ensure   => $version,
  }

  package { 'beegfs-client':
    ensure   => $version,
  }

  service { 'beegfs-helperd':
    ensure   => running,
    enable   => true,
    provider => redhat,
    require  => Package['beegfs-helperd'],
  }

  service { 'beegfs-client':
    ensure   => running,
    enable   => true,
    provider => redhat,
    require  => [ Package['beegfs-client'], Service['beegfs-helperd'],
File['/var/lib/beegfs/client/force-auto-build'],
File["/lib/modules/${::kernelrelease}/updates/fs/beegfs_autobuild/beegfs.ko"],
Exec['load_module'], File['/etc/beegfs/beegfs-mounts.conf'], ],
  }

  file { '/var/lib/beegfs/client/force-auto-build':
    ensure  => absent,
  }

  file { [ "/lib/modules/${::kernelrelease}/updates/fs", "/lib/modules/${::kernelrelease}/updates/fs/beegfs_autobuild" ]:
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
  }

  file { "/lib/modules/${::kernelrelease}/updates/fs/beegfs_autobuild/beegfs.ko":
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    source  => $kernel_module,
    require => [ File["/lib/modules/${::kernelrelease}/updates/fs/beegfs_autobuild"] ],
  }

  exec { 'load_module':
    command => "/sbin/depmod -a && touch /etc/beegfs/depmod_${::kernelrelease}_${::beegfsversion}",
    path    => ['/sbin', '/bin', '/usr/sbin', '/usr/bin'],
    creates => "/etc/beegfs/depmod_${::kernelrelease}_${::beegfsversion}",
    require => [ File["/lib/modules/${::kernelrelease}/updates/fs/beegfs_autobuild/beegfs.ko"] ],
  }

  if $beegfs_mount_hash {
    create_resources('beegfs::mount', $beegfs_mount_hash)

    file { '/etc/beegfs/beegfs-mounts.conf':
      ensure  => present,
      owner   => root,
      group   => root,
      mode    => '0644',
      content => template('beegfs/beegfs-mounts.conf.erb'),
      require => [ Package['beegfs-client'] ],
    }
  } else {
    file { '/etc/beegfs/beegfs-mounts.conf':
      ensure  => present,
      owner   => root,
      group   => root,
      mode    => '0644',
      source  => 'puppet:///modules/beegfs/beegfs-mounts.conf',
      require => [ Package['beegfs-client'] ],
    }
  }
}	