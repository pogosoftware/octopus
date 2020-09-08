###################################################################################################
### CONFIGURATION
###################################################################################################
$OctopusURI = "http://192.168.33.10:8080"

$OctopusUsername = "admin"
$OctopusPassword = Get-Content -Path ..\secrets\admin_password

$SpaceName       = "Default"
$EnvironmentName = "dev"

$WorkerPoolName = "dev"

$ServiceAccountUsername    = "tentacle_dev"
$ServiceAccountDisplayName = "Tentacle DEV"

$TeamName = "Tentacles"


###################################################################################################
### ADDING LIBRARIES
###################################################################################################
Add-Type -Path "Newtonsoft.Json.dll"
Add-Type -Path "Octopus.Client.dll"


###################################################################################################
### CREATING A CONNECTION
###################################################################################################
$endpoint   = new-object Octopus.Client.OctopusServerEndpoint $OctopusURI
$repository = new-object Octopus.Client.OctopusRepository $endpoint


###################################################################################################
### LOGGING IN TO OCTOPUS
###################################################################################################
$LoginObj = New-Object Octopus.Client.Model.LoginCommand 
$LoginObj.Username = $OctopusUsername
$LoginObj.Password = $OctopusPassword

$repository.Users.SignIn($LoginObj)


###################################################################################################
### CREATING AN ENVIRONMENT
###################################################################################################
$environmentResource             = New-Object Octopus.Client.Model.EnvironmentResource
$environmentResource.Name        = $EnvironmentName
$environmentResource.Description = "This is Developer environment"

$environment = $repository.Environments.Create($environmentResource)


###################################################################################################
### CREATING WORKER POOL
###################################################################################################
$workerPoolResource             = New-Object Octopus.Client.Model.WorkerPoolResource
$workerPoolResource.Name        = $WorkerPoolName
$workerPoolResource.Description = "Tentacle workers for development environment"

$repository.WorkerPools.Create($workerPoolResource)


###################################################################################################
### CREATE A SERVICE ACCOUNT
###################################################################################################
$serviceAccount       = $repository.Users.CreateServiceAccount($ServiceAccountUsername, $ServiceAccountDisplayName)
$serviceAccountApiKey = $repository.Users.CreateApiKey($serviceAccount, "Service Account used by dev tentacle")

Add-Content -NoNewline -Path ..\secrets\tentacle_dev_api_key -Value $serviceAccountApiKey.ApiKey


###################################################################################################
### CREATE ROLE FOR TENTACLE
###################################################################################################
$registerWorkerRole                         = New-Object Octopus.Client.Model.UserRoleResource
$registerWorkerRole.Description             = "This role is used by tentacle to register the VM in the Octopus Server."
$registerWorkerRole.Name                    = "RegisterWorkerInOctopus"
$registerWorkerRole.GrantedSpacePermissions = @("MachineCreate", "MachinePolicyView", "WorkerEdit", "WorkerView")

$tentacleRole = $repository.UserRoles.Create($registerWorkerRole)


###################################################################################################
### CREATE TENTACLE TEAM
###################################################################################################
$teamMembers = New-Object Octopus.Client.Model.ReferenceCollection
$teamMembers.Add($serviceAccount.Id)

$teamResource               = New-Object Octopus.Client.Model.TeamResource
$teamResource.Name          = $TeamName
$teamResource.Description   = "Team for tentacle service users"
$teamResource.MemberUserIds = $teamMembers

$team = $repository.Teams.Create($teamResource)


###################################################################################################
### ASSIGN ROLE TO TEAM
###################################################################################################
$space          = $repository.Spaces.FindByName($SpaceName)
$environmentIds = New-Object Octopus.Client.Model.ReferenceCollection
$environmentIds.Add($environment.Id)

$roleAssigment                = New-Object Octopus.Client.Model.ScopedUserRoleResource
$roleAssigment.TeamId         = $team.Id
$roleAssigment.UserRoleId     = $tentacleRole.Id
$roleAssigment.SpaceId        = $space.Id
$roleAssigment.EnvironmentIds = $environmentIds

$repository.ScopedUserRoles.Create($roleAssigment)