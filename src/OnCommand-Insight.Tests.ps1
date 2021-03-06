﻿Import-Module "$PSScriptRoot\OnCommand-Insight"

if (!$OciServerName) {
    $OciServerName = 'localhost'
    $OciCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "admin",("admin123" | ConvertTo-SecureString -AsPlainText -Force)
}

# Constants

$REGEX_STRING_HOSTNAME_IP = "([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])(\.([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9]))*"
$REGEX_HOSTNAME_IP = "^$REGEX_STRING_HOSTNAME_IP$"
$REGEX_LIST_OF_HOSTNAME_IP = "^$REGEX_STRING_HOSTNAME_IP(,$REGEX_STRING_HOSTNAME_IP)*$"

Write-Host "Running tests against OCI Server $OciServerName"

### functions for validating OCI objects
function ValidateAcquisitionUnit {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$True,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="Acquisition unit to be verified")][PSObject]$AcquisitionUnit
    )

        Process {
            $AcquisitionUnit.id | Should BeGreaterThan 0
            $AcquisitionUnit.self | Should Be "/rest/v1/admin/acquisitionUnits/$($AcquisitionUnit.id)"
            $AcquisitionUnit.name | Should Be "local"
            $AcquisitionUnit.ip | Should Match "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"
            $AcquisitionUnit.status | Should Match "CONNECTED|CONNECTED_TIMEOUT"
            $AcquisitionUnit.isActive | Should BeOfType Boolean
            if ($AcquisitionUnit.leaseContract) {
                $AcquisitionUnit.leaseContract | Should Be 120000
            }
            if ($AcquisitionUnit.nextLeaseRenewal) {
                $AcquisitionUnit.nextLeaseRenewal | Should BeGreaterThan (Get-Date)
            }
            if ($AcquisitionUnit.lastReported) {
                $AcquisitionUnit.lastReported | Should BeLessThan (Get-Date)
            }
    }
}

function ValidateAnnotation {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$True,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="Annotation to be verified")][PSObject]$Annotation
    )

        Process {
            $Annotation.id | Should BeGreaterThan 0
            $Annotation.self | Should Be "/rest/v1/assets/annotations/$($Annotation.id)"
            $Annotation.name | Should Match ".+"
            $Annotation.type | Should Match "DATE|TEXT|FIXED_ENUM|FLEXIBLE_ENUM|BOOLEAN|NUMBER"
            $Annotation.label | Should Match ".+"
            if ($Annotation.description) {
               $Annotation.description | Should Match ".+" 
            }
            $Annotation.isUserDefined | Should BeOfType Boolean
            $Annotation.isCostBased | Should BeOfType Boolean
            if ($Annotation.enumValues) {
                $Annotation.enumValues.id | Should BeGreaterThan 0
                $Annotation.enumValues.name | Should Match ".+"
                $Annotation.enumValues.label | Should Match ".+"
                $Annotation.enumValues.description | Should Match ".+"
                $Annotation.enumValues.isUserDefined | Should Match ".+"
            }
            $Annotation.supportedObjectTypes | Should Match "StoragePool|Qtree|Port|Host|StorageNode|Storage|InternalVolume|Switch|Volume|Vmdk|DataStore|Disk|Share|VirtualMachine"
    }
}

function ValidateAnnotationValue {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$True,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="Annotation value to be verified")][PSObject]$AnnotationValue
    )

        Process {
            $AnnotationValue.rawValue | Should Match ".+"
            $AnnotationValue.displayValue | Should Match ".+"
            $AnnotationValue.label | Should Match ".+"
            $AnnotationValue.isDerived | Should BeOfType Boolean
            $AnnotationValue.annotationAssignment | Should Match "MANUAL"
    }
}

function ValidateApplication {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$True,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="Application to be verified")][PSObject]$Application
    )

        Process {
            $Application.id | Should BeGreaterThan 0
            $Application.self | Should Be "/rest/v1/assets/applications/$($Application.id)"
            $Application.name | Should Match ".+"
            $Application.simpleName | Should Match ".+"
            $Application.priority | Should Match "Low|Medium|High|Critical" 
            $Application.isBusinessEntityDefault | Should BeOfType Boolean
            $Application.isInherited | Should BeOfType Boolean
            $Application.ignoreShareViolations | Should BeOfType Boolean
    }
}

function ValidateBusinessEntity {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$True,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="Businesse entity to be verified")][PSObject]$BusinessEntity
    )

        Process {
            $BusinessEntity.id | Should BeGreaterThan 0
            $BusinessEntity.self | Should Be "/rest/v1/assets/businessEntities/$($BusinessEntity.id)"
            $BusinessEntity.tenant | Should Match ".+"
            $BusinessEntity.lob | Should Match ".+"
            $BusinessEntity.businessUnit | Should Match ".+" 
            $BusinessEntity.project | Should Match ".+"
    }
}

function ValidatePackage {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$False,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="Datasource package to be verified")][PSObject]$Package
    )

        Process {
            $Package.packageName | Should Match 'Inventory|Performance'
            $Package.status | Should Match 'ACQUIRING|STANDBY|ERROR|SUCCESS'
            $Package.statusText | Should Match ".+"
            $Package.releaseStatus | Should Match "BETA|OFFICIAL"
    }
}

function ValidateDatasource {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$False,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="Datasource to be verified")][PSObject]$Datasource
    )

        Process {
            $Datasource.id | Should BeGreaterThan 0
            $Datasource.self | Should Be "/rest/v1/admin/datasources/$($Datasource.id)"
            $Datasource.impactIndex | Should Match "-?[0-9]+"
            $Datasource.name | Should Match ".+"
            $Datasource.status | Should Match "[A-Z]+"
            $Datasource.statusText | Should Match ".*"
            $Datasource.pollStatus | Should Match "[A-Z]+"
            $Datasource.vendor | Should Match ".+"
            $Datasource.foundationIp | Should Match $REGEX_HOSTNAME_IP
            $Datasource.lastSuccessfullyAccquired | Should BeLessThan (Get-Date)
            if ($Datasource.resumeTime) {
                $Datasource.resumeTime | Should BeGreaterThan (Get-Date)
            }
    }
}

function ValidateDatasourceConfig {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$False,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="Datasource configuration to be verified")][PSObject]$DatasourceConfig
    )

        Process {
            $DatasourceConfig.dsTypeId | Should BeGreaterThan 0
            $DatasourceConfig.self | Should Match "/rest/v1/admin/datasources/[0-9]+/config"
            $DatasourceConfig.vendor | Should Match ".+"
            $DatasourceConfig.model | Should Match ".+"
            $DatasourceConfig.packages | ValidateDatasourceConfigPackage
    }
}

function ValidateDatasourceChange {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$False,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="Datasource to be verified")][PSObject]$DatasourceChange
    )

        Process {
            if ($DatasourceChange.time) {
                $DatasourceChange.time | Should BeOfType DateTime
                $DatasourceChange.time | Should BeLessThan (Get-Date)
                $DatasourceChange.type | Should Match ".+"
            }
            if ($DatasourceChange.summary) {
                $DatasourceChange.summary | Should Match ".+"
            }
    }
}

function ValidateDatasourceEvent {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$False,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="Datasource to be verified")][PSObject]$DatasourceEvent
    )

        Process {
            $DatasourceEvent.id | Should BeGreaterThan 0
            $DatasourceEvent.packageName | Should Match 'Performance|Inventory'
            $DatasourceEvent.status | Should Match 'STANDBY|ERROR|SUCCESS|DISABLED'
            $DatasourceEvent.statusText | Should Match '.+'
            $DatasourceEvent.startTime | Should BeOfType DateTime
            $DatasourceEvent.endTime | Should BeOfType DateTime
            $DatasourceEvent.numberOfTimes | Should BeGreaterThan 0
    }
}

function ValidateDatasourceTypePackage {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$False,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="Datasource package to be verified")][PSObject]$DatasourcePackage
    )

        Process {
            $DatasourcePackage.id | Should Match 'cloud|performance|hostvirtualization|storageperformance|foundation|integration'
            $DatasourcePackage.displayName | Should Match '.+'
            $DatasourcePackage.isMandatory | Should BeOfType Boolean
            $DatasourcePackage.attributes | ValidateDatasourceTypePackageAttribute
    }
}

