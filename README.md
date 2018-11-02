## Powershell scripts

Collection of useful powershell scripts 


# Backup
Backup scripts to backup virtual machines, incl. 

- time series backup 
- monitoring via email
- scheduling via task jobs

Possible params: 
- VMs [array of VM names]
- flagAllVms [Boolean to execute backup for all VMs]
- flagIsTest [Execute job as a dry run]
- flagCoreVMs [in the config file, you can depict certain machines as more important and combine them as "core machines"]