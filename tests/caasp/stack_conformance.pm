# SUSE's openQA tests
#
# Copyright © 2018 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Run CNCF K8s Conformance tests
#   Maintain certified status of CaaSP under k8s certification
#   Project: https://github.com/cncf/k8s-conformance
# Maintainer: Martin Kravec <mkravec@suse.com>, George Gkioulis <ggkioulis@suse.com>

use parent 'caasp_controller';
use caasp_controller;

use strict;
use utils;
use testapi;
use caasp 'script_retry';
use version_utils 'is_caasp';

my $config_json = <<'EOF';
{
  "plugins": [ { "name": "e2e" } ]
}
EOF

sub run {
    # The repository for the sonobuoy package
    my $repo = "https://download.opensuse.org/repositories/devel:/kubic/openSUSE_Tumbleweed/devel:kubic.repo";

    my $json_name = "sonobuoy.json";
    my $logs_dir  = "sonobuoy_logs";

    my $sb_pass = '"SUCCESS! -- [1-9][0-9]\+ Passed | 0 Failed | 0 Pending.*PASS"';
    my $sb_test = '"Test Suite Passed"';

    switch_to 'xterm';
    become_root;

    # Add the repo
    zypper_call " ar -Gf $repo";

    # Install the sonobuoy package on the controller node
    zypper_call "-n in sonobuoy";

    type_string "exit\n";

    # Create config file
    assert_script_run "echo '$config_json' >> $json_name";

    # Run the testsuite
    assert_script_run("sonobuoy run --config $json_name");

    # Check every 60 seconds that the testsuite has finished running
    # Times out after 90 checks.
    script_retry "sonobuoy status| grep complete", retry => 90, delay => 60;

    assert_script_run("sonobuoy retrieve $logs_dir");
    assert_script_run("cd $logs_dir");
    assert_script_run("tar xzf *.tar.gz");

    # Expect: SUCCESS! -- 123 Passed | 0 Failed | 0 Pending | 586 Skipped PASS
    upload_logs 'plugins/e2e/results/e2e.log';
    assert_script_run "tail -10 plugins/e2e/results/e2e.log | tee /dev/tty | grep $sb_pass";
    assert_script_run "tail -10 plugins/e2e/results/e2e.log | grep $sb_test";

    switch_to 'velum';
}

1;

