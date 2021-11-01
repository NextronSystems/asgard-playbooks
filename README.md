# Sysmon Maintenance Playbooks and Scripts for ASGARD

## Playbook Creation
Before you create the custom playbooks, you need to put some files into the `/var/lib/nextron/asgard2/playbook-files` directory:

1. A current version of [Sysmon.zip](https://download.sysinternals.com/files/Sysmon.zip)
2. Your Sysmon config called `sysmonconfig.xml`
3. The playbook Powershell scripts from this repo's `playbook-files`

You can either do that beforehand using scp, rsync, WinSCP or whatever tool you use for Linux file transfer. Do not forget to change the file ownership to **asgard2:asgard2**
(e.g. `chown asgard2: /var/lib/nextron/asgard2/playbook-files/[Ss]ysmon*`).

Or you can use the file upload feature during playbook creation:
![01.png](img/01.png)

### Choosing a Sysmon configuration
If you do not have a Sysmon configuration yet, there are several options we suggest:

1. The Nextron Systems fork of SwiftOnSecurity's [sysmon-config](https://github.com/Neo23x0/sysmon-config)
2. The SwiftOnSecurity [sysmon-config](https://github.com/SwiftOnSecurity/sysmon-config)
3. Olaf Hartong's [sysmon-modular](https://github.com/olafhartong/sysmon-modular)

In general we suggest our own config, as we test our rules with it and include changes from the upstream configuration. But depending on your preferences, either of those listed configurations are good starting points for writing your own config.

NOTE: Test your configuration and configuration changes before rolling them out to a greater number of systems. Every environment is unique.

### How to Create a Playbook
*This section explains how to create a playbook for the Sysmon installation in detail. If you are familiar with ASGARD's playbook creation, see the overview of the Sysmon playbooks in the next 3 sections.*

Go to **Response Control > Playbooks > Add Playbook**, enter
* Name: Sysmon Install
* Description: Installs Sysmon with the current configuration to the selected asset(s).

and click **Add Playbook**.
![02.png](img/02.png)

Next add the single playbook steps. Therefore click anywhere on the newly created playbook to open its drop-down menu and then choose **Add Step** for each of the following Steps:
![03.png](img/03.png)
1. Fetch Sysmon.zip from ASGARD and unzip it
![04.png](img/04.png)
	- Check the Unzip box
2. Fetch sysmonconfig.xml from ASGARD
![05.png](img/05.png)
	- The name  `sysmonconfig.xml` is used in the installer script
3. Fetch Sysmon Install Script from ASGARD
![06.png](img/06.png)
4. Execute Sysmon Install Script
![07.png](img/07.png)
	- Commands: `powershell -exec bypass .\sysmon-install.ps1`




### Sysmon Install Playbook
![08.png](img/08.png)
Text for Copy-Paste:
* Name: Sysmon Install
* Description: Installs Sysmon with the current configuration to the selected asset(s).
* Step 1:
	* Name: Fetch Sysmon.zip from ASGARD and unzip it
* Step 2:
	* Name: Fetch sysmonconfig.xml from ASGARD
* Step 3:
	* Name: Fetch Sysmon Install Script from ASGARD
* Step 4:
	* Name: Execute Sysmon Install Script
	* Commands: `powershell -exec bypass .\sysmon-install.ps1`


### Sysmon Config Update Playbook
![09.png](img/09.img)
Text for Copy-Paste:
* Name: Sysmon Configuration Update
* Description: Updates the Sysmon configuration on the selected asset(s).
* Step 1:
	* Name: Fetch sysmonconfig.xml from ASGARD
* Step 2:
	* Name: Fetch Sysmon Update Script from ASGARD
* Step 3:
	* Name: Execute Sysmon Update Script
	* Commands: `powershell -exec bypass .\sysmon-configupdate.ps1`


### Sysmon Uninstall Playbook
![10.png](img/10.png)
Text for Copy-Paste:
* Name: Sysmon Uninstall
* Description: Uninstalls Sysmon from the selected asset(s).
* Step 1:
	* Name: Fetch Sysmon Uninstall Script from ASGARD
* Step 2:
	* Name: Execute Sysmon Uninstall Script
	* Commands: `powershell -exec bypass .\sysmon-uninstall.ps1`

### Using multiple Sysmon configurations
If you use more than one sysmon config, you can upload your configurations to ASGARD under different names and using an additional Sysmon Config Update Playbook. You can give an additional parameter to the Sysmon update or install  script to use a different configuration. An example for updating the Sysmon config for domain controllers is given below:
![11.png](img/11.png)
Text for Copy-Paste:
* Name: Sysmon Config Update for DCs
* Description: Updates the Sysmon configuration on the selected asset(s) to use the sysmonconfig-dcs.xml configuration file.
* Step 1:
	* Name: Fetch sysmonconfig-dcs.xml from ASGARD
* Step 2:
	* Name: Fetch Sysmon Update Script from ASGARD
* Step 3:
	* Name: Execute Sysmon Update Script
	* Commands: `powershell -exec bypass .\sysmon-configupdate.ps1 sysmonconfig-dcs.xml`