function ValidateDatasourceTypePackageAttribute {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$False,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="Datasource package to be verified")][PSObject]$DatasourcePackageAttribute
    )

        Process {
            $DatasourcePackageAttribute.type | Should Match 'list|integer|string|boolean|enum|float'
            $DatasourcePackageAttribute.name | Should Match '.+'
            $DatasourcePackageAttribute.description | Should Match '.*'
            $DatasourcePackageAttribute.label | Should Match '.*'
            $DatasourcePackageAttribute.isEditable | Should BeOfType Boolean
            $DatasourcePackageAttribute.defaultValue | Should Match '.*'
            $DatasourcePackageAttribute.isEncrypted | Should BeOfType Boolean
            $DatasourcePackageAttribute.guiorder | Should BeOfType int
            $DatasourcePackageAttribute.isMandatory | Should BeOfType Boolean
            $DatasourcePackageAttribute.isHidden | Should BeOfType Boolean
            $DatasourcePackageAttribute.isCloneable | Should BeOfType Boolean
            $DatasourcePackageAttribute.isAdvanced | Should BeOfType Boolean
    }
}

function ValidateDatasourceConfigPackage {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$False,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="Datasource package to be verified")][PSObject]$DatasourcePackage
    )

        Process {
            $DatasourcePackage.id | Should Match 'cloud|performance|storageperformance|hostvirtualization|foundation'
            $DatasourcePackage.displayName | Should Match '.+'
            $DatasourcePackage.isMandatory | Should BeOfType Boolean
            $DatasourcePackage.attributes | ValidateDatasourceConfigPackageAttribute
    }
}

function ValidateDatasourceConfigPackageAttribute {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$False,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="Datasource package to be verified")][PSObject]$DatasourceConfigPackageAttribute
    )

        Process {
            $DatasourceConfigPackageAttribute.RELEASESTATUS | Should Match 'BETA|OFFICIAL'
            # TODO: add parameters
    }
}

function ValidateDatasourcePatch {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$False,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="Datasource package to be verified")][PSObject]$DatasourcePatch
    )

        Process {
            $DatasourcePatch.id | Should BeGreaterThan 0
            $DatasourcePatch.self | Should Be "/rest/v1/admin/patches/$($DatasourcePatch.id)"
            $DatasourcePatch.name | Should Match ".+"
            $DatasourcePatch.description | Should Match ".+"
            $DatasourcePatch.createTime | Should BeOfType DateTime
            $DatasourcePatch.createTime | Should BeLessThan (Get-Date)
            $DatasourcePatch.lastUpdateTime | Should BeOfType DateTime
            $DatasourcePatch.lastUpdateTime | Should BeLessThan (Get-Date)
            $DatasourcePatch.state | Should Match "ACTIVE"
            $DatasourcePatch.recommendation | Should Match "VERIFYING"
            $DatasourcePatch.recommendationText | Should Match ".+"
            $DatasourcePatch.datasourceTypes | ValidateDatasourceType
            $DatasourcePatch.numberOfAffectedDatasources | Should BeGreaterThan 0
            $DatasourcePatch.type | Should Match 'PATCH'
            if ($DatasourcePatch.note) {
                $DatasourcePatch.note | Should Match '.+'
            }
    }
}

function ValidateDatasourceType {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$False,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="Datasource package to be verified")][PSObject]$DatasourceType
    )

        Process {
            $DatasourceType.id | Should BeGreaterThan 0
            $DatasourceType.name | Should Match '.+'
            $DatasourceType.description | Should Match '.+'
            $DatasourceType.self | Should Be "/rest/v1/admin/datasourceTypes/$($DatasourceType.id)"
            $DatasourceType.vendorModels | ValidateVendorModel
            $DatasourceType.packages | ValidateDatasourceTypePackage
    }
}

function ValidateVendorModel {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$False,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="Datasource package to be verified")][PSObject]$VendorModel
    )

        Process {
            $VendorModel.modelName | Should Match '.+'
            $VendorModel.modelDescription | Should Match '.+'
            $VendorModel.vendorName | Should Match '.+'
            $VendorModel.vendorDescription | Should Match '.+'
    }
}

function ValidateDevice {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$False,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="Device to be verified")][PSObject]$Device
    )

        Process {
            $Device.id | Should BeGreaterThan 0
            $Device.name | Should Match '.+'
            $Device.simpleName | Should Match '.+'
            $Device.ip | Should Match $REGEX_LIST_OF_HOSTNAME_IP
            $Device.type | Should Match 'SWITCH|STORAGE|HOST'
            $Device.wwn | Should Match '.*'
            $Device.description | Should Match '.+'
            $Device.self | Should Match "/rest/v1/assets/$($Device.type.toLower())[es]*/$($Device.id)"
    }
}

function ValidateDatastore {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$False,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="Datastore to be verified")][PSObject]$Datastore
    )

        Process {
            $Datastore.id | Should BeGreaterThan 0
            $Datastore.name | Should Match '.+'
            $Datastore.simpleName | Should Match '.+'
            $Datastore.virtualCenterIp | Should Match '.+'
            $Datastore.capacity | ValidateCapacity
            $Datastore.self | Should Match "/rest/v1/assets/datastores/$($Datastore.id)"
    }
}

function ValidateCapacity {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$False,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="Capacity to be verified")][PSObject]$Capacity
    )

        Process {
            $Capacity.description | Should Match '.+'
            $Capacity.unitType | Should Match '.+'
            $Capacity.total | ValidateValue
            $Capacity.used | ValidateValue
    }
}

function ValidateValue {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$False,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="Value to be verified")][PSObject]$Value
    )

    Process {
        $Value.value -as [Decimal] | Should BeOfType Decimal
        if ($Value.highThreshold) {
            $Value.highThreshold | Should BeOfType Decimal
            $Value.highThreshold | Should BeGreaterThan -1
            $Value.highThreshold | Should BeLessThan 101
        }
        if ($Value.numericType) {
            $Value.numericType | Should Match "LONG"
        }
        if ($Value.unitType) {
            $Value.unitType | Should Match "Mhz|MB"
        }
    }
}

function ValidateHost {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$False,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="Host to be verified")][PSObject]$HostItem
    )

        Process {
            $HostItem.id | Should BeGreaterThan 0
            $HostItem.name | Should Match '.+'
            $HostItem.simpleName | Should Match '.+'
            $HostItem.ip | Should Match '([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+,?)+'
            $HostItem.resourceType | Should Be 'Host'
            $HostItem.self | Should Match "/rest/v1/assets/hosts/$($Host.id)"
            $HostItem.os | Should Match '.*'
            $HostItem.model | Should Match '.*'
            $HostItem.manufacturer | Should Match '.*'
            if ($HostItem.memory) {
                $HostItem.memory | ValidateValue
            }
            if ($HostItem.cpuCount) { 
                $HostItem.cpuCount | Should BeGreaterThan 0
            }
            if ($HostItem.cpu) {
                $HostItem.cpu | ValidateValue
            }
            $HostItem.isActive | Should BeOfType Boolean
    }
}

