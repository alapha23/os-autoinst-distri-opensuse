# SUSE's SLES4SAP openQA tests
#
# Copyright © 2018 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Checks HANA installation as performed by sles4sap/wizard_hana_install
# Requires: sles4sap/wizard_hana_install, ENV variable SAPADM
# Maintainer: Ricardo Branco <rbranco@suse.de>

use base "sles4sap";
use testapi;
use strict;
use utils 'ensure_serialdev_permissions';

sub run {
    my ($self) = @_;
    my $ps_cmd = $self->set_ps_cmd('HDB');

    select_console 'root-console';

    # The SAP Admin was set in sles4sap/wizard_hana_install
    my ($sapadm, $sid) = $self->set_sap_info(get_required_var('SAPADM'));
    $self->become_sapadm;

    # Check HDB with a database query
    my $password = get_required_var('PASSWORD');
    my $output   = script_output "hdbsql -j -d $sid -u SYSTEM -n localhost:30015 -p $password 'SELECT * FROM DUMMY'";
    die "hdbsql: failed to query the dummy table\n\n$output" unless ($output =~ /1 row selected/);

    $self->test_version_info;
    $self->test_instance_properties;
    $self->test_stop;

    assert_script_run "$ps_cmd ; $ps_cmd | wc -l";
    save_screenshot;

    $self->test_start_service;
    $self->test_start_instance;

    assert_script_run "HDB info";

    # Rollback changes to $testapi::serialdev and close the window
    type_string "exit\n";
    ensure_serialdev_permissions;
}

1;
