# azure_pipelines

#### Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with azure_pipelines](#setup)
    * [Setup requirements](#setup-requirements)
    * [Beginning with azure_pipelines](#beginning-with-azure_pipelines)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

This module manages the installation of agents for Microsoft's [Azure Pipelines](https://azure.microsoft.com/en-us/services/devops/pipelines/), previously called [Visual Studio Team Services (VSTS)](https://www.visualstudio.com/team-services/). Both standard agents and deployment group agents are supported.

At this time, only agent installation is handled. Configuration changes (e.g. adding a deployment group tag, removing an agent) are not supported.

This module was previously called vsts_agent, prior to the 1.0.0 release.

## Setup

### Setup Requirements

All dependencies for the agent must be installed prior to using this module.

On Windows, the System.IO.Compression.FileSystem .NET assembly must be available.

If you are unable to download packages from the internet (either directly or through a proxy), you will need a locally accessible copy of the agent.

### Beginning with azure_pipelines

To install an instance of the agent with minimal configuration:

```puppet
azure_pipelines::agent { 'testagent':
    install_path   => '/opt/azure_pipelines/testagent',
    token          => 'pat-token',
    instance_name  => 'instance-name',
    service_user   => 'vsts',
    service_group  => 'vsts',
    run_as_service => true,
}
```
To force *.visualstudio.com URLs (if dev.azure.com URLs are blocked):

```puppet
azure_pipelines::agent { 'testagent':
    install_path   => '/opt/vsts/testagent',
    token          => 'pat-token',
    instance_name  => 'instance-name',
    service_user   => 'vsts',
    service_group  => 'vsts',
    run_as_service => true,
    vsts           => true,
}
```

## Usage

An example of basic configuration is provided above. 

This module supports all of the parameters that can be passed to the VSTS agent's configuration script.

## Reference

Please see the parameter documentation in [agent.pp](manifests/agent.pp) or generate documentation using `puppet strings`.

## Limitations

This module has only been tested on Windows Server 2016, CentOS 7, and macOS Sierra.

This module does not yet support upgrading agents, or changing the configuration of existing agents.

On Windows, `install_path` must be specified using backslashes due to a limitation in the `dirtree` module.

There are currently no automated tests for this module.

## Development

Contributions are encouraged! Please open a pull request for all proposed changes.