function ValidatePort {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$False,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="Host to be verified")][PSObject]$Port
    )

    Process {
        $Port.id | Should BeGreaterThan 0
        $Port.name | Should Match '.+'
        $Port.simpleName | Should Match '.+'
        $Port.self | Should Match "/rest/v1/assets/ports/$($Port.id)"
        if ($Port.ip) {
            $HostItem.ip | Should Match '([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+,?)+'
        }
        if ($Port.wwn) {
            $Port.wwn | Should Match '[a-fA-F0-9][a-fA-F0-9]:[a-fA-F0-9][a-fA-F0-9]:[a-fA-F0-9][a-fA-F0-9]:[a-fA-F0-9][a-fA-F0-9]:[a-fA-F0-9][a-fA-F0-9]:[a-fA-F0-9][a-fA-F0-9]:[a-fA-F0-9][a-fA-F0-9]:[a-fA-F0-9][a-fA-F0-9]'
        }
        if ($Port.nodeWwn) {
            $Port.nodeWwn | Should Match '[a-fA-F0-9][a-fA-F0-9]:[a-fA-F0-9][a-fA-F0-9]:[a-fA-F0-9][a-fA-F0-9]:[a-fA-F0-9][a-fA-F0-9]:[a-fA-F0-9][a-fA-F0-9]:[a-fA-F0-9][a-fA-F0-9]:[a-fA-F0-9][a-fA-F0-9]:[a-fA-F0-9][a-fA-F0-9]'
        }
        $Port.type | Should Match ".+"
        if ($Port.speed) {
            $Port.speed | Should Match '.+'
        }
        if ($Port.deviceType) {
            $Port.deviceType | Should Match '.+'
        }
        if ($Port.deviceName) {
            $Port.deviceName | Should Match '.+'
        }
        if ($Port.role) {
            $Port.role | Should Match '.+'
        }
        if ($Port.portIndex) {
            $Port.portIndex | Should Match '.+'
        }
        if ($Port.blade) {
            $Port.blade | Should Match '.+'
        }
        if ($Port.gbicType) {
            $Port.gbicType | Should Match '.+'
        }
        if ($Port.controller) {
            $Port.controller | Should Match '.+'
        }
        if ($Port.isGenerated) {
            $Port.isGenerated | Should BeOfType Boolean
        }
        if ($Port.portState) {
            $Port.portState | Should Match '.+'
        }
        if ($Port.portStatus) {
            $Port.portStatus | Should Match '.+'
        }
        if ($Port.fc4Protocol) {
            $Port.fc4Protocol | Should Match '.+'
        }
        if ($Port.gbicType) {
            $Port.gbicType | Should Match '.+'
        }
        if ($Port.isActive) {
            $Port.isActive | Should BeOfType Boolean
        }
        if ($Port.classOfService) {
            $Port.classOfService | Should Match '.+'
        }
    }
}

function ValidateStorageResource {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$False,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="Storage Resource to be verified")][PSObject]$StorageResource
    )

        Process {
            $StorageResource.id | Should BeGreaterThan 0
            $StorageResource.self | Should Match "/rest/v1/assets/$($StorageResource.resourceType.substring(0,1).toLower()+$StorageResource.resourceType.substring(1))s*/$($StorageResource.id)"
            $StorageResource.name | Should Match '.+'
            $StorageResource.simpleName | Should Match '.+'
            $StorageResource.capacity | ValidateCapacity
            $StorageResource.isThinProvisioned | Should BeOfType Boolean
            if ($StorageResource.dataStores) {
                $StorageResource.dataStores | ValidateDatastore
            }
            if ($StorageResource.computeResources) {
                $StorageResource.computeResources | ValidateComputeResource
            }
            if ($StorageResource.storagePools) {
                $StorageResource.storagePools | ValidateStoragePool
            }
    }
}

function ValidateFileSystem {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$False,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="FileSystem to be verified")][PSObject]$FileSystem
    )

        Process {
            $FileSystem.id | Should BeGreaterThan 0
            $FileSystem.self | Should Match "/rest/v1/assets/fileSystems/$($FileSystem.id)"
            $FileSystem.type | Should Match '.*'
            $FileSystem.name | Should Match '.+'
            $FileSystem.simpleName | Should Match '.+'
            $StorageResource.capacity | ValidateCapacity
    }
}

function ValidateVirtualMachine {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$False,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="Virtual machine to be verified")][PSObject]$VirtualMachine
    )

        Process {
            $VirtualMachine.id | Should BeGreaterThan 0
            $VirtualMachine.self | Should Match "/rest/v1/assets/virtualMachines/$($VirtualMachine.id)"
            $VirtualMachine.resourceType | Should Be "VirtualMachine"
            $VirtualMachine.name | Should Match ".+"
            $VirtualMachine.simpleName | Should Match ".+"
            $VirtualMachine.guestState | Should Match ".+"
            $VirtualMachine.os | Should Match ".+"
            $VirtualMachine.powerState | Should Match ".+"
            if ($VirtualMachine.powerStateChangeTime) {
                $VirtualMachine.powerStateChangeTime | Should BeOfType DateTime
            }
            $VirtualMachine.createTime | Should BeOfType DateTime
            $VirtualMachine.ip | Should Match $REGEX_HOSTNAME_IP
            # TODO: Remove fix for error in OCI Demo DB
            $VirtualMachine.dnsName = $VirtualMachine.dnsName -replace "_","-"
            $VirtualMachine.dnsName | Should Match $REGEX_HOSTNAME_IP
            $VirtualMachine.processors | Should BeGreaterThan 0
            # TODO validate memory
            # $StorageResource.memory
            $VirtualMachine.capacity | ValidateCapacity
    }
}

function ValidatePerformance {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$False,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="Performance to be verified")][PSObject]$Performance
    )

    Process {
        $Performance.self | Should Match "/rest/v1/assets/[a-z]+/[0-9]+/performance"
        if ($Performance.cacheHitRatio) {
            $Performance.cacheHitRatio | ValidatePerformanceCategory
        }
        if ($Performance.cpuUtilization) {
            $Performance.cpuUtilization | ValidatePerformanceCategory
        }
        if ($Performance.diskThroughput) {
            $Performance.diskThroughput | ValidatePerformanceCategory
        }
        if ($Performance.swapRate) {
            $Performance.swapRate | ValidatePerformanceCategory
        }
        if ($Performance.diskIops) {
            $Performance.diskIops | ValidatePerformanceCategory
        }
        if ($Performance.diskLatency) {
            $Performance.diskLatency | ValidatePerformanceCategory
        }
        if ($Performance.fcWeightedPortBalanceIndex) {
            $Performance.fcWeightedPortBalanceIndex | ValidateFcWeightedPortBalanceIndex
        }
        if ($Performance.iops) {
            $Performance.iops | ValidatePerformanceCategory
        }
        if ($Performance.ipThroughput) {
            $Performance.ipThroughput | ValidatePerformanceCategory
        }
        if ($Performance.latency) {
            $Performance.latency | ValidatePerformanceCategory
        }
        if ($Performance.memoryUtilization) {
            $Performance.memoryUtilization | ValidatePerformanceCategory
        }
        if ($Performance.partialBlocksRatio) {
            $Performance.partialBlocksRatio | ValidatePerformanceCategory
        }
        if ($Performance.throughput) {
            $Performance.throughput | ValidatePerformanceCategory
        }
        if ($Performance.writePending) {
            $Performance.writePending | ValidatePerformanceCategory
        }
    }
}

function ValidatePerformanceCategory {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$False,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="Performance to be verified")][PSObject]$PerformanceCategory
    )

        Process {
            
            $PerformanceCategory.performanceCategory | Should Match '.+'
            $PerformanceCategory.description | Should Match '.+'
            if ($PerformanceCategory.read) {
                $PerformanceCategory.read | ValidatePerformanceIndicator
            }
            if ($PerformanceCategory.write) {
                $PerformanceCategory.write | ValidatePerformanceIndicator
            }
            if ($PerformanceCategory.totalMax) {
                $PerformanceCategory.totalMax | ValidatePerformanceIndicator
            }
            if ($PerformanceCategory.total) {
                $PerformanceCategory.total | ValidatePerformanceIndicator
            }
            if ($PerformanceCategory.inRate) {
                $PerformanceCategory.inRate | ValidatePerformanceIndicator
            }
            if ($PerformanceCategory.outRate) {
                $PerformanceCategory.outRate | ValidatePerformanceIndicator
            }
            if ($PerformanceCategory.totalRate) {
                $PerformanceCategory.totalRate | ValidatePerformanceIndicator
            }
            if ($PerformanceCategory.totalMaxRate) {
                $PerformanceCategory.totalMaxRate | ValidatePerformanceIndicator
            }
    }
}

