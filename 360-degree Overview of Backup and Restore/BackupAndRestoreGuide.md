# The DBA’s Survival Guide: 360° SQL Server Backup and Restore

### DBA Fundamentals Group

Wednesday, July 22, 2025 at 12:00 PM EDT

<span style="color: var(--vscode-foreground);">Thanks to the chapter leadership for the opportunity</span>

<span style="color: var(--vscode-foreground);">Taiob Ali</span>

[taiob@sqlworldwide.com](mailto:taiob@sqlworldwide.com)

[https://bsky.app/profile/sqlworldwide.bsky.social](https://bsky.app/profile/sqlworldwide.bsky.social)

[https://sqlworldwide.com/](https://sqlworldwide.com/)

[https://www.linkedin.com/in/sqlworldwide/](https://www.linkedin.com/in/sqlworldwide/)

### Abstract

If you are the database steward, your most critical task is to guarantee that all committed transactions are always recoverable during a disaster within acceptable limits for data loss and downtimes.

Achieving this can be simple, such as taking a full backup, or complex, which might include filegroup backups based on the size and criticality of your application data.

Whatever your situation is, being well-prepared and practicing with your tools, scripts, and strategy will ensure you can respond quickly and efficiently when a disaster happens.

In this session, I will teach you all the basic types of backups and how to create backups and restores using SSMS and TSQL. Then we will move to advanced techniques, discussing file and filegroup backups, partial database restore, and T-SQL snapshot backups introduced with SQL Server 2022.

At the end of the session, you can create a solid Backup and restore strategy based on the service level agreement you and your business counterpart have agreed to.
---
### Learning Objective

- Understand and implement various SQL Server backup types—from full and differential to filegroup and snapshot backups.
- Design a disaster recovery strategy tailored to your business SLAs, ensuring minimal downtime and data loss.


---
## Why Backup?

### Primary Reasons for Database Backups

- **Disaster Recovery & Data Protection**
    - Hardware failures (disk crashes, server failures)
    - Human errors (accidental deletions, incorrect updates)
    - Natural disasters (fire, flood, power outages)
    - Cyber attacks (ransomware, malicious data corruption)
    - Software bugs and corruption

- **Business Continuity**
    - Meet Recovery Time Objectives (RTO) and Recovery Point Objectives (RPO)
    - Minimize downtime and maintain business operations
    - Ensure data availability for critical business processes

- **Development & Testing**
    - Creating consistent environments for development/testing
    - Data refresh for non-production environments
    - Performance testing with production-like data

- **Compliance & Legal Requirements**
    - Regulatory compliance (SOX, HIPAA, GDPR, etc.)
    - Data retention policies
    - Audit trail requirements
### Key Question for Discussion
*"Are backups alone sufficient for your HA/DR strategy, or do you need additional technologies?"*

## Who can back up the database?

- sysadmin fixed server role 
- db_owner fixed database roles
- db_backupoperator fixed database roles

---
## Backup and restore strategies

- Align with Business Requirements
    - Ensure backup strategies support SLAs, compliance, and operational needs.
- Maximum data availability
    - Design for minimal downtime using high-availability and disaster recovery (HA/DR) solutions
- Minimize Data Loss (RPO)
    - Define acceptable Recovery Point Objectives (RPO) and tailor backup frequency accordingly
- Optimize Backup Costs
    - Balance performance, storage, and retention policies to control costs effectively
---
## How do you meet above requirements?

- Backup Planning
    - Choose appropriate backup types and frequency (Full, Differential, Transaction Log)
    - Consider database size and rate of change
    - Evaluate hardware performance (disk speed, network bandwidth)
- Backup Integrity and Security
    - Verify integrity of backup files regularly
    - Ensure physical security of backup media
    - Plan for secure and timely retrieval of backup media
- Restore Readiness
    - Define and document restore strategies
    - Practice and test restores under various scenarios
    - Account for time to retrieve and restore backups
- Constraints and Considerations
    - Hardware limitations
    - Availability of trained personnel
    -   Location and accessibility of backup media
    - Physical and environmental security

---
## Recovery Model

- Simple
    - Automatically reclaims log space, eliminate transaction log management (**mostly**)
    - Exposure to data loss since last Full/Differential backup
    - Cannot use features:
        - Log shipping
        - Always On or Database mirroring
        - Media recovery without data loss
        - Point-in-time restores

- Full
    - Requires log backups
    - Can recover to an arbitrary point in time
    - Exposure to data loss only if the tail of the log is damaged

- Bulk logged
    - Requires log backups
    - Can switch between Full and Bulk logged
    - Permits high-performance bulk copy operations
    - Can recover to the end of any backup
    - Compromises recovery options:
        - Cannot point-in-time restore for the period of bulk logged recovery model
        - Cannot backup tail of transaction log

---
## Backup Type

- Database backups
    - Full database backup
    - Differential database backup
    - Transaction log backup
    - **Tail-Log backup**
- File Backup
    - Full file backup (typically called file backups)
    - Differential file backup
    - Partial backup (Only if you have read-only filegroups)
    - Differential partial backup
- **Copy-Only backup**
    - Full and Transaction Log only

---
## Estimate size of Backup

### Full

```
--This code not considering the compression
USE StackOverflow2010  
GO  
EXEC sp_spaceused @oneresultset = 1,@updateusage = N'TRUE'; 
GO 
```
---
### Differential

[New script: How much of the database has changed since the last full backup? by Paul Randal](https://www.sqlskills.com/blogs/paul/new-script-how-much-of-the-database-has-changed-since-the-last-full-backup/)

---

## Possible Media Errors During Backup and Restore

[Possible Media Errors During Backup and Restore (SQL Server)](https://learn.microsoft.com/en-us/sql/relational-databases/backup-restore/possible-media-errors-during-backup-and-restore-sql-server?view=sql-server-ver17)