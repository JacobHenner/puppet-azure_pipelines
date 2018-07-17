# vsts_agent

#### Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with vsts_agent](#setup)
    * [Setup requirements](#setup-requirements)
    * [Beginning with vsts_agent](#beginning-with-vsts_agent)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

This module manages the installation of agents for Microsoft's [Visual Studio Team Services (VSTS)](https://www.visualstudio.com/team-services/). Both standard agents and deployment group agents are supported. 

At this time, only agent installation is handled. Configuration changes (e.g. adding a deployment group tag, removing an agent) are not supported.

## Setup

### Setup Requirements

All dependencies for the VSTS agent must be installed prior to using this module.

On Windows, PowerShell >= 5 is required.

If you are unable to download packages from the internet (either directly or through a proxy), you will need a locally accessible copy of the agent.

### Beginning with vsts_agent

To install an instance of the VSTS agent with minimal configuration:

```puppet
vsts_agent::agent { 'testagent':
    install_path       => '/opt/vsts_agent/testagent',
    token              => 'pat-token',
    vsts_instance_name => 'instance-name',
    service_user       => 'vsts',
    service_group      => 'vsts',
    run_as_service     => true,
}
```

## Usage

An example of basic configuration is provided above. 

This module supports all of the parameters that can be passed to the VSTS agent's configuration script.

## Reference

Please see the parameter documentation in [agent.pp](manifests/agent.pp) or generate documentation using `puppet strings`.

## Limitations

This module has been tested on Windows Server 2016 and CentOS 7. It is not expected to work on Mac OS, or other systems.

This module does not yet support upgrading VSTS agents, or changing the configuration of existing VSTS agents.

On Windows, `install_path` must be specified using backslashes due to a limitation in the `dirtree` module.

There are currently no automated tests for this module.

## Development

Contributions are encouraged! Please open a pull request for all proposed changes.