function ValidateFcWeightedPortBalanceIndex {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$False,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="Performance to be verified")][PSObject]$FcWeightedPortBalanceIndex
    )

        Process {
            
            $FcWeightedPortBalanceIndex.description | Should Match '.+'
            if ($FcWeightedPortBalanceIndex.unitType) {
                $FcWeightedPortBalanceIndex.unitType | Should Match '%|KB/s|MB/s|IO/s|ms'
            }
            if ($FcWeightedPortBalanceIndex.start) {
                $FcWeightedPortBalanceIndex.start | Should BeOfType DateTime
            }
            if ($FcWeightedPortBalanceIndex.end) {
                $FcWeightedPortBalanceIndex.end | Should BeOfType DateTime
            }
            if ($FcWeightedPortBalanceIndex.current) {
                $FcWeightedPortBalanceIndex.current -as [double] | Should BeOfType Double
            }
            if ($FcWeightedPortBalanceIndex.min) {
                $FcWeightedPortBalanceIndex.min -as [double] | Should BeOfType Double
            }
            if ($FcWeightedPortBalanceIndex.max) {
                $FcWeightedPortBalanceIndex.max -as [double] | Should BeOfType Double
            }
            if ($FcWeightedPortBalanceIndex.avg) {
                $FcWeightedPortBalanceIndex.avg -as [double] | Should BeOfType Double
            }
            if ($FcWeightedPortBalanceIndex.sum) {
                $FcWeightedPortBalanceIndex.sum -as [double] | Should BeOfType Double
            }
    }
}

function ValidatePerformanceIndicator {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$False,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="Performance to be verified")][PSObject]$PerformanceIndicator
    )

        Process {
            $PerformanceIndicator.description | Should Match '.+'
            $PerformanceIndicator.unitType | Should Match '%|KB/s|MB/s|IO/s|ms'
            if ($PerformanceIndicator.start) {
                $PerformanceIndicator.start | Should BeOfType DateTime
            }
            if ($PerformanceIndicator.end) {
                $PerformanceIndicator.end | Should BeOfType DateTime
            }
            if ($PerformanceIndicator.current) {
                $PerformanceIndicator.current -as [double] | Should BeOfType Double
            }
            if ($PerformanceIndicator.min) {
                $PerformanceIndicator.min -as [double] | Should BeOfType Double
            }
            if ($PerformanceIndicator.max) {
                $PerformanceIndicator.max -as [double] | Should BeOfType Double
            }
            if ($PerformanceIndicator.avg) {
                $PerformanceIndicator.avg -as [double] | Should BeOfType Double
            }
            if ($PerformanceIndicator.sum) {
                $PerformanceIndicator.sum -as [double] | Should BeOfType Double
            }
    }
}

function ValidateLicense {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$False,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="License to be verified")][PSObject]$License
    )

    Process {
        $License.isValid | Should BeOfType Boolean
        $License.isPerformLicense | Should BeOfType Boolean
        $License.errorMessages | Should Match ".*"
        $License.warningMessages | Should Match ".*"
        $License.serialNumber | Should Match ".+"
        $license.licenseParts | ValidateLicensePart
    }
}

function ValidateLicensePart {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$False,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="License part to be verified")][PSObject]$LicensePart
    )

    Process {
        $LicensePart.id | Should Match "IASR|IPER|IPLN|IDIS|IHUP"
        $LicensePart.status | Should Match "OK"
        $LicensePart.displayName | Should Match ".+"
        $LicensePart.expirationDate | Should BeOfType DateTime
        $LicensePart.compliance | ValidateLicensePartCompliance
        $LicensePart.serialNumber | Should Match ".+"
    }
}

function ValidateLicensePartCompliance {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$False,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="License part compliance to be verified")][PSObject]$LicensePartCompliance
    )

    Process {
        $LicensePartCompliance.maxQuantity | Should BeOfType Int
        $LicensePartCompliance.actualQuantity | Should BeOfType Int
        $LicensePartCompliance.quantityUnit | Should Match ".+"
        $LicensePartCompliance.quantityUnitDisplay | Should Match ".+"
    }
}

function ValidateBackup {
    [CmdletBinding()]
        
    PARAM (
    [parameter(Mandatory=$False,
                Position=0,
                ValueFromPipeline=$True,
                HelpMessage="Backup to be verified")][PSObject]$Backup
    )

    Process {
        $Backup.Date | Should BeOfType DateTime
        Test-Path $Backup.FilePath | Should Be $True
        [URI]::IsWellFormedUriString($Backup.URI,[URIKind]::Absolute) | Should Be $True
    }
}

### Begin of tests ###

Describe "OCI server connection management" {
    BeforeEach {
        $OciServer = $null
        $Global:CurrentOciServer = $null
    }

    Context "initiating a connection to an OnCommand Insight Server" {
        it "succeeds with parameters Name, Credential, Insecure" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure
            $OciServer.Name | Should Be $OciServerName
            $Global:CurrentOciServer | Should Be $OciServer
        }

        it "succeeds when forcing HTTPS" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure -HTTPS
            $OciServer.Name | Should Be $OciServerName
            $Global:CurrentOciServer | Should Be $OciServer
        }

        it "succeeds when timezone is set to UTC" {
            $Timezone = [TimeZoneInfo]::UTC
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure -Timezone $Timezone
            $OciServer.Name | Should Be $OciServerName
            $OciServer.Timezone | Should Be $Timezone
            $Global:CurrentOciServer | Should Be $OciServer
        }

        it "succeeds when transient OCI Server object is requested" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Transient -Insecure
            $OciServer.Name | Should Be $OciServerName
            $Global:CurrentOciServer | Should BeNullOrEmpty
        }
    }
}

Describe "License management" {
    BeforeEach {
        $OciServer = $null
        $Global:CurrentOciServer = $null
    }

    AfterEach {
        $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure -Transient
        $Licenses = Get-Content -Path .\demodb\ValidLicenses.txt
        Replace-OciLicenses -Licenses $Licenses -Server $OciServer
    }

    Context "replacing licenses" {
        it "succeeds with valid license" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure
            $ValidLicenses = Get-Content -Path .\demodb\ValidLicenses.txt
            Replace-OciLicenses -Licenses $ValidLicenses
            $Licenses = Get-OciLicenses
            $Licenses.serialNumber | Should Be $ValidLicenses[0].Substring(29,32)
        }

        it "fails with expired license" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure
            $InvalidLicenses = Get-Content -Path .\demodb\InvalidLicenses.txt
            { Replace-OciLicenses -Licenses $InvalidLicenses } | Should Throw
        }

        it "succeeds with valid license and transient OCI Server" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure -Transient
            $ValidLicenses = Get-Content -Path .\demodb\ValidLicenses.txt
            Replace-OciLicenses -Licenses $ValidLicenses -Server $OciServer
            $Licenses = Get-OciLicenses -Server $OciServer
            $Licenses.serialNumber | Should Be $ValidLicenses[0].Substring(29,32)
        }
    }

    Context "updating licenses" {
        it "succeeds with valid license" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure
            $PreviousLicenses = Get-OciLicenses
            $ValidLicense = Get-Content -Path .\demodb\ValidLicenses.txt | Select-Object -first 1
            $Licenses = Update-OciLicenses -Licenses $ValidLicense
            $PreviousLicenses.licenseParts.Count | Should Be $Licenses.licenseParts.Count
        }

        it "fails with expired license" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure
            $ExpiredLicense = Get-Content -Path .\demodb\InvalidLicenses.txt | Where-Object { $_.substring(6,4) -match "IDIS" }
            { Update-OciLicenses -Licenses $ExpiredLicense } | Should Throw
        }

        it "succeeds with valid license and transient OCI Server" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure -Transient
            $PreviousLicenses = Get-OciLicenses -Server $OciServer
            $ValidLicense = Get-Content -Path .\demodb\ValidLicenses.txt | Select-Object -first 1
            $Licenses = Update-OciLicenses -Licenses $ValidLicense -Server $OciServer
            $PreviousLicenses.licenseParts.Count | Should Be $Licenses.licenseParts.Count
        }
    }

    Context "retrieving licenses" {
        it "succeeds with no parameters" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure
            $Licenses = Get-OciLicenses
            $Licenses | ValidateLicense
        }

        it "succeeds with transient OCI Server" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure -HTTPS
            $OciServer.Name | Should Be $OciServerName
            $Global:CurrentOciServer | Should Be $OciServer
        }
    }
}

