# DNS Configuration Script

## Overview

This PowerShell script automates the installation and configuration of DNS services on a Windows Server environment. It specifically:

- Installs the DNS Server feature.
- Configures the DNS service to start automatically upon system boot.
- Creates specified DNS zones with defined replication scopes.
- Adds A records to these zones for specific hosts.

## Script Features


- **Zone Creation**: Customizable DNS zone creation with options for replication scope.
- **Record Addition**: Adds A records to DNS zones for simplified network management.
- **Error Handling**: Stops execution on error to prevent partial configurations.
- **Verbose Logging**: Provides detailed logs of each operation for troubleshooting and verification.

## Prerequisites

- **Operating System**: Windows Server (with PowerShell 5.1 or later).
- **Permissions**: Must be run with administrative privileges.
- **Network Configuration**: Ensure network settings are appropriate for DNS service operation.
- **DNS Installed on a Windows System**: Script will verify service, if not present, alert and exit.

## Usage

1. **Download the Script**:
   - Clone this repository or download the script directly.

2. **Run the Script**:
   - Open PowerShell as Administrator.
   - Navigate to the script's directory:
     ```powershell
     cd path\to\script\directory
     ```
   - Execute the script:
     ```powershell
     .\fake_net.ps1 -Verbose
     ```
   
   The `-Verbose` flag is optional but recommended for full logging.

## Functions

- **Update-DNSZone**: Adds a new DNS zone with specified replication settings.
- **Add-ARecord**: Adds an A record to a specified DNS zone.

## Configuration

# DNS Zones CSV Format and Output Structure

## CSV File Format

The CSV file used by this script should adhere to the following format:

| Column Name | Description |
|-------------|-------------|
| **ZoneName** | The name of the DNS zone. Should be RFC 2606 compliant for testing (e.g., `example.test`). |
| **Replication** | The replication scope of the DNS zone, typically "Domain". |
| **RecordName** | The name of the DNS record within the zone. |
| **IPAddress** | The IP address associated with the record. Should be RFC 5737 compliant for testing (e.g., `192.0.2.1`). |

### Example CSV Content

```csv
ZoneName,Replication,RecordName,IPAddress
example.test,Domain,dl,192.0.2.1
example.test,Domain,games,192.0.2.1
example.test,Domain,livegames,192.0.2.1
example.test,Domain,blogspot,192.0.2.1
example.test,Domain,content,192.0.2.1
example.test,Domain,xin,192.0.2.1
example.test,Domain,link54154415,192.0.2.1
example.test,Domain,tools,192.0.2.1