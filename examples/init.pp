# The baseline for module testing used by Puppet Inc. is that each manifest
# should have a corresponding test manifest that declares that class or defined
# type.
#
# Tests are then run by using puppet apply --noop (to check for compilation
# errors and view a log of events) or by fully applying the test in a virtual
# environment (to compare the resulting system state to the desired state).
#
# Learn more about module testing here:
# https://docs.puppet.com/guides/tests_smoke.html

vsts_agent::agent { 'testagent':
    install_path       => '/opt/vsts_agent/testagent',
    token              => 'pat-token',
    vsts_instance_name => 'instance-name',
    service_user       => 'vsts',
    service_group      => 'vsts',
    run_as_service     => true,
}
