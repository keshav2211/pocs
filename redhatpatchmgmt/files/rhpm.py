#!/usr/bin/python

# THIS FILE IS MANAGED BY PUPPET - DO NOT MANUALLY EDIT

import sys
import socket
import yum
import xlsxwriter
import yaml

# Validate inputs
if len(sys.argv) > 4:
    print "Syntax Error: Maximum three arguments allowed \n " + sys.argv[0] + "[option] [path of reportfile] [yumreponame]"
    sys.exit(1)

# Set variables 
option = sys.argv[1] if len(sys.argv) > 1 else 'reportonly'
workbookpath = sys.argv[2] if len(sys.argv) > 2 else '/var/local'
repofilter = sys.argv[3] if len(sys.argv) > 3 else 'ALL_REPO'

# Set Workbook
workbookName = workbookpath + "/RedHat_Patch_Mgmt_Report_" + socket.gethostname() + ".xlsx"
workbook = xlsxwriter.Workbook(workbookName)

formatHeader = workbook.add_format({'italic': True, 'bg_color': 'black', 'font_color': 'white', 'font_size': 10})
formatData = workbook.add_format({'border': 1})
formatUpdates = workbook.add_format({'border': 1, 'bold': True, 'font_color': 'blue'})

worksheet1 = workbook.add_worksheet('Installed Packages')
worksheet1.set_column(0, 2, 30)
worksheet1.set_column(1, 1, 10)
worksheet1.set_column(3, 3, 55)
worksheet1.write_row(0, 0, [ 'Name', 'Arch', 'Version', 'Repository' ], formatHeader)
row1 = 1

worksheet2 = workbook.add_worksheet('Available Updates')
worksheet2.set_column(0, 3, 30)
worksheet2.set_column(1, 1, 10)
worksheet2.set_column(4, 4, 55)
worksheet2.write_row(0, 0, [ 'Name', 'Arch', 'Installed Version', 'Available Version', 'Repository' ], formatHeader)
row2 = 1

worksheet3 = workbook.add_worksheet('Installation Status')
worksheet3.set_column(0, 0, 30)
worksheet3.set_column(1, 1, 50)
worksheet3.set_column(2, 2, 12)
worksheet3.write_row(0, 0, [ 'Name', 'name-epoch:version-release.architecture', 'Status' ], formatHeader)

# Declare datastructures
repoInstalledPackages={}
availableUpdates={}
pkgsToBeUpdated=[]

# Initialize yum
yb=yum.YumBase()
yb.conf.assumeyes = True

# Get list of installed packages
installedPackages=yb.rpmdb.returnPackages()

# Get list of available updates
avblPckgs = yb.doPackageLists('updates')
availablePackages = [ apkg for apkg in avblPckgs ]

# Write installed packages worksheet and fiter repo 
for pkg in installedPackages:
    worksheet1.write_row(row1, 0, [ pkg.name, pkg.arch, pkg.version + '-' + pkg.release, pkg.ui_from_repo ], formatData)
    row1+=1
    if repofilter == 'ALL_REPO':
       repoInstalledPackages[pkg.name+pkg.arch]=pkg.version + '-' + pkg.release
    else:
       if pkg.ui_from_repo == "@" + repofilter:
          repoInstalledPackages[pkg.name+pkg.arch]=pkg.version + '-' + pkg.release

# Write availabe updates worksheet and set data structures
for pkg in availablePackages:
    if (pkg.name + pkg.arch) in repoInstalledPackages.keys():
      worksheet2.write_row(row2, 0, [ pkg.name, pkg.arch, repoInstalledPackages[pkg.name+pkg.arch], pkg.version +'-'+ pkg.release, pkg.ui_from_repo ], formatData)
      row2+=1
      availableUpdates[pkg.name]= pkg.ui_nevra
      pkgsToBeUpdated.append(pkg)

worksheet2.conditional_format(1,3,row2+1,3, {'type':   'no_blanks',
                                            'format': formatUpdates})
# write available updates to yaml to be used for custom fact
with open('/var/local/data.yaml', 'w') as outfile:
    outfile.write( yaml.dump(availableUpdates, default_flow_style=True) )

# Definition for installing updates
def installupdates():
  row=1
  for pkg in pkgsToBeUpdated:
    yb.update(pkg)
    yb.resolveDeps()
    worksheet3.write_row(row, 0, [ pkg.name, pkg.ui_nevra, 'UPDATED' ], formatData)
    row+=1
  yb.buildTransaction()
  yb.processTransaction()

# Call installupdates function according to input option
if option == 'installupdates':
  installupdates()

# Close workbook
workbook.close()

