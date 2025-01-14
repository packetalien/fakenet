# DNS Configuration Script

## Overview

This PowerShell script automates the installation and configuration of DNS services on a Windows Server environment. It specifically:

- Installs the DNS Server feature.
- Configures the DNS service to start automatically upon system boot.
- Creates specified DNS zones with defined replication scopes.
- Adds A records to these zones for specific hosts.

## Script Features

- **DNS Feature Installation**: Uses `Install-WindowsFeature` to add the DNS Server role.
- **Service Management**: Ensures the DNS service is running and set to start automatically.
- **Zone Creation**: Customizable DNS zone creation with options for replication scope.
- **Record Addition**: Adds A records to DNS zones for simplified network management.
- **Error Handling**: Stops execution on error to prevent partial configurations.
- **Verbose Logging**: Provides detailed logs of each operation for troubleshooting and verification.

## Prerequisites

- **Operating System**: Windows Server (with PowerShell 5.1 or later).
- **Permissions**: Must be run with administrative privileges.
- **Network Configuration**: Ensure network settings are appropriate for DNS service operation.

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
     .\ConfigureDNS.ps1 -Verbose
     ```
   
   The `-Verbose` flag is optional but recommended for full logging.

## Functions

- **Update-DNSZone**: Adds a new DNS zone with specified replication settings.
- **Add-ARecord**: Adds an A record to a specified DNS zone.

## Configuration

The script uses a predefined array `$dnsZones` to set up the zones and records. To modify:

- Edit the `$dnsZones` array within the script to include new zones or change existing ones:
  ```powershell
  $dnsZones = @(
      @{
          name = "example.com"
          replication = "Domain"
          records = @(
              @{ name = "www"; ip = "192.168.1.1" },
              # Add more records here
          )
      },
      # Other zones
  )