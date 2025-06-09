param (
    $AADSecret,
    $AADClientID,
    $TenantID,
    $SubscriptionID,
    $SqlServer,
    $SqlReadOnlyGroup,
    $SqlDbOwnerGroup ,
    $SqlDbOwnerUser,
    $SqlReadOnlyUser,
    $SqlAdAdminLogin,
    $SqlAdminPassword,
    $ExcludeUserFromRemoval,
    $UserDatabases
)

$connectionString = ('Server=tcp:{0},{1};Database={2};User ID={3};Password={4};Persist Security Info=False;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Authentication="Active Directory Password"' -f $SqlServer, 1433, '{0}', $SqlAdAdminLogin, $SqlAdminPassword)

$sqlQueryCreateUsers = @"
-- create readonly ad group if not exist
CREATE USER [$SqlReadOnlyGroup] FROM EXTERNAL PROVIDER; 
-- create dbowner ad group if not exist
CREATE USER [$SqlDbOwnerGroup] FROM EXTERNAL PROVIDER; 
-- create readonly user if not exist  
CREATE USER [$SqlReadOnlyUser] FROM EXTERNAL PROVIDER;
-- create dbowner user if not exist
CREATE USER [$SqlDbOwnerUser] FROM EXTERNAL PROVIDER; 
"@
$sqlQueryGrantPermissions = @"
print 'Current database - ' +  DB_NAME()
ALTER USER "$SqlDbOwnerGroup" WITH DEFAULT_SCHEMA = dbo;  
ALTER USER "$SqlDbOwnerUser" WITH DEFAULT_SCHEMA = dbo; 
-- grant permissions for user and group
-- db_owner
ALTER ROLE db_owner ADD MEMBER [$SqlDbOwnerUser]; 
ALTER ROLE db_ddladmin ADD MEMBER [$SqlDbOwnerUser]; 

ALTER ROLE db_owner ADD MEMBER [$SqlDbOwnerGroup]; 
ALTER ROLE db_ddladmin ADD MEMBER [$SqlDbOwnerGroup]; 

ALTER ROLE db_datareader ADD MEMBER [$SqlReadOnlyUser]; 
ALTER ROLE db_datareader ADD MEMBER [$SqlReadOnlyUser]; 
"@ 

function Drop-SqlUser() {
    param (
        $ConnectionString = ($connectionString -f $databaseName),
        $ExcludeUser = $ExcludeUserFromRemoval 
    )
    
    $excludeUserList = "'public', 'dbo','guest','INFORMATION_SCHEMA','sys'" + ",'$($ExcludeUser.split(',') -join "','")'"
    $sqlUsers = Invoke-Sqlcmd -ConnectionString $ConnectionString -Query ("select name from sys.database_principals where type in ('E', 'X', 'S') AND name not in ($excludeUserList)")

    foreach ($user in $sqlUsers.name) {

        Write-Output ("Drop user from database: {0}" -f $user)
        $userSchema = Invoke-Sqlcmd -ConnectionString $ConnectionString -Query "SELECT name FROM  sys.schemas WHERE principal_id = USER_ID('$user')"

        if ($userSchema) {

            foreach ($schema in $userSchema.Name) {

                Write-Output ("- the database principal owns a schema in the database, and cannot be dropped. Change schema from {0} to dbo" -f $schema)
                Invoke-Sqlcmd -ConnectionString $ConnectionString -Query ('ALTER AUTHORIZATION ON SCHEMA::"{0}" TO dbo' -f $schema)
                
            }

        }

        # The database principal owns a fulltext catalog in the database, and cannot be dropped.
        $fulltextCatalog = Invoke-Sqlcmd -ConnectionString $ConnectionString -Query "select * from sys.fulltext_catalogs"
        foreach ($catalog in $fulltextCatalog.Name) {

            Write-Output ("- the database principal owns a fulltext catalog in the database, and cannot be dropped. Change fulltext catalog from {0} to dbo" -f $catalog)
            Invoke-Sqlcmd -ConnectionString $ConnectionString -Query ('ALTER AUTHORIZATION ON Fulltext Catalog::[{0}] TO [dbo]; ' -f $catalog)

        }
            
        Write-Output "- drop user"
        Invoke-Sqlcmd -ConnectionString $ConnectionString -Query ("DROP USER [{0}]" -f $user)
    } 
    
    
}
Write-Output "Open SQL connection"
try {
    $sqlServerDatabases = Invoke-Sqlcmd -ConnectionString ($connectionString -f 'master') -Query "select name from sys.databases"
    Write-Output "Login successful"
}
catch {
    Throw ("Can't login to server: {0}" -f ($connectionString -f 'master'))
}
if ($UserDatabases -ne $null) {

    $databasesList = $UserDatabases.Split(';')

} else {

    $databasesList = $sqlServerDatabases.name

}
Write-Output ("Add AD user and group to {0}" -f $SqlServerUrl)
$errorList = @()
foreach ($databaseName in $databasesList ) {

    Write-Output ("{0}...." -f $databaseName)
    try {
        Drop-SqlUser -ConnectionString ($connectionString -f $databaseName) -ExcludeUser $ExcludeUserFromRemoval
        Write-Output "Create users..."
        Invoke-Sqlcmd -ConnectionString ($connectionString -f $databaseName) -Query $sqlQueryCreateUsers
        IF ($databaseName -ne 'master') {
            Invoke-Sqlcmd -ConnectionString ($connectionString -f $databaseName) -Query $sqlQueryGrantPermissions
        } 
        
        Invoke-Sqlcmd -ConnectionString ($connectionString -f $databaseName) -Query "SELECT DP1.name AS DatabaseRoleName,   
                                                                        isnull (DP2.name, 'No members') AS DatabaseUserName   
                                                                        FROM sys.database_role_members AS DRM  
                                                                        RIGHT OUTER JOIN sys.database_principals AS DP1  
                                                                        ON DRM.role_principal_id = DP1.principal_id  
                                                                        LEFT OUTER JOIN sys.database_principals AS DP2  
                                                                        ON DRM.member_principal_id = DP2.principal_id  
                                                                        ORDER BY DP1.name; "
        Write-Output ("{0} - completed. `n" -f $databaseName)
    }
    catch {
        Write-Output ("{0} - failed to update. `n" -f $databaseName)
        if ($errorList -notcontains $databaseName) {
            $errorList += $databaseName
        }
    }
}
if ($errorList.Count -gt 0) {
    Throw "Failed to create users for databases:$($errorList -join ',')"
}






