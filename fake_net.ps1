<#
.SYNOPSIS
    Configures DNS server with specific zones and A records.

.DESCRIPTION
    This script:
    - Updates the system and installs the DNS Server feature.
    - Starts and sets the DNS service to start automatically.
    - Creates DNS zones with specified replication scopes.
    - Adds A records to the created DNS zones.
    - Provides detailed verbose logging for each step.

.EXAMPLE
    .\ConfigureDNS.ps1 -Verbose

.NOTES
    File Name      : ConfigureDNS.ps1
    Author         : Your Name
    Requires       : PowerShell 5.1 or higher
    Version        : 1.0
    Date           : Today's Date

    Ensure you run this with administrative privileges. This script assumes you have the necessary permissions to install features and manage DNS zones.

.LINK
    None

#>

# Set error handling to stop script on error
$ErrorActionPreference = "Stop"

# Function to log messages with timestamp
function Write-Log {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "[$timestamp] $Message"
}

<#
.SYNOPSIS
    Creates a new DNS Primary Zone.

.DESCRIPTION
    This function adds a new primary DNS zone with the specified replication scope.

.PARAMETER ZoneName
    The name of the DNS zone to create.

.PARAMETER ReplicationScope
    The replication scope for the zone, e.g., 'Domain', 'Forest', or 'Legacy'.

.EXAMPLE
    Update-DNSZone -ZoneName "example.com" -ReplicationScope "Domain"
#>
function Update-DNSZone {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ZoneName,
        [Parameter(Mandatory=$true)]
        [string]$ReplicationScope
    )
    Write-Log "Creating DNS zone $ZoneName with replication scope $ReplicationScope..."
    Add-DnsServerPrimaryZone -Name $ZoneName -ReplicationScope $ReplicationScope -Verbose
}

<#
.SYNOPSIS
    Adds an A record to a DNS zone.

.DESCRIPTION
    Adds an A (Address) record to the specified DNS zone.

.PARAMETER ZoneName
    The DNS zone where the A record will be added.

.PARAMETER RecordName
    The name of the A record.

.PARAMETER RecordIP
    The IP address associated with the A record.

.EXAMPLE
    Add-ARecord -ZoneName "example.com" -RecordName "www" -RecordIP "192.168.1.1"
#>
function Add-ARecord {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ZoneName,
        [Parameter(Mandatory=$true)]
        [string]$RecordName,
        [Parameter(Mandatory=$true)]
        [string]$RecordIP
    )
    Write-Log "Adding A record $RecordName with IP $RecordIP to zone $ZoneName..."
    Add-DnsServerResourceRecordA -ZoneName $ZoneName -Name $RecordName -IPv4Address $RecordIP -Verbose
}

# Main script execution starts here
try {
    # Update the system and install necessary features
    Write-Log "Updating system and installing DNS Server feature..."
    Install-WindowsFeature -Name DNS -IncludeManagementTools -Verbose

    # Start and enable the DNS Server service
    Write-Log "Starting and enabling DNS Server service..."
    Set-Service -Name DNS -StartupType Automatic -Verbose
    Start-Service -Name DNS -Verbose

    # Verify DNS Server installation
    $dnsFeature = Get-WindowsFeature -Name DNS
    Write-Log "DNS Server installation state: $($dnsFeature.InstallState)"

    # DNS zones and A records configuration
    $dnsZones = @(
        @{
            name = "blogspot.ie"
            replication = "Domain"
            records = @(
                @{ name = "dl"; ip = "78.16.206.86" },
                @{ name = "games"; ip = "78.16.206.86" },
                @{ name = "livegames"; ip = "78.16.206.86" },
                @{ name = "blogspot"; ip = "78.16.206.86" },
                @{ name = "content"; ip = "78.16.206.86" },
                @{ name = "xin"; ip = "78.16.206.86" },
                @{ name = "link54154415"; ip = "78.16.206.86" },
                @{ name = "tools"; ip = "78.16.206.86" }
            )
        },
        @{
            name = "coateng.cn"
            replication = "Domain"
            records = @(
                @{ name = "dl"; ip = "121.43.50.68" },
                @{ name = "games"; ip = "121.43.50.68" },
                @{ name = "livegames"; ip = "121.43.50.68" },
                @{ name = "blogspot"; ip = "121.43.50.68" },
                @{ name = "content"; ip = "121.43.50.68" },
                @{ name = "xin"; ip = "121.43.50.68" },
                @{ name = "link54154415"; ip = "121.43.50.68" },
                @{ name = "tools"; ip = "121.43.50.68" }
            )
        },
        @{
            name = "steanconmmunity.ru"
            replication = "Domain"
            records = @(
                @{ name = "dl"; ip = "80.66.75.51" },
                @{ name = "games"; ip = "80.66.75.51" },
                @{ name = "livegames"; ip = "80.66.75.51" },
                @{ name = "blogspot"; ip = "80.66.75.51" },
                @{ name = "content"; ip = "80.66.75.51" },
                @{ name = "xin"; ip = "80.66.75.51" },
                @{ name = "link54154415"; ip = "80.66.75.51" },
                @{ name = "tools"; ip = "80.66.75.51" }
            )
        }
    )

    # Create DNS zones and add A records
    foreach ($zone in $dnsZones) {
        Update-DNSZone -ZoneName $zone.name -ReplicationScope $zone.replication
        foreach ($record in $zone.records) {
            Add-ARecord -ZoneName $zone.name -RecordName $record.name -RecordIP $record.ip
        }
    }

    Write-Log "DNS configuration completed successfully!"

} catch {
    Write-Log "An error occurred: $_"
    exit 1
}