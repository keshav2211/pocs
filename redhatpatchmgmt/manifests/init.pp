# Class: redhatpatchmgmt
# ===========================
#
# Module for checking available updates for packages.
#
# Parameters
# ----------
#
#  * reportpath
#
#  File system path where generated report should be place.
#  eg. '/var/local'
#
#  * reponame
#
#  Repository name for which updates are to be checked.
#  eg. 'epel'
#
#  * recipientmail
#
#  Comma separated list of mail ids who should recieve report on mail
#  eg. 'firstname.lastname@symantec.com, secondrecipient@symantec.com
#  
#  * option
#
#  Option or mode for the python script.
#  eg. 'reportonly' 
#
# Variables
# ----------
#
#
# Examples
# --------
#
# @example
#    class { 'redhatpatchmgmt':
#      reportpath => '/var/local',
#      reponame   => 'epel',
#      option     => 'installupdates',
#    }
#
# Authors
# -------
#
#
# Keshav Sharma <keshav_sharma@symantec.com>
# Copyright
# ---------
#
# Copyright 2016 Your name here, unless otherwise noted.
#
#

class redhatpatchmgmt (
  $reportpath    = hiera(redhatpatchmgmt::reportpath, '/var/local'),
  $reponame      = hiera(redhatpatchmgmt::reponame, 'ALL_REPO'),
  $recipientmail = hiera(redhatpatchmgmt::recipientmail),
  $option        = hiera(redhatpatchmgmt::option, 'reportonly' ),
) {

#Resource default
Exec {
  path    => ['/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/', '/usr/local/bin/'],
  timeout => 0,
}

#validate option
$valid_options = ['reportonly', 'refreshreport', 'installupdates']

if $option in $valid_options {
  if $option == 'reportonly' {
    $reportname = "${reportpath}/RedHat_Patch_Mgmt_Report_${hostname}.xlsx"
  }
  else {
    $reportname = "${reportpath}/NONEXISTINGFILE"
  }
}
else {
  fail("$option is an invalid option for class redhatpatchmgmt. Valid options are $valid_options ")
}

#install python modules and python files
include redhatpatchmgmt::setup

#form arguments for python script
$rhpm_args = "$option $reportpath $reponame"

exec { "Run_Patch_management_python_script":
  require => Class['redhatpatchmgmt::setup'],
  command => "rhpm.py ${rhpm_args}",
  notify  => Exec['mail_RedHat_patch_management_report'],
  creates => "$reportname"
  }

exec { 'mail_RedHat_patch_management_report':
  command     => "echo \"RedHat Patch Management class declared with option - $option.\nAttached xlsx report contains information about:\n  * List of packages installed(sheet - Installed Packages) on ${::hostname}. \n  * List of updates available from yum repository - ${reponame} (sheet - Available Updates). \n  * Status of installation of updates (sheet - Installation status).\" | mailx -r RedHat_Patch_Management@symantec.com -s \"RedHat Patch  Management Report for ${hostname}\" -a \"${reportpath}/RedHat_Patch_Mgmt_Report_${hostname}.xlsx\" \"${recipientmail}\"",
  refreshonly => true,
  }

if $option == 'installupdates' {
  exec { 'Mark_report_outdated':
    require => Exec['mail_RedHat_patch_management_report'],
    command => "mv ${reportpath}/RedHat_Patch_Mgmt_Report_${hostname}.xlsx ${reportpath}/RedHat_Patch_Mgmt_Report_${hostname}.xlsx.outdated",
    }
}

}