Describe "OCI server backup / restore" {
    BeforeEach {
        $OciServer = $null
        $Global:CurrentOciServer = $null
    }

    Context "restore" {
        it "succeeds when restoring Demo DB" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            Restore-OciBackup -FilePath .\demodb\Backup_Demo_V7-3-0_B994_D20170405_1604_7562582910350986847.zip

            sleep 300

            # ensure that datasources do not try to discover anything as this is a demo DB
            $null = $Datasources | Suspend-OciDatasource -Days 999

            # TODO: remove once DemoDB has been fixed
            # fix for invalid datasource foundation IP in Demo DB
            $Datasources = Get-OciDatasources -config
            # change , to . in foundation IP
            $Datasources | ? { $_.foundationIp -match "," } | % { $_.config.foundation.attributes.ip = $_.config.foundation.attributes.ip -replace ",","." }
            # change invalid datasource names
            $Datasources | ? { $_.name -match "-" } | % { $_.name = $_.name -replace "-","_" }
            $Datasources = $Datasources | Update-OciDataSource

            $Datasources.Count | should BeGreaterThan 0
            $Datasources | ValidateDatasource
        }

        it "succeeds when restoring Demo DB with transient OCI server" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure -HTTPS -Transient

            Restore-OciBackup -FilePath .\demodb\Backup_Demo_V7-3-0_B994_D20170405_1604_7562582910350986847.zip -Server $OciServer

            sleep 300

            # ensure that datasources do not try to discover anything as this is a demo DB
            $null = $Datasources | Suspend-OciDatasource -Days 999 -Server $OciServer

            # TODO: remove once DemoDB has been fixed
            # fix for invalid datasource foundation IP in Demo DB
            $Datasources = Get-OciDatasources -config -Server $OciServer
            # change , to . in foundation IP
            $Datasources | ? { $_.foundationIp -match "," } | % { $_.config.foundation.attributes.ip = $_.config.foundation.attributes.ip -replace ",","." }
            # change invalid datasource names
            $Datasources | ? { $_.name -match "-" } | % { $_.name = $_.name -replace "-","_" }
            $Datasources = $Datasources | Update-OciDataSource -Server $OciServer

            $Datasources = Get-OciDatasources -Server $OciServer
            $Datasources.Count | should BeGreaterThan 0
            $Datasources | ValidateDatasource
        }
    }

    Context "backup" {
        it "succeeds without parameters" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $StartTime = Get-Date

            sleep 60

            $Backup = Get-OciBackup -Path $env:TEMP
            $Backup | ValidateBackup
            $Backup.Date | Should BeGreaterThan $StartTime
            $Backup.FilePath | Should Match ([regex]::Escape($env:TEMP))
            $Backup.URI | Should Match $OciServer.Name

            Remove-Item -Path $Backup.FilePath
        }

        it "succeeds with transient OCI server" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure -Transient

            $StartTime = Get-Date

            sleep 60

            $Backup = Get-OciBackup -Path $env:TEMP -Server $OciServer
            $Backup | ValidateBackup
            $Backup.Date | Should BeGreaterThan $StartTime
            $Backup.FilePath | Should Match ([regex]::Escape($env:TEMP))
            $Backup.URI | Should Match $OciServer.Name

            Remove-Item -Path $Backup.FilePath
        }
    }

    Context "backup followed by restore" {
        it "succeeds without parameters" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $StartTime = Get-Date

            # retrieve datasources to compare them after restore
            $Datasources = Get-OciDatasources -devices -config -acquisitionUnit

            sleep 60

            $Backup = Get-OciBackup -Path $env:TEMP
            $Backup | ValidateBackup
            $Backup.Date | Should BeGreaterThan $StartTime
            $Backup.FilePath | Should Match ([regex]::Escape($env:TEMP))
            $Backup.URI | Should Match $OciServer.Name

            sleep 5

            $Backup | Restore-OciBackup

            Remove-Item -Path $Backup.FilePath

            sleep 300

            # ensure that datasources do not try to discover anything as this is a demo DB
            $null = $Datasources | Suspend-OciDatasource -Days 999

            $DatasourcesAfterRestore = Get-OciDatasources -devices -config -acquisitionUnit

            $DatasourcesAfterRestore.Count | Should Be $Datasources.Count
        }
    }
}

Describe "Acquisition unit management" {

    BeforeEach {
        $OciServer = $null
        $Global:CurrentOciServer = $null
        $AcquisitionUnits = $null
    }

    Context "retrieving acquisition units" {
        it "succeeds with no parameters" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $AcquisitionUnits = Get-OciAcquisitionUnits
            $AcquisitionUnits | Should Not BeNullOrEmpty
            $AcquisitionUnits | ValidateAcquisitionUnit
        }

        it "succeeds with getting datasources" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $AcquisitionUnits = Get-OciAcquisitionUnits -datasources
            $AcquisitionUnits | Should Not BeNullOrEmpty
            $AcquisitionUnits | ValidateAcquisitionUnit
            $AcquisitionUnits.datasources | ValidateDatasource
        }

        it "succeeds with transient OCI Server" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure -Transient
            $Global:CurrentOciServer | Should BeNullOrEmpty

            $AcquisitionUnits = Get-OciAcquisitionUnits -Server $OciServer
            $AcquisitionUnits | Should Not BeNullOrEmpty
            $AcquisitionUnits | ValidateAcquisitionUnit
        }
    }

    Context "retrieving single acquisition unit" {
        it "succeeds with no parameters" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $AcquisitionUnits = Get-OciAcquisitionUnits
            $AcquisitionUnits | Should Not BeNullOrEmpty
            $AcquisitionUnit = $AcquisitionUnits | Get-OciAcquisitionUnit
            $AcquisitionUnit | ValidateAcquisitionUnit
        }

        it "succeeds with getting datasources" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $AcquisitionUnits = Get-OciAcquisitionUnits -datasources
            $AcquisitionUnits | Should Not BeNullOrEmpty
            $AcquisitionUnit = $AcquisitionUnits | Get-OciAcquisitionUnit -datasources
            $AcquisitionUnit | ValidateAcquisitionUnit
            $AcquisitionUnit.datasources | ValidateDatasource
        }

        it "succeeds with transient OCI Server" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure -Transient
            $Global:CurrentOciServer | Should BeNullOrEmpty

            $AcquisitionUnits = Get-OciAcquisitionUnits -Server $OciServer
            $AcquisitionUnits | Should Not BeNullOrEmpty
            $AcquisitionUnit = $AcquisitionUnits | Get-OciAcquisitionUnit -Server $OciServer
            $AcquisitionUnit | ValidateAcquisitionUnit
        }
    }

    Context "retrieving datasources of single acquisition unit" {
        it "succeeds with no parameters" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $AcquisitionUnits = Get-OciAcquisitionUnits
            $AcquisitionUnits | Should Not BeNullOrEmpty
            $Datasources = $AcquisitionUnits | Get-OciDatasourcesByAcquisitionUnit
            $Datasources | ValidateDatasource
        }

        it "succeeds when requesting related acquisition units" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $AcquisitionUnits = Get-OciAcquisitionUnits
            $AcquisitionUnits | Should Not BeNullOrEmpty
            $Datasources = $AcquisitionUnits | Get-OciDatasourcesByAcquisitionUnit -acquisitionUnit
            $Datasources | ValidateDatasource
            $Datasources.acquisitionUnit | ValidateAcquisitionUnit
        }
        
        it "succeeds when requesting related notes" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $AcquisitionUnits = Get-OciAcquisitionUnits
            $AcquisitionUnits | Should Not BeNullOrEmpty
            $Datasources = $AcquisitionUnits | Get-OciDatasourcesByAcquisitionUnit -note
            $Datasources | ValidateDatasource
            $Datasources | % { [bool]($_.PSobject.Properties.name -match "note") | Should Be $true }
        }

        it "succeeds when requesting related changes" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $AcquisitionUnits = Get-OciAcquisitionUnits
            $AcquisitionUnits | Should Not BeNullOrEmpty
            $Datasources = $AcquisitionUnits | Get-OciDatasourcesByAcquisitionUnit -changes
            $Datasources | ValidateDatasource
            $Datasources.changes | ValidateDatasourceChange
        }

        it "succeeds when requesting related packages" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $AcquisitionUnits = Get-OciAcquisitionUnits
            $AcquisitionUnits | Should Not BeNullOrEmpty
            $Datasources = $AcquisitionUnits | Get-OciDatasourcesByAcquisitionUnit -packages
            $Datasources | ValidateDatasource
            $Datasources.packages | ValidatePackage
        }

        it "succeeds when requesting related events" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $AcquisitionUnits = Get-OciAcquisitionUnits
            $AcquisitionUnits | Should Not BeNullOrEmpty
            $Datasources = $AcquisitionUnits | Get-OciDatasourcesByAcquisitionUnit -events
            $Datasources | ValidateDatasource
            $Datasources.events | ? { $_ } | ValidateDatasourceEvent
        }

        it "succeeds when requesting related devices" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $AcquisitionUnits = Get-OciAcquisitionUnits
            $AcquisitionUnits | Should Not BeNullOrEmpty
            $Datasources = $AcquisitionUnits | Get-OciDatasourcesByAcquisitionUnit -devices
            $Datasources | ValidateDatasource
            $Datasources.devices | ? { $_ } | ValidateDevice
        }

        it "succeeds when requesting related devices" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $AcquisitionUnits = Get-OciAcquisitionUnits
            $AcquisitionUnits | Should Not BeNullOrEmpty
            $Datasources = $AcquisitionUnits | Get-OciDatasourcesByAcquisitionUnit -config
            $Datasources | ValidateDatasource
            $Datasources.config | ? { $_ } | ValidateDatasourceConfig
        }

        it "succeeds with transient OCI Server" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure -Transient
            $Global:CurrentOciServer | Should BeNullOrEmpty

            $AcquisitionUnits = Get-OciAcquisitionUnits -Server $OciServer
            $AcquisitionUnits | Should Not BeNullOrEmpty
            $Datasources = $AcquisitionUnits | Get-OciDatasourcesByAcquisitionUnit -Server $OciServer
            $Datasources | ValidateDatasource
        }     
    }
}

