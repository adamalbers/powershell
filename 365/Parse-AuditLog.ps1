$auditLogPath = 'AuditLog_2021-12-01_2022-02-19.csv'

$auditData = (Import-Csv $auditLogPath).AuditData | ConvertFrom-Json

$dataArray = [System.Collections.ArrayList]::new()
$ErrorActionPreference = 'SilentlyContinue'
foreach ($data in $auditData) {
    $dataObject = [PSCustomObject]@{
        CreationTime            = $data.CreationTime
        Id                      = $data.Id
        Operation               = $data.Operation
        OrganizationId          = $data.OrganizationId
        RecordType              = $data.RecordType
        ResultStatus            = $data.ResultStatus
        UserKey                 = $data.UserKey
        UserType                = $data.UserType
        Version                 = $data.Version
        Workload                = $data.Workload
        ClientIP                = $data.ClientIP
        ObjectId                = $data.ObjectId
        UserId                  = $data.UserId
        AADEventType            = $data.AzureActiveDirectoryEventType
        ResultStatusDetail      = $data.ExtendedProperties.Value[0]
        UserAgent               = $data.ExtendedProperties.Value[1]
        UserAuthMethod          = $data.ExtendedProperties.Value[2]
        RequestType             = $data.ExtendedProperties.Value[3]
        ActorID                 = $data.Actor.ID[0]
        ActorUPN                = $data.Actor.ID[1]
        ActorContextId          = $data.ActorContextId
        ActorIpAddress          = $data.ActorIpAddress
        InterSystemsId          = $data.InterSystemsId
        IntraSystemsId          = $data.IntraSystemsId
        TargetId                = $data.Target.Id[0]
        TargetContextId         = $data.TargetContextId
        ApplicationId           = $data.ApplicationId
        DeviceOS                = $data.DeviceProperties.Value[0]
        DeviceBrowser           = $data.DeviceProperties.Value[1]
        DeviceCompliant         = $data.DeviceProperties.Value[2]
        DeviceSessionId         = $data.DeviceProperties.Value[3]
        ErrorNumber             = $data.ErrorNumber
    }

    $dataArray.Add($dataObject) | Out-Null
}