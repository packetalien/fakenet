<#
.SYNOPSIS
    Configures DNS server with specific zones and A records. Assume DNS on Windows exists. 

.DESCRIPTION
    - Creates DNS zones with specified replication scopes.
    - Adds A records to the created DNS zones.
    - Provides detailed verbose logging for each step.

.EXAMPLE
    .\fake_net.ps1 -Verbose

.NOTES
    File Name      : fake_net.ps1.ps1
    Author         : @packetmonk (@packetalien on GitHub)
    Requires       : PowerShell 5.1 or higher
    Version        : 1.0
    Date           : 30 JAN 2025

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
    Checks if the DNS Server service is installed on the system.

.DESCRIPTION
    This function checks to see if the DNS Server feature is installed. 
    If the DNS Server service is not detected, it logs a message and 
    exits the script. This ensures that DNS-related operations are 
    performed only when the necessary service is available.

.EXAMPLE
    Check-DNSService -Verbose
    This command checks for the DNS Server service and outputs verbose logging.
#>
function Check-DNSService {
    [CmdletBinding()]
    param()

    Write-Verbose "Checking for DNS Server service..."
    
    try {
        $dnsFeature = Get-WindowsFeature -Name DNS
        if ($dnsFeature -and $dnsFeature.Installed) {
            Write-Verbose "DNS Server service is installed and available."
        } else {
            Write-Verbose "DNS Server service is not installed."
            Write-Error "The DNS Server service is not installed. Exiting script."
            exit 1
        }
    } catch {
        Write-Error "An error occurred while checking for DNS Server service: $_"
        exit 1
    }
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
<#
.SYNOPSIS
    Imports DNS zone data from a CSV file and structures it into an array.

.DESCRIPTION
    This function reads a CSV file containing DNS zone information, constructs 
    an array where each element represents a DNS zone with its associated 
    records. The function uses verbose logging to detail each step of the 
    import process.

.PARAMETER Path
    The full path to the CSV file containing the DNS zone data.

.RETURNS
    An array of hashtables, each representing a DNS zone with its records.

.EXAMPLE
    $dnsZones = Import-DNSZonesFromCSV -Path "C:\dnsZones.csv" -Verbose
    This command imports DNS zones from dnsZones.csv, outputs verbose logging, 
    and stores the result in $dnsZones.

.NOTES
    The CSV should have columns named "ZoneName", "Replication", "RecordName", 
    and "IPAddress". This function assumes the CSV adheres to this structure.
#>
function Import-DNSZonesFromCSV {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]$Path = ".\fake_net.csv"
    )
    
    Write-Verbose "Starting import of DNS zones from CSV."

    try {
        Write-Verbose "Reading CSV file from path: $Path"
        $importedData = Import-Csv -Path $Path

        $dnsZones = @()
        $currentZoneName = $null

        Write-Verbose "Processing CSV entries..."
        foreach ($row in $importedData) {
            if ($currentZoneName -ne $row.ZoneName) {
                Write-Verbose "Adding new zone: $($row.ZoneName)"
                $currentZoneName = $row.ZoneName
                $dnsZones += @{
                    name = $row.ZoneName
                    replication = $row.Replication
                    records = @()
                }
            }
            
            # Find the correct zone to add the record to
            $zone = $dnsZones | Where-Object { $_.name -eq $row.ZoneName }
            Write-Verbose "Adding record $($row.RecordName) with IP $($row.IPAddress) to zone $($row.ZoneName)"
            $zone.records += @{ name = $row.RecordName; ip = $row.IPAddress }
        }

        Write-Verbose "Finished processing CSV. Total zones imported: $($dnsZones.Count)"
        return $dnsZones

    } catch {
        Write-Error "An error occurred while importing DNS zones from CSV: $_"
        return $null
    }
}
# Main script execution starts here
try {
    # Update the system and install necessary features
    Check-DNSService
    
    # DNS zones and A records configuration
    $dnsZones = Import-DNSZonesFromCSV -Path .\fake_net.csv -Verbose

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