Describe "Datasource management" {

    BeforeEach {
        $OciServer = $null
        $Global:CurrentOciServer = $null
        $Datasources = $null
    }

    Context "retrieving datasource types" {
        it "succeeds with no parameters" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $DatasourceTypes = Get-OciDatasourceTypes
            $DatasourceTypes | Should Not BeNullOrEmpty
            $DatasourceTypes | ValidateDatasourceType
        }

        it "succeeds when retrieving one by one" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            Get-OciDatasourceTypes | Get-OciDatasourceType | ValidateDatasourceType
        }

        it "succeeds with transient OCI Server" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure -Transient
            $Global:CurrentOciServer | Should BeNullOrEmpty

            $DatasourceTypes = Get-OciDatasourceTypes -Server $OciServer
            $DatasourceTypes | Should Not BeNullOrEmpty
            $DatasourceTypes = $DatasourceTypes | Get-OciDatasourceType -Server $OciServer
            $DatasourceTypes | Should Not BeNullOrEmpty
            $DatasourceTypes | ValidateDatasourceType
        }
    }

    Context "retrieving datasources" {
        it "succeeds with no parameters" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $Datasources = Get-OciDatasources
            $Datasources | Should Not BeNullOrEmpty
            $Datasources | ValidateDatasource
        }

        it "succeeds when retrieving one by one" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            Get-OciDatasources | Get-OciDatasource | ValidateDatasource
        }

        it "succeeds with transient OCI Server" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure -Transient
            $Global:CurrentOciServer | Should BeNullOrEmpty

            $Datasources = Get-OciDatasources -Server $OciServer
            $Datasources | Should Not BeNullOrEmpty
            $Datasources = $Datasources | Get-OciDatasource -Server $OciServer
            $Datasources | Should Not BeNullOrEmpty
            $Datasources | ValidateDatasource
        }
    }

    Context "modifying datasources" {
        it "succeeds when modifying name" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $Datasources = Get-OciDatasources
            $Datasources | Should Not BeNullOrEmpty
            
            foreach ($Datasource in $Datasources) {
                $CurrentName = $Datasource.name
                $NewName = ($Datasource.name -replace "-","") + "test"
                $Datasource = $Datasource | Update-OciDataSource -name $NewName

                $Datasource | ValidateDatasource
                $Datasource.Name | Should Be $NewName

                sleep 1

                $Datasource = $Datasource | Update-OciDataSource -name $CurrentName

                $Datasource | ValidateDatasource
                $Datasource.Name | Should Be $CurrentName
            }
        }

        it "succeeds when modifying acquisition unit" {
            Write-Warning "Checking modification of acquisition unit not implemented"
        }

        it "succeeds when modifying poll interval in configuration" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $Datasources = Get-OciDatasources -config
            $Datasources | Should Not BeNullOrEmpty

            foreach ($Datasource in $Datasources) {
                if ($Datasource.config.foundation.attributes.poll) {
                    $CurrentPollInterval = 0 + $Datasource.config.foundation.attributes.poll
                    $NewPollInterval = $CurrentPollInterval + 120

                    $Datasource.config.foundation.attributes.poll = $NewPollInterval
                    $Datasource = $Datasource | Update-OciDataSource -config $Datasource.config
                    $Datasource | ValidateDatasource
                    $Datasource.config.foundation.attributes.poll | Should Be $NewPollInterval

                    $Datasource.config.foundation.attributes.poll = $CurrentPollInterval
                    $Datasource = $Datasource | Update-OciDataSource -config $Datasource.config
                    $Datasource | ValidateDatasource
                    $Datasource.config.foundation.attributes.poll | Should Be $CurrentPollInterval
                }
                elseif ($Datasource.config.cloud.attributes.poll) {
                    $CurrentPollInterval = 0 + $Datasource.config.cloud.attributes.poll
                    $NewPollInterval = $CurrentPollInterval + 120

                    $Datasource.config.cloud.attributes.poll = $NewPollInterval
                    $Datasource = $Datasource | Update-OciDataSource -config $Datasource.config
                    $Datasource | ValidateDatasource
                    $Datasource.config.cloud.attributes.poll | Should Be $NewPollInterval

                    $Datasource.config.cloud.attributes.poll = $CurrentPollInterval
                    $Datasource = $Datasource | Update-OciDataSource -config $Datasource.config
                    $Datasource | ValidateDatasource
                    $Datasource.config.cloud.attributes.poll | Should Be $CurrentPollInterval
                }

            }
        }

        it "succeeds when modifying name using transient OCI Server" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure -Transient
            $Global:CurrentOciServer | Should BeNullOrEmpty

            $Datasources = Get-OciDatasources -Server $OciServer
            $Datasources | Should Not BeNullOrEmpty
            
            foreach ($Datasource in $Datasources) {
                $CurrentName = $Datasource.name
                $NewName = $Datasource.name + "test"
                $Datasource = $Datasource | Update-OciDataSource -name $NewName -Server $OciServer

                $Datasource | ValidateDatasource
                $Datasource.Name | Should Be $NewName

                sleep 2

                $Datasource = $Datasource | Update-OciDataSource -name $CurrentName -Server $OciServer

                $Datasource | ValidateDatasource
                $Datasource.Name | Should Be $CurrentName
            }
        }
    }

    Context "creating datasources" {
        it "succeeds for all datasource types" {
             $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

             $User = "test"
             $IP = "127.0.0.1"
             $Password = "test"

             $DatasourceTypes = Get-OciDatasourceTypes

             $AcquisitionUnit = Get-OciAcquisitionUnits | select -first 1

             foreach ($DatasourceType in $DatasourceTypes) {
                # TODO: Implement testing of SNMP Integration, until then, skip it
                if ($DatasourceType.name -eq "integration_snmp") {
                    Continue
                }
                if ($DatasourceType.vendorModels.count -gt 1) {
                    $DatasourceType.vendorModels = $DatasourceType.vendorModels | select -Last 1
                }
                $Datasource = New-OciDatasource -type $DatasourceType -name "test" -acquisitionUnit $AcquisitionUnit
                if ($Datasource.config.foundation) {
                    if ($Datasource.config.foundation.attributes.PSobject.Properties.name -match "ip") {
                        $Datasource.config.foundation.attributes.ip = $IP
                    }
                    if ($Datasource.config.foundation.attributes.PSobject.Properties.name -match "user") {
                        $Datasource.config.foundation.attributes.user = $User
                    }
                    if ($Datasource.config.foundation.attributes.PSobject.Properties.name -match "password") {
                        $Datasource.config.foundation.attributes.password = $Password
                    }
                }
                if ($Datasource.config.performance) {
                    $Datasource.config.performance.attributes.enabled = $true
                }
                if ($Datasource.config.storageperformance) {
                    $Datasource.config.storageperformance.attributes.enabled = $true
                }
                if ($Datasource.config.hostvirtualization) {
                    $Datasource.config.hostvirtualization.attributes.enabled = $true
                }
                if ($Datasource.config.cloud) {
                    if ($Datasource.config.cloud.attributes.PSobject.Properties.name -match "ip") {
                        $Datasource.config.cloud.attributes.ip = $IP
                    }
                    if ($Datasource.config.cloud.attributes.PSobject.Properties.name -match "user") {
                        $Datasource.config.cloud.attributes.user = $User
                    }
                    if ($Datasource.config.cloud.attributes.PSobject.Properties.name -match "password") {
                        $Datasource.config.cloud.attributes.password = $Password
                    }
                }
                $Datasource = Add-OciDatasource -name $Datasource.name -acquisitionUnit $AcquisitionUnit -config $Datasource.config
                sleep 2
                $null = $Datasource | Remove-OciDatasource
                sleep 3
             }
        }
    }
}

