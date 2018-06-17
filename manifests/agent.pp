# @summary Installs the Microsoft Visual Studio Team Services (VSTS) agent.
#
# @example
#  vsts_agent::agent { 'testagent':
#      install_path       => '/opt/vsts_agent/testagent',
#      token              => 'pat-token',
#      vsts_instance_name => 'instance-name',
#      service_user       => 'vsts',
#      service_group      => 'vsts',
#      run_as_service     => true,
#  }
#
# @param install_path
#   The installation path for the VSTS agent. 
# @param service_user
#   The user that will own the $install_path directory, and run the VSTS service if $run_as_service is true.
# @param vsts_instance_name
#   The name of the VSTS account.
# @param agent_name
#   Unique name to identify the VSTS agent
# @param package_src 
#   Source of the VSTS installation package. Supports all URIs supported by the archive module.
# @param package_sha512
#   SHA-512 hash of the VSTS installation package, for verification.
# @param service_group
#   The group that will own the $install_path directory.
# @param proxy_proto
#   The protocol (http, https) to use for a proxy, if needed.
# @param proxy_host
#   The hostname for a proxy, if needed.
# @param proxy_port
#   The port for a proxy, if needed.
# @param proxy_user
#   The username for a proxy, if needed.
# @param proxy_password
#   The password for a proxy, if needed.
# @param proxy_bypass_hosts
#   Hostname regexes to bypass proxy.
# @param vsts_url
#   The URL for VSTS or TFS. If using VSTS, setting $vsts_instance_name is sufficient.
# @param auth_type
#   The auth type to use.
# @param token
#   The access token to use if $auth_type is 'pat'.
# @param username
#   The Windows username to use if $auth_type is 'negotiate' or 'alt'.
# @param password
#   The Windows password to use if $auth_type is 'negotiate' or 'alt'.
# @param pool
#   The pool for the agent to join.
# @param replace
#   Replace the agent in a pool.
# @param work
#   Work directory where job data is stored. Should not be shared between agents.
# @param accept_tee_eula
#   Accept the TEE end user license agreement.
# @param run_as_service
#   Configure the agent to run as a service.
# @param run_as_auto_logon
#   Configure auto logon and run the agent on startup.
# @param windows_logon_account
#   Specify the Windows user running the service, if different than $service_user.
# @param windows_logon_password
#   Specify the password for the Windows user running the VSTS service.
# @param overwrite_auto_logon
#   Overwrite any existing auto logon on the machine.
# @param no_restart
#   Do not restart after configuration completes.
# @param deployment_group
#   Configure the agent as a deployment group agent. $project_name and $deployment_group_name must also be set.
# @param project_name
#   Team project name for deployment group.
# @param deployment_group_name
#   Deployment group name.
# @param deployment_group_tags
#   Tags for a deployment group agent.
# @param archive_name
#   Destination filename for VSTS installation package. 
# @param config_script
#   Name of script file used to install the VSTS agent.
# @param manage_service
#   If enabled and $run_as_service is true, ensure VSTS agent is running.
define vsts_agent::agent (
    Stdlib::Absolutepath $install_path,
    String[1] $service_user,
    String[1] $vsts_instance_name,
    String[1] $agent_name = $title,
    String[1] $package_src = lookup('vsts_agent::agent::package_src'),
    String[128,128] $package_sha512 = lookup('vsts_agent::agent::package_sha512'),
    Optional[String[1]] $service_group = undef,
    Optional[Enum['http','https']] $proxy_proto = undef,
    Optional[Stdlib::Host] $proxy_host = undef,
    Optional[Stdlib::Port] $proxy_port = undef,
    Optional[String[1]] $proxy_user = undef,
    Optional[String[1]] $proxy_password = undef,
    Optional[Array[String[1]]] $proxy_bypass_hosts = undef,
    Stdlib::HTTPUrl $vsts_url = "https://${vsts_instance_name}.visualstudio.com",
    Enum['pat', 'negotiate','alt','integrated'] $auth_type = 'pat',
    Optional[String[1]] $token = undef,
    Optional[String[1]] $username = undef,
    Optional[String[1]] $password = undef,
    Optional[String[1]] $pool = 'Default',
    Boolean $replace = false,
    Optional[String[1]] $work = undef,
    Boolean $accept_tee_eula = false,
    Boolean $run_as_service = false,
    Boolean $run_as_auto_logon = false,
    Optional[String[1]] $windows_logon_account = $service_user,
    Optional[String[1]] $windows_logon_password = undef,
    Boolean $overwrite_auto_logon = false,
    Boolean $no_restart = false,
    Boolean $deployment_group = false,
    Optional[String[1]] $project_name = undef,
    Optional[String[1]] $deployment_group_name = undef,
    Optional[Array[String[1],1]] $deployment_group_tags = undef,
    String[1] $archive_name = lookup('vsts_agent::agent::archive_name'),
    String[1] $config_script = lookup('vsts_agent::agent::config_script'),
    Boolean $manage_service = $run_as_service,
) {
    if $facts['kernel'] != 'Linux' and $facts['os']['family'] != 'windows' {
        fail('Unsupported operating system')
    }
    if $deployment_group and !($deployment_group_name and $project_name){
        fail('Deployment group name and project name must be set if deployment group mode is enabled')
    }

    $proxy_server = $proxy_host ? {
        undef   => undef,
        default => "${proxy_proto}://${proxy_user}:${proxy_password}@${proxy_host}:${proxy_port}"
    }
    $proxy_type = $proxy_proto ? {
        undef   => 'none',
        default => $proxy_proto,
    }

    if $facts['os']['family'] == 'windows' {
        if $run_as_service and $windows_logon_account and !$windows_logon_password {
            fail('windows_login_password needs to be specified')
        }
        # Requires PowerShell >= 4 (alternative to depending on 7z)
        archive {"${install_path}/${archive_name}":
            ensure          => present,
            extract         => true,
            extract_path    => $install_path,
            extract_command => "PowerShell -Command \"Expand-Archive -Path %s -DestinationPath ${install_path}\"",
            source          => $package_src,
            creates         => "${install_path}/${config_script}",
            proxy_type      => $proxy_type,
            proxy_server    => $proxy_server,
            user            => $service_user,
            group           => $service_group,
        }
    }
    else {
        archive {"${install_path}/${archive_name}":
            ensure       => present,
            extract      => true,
            extract_path => $install_path,
            source       => $package_src,
            creates      => "${install_path}/${config_script}",
            proxy_type   => $proxy_type,
            proxy_server => $proxy_server,
            user         => $service_user,
            group        => $service_group,
        }
    }

    file {$install_path:
        ensure  => directory,
        recurse => true,
        owner   => $service_user,
    }

    # The VSTS credential store is not supported due to security concerns
    # See https://github.com/Microsoft/vsts-agent/issues/1542 for additional info
    # Consider using cntlm on Linux (https://forge.puppet.com/jacobhenner/cntlm)

    if $proxy_host and $proxy_port and $proxy_proto {
        file {"${install_path}/.proxy":
            ensure  => present,
            content => "${proxy_proto}://${proxy_host}:${proxy_port}",
        }
    }
    else {
        file {"${install_path}/.proxy":
            ensure => absent,
        }
    }

    if $proxy_bypass_hosts {
        file {"${install_path}/.proxybypass":
            ensure  => present,
            content => join($proxy_bypass_hosts, "\n")
        }
    }
    else {
        file {"${install_path}/.proxybypass":
            ensure => absent,
        }
    }

    $token_opts = $token ? {
        undef   => undef,
        default => "--token ${token}",
    }
    $username_opts = $username ? {
        undef   => undef,
        default => "--username ${username}"
    }
    $password_opts = $password ? {
        undef   => undef,
        default => "--password ${password}"
    }
    $pool_opts = $pool ? {
        undef   => undef,
        default => "--pool ${pool}"
    }
    $replace_opts = $replace ? {
        true     => '--replace',
        default  => undef,
    }
    $agent_name_opts = $agent_name ? {
        undef   => undef,
        default => "--agent ${agent_name}",
    }
    $work_opts = $work ? {
        undef   => undef,
        default => "--work ${work}",
    }
    $accept_tee_eula_opts = $accept_tee_eula ? {
        true    => '--acceptTeeEula',
        default => undef,
    }
    $run_as_service_opts = $run_as_service ? {
        true    => '--runAsService',
        default => undef,
    }
    $run_as_auto_logon_opts = $run_as_auto_logon ? {
        true    => '--runAsAutoLogon',
        default => undef,
    }
    $windows_logon_account_opts = $windows_logon_account ? {
        undef   => undef,
        default => "--windowsLogonAccount ${windows_logon_account}",
    }
    $windows_logon_password_opts = $windows_logon_password ? {
        undef   => undef,
        default => "--windowsLogonPassword ${windows_logon_password}",
    }
    $overwrite_auto_logon_opts = $overwrite_auto_logon ? {
        true    => '--overwriteAutoLogon',
        default => undef,
    }
    $no_restart_opts = $no_restart ? {
        true    => '--noRestart',
        default => undef,
    }
    $deployment_group_opts = $deployment_group ? {
        true    => '--deploymentGroup',
        default => undef,
    }
    $project_name_opts = $project_name ? {
        undef   => undef,
        default => "--projectName ${project_name}",
    }
    $deployment_group_name_opts = $deployment_group_name ? {
        undef   => undef,
        default => "--deploymentGroupName ${deployment_group_name}",
    }
    if $deployment_group_tags {
        $deployment_group_tags_joined = join($deployment_group_tags,',')
    }
    $deployment_group_tags_opts = $deployment_group_tags ? {
        undef   => undef,
        default => "--addDeploymentGroupTags --deploymentGroupTags ${deployment_group_tags_joined}",
    }

    $opts = "${token_opts} ${username_opts} ${password_opts} ${pool_opts} ${replace_opts} ${agent_name_opts} ${work_opts} ${accept_tee_eula_opts} ${run_as_service_opts} ${run_as_auto_logon_opts} ${windows_logon_account_opts} ${windows_logon_password_opts} ${overwrite_auto_logon_opts} ${no_restart_opts} ${deployment_group_opts} ${project_name_opts} ${deployment_group_name_opts} ${deployment_group_tags_opts}"

    if $facts['os']['family'] == 'windows' {
        exec {"${install_path}/${config_script} --unattended --url ${vsts_url} --auth ${auth_type} ${opts}":
            creates => "${install_path}/.credentials",
        }
        # If this fails, it's likely that the initial installation failed
        if $manage_service {
            service {"vstsagent.${vsts_instance_name}.${agent_name}":
                ensure => 'running',
            }
        }
    }
    else {
        exec {"${install_path}/${config_script} --unattended --url ${vsts_url} --auth ${auth_type} ${opts}":
            creates => "${install_path}/.credentials",
            user    => $service_user,
        }
        if $facts['kernel'] == 'Linux' and $run_as_service {
            exec {"${install_path}/svc.sh install ${service_user}":
                creates => "/etc/systemd/system/vsts.agent.${vsts_instance_name}.${agent_name}.service",
                user    => 'root',
                cwd     => $install_path,
            }
            if $manage_service {
                service {"vsts.agent.${vsts_instance_name}.${agent_name}.service":
                    ensure => 'running',
                }
            }
        }
    }
}
