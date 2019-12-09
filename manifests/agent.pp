# @summary Installs the Azure Pipelines (VSTS, TFS) agent.
#
# @example
#  azure_pipelines::agent { 'testagent':
#      install_path         => '/opt/azure_pipelines/testagent',
#      token                => 'pat-token',
#      instance_name        => 'instance-name',
#      service_user         => 'vsts',
#      service_group        => 'vsts',
#      run_as_service       => true,
#      service_startup_type => 'true',
#  }
#
# @param install_path
#   The installation path for the agent. Must use escaped backslashes on Windows.
# @param service_user
#   The user that will own the $install_path directory, and run the agent service if $run_as_service is true.
# @param instance_name
#   The name of the Azure Pipelines or VSTS account.
# @param agent_name
#   Unique name to identify the agent
# @param package_src 
#   Source of the agent installation package. Supports all URIs supported by the archive module.
# @param package_sha512
#   SHA-512 hash of the installation package, for verification.
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
# @param vsts
#   If enabled, agent will connect to VSTS URLs instead of Azure Pipelines URLs.
#   This is generally only necessary if dev.azure.com URLs are blocked.
# @param instance_url
#   The URL for Azure Pipelines, VSTS, or TFS. If using Azure Pipelines or VSTS, setting $instance_name is sufficient.
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
# @param service_startup_type
#   Configure the startup type for the service (see https://puppet.com/docs/puppet/latest/types/service.html#service-attribute-enable)
# @param run_as_auto_logon
#   Configure auto logon and run the agent on startup.
# @param windows_logon_account
#   Specify the Windows user running the service, if different than $service_user.
# @param windows_logon_password
#   Specify the password for the Windows user running the agent service.
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
#   Destination filename for agent installation package. 
# @param config_script
#   Name of script file used to install the agent.
# @param manage_service
#   If enabled and $run_as_service is true, ensure agent is running.
# @param strict_windows_acl
#   If enabled, the Windows ACL for $install_path will not inherit parent permissions, and all unmanaged ACEs will be purged.
# @param windows_acl_owner
#   Owner for $install_path ACL.
# @param windows_acl_permissions
#   Sets the ACEs applied to the $install_path ACL on Windows. See the Puppet acl module fot details.
define azure_pipelines::agent (
    Stdlib::Absolutepath $install_path,
    String[1] $service_user,
    String[1] $instance_name,
    String[1] $agent_name = $title,
    String[1] $package_src = lookup('azure_pipelines::agent::package_src'),
    String[128,128] $package_sha512 = lookup('azure_pipelines::agent::package_sha512'),
    Optional[String[1]] $service_group = undef,
    Optional[Enum['http','https']] $proxy_proto = undef,
    Optional[Stdlib::Host] $proxy_host = undef,
    Optional[Stdlib::Port] $proxy_port = undef,
    Optional[String[1]] $proxy_user = undef,
    Optional[String[1]] $proxy_password = undef,
    Optional[Array[String[1]]] $proxy_bypass_hosts = undef,
    Boolean $vsts = false,
    Optional[Stdlib::HTTPUrl] $instance_url = undef,
    Enum['pat', 'negotiate','alt','integrated'] $auth_type = 'pat',
    Optional[String[1]] $token = undef,
    Optional[String[1]] $username = undef,
    Optional[String[1]] $password = undef,
    Optional[String[1]] $pool = 'Default',
    Boolean $replace = false,
    Optional[String[1]] $work = undef,
    Boolean $accept_tee_eula = false,
    Boolean $run_as_service = false,
    Optional[String[1]] $service_startup_type = 'automatic',
    Boolean $run_as_auto_logon = false,
    Optional[String[1]] $windows_logon_account = $service_user,
    Optional[String[1]] $windows_logon_password = undef,
    Boolean $overwrite_auto_logon = false,
    Boolean $no_restart = false,
    Boolean $deployment_group = false,
    Optional[String[1]] $project_name = undef,
    Optional[String[1]] $deployment_group_name = undef,
    Optional[Array[String[1],1]] $deployment_group_tags = undef,
    String[1] $archive_name = lookup('azure_pipelines::agent::archive_name'),
    String[1] $config_script = lookup('azure_pipelines::agent::config_script'),
    Boolean $manage_service = $run_as_service,
    Boolean $strict_windows_acl = false,
    String[1] $windows_acl_owner = 'Administrators',
    Array[Hash[String[1],Variant[String[1],Array[String[1]]]]] $windows_acl_permissions = [
        { identity => 'Administrator', rights => ['full'], perm_type=> 'allow', child_types => 'all', affects => 'all' },
        { identity => 'Administrators', rights => ['full'], perm_type=> 'allow', child_types => 'all', affects => 'all' },
        { identity => $service_user, rights => ['full'], perm_type=> 'allow', child_types => 'all', affects => 'all' },
    ],
) {
    if $instance_url == undef {
        if $vsts {
            $_instance_url = "https://${instance_name}.visualstudio.com"
        }
        else {
            $_instance_url = "https://dev.azure.com/${instance_name}/"
        }
    }
    else {
        $_instance_url = $instance_url
    }
    if $facts['kernel'] != 'Linux' and $facts['kernel'] != 'windows' and $facts['kernel'] != 'Darwin' {
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

    $dirtree = delete(dirtree($install_path),$install_path)
    ensure_resource('file', $dirtree, {'ensure' => 'directory'})

    $install_path_parent = $dirtree[-1]

    if $facts['kernel'] == 'windows' {

        if $run_as_service and $windows_logon_account and !$windows_logon_password {
            fail('windows_logon_password needs to be specified')
        }

        file {$install_path:
            ensure  => directory,
            require => File[$install_path_parent],
        }

        archive {"${install_path}/${archive_name}":
            ensure        => present,
            extract       => true,
            extract_path  => $install_path,
            source        => $package_src,
            checksum      => $package_sha512,
            checksum_type => 'sha512',
            creates       => "${install_path}/${config_script}",
            proxy_type    => $proxy_type,
            proxy_server  => $proxy_server,
            user          => $service_user,
            group         => $service_group,
            require       => File[$install_path],
        }

        acl {$install_path:
            permissions                => $windows_acl_permissions,
            owner                      => $windows_acl_owner,
            inherit_parent_permissions => !$strict_windows_acl,
            purge                      => $strict_windows_acl,
            require                    => Archive["${install_path}/${archive_name}"],
        }
    }
    else {
        file {$install_path:
            ensure  => directory,
            owner   => $service_user,
            group   => $service_group,
            mode    => '0750',
            require => File[$install_path_parent],
        }

        archive {"${install_path}/${archive_name}":
            ensure        => present,
            extract       => true,
            extract_path  => $install_path,
            source        => $package_src,
            checksum      => $package_sha512,
            checksum_type => 'sha512',
            creates       => "${install_path}/${config_script}",
            proxy_type    => $proxy_type,
            proxy_server  => $proxy_server,
            user          => $service_user,
            group         => $service_group,
            require       => File[$install_path],
        }
    }

    # The agent credential store is not supported due to security concerns
    # See https://github.com/Microsoft/vsts-agent/issues/1542 for additional info
    # Consider using cntlm on Linux (https://forge.puppet.com/jacobhenner/cntlm)

    if $proxy_host and $proxy_port and $proxy_proto {
        file {"${install_path}/.proxy":
            ensure  => present,
            content => "${proxy_proto}://${proxy_host}:${proxy_port}",
            require => File[$install_path],
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
            content => join($proxy_bypass_hosts, "\n"),
            require => File[$install_path],
        }
    }
    else {
        file {"${install_path}/.proxybypass":
            ensure => absent,
        }
    }

    $token_opts = $token ? {
        undef   => undef,
        default => "--token \"${token}\"",
    }
    $username_opts = $username ? {
        undef   => undef,
        default => "--username \"${username}\""
    }
    $password_opts = $password ? {
        undef   => undef,
        default => "--password \"${password}\""
    }
    $pool_opts = $pool ? {
        undef   => undef,
        default => "--pool \"${pool}\""
    }
    $replace_opts = $replace ? {
        true     => '--replace',
        default  => undef,
    }
    $agent_name_opts = $agent_name ? {
        undef   => undef,
        default => "--agent \"${agent_name}\"",
    }
    $work_opts = $work ? {
        undef   => undef,
        default => "--work \"${work}\"",
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
        default => "--windowsLogonAccount \"${windows_logon_account}\"",
    }
    $windows_logon_password_opts = $windows_logon_password ? {
        undef   => undef,
        default => "--windowsLogonPassword \"${windows_logon_password}\"",
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
        default => "--projectName \"${project_name}\"",
    }
    $deployment_group_name_opts = $deployment_group_name ? {
        undef   => undef,
        default => "--deploymentGroupName \"${deployment_group_name}\"",
    }
    if $deployment_group_tags {
        $deployment_group_tags_joined = join($deployment_group_tags,',')
    }
    $deployment_group_tags_opts = $deployment_group_tags ? {
        undef   => undef,
        default => "--addDeploymentGroupTags --deploymentGroupTags \"${deployment_group_tags_joined}\"",
    }

    $opts = "${token_opts} ${username_opts} ${password_opts} ${pool_opts} ${replace_opts} ${agent_name_opts} ${work_opts} ${accept_tee_eula_opts} ${run_as_service_opts} ${run_as_auto_logon_opts} ${windows_logon_account_opts} ${windows_logon_password_opts} ${overwrite_auto_logon_opts} ${no_restart_opts} ${deployment_group_opts} ${project_name_opts} ${deployment_group_name_opts} ${deployment_group_tags_opts}"

    if $facts['kernel'] == 'windows' {
        exec {"${install_path}/${config_script}":
            command => Sensitive.new("${install_path}/${config_script} --unattended --url ${_instance_url} --auth ${auth_type} ${opts}"),
            creates => "${install_path}/.credentials",
            require => Archive["${install_path}/${archive_name}"],
        }
        # If this fails, it's likely that the initial installation failed
        if $manage_service {
            service {"vstsagent.${instance_name}.${agent_name}":
                ensure  => 'running',
                enable  => $service_startup_type,
                require => Exec["${install_path}/${config_script}"],
            }
        }
    }
    else {
        exec {"${install_path}/${config_script}":
            command => Sensitive.new("${install_path}/${config_script} --unattended --url ${_instance_url} --auth ${auth_type} ${opts}"),
            creates => "${install_path}/.credentials",
            user    => $service_user,
            require => Archive["${install_path}/${archive_name}"],
        }
        if $facts['kernel'] == 'Linux' and $run_as_service {
            exec {"${install_path}/svc.sh install ${service_user}":
                creates => "/etc/systemd/system/vsts.agent.${instance_name}.${agent_name}.service",
                user    => 'root',
                cwd     => $install_path,
                require => Exec["${install_path}/${config_script}"],
            }
            if $manage_service {
                service {"vsts.agent.${instance_name}.${agent_name}.service":
                    ensure  => 'running',
                    enable  => $service_startup_type,
                    require => Exec["${install_path}/svc.sh install ${service_user}"],
                }
            }
        }
        if $facts['kernel'] == 'Darwin' and $run_as_service {
            file { "/Users/${service_user}/Library/LaunchAgents" :
                ensure => directory,
                owner  => $service_user,
            }
            exec {"${install_path}/svc.sh install":
                environment => ["HOME=/Users/${service_user}"],
                creates     => "${install_path}/.service",
                user        => $service_user,
                cwd         => $install_path,
                require     => [Exec["${install_path}/${config_script}"], File["/Users/${service_user}/Library/LaunchAgents"]],
            }
            if $manage_service {
                exec { "Service: vsts.agent.${instance_name}.${agent_name}.plist" :
                    command => "/bin/launchctl bootstrap gui/`id -u ${service_user}` /Users/${service_user}/Library/LaunchAgents/vsts.agent.${instance_name}.${agent_name}.plist",
                    unless  => "/bin/launchctl print gui/`id -u ${service_user}`/vsts.agent.${instance_name}.${agent_name}",
                    require => Exec["${install_path}/svc.sh install"]
                }
            }
        }
    }
}