Describe "Annotation management" {

    BeforeEach {
        $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure
        $null = Get-OciAnnotations | ? { $_.Name -eq "OciCmdletTest" } | Remove-OciAnnotation
        $OciServer = $null
        $Global:CurrentOciServer = $null
        $Annotation = $null
    }

    Context "adding and removing annotations" {
        it "succeeds for type BOOLEAN" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $Annotation = Add-OciAnnotation -Name "OciCmdletTest" -Type BOOLEAN
            $Annotation | ValidateAnnotation
            $Annotation | Remove-OciAnnotation
        }

        it "succeeds for type DATE" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $Annotation = Add-OciAnnotation -Name "OciCmdletTest" -Type DATE
            $Annotation | ValidateAnnotation
            $Annotation | Remove-OciAnnotation
        }

        it "succeeds for type FIXED_ENUM" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $Annotation = Add-OciAnnotation -Name "OciCmdletTest" -Type FIXED_ENUM -enumValues @(@{name="key1";label="label of key 1"},@{name="key2";label="label of key 2"})
            $Annotation | ValidateAnnotation
            $Annotation | Remove-OciAnnotation
        }

        it "succeeds for type FLEXIBLE_ENUM" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $Annotation = Add-OciAnnotation -Name "OciCmdletTest" -Type FLEXIBLE_ENUM -enumValues @(@{name="key1";label="label of key 1"},@{name="key2";label="label of key 2"})
            $Annotation | ValidateAnnotation
            $Annotation | Remove-OciAnnotation
        }

        it "succeeds for type NUMBER" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $Annotation = Add-OciAnnotation -Name "OciCmdletTest" -Type NUMBER
            $Annotation | ValidateAnnotation
            $Annotation | Remove-OciAnnotation
        }

        it "succeeds with description" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $Annotation = Add-OciAnnotation -Name "OciCmdletTest" -Type BOOLEAN -Description "description"
            $Annotation.description | Should Be "description"
            $Annotation | ValidateAnnotation
            $Annotation | Remove-OciAnnotation
        }

        it "succeeds with transient OCI Server" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure -Transient
            $CurrentOciServer | Should BeNullOrEmpty

            $Annotation = Add-OciAnnotation -Name "OciCmdletTest" -Type BOOLEAN -Server $OciServer
            $Annotation | ValidateAnnotation
            $Annotation | Remove-OciAnnotation -Server $OciServer
        }
    }
}

Describe "Application management" {

    BeforeEach {
        $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure
        $null = Get-OciApplications | ? { $_.Name -eq "OciCmdletTest" } | Remove-OciApplication
        $null = Get-OciBusinessEntities | ? { $_.Tenant -eq "OciCmdletTest" } | Remove-OciBusinessEntity
        $OciServer = $null
        $Global:CurrentOciServer = $null
        $Application = $null
    }

    Context "Add and remove application" {
        it "succeeds using only name parameter" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $Application = Add-OciApplication -Name "OciCmdletTest"
            $Application | ValidateApplication
            $Application | Remove-OciApplication
        }

        it "succeeds with priority" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $Application = Add-OciApplication -Name "OciCmdletTest" -priority Critical
            $Application | ValidateApplication
            $Application.priority | Should Be "Critical"
            $Application | Remove-OciApplication
        }

        it "succeeds when associating business entity" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $BusinessEntity = Add-OciBusinessEntity -Tenant "OciCmdletTest"

            $Application = Add-OciApplication -Name "OciCmdletTest" -businessEntity $BusinessEntity.id
            $Application | ValidateApplication
            $Application.businessEntity.id | Should Be $BusinessEntity.id
            $Application | Remove-OciApplication

            $BusinessEntity | Remove-OciBusinessEntity
        }

        it "succeeds with ignoreShareViolations switch" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $Application = Add-OciApplication -Name "OciCmdletTest" -ignoreShareViolations
            $Application | ValidateApplication
            $Application.ignoreShareViolations | Should Be $true
            $Application | Remove-OciApplication
        }

        it "succeeds when list of compute resources is requested" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $Application = Add-OciApplication -Name "OciCmdletTest" -ComputeResources
            $Application | ValidateApplication
            $Application.computeResources | Should BeNullOrEmpty
            $Application | Remove-OciApplication
        }

        it "succeeds when list of storage resources is requested" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $Application = Add-OciApplication -Name "OciCmdletTest" -StorageResources
            $Application | ValidateApplication
            $Application.computeResources | Should BeNullOrEmpty
            $Application | Remove-OciApplication
        }

        it "succeeds with transient OCI Server" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure -Transient
            $Global:CurrentOciServer | Should BeNullOrEmpty

            $Application = Add-OciApplication -Name "OciCmdletTest" -Server $OciServer
            $Application | ValidateApplication
            $Application.computeResources | Should BeNullOrEmpty
            $Application | Remove-OciApplication -Server $OciServer
        }
    }

    Context "Adding, updating and deleting application" {
        it "succeeds when updating priority" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $Application = Add-OciApplication -Name "OciCmdletTest"
            $Application = $Application | Update-OciApplication -priority Critical
            $Application | ValidateApplication
            $Application.priority | Should Be "Critical"
            $Application | Remove-OciApplication
        }

        it "succeeds when associating business entity" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $BusinessEntity = Add-OciBusinessEntity -Tenant "OciCmdletTest"

            $Application = Add-OciApplication -Name "OciCmdletTest"
            $Application = $Application | Update-OciApplication -businessEntity $BusinessEntity.id
            $Application | ValidateApplication
            $Application.businessEntity.id | Should Be $BusinessEntity.id
            $Application | Remove-OciApplication

            $BusinessEntity | Remove-OciBusinessEntity
        }

        it "succeeds with ignoreShareViolations switch" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $Application = Add-OciApplication -Name "OciCmdletTest"
            $Application = $Application | Update-OciApplication -ignoreShareViolations
            $Application | ValidateApplication
            $Application.ignoreShareViolations | Should Be $true
            $Application | Remove-OciApplication
        }

        it "succeeds when list of compute resources is requested" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $Application = Add-OciApplication -Name "OciCmdletTest"
            $Application = $Application | Update-OciApplication -ComputeResources
            $Application | ValidateApplication
            $Application.computeResources | Should BeNullOrEmpty
            $Application | Remove-OciApplication
        }

        it "succeeds when list of storage resources is requested" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $Application = Add-OciApplication -Name "OciCmdletTest" -StorageResources
            $Application = $Application | Update-OciApplication -StorageResources
            $Application | ValidateApplication
            $Application.computeResources | Should BeNullOrEmpty
            $Application | Remove-OciApplication
        }

        it "succeeds with transient OCI Server" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure -Transient
            $Global:CurrentOciServer | Should BeNullOrEmpty

            $Application = Add-OciApplication -Name "OciCmdletTest" -Server $OciServer
            $Application = $Application | Update-OciApplication -Server $OciServer
            $Application | ValidateApplication
            $Application.computeResources | Should BeNullOrEmpty
            $Application | Remove-OciApplication -Server $OciServer
        }
    }
}

Describe "Business entity management" {

    BeforeEach {
        $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure
        $null = Get-OciAnnotations | ? { $_.Name -eq "OciCmdletTest" } | Remove-OciAnnotation
        $OciServer = $null
        $Global:CurrentOciServer = $null
        $BusinessEntity = $null
    }

    Context "adding and removing business entities" {
        it "succeeds with only tenant" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $Tenant = "OciCmdletTest"
            $BusinessEntity = Add-OciBusinessEntity -Tenant $Tenant
            $BusinessEntity | ValidateBusinessEntity
            $BusinessEntity.tenant | Should Be $Tenant
            $BusinessEntity | Remove-OciBusinessEntity
        }

        it "succeeds with parameters tenant, LineOfBusiness, BusinessUnit and Project" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $Tenant = "OciCmdletTest"
            $LineOfBusiness = "OciCmdletTest"
            $BusinessUnit = "OciCmdletTest"
            $Project = "OciCmdletTest"

            $BusinessEntity = Add-OciBusinessEntity -Tenant $Tenant -LineOfBusiness $LineOfBusiness -BusinessUnit $BusinessUnit -Project $Project
            $BusinessEntity | ValidateBusinessEntity
            $BusinessEntity.tenant | Should Be $Tenant
            $BusinessEntity | Remove-OciBusinessEntity
        }

        it "succeeds with transient OCI Server" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure -Transient

            $Tenant = "OciCmdletTest"
            $BusinessEntity = Add-OciBusinessEntity -Tenant $Tenant -Server $OciServer
            $BusinessEntity | ValidateBusinessEntity
            $BusinessEntity.tenant | Should Be $Tenant
            $BusinessEntity | Remove-OciBusinessEntity -Server $OciServer
        }
    }
}

Describe "Datastore management" {

    BeforeEach {
        $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure
        $null = Get-OciAnnotations | ? { $_.Name -eq "OciCmdletTest" } | Remove-OciAnnotation
        $OciServer = $null
        $Global:CurrentOciServer = $null        
    }

    Context "retrieving datastores" {
        it "succeeds with no parameters" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $Datastores = Get-OciDatastores
            @($Datastores).Count | Should BeGreaterThan 0
            $Datastores | ValidateDatastore
        }

        it "succeeds with parameter limit and offset" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $DatastoreCount = Get-OciDatastoreCount

            $Datastores = @()
            for ($i=0;$i -le $DatastoreCount;$i++) {
                $Datastores += Get-OciDatastores -limit 1 -offset $i
            }
            @(($Datastores.id | select -Unique)).Count | Should Be $DatastoreCount
            $Datastores | ValidateDatastore
        }

        it "succeeds with transient OCI Server" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure -Transient

            $Datastores = Get-OciDatastores -Server $OciServer
            @($Datastores).Count | Should BeGreaterThan 0
            $Datastores | ValidateDatastore
        }
    }

    Context "retrieving datastore count" {
        it "succeeds with no parameters" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $Datastores = Get-OciDatastores
            $Count = Get-OciDatastoreCount
            @($Datastores).Count | Should Be $Count
        }

        it "succeeds with transient OCI Server" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure -Transient

            $Datastores = Get-OciDatastores -Server $OciServer
            $Count = Get-OciDatastoreCount -Server $OciServer
            @($Datastores).Count | Should Be $Count
        }
    }

    Context "retrieving single datastore" {
        it "succeeds with no parameters" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $Datastores = Get-OciDatastores
            $Count = @($Datastores).Count
            $Datastores = $Datastores | Get-OciDatastore
            @($Datastores).Count | Should Be $Count
            $Datastores | ValidateDatastore
        }

        it "succeeds with transient OCI Server" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure -Transient

            $Datastores = Get-OciDatastores -Server $OciServer
            $Count = @($Datastores).Count
            $Datastores = $Datastores | Get-OciDatastore -Server $OciServer
            @($Datastores).Count | Should Be $Count
            $Datastores | ValidateDatastore
        }
    }

    Context "managing annotations of datastores" {
        it "succeeds with no parameters" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $Datastores = Get-OciDatastores
            @($Datastores).Count | Should BeGreaterThan 0
            $Datastores | ValidateDatastore
        }

        it "succeeds with parameter limit and offset" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $DatastoreCount = Get-OciDatastoreCount

            $Datastores = @()
            for ($i=0;$i -le $DatastoreCount;$i++) {
                $Datastores += Get-OciDatastores -limit 1 -offset $i
            }
            @(($Datastores.id | select -Unique)).Count | Should Be $DatastoreCount
            $Datastores | ValidateDatastore
        }

        it "succeeds with transient OCI Server" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure -Transient

            $Datastores = Get-OciDatastores -Server $OciServer
            @($Datastores).Count | Should BeGreaterThan 0
            $Datastores | ValidateDatastore
        }
    }

    Context "retrieving related objects" {
        it "succeeds when retrieving related datasources" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $Datastores = Get-OciDatastores
            $Datasources = $Datastores | Get-OciDatasourcesByDataStore
            $Datasources | ValidateDatasource
        }

        it "succeeds when retrieving related datasources with transient OCI Server" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure -Transient

            $Datasources = Get-OciDatastores -Server $OciServer | Get-OciDatasourcesByDataStore -Server $OciServer 
            $Datasources | ValidateDatasource
        }

        it "succeeds when retrieving related hosts" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $Hosts = Get-OciDatastores | Get-OciHostsByDataStore
            $Hosts | ValidateHost
        }

        it "succeeds when retrieving related hosts with parameters performance, fromTime, toTime, ports, storageResources, fileSystems, applications, virtualMachines, dataCenter, annotations, clusterHosts and datasources" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $Hosts = Get-OciDatastores | Get-OciHostsByDataStore -performance -fromTime (Get-Date).AddDays(-1) -toTime (Get-Date) -ports -storageResources -fileSystems -applications -virtualMachines -dataCenter -annotations -clusterHosts -datasources
            $Hosts | ValidateHost
            $Hosts.performance | ValidatePerformance
            $Hosts.storageResources | ValidateStorageResource
            $Hosts.fileSystems | ValidateFileSystem
            $Hosts.ports | ValidatePort
            $Hosts.applications | ValidateApplication
            $Hosts.virtualMachines | ValidateVirtualMachine
            $Hosts.clusterHosts | ValidateHost
            $Hosts.annotations | ValidateAnnotationValue
            $Hosts.datasources | ValidateDatasource
        }

        it "succeeds when retrieving related hosts with transient OCI Server" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure -Transient

            $Hosts = Get-OciDatastores -Server $OciServer  | Get-OciHostsByDataStore -Server $OciServer 
            $Hosts | ValidateHost
        }

        it "succeeds when retrieving related performance" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $Performance = Get-OciDatastores | Get-OciDatastorePerformance
            $Performance | ValidatePerformance
        }

        it "succeeds when retrieving related performance with parameters fromTime and toTime" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure

            $Performance = Get-OciDatastores | Get-OciDatastorePerformance -fromTime (Get-Date).AddDays(-1) -toTime (Get-Date)
            $Performance | ValidatePerformance
        }

        it "succeeds when retrieving related performance with transient OCI Server" {
            $OciServer = Connect-OciServer -Name $OciServerName -Credential $OciCredential -Insecure -Transient

            $Performance = Get-OciDatastores -Server $OciServer  | Get-OciDatastorePerformance -Server $OciServer 
            $Performance | ValidatePerformance
        }
    }
}