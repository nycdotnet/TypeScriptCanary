#Usage:
# Powershell GetLKGTypeScript.ps1

# No parameters checks the default download location, refreshes from Codeplex, and lists latest commits on $desiredBranch branch (typically develop).
# -install #######  will build and install the specified version of TypeScript from the $desiredBranch branch (####### represents the Git commit hash)
# Note that you can also say -install HEAD and it will install whatever the latest is, or HEAD~n where n is the integer number of
# commits behind the HEAD you want to install (so HEAD~1 is the commit before the latest).

  
$analyzeCommitCount = 20;
$desiredBranch = "develop";
$typeScriptRepoParent = ([Environment]::GetFolderPath('MyDocuments').ToString());
$typeScriptRepoFolderName = "TypeScriptSourceCode";


Function Canary-Main() {
  $nodeExePath = FindNodeOrDie;
  $gitExePath = FindGitOrDie;
  
  pushd $typeScriptRepoParent;
  $TSFolderFound = Test-Path ".\TypeScriptSourceCode";
  if ($TSFolderFound -eq $true) {
    write-host "$typeScriptRepoFolderName folder found." -foregroundcolor "darkgray";
    pushd $typeScriptRepoFolderName\typescript;
    
    if ($desiredAction.IndexOf("fetch") -ge 0) {
      write-host "Fetching latest TypeScript updates from CodePlex..."  -foregroundcolor "white";
      $fetchResult = git fetch https://git01.codeplex.com/typescript
    }
  } else {
    write-host "$typeScriptRepoFolderName folder not found."
    if ($desiredAction.IndexOf("fetch") -ge 0) {
      write-host "Creating it..."  -foregroundcolor "white";
      mkdir $typeScriptRepoFolderName | out-null;
      pushd $typeScriptRepoFolderName;
      write-host "Cloning TypeScript repository - this could take several minutes."  -foregroundcolor "white";
      git clone https://git01.codeplex.com/typescript
      popd;
    } else {
      write-host "Since the folder does not exist and we are not fetching, there is nothing left to do.";
      Exit;
    }
    pushd $typeScriptRepoFolderName\typescript;
  }
  
  $gitCheckoutResult = git checkout $desiredBranch
  $indexOfLKG = -1;
  
  if ($desiredAction.IndexOf("list") -ge 0) {
    write-host "Latest $analyzeCommitCount commits on $desiredBranch branch:"  -foregroundcolor "white";
    $gitCommits = @();
    $recentCommitHashes = git rev-list --max-count $analyzeCommitCount HEAD
    for ($i = 0; $i -lt $recentCommitHashes.Count; $i++) {
      $commit = GitCheckin $recentCommitHashes[$i];
      $commitDetail = git show -s --format="%ci;%h;%s" $commit.Hash
      $commit.Parse($commitDetail);
      $gitCommits += $commit;
      if ($commit.IsLKG()) {
        if ($indexOfLKG -eq -1) {
          $indexOfLKG = $i;
        }
        write-host $commit.ToPrettyString() -foregroundcolor "green";
      } else {
        write-host $commit.ToPrettyString() -foregroundcolor "gray";
      }
    }
  }
  
  if ($desiredAction.IndexOf("use") -ge 0) {
    if ($desiredCommit -eq "LKG") {
      $desiredCommit = Hash-Of-Last-Known-Good;
    }
    write-host "Checking out commit $desiredCommit  (this may take a few minutes - all work is local.)" -foregroundcolor "white";
    $checkoutResult = git checkout $desiredCommit .
    Get-Jake-If-Not-Installed;
    Build-TypeScript;
    Backup-Existing-TypeScript-Files;
    Update-TypeScript;
    write-host "TypeScript has been updated to commit $desiredCommit of the $desiredBranch branch." -foregroundcolor "green";
  }
  
  popd;
  popd;
  write-host ""
  
}

function Get-Jake-If-Not-Installed() {
  $appData = ([Environment]::GetFolderPath('ApplicationData').ToString());
  $JakeFound = Test-Path "$appData\npm\jake";
  if ($JakeFound -eq $false) {
    write-host "installing jake globally...";
    $installJake = npm install -g jake
  }
}

function Build-TypeScript() {
  write-host "Removing previously built TypeScript (if any)...";
  $jakeClean = jake clean
  write-host "Building TypeScript...";
  $jakeLocal = jake local
}

function Backup-Existing-TypeScript-Files() {
  write-host "Backing up files to $typeScriptRepoFolderName\backupTypeScriptFiles";
  $timestampFolderName = [DateTime]::Now.ToString("yyyy-MM-dd_HH-mm-ss");
  $backupFolder = "..\backupTypeScriptFiles\$timestampFolderName";
  mkdir $backupFolder | Out-Null;
  $ProgFilesX86 = ([Environment]::GetFolderPath('ProgramFilesX86').ToString());
  Copy-File-If-Source-Exists "$ProgFilesX86\Microsoft SDKs\TypeScript\lib.d.ts" "$backupFolder\SDKs_lib.d.ts"
  Copy-File-If-Source-Exists "$ProgFilesX86\Microsoft SDKs\TypeScript\tsc.js" "$backupFolder\SDKs_tsc.js"
  Copy-File-If-Source-Exists "$ProgFilesX86\Microsoft SDKs\TypeScript\typescript.js" "$backupFolder\SDKs_typescript.js"
  Copy-File-If-Source-Exists "$ProgFilesX86\Microsoft Visual Studio 12.0\Common7\IDE\CommonExtensions\Microsoft\TypeScript\lib.d.ts" "$backupFolder\VS12_lib.d.ts"
  Copy-File-If-Source-Exists "$ProgFilesX86\Microsoft Visual Studio 12.0\Common7\IDE\CommonExtensions\Microsoft\TypeScript\typescriptServices.js" "$backupFolder\VS12_typescriptServices.js"
  Copy-File-If-Source-Exists "$ProgFilesX86\Microsoft Visual Studio 12.0\Common7\IDE\VWDExpressExtensions\Microsoft\TypeScript\lib.d.ts" "$backupFolder\VS12WebDevExpress_lib.d.ts"
  Copy-File-If-Source-Exists "$ProgFilesX86\Microsoft Visual Studio 12.0\Common7\IDE\VWDExpressExtensions\Microsoft\TypeScript\typescriptServices.js" "$backupFolder\VS12WebDevExpress_typescriptServices.js"
  Copy-File-If-Source-Exists "$ProgFilesX86\Microsoft Visual Studio 11.0\Common7\IDE\CommonExtensions\Microsoft\TypeScript\lib.d.ts" "$backupFolder\VS11_lib.d.ts"
  Copy-File-If-Source-Exists "$ProgFilesX86\Microsoft Visual Studio 11.0\Common7\IDE\CommonExtensions\Microsoft\TypeScript\typescriptServices.js" "$backupFolder\VS11_typescriptServices.js"
  Copy-File-If-Source-Exists "$ProgFilesX86\Microsoft Visual Studio 11.0\Common7\IDE\VWDExpressExtensions\Microsoft\TypeScript\lib.d.ts" "$backupFolder\VS11WebDevExpress_lib.d.ts"
  Copy-File-If-Source-Exists "$ProgFilesX86\Microsoft Visual Studio 11.0\Common7\IDE\VWDExpressExtensions\Microsoft\TypeScript\typescriptServices.js" "$backupFolder\VS11WebDevExpress_typescriptServices.js"
}

function Update-Typescript() {
  $ProgFilesX86 = ([Environment]::GetFolderPath('ProgramFilesX86').ToString());
  Copy-File-If-Destination-Exists ".\built\local\lib.d.ts" "$ProgFilesX86\Microsoft SDKs\TypeScript\lib.d.ts"
  Copy-File-If-Destination-Exists ".\built\local\tsc.js" "$ProgFilesX86\Microsoft SDKs\TypeScript\tsc.js"
  Copy-File-If-Destination-Exists ".\built\local\typescript.js" "$ProgFilesX86\Microsoft SDKs\TypeScript\typescript.js"
  Copy-File-If-Destination-Exists ".\built\local\lib.d.ts" "$ProgFilesX86\Microsoft Visual Studio 12.0\Common7\IDE\CommonExtensions\Microsoft\TypeScript\lib.d.ts"
  Copy-File-If-Destination-Exists ".\built\local\typescriptServices.js" "$ProgFilesX86\Microsoft Visual Studio 12.0\Common7\IDE\CommonExtensions\Microsoft\TypeScript\typescriptServices.js"
  Copy-File-If-Destination-Exists ".\built\local\lib.d.ts" "$ProgFilesX86\Microsoft Visual Studio 12.0\Common7\IDE\VWDExpressExtensions\Microsoft\TypeScript\lib.d.ts"
  Copy-File-If-Destination-Exists ".\built\local\typescriptServices.js" "$ProgFilesX86\Microsoft Visual Studio 12.0\Common7\IDE\VWDExpressExtensions\Microsoft\TypeScript\typescriptServices.js"
  Copy-File-If-Destination-Exists ".\built\local\lib.d.ts" "$ProgFilesX86\Microsoft Visual Studio 11.0\Common7\IDE\CommonExtensions\Microsoft\TypeScript\lib.d.ts"
  Copy-File-If-Destination-Exists ".\built\local\typescriptServices.js" "$ProgFilesX86\Microsoft Visual Studio 11.0\Common7\IDE\CommonExtensions\Microsoft\TypeScript\typescriptServices.js"
  Copy-File-If-Destination-Exists ".\built\local\lib.d.ts" "$ProgFilesX86\Microsoft Visual Studio 11.0\Common7\IDE\VWDExpressExtensions\Microsoft\TypeScript\lib.d.ts"
  Copy-File-If-Destination-Exists ".\built\local\typescriptServices.js" "$ProgFilesX86\Microsoft Visual Studio 11.0\Common7\IDE\VWDExpressExtensions\Microsoft\TypeScript\typescriptServices.js"
}

function Copy-File-If-Source-Exists([string] $CheckForThisFile, [string] $CopyItToThisFileName) {
  $found = Test-Path $CheckForThisFile;
  if ($found) {
    Copy-Item -Path $CheckForThisFile -Destination $CopyItToThisFileName;
  }
}

function Copy-File-If-Destination-Exists([string] $OverwriteDestinationFileWithThis, [string] $CheckForThisDestinationFile) {
  $found = Test-Path $CheckForThisDestinationFile;
  if ($found) {
    try {
      Copy-Item -Path $OverwriteDestinationFileWithThis -Destination $CheckForThisDestinationFile -Force;
    } catch [Exception] {
      write-host "Are you running this with admin rights?" -foregroundcolor "white";
    }
  }
}


function Hash-Of-Last-Known-Good() {
  $recentCommitHashes = git rev-list HEAD
  write-host "Searching for Last Known Good commit..." -foregroundcolor "white";
  for ($i = 0; $i -lt $recentCommitHashes.Count; $i++) {
      $commit = GitCheckin $recentCommitHashes[$i];
      $commitDetail = git show -s --format="%ci;%h;%s" $commit.Hash
      $commit.Parse($commitDetail);
      if ($commit.IsLKG()) {
        write-host $commit.ToPrettyString() -foregroundcolor "green";
        return $commit.AbbreviatedHash;
      }
    }
  return "HEAD";  #Give up if not found.
}

function TypeScript-Repo-Exists() {
  Test-Path ($typeScriptRepoParent + "\" + $typeScriptRepoFolderName);
}

function FindGitOrDie([boolean] $silent=$false) {
  try {
    $gitExePath = Find-Path "git.exe"
    if ($silent -eq $false) {
      write-host "Git found at [$gitExePath]" -foregroundcolor "darkgray";
    }
  } catch [Exception] {
    if ($silent -eq $false) {
      write-host "ERROR: Git.exe not found on path. Download from http://msysgit.github.io/" -foregroundcolor "red";
      write-host "Select the install option that adds git to the path, or add manually." -foregroundcolor "red";
      write-host "You may have to close this command window for the PATH to update." -foregroundcolor "red";
    }
    Exit;
  }
  return $gitExePath;
}
function FindNodeOrDie([boolean] $silent=$false) {
  try {
    $nodeExePath = Find-Path "node.exe"
    if ($silent -eq $false) {
      write-host "Node.js found at [$nodeExePath]" -foregroundcolor "darkgray";
    }
  } catch [Exception] {
    if ($silent -eq $false) {
      write-host "ERROR: Node.exe not found on path. You can download from http://nodejs.org" -foregroundcolor "red";
      write-host "You may have to close this command window for the PATH to update." -foregroundcolor "red";
    }
    Exit;
  }
  return $nodeExePath;
}


function global:GitCheckin ([string] $_hash="")
{
    $obj = @{
      Hash = $_hash
      AbbreviatedHash = ""
      Timestamp = $null
      Description = ""
    }
    
    $ParseBlock = {
      param ([string] $input)
      $tempArray = $input.split(";");
      $this.Timestamp = [DateTime] $tempArray[0];
      $this.AbbreviatedHash = $tempArray[1];
      $this.Description = $tempArray[2];
    } 
    $ShortDescriptionBlock = {
      if ($this.Description.length -gt 80) {
         $this.Description.Substring(0,77) + "...";
      } else {
         $this.Description;
      }
    }
    
    Add-Member -inputobject $obj -membertype ScriptMethod -name Parse -value $ParseBlock;
    Add-Member -inputobject $obj -membertype ScriptMethod -name IsLKG -value { $this.Description.IndexOf("LKG") -ge 0 };
    Add-Member -inputobject $obj -membertype ScriptMethod -name ShortDescription -value $ShortDescriptionBlock;
    Add-Member -inputobject $obj -membertype ScriptMethod -name ToPrettyString -value {$this.AbbreviatedHash + " @ " + $this.Timestamp.ToString("yyyy-MM-dd HH:mm") + ": " + $this.ShortDescription()};

    return $obj;

    #http://blogs.msdn.com/b/powershell/archive/2009/12/05/new-object-psobject-property-hashtable.aspx
    #http://rbubblog.wordpress.com/2011/03/23/ps-extending-objects-3/
}


Function Find-Path($Path, [switch]$All=$false, $type="Any") {
#thanks to Joel Bennett | http://huddledmasses.org/powershell-find-path/
    if($(Test-Path $Path -Type $type)) {
       return $path
    } else {
       [string[]]$paths = @($pwd); 
       $paths += "$pwd;$env:path".split(";")
       
       $paths = Join-Path $paths $(Split-Path $Path -leaf) | ? { Test-Path $_ -Type $type }
       if($paths.Length -gt 0) {
          if($All) {
             return $paths;
          } else {
             return $paths[0]
          }
       }
    }
    throw "Couldn't find a matching path of type $type"
}

Function Show-Help-And-Quit() {
  write-host "This PowerShell script will fetch the latest TypeScript code from Codeplex";
  write-host " and can update the code used by Visual Studio 2012 and 2013 if you have";
  write-host " them installed.";
  write-host "";
  write-host "usage:";
  write-host "Powershell .\GetLKGTypeScript.ps1" -foregroundcolor "green";
  write-host " Once the repo has been cloned, this will fetch the latest code and show the";
  write-host " most recent check-ins.";
  write-host "Powershell .\GetLKGTypeScript.ps1 use #######"  -foregroundcolor "green";
  write-host " This will check out a specific version, build TypeScript, back up the existing";
  write-host " TypeScript files, and copy the built code to the relevant folders so that";
  write-host " Visual Studio, Node, and the command-line compiler can use it.";
  write-host " ####### can be a Git commit hash, HEAD for the latest, HEAD~n where n is the";
  write-host " count of check-ins in the past to use (so HEAD~2 is the parent of the parent of";
  write-host " the current check-in) or LKG which uses the last check-in that the TypeScript";
  write-host " team included the string ""LKG"" in the commit message.";
  write-host "";
  EXIT;
}

Function Show-Introduction-And-Quit() {
  write-host "Welcome to the TypeScript ""Canary"" Tool.";
  write-host "";
  write-host "This PowerShell script will fetch the latest TypeScript code from Codeplex";
  write-host " and can update the code used by Visual Studio 2012 and 2013 if you have";
  write-host " them installed.";
  write-host "";
  write-host "Before using this script, please be aware that it will download the entire";
  write-host " Git repo for TypeScript (approximately 1.8 GB as of October 2013) to your";
  write-host " ""MyDocuments"" folder.  This will be downloaded once and refreshed using";
  write-host " a delta from then on.";
  write-host "";
  write-host "If you want to change the default location, edit the typeScriptRepoParent";
  write-host " variable at the top of the script.";
  write-host "";
  write-host "Lastly, you need to have Git and Node.js installed and in your %PATH% for";
  write-host " this script to work.  Visit http://msysgit.github.io/ and ";
  write-host " http://nodejs.org to download.";
  write-host "";
  $z = FindNodeOrDie;
  $z = FindGitOrDie;
  write-host "You're ready to begin.  Run Powershell .\GetLKGTypeScript.ps1 getstarted" -foregroundcolor "green";
  write-host "";
  Exit;
}

Function Parse-Command-Line($TheArgs) {
  write-host "TypeScript ""Canary"" Tool - by Steve Ognibene (@NYCDotNet) v0.0.1" -foregroundcolor "yellow";
  if($TheArgs.length -eq 0) {
    if (TypeScript-Repo-Exists) {
      Set-Variable -Name desiredAction -Value "fetch;list" -Scope 1
    } else {
      Show-Introduction-And-Quit;
    }
  } ElseIf ($TheArgs.length -eq 1) {
    if ($TheArgs[0] -eq "getstarted") {
        $z = FindNodeOrDie;
        $z = FindGitOrDie;
        Set-Variable -Name desiredAction -Value "fetch;list" -Scope 1
      } else {
        Show-Introduction-And-Quit;
      }
  } ElseIf ($TheArgs.length -eq 2) {
   if ($TheArgs[0] -eq "use") {
     Set-Variable -Name desiredAction -Value "use" -Scope 1
     Set-Variable -Name desiredCommit -Value $TheArgs[1] -Scope 1
   } Else {
     Show-Help-And-Quit;
   }
  } Else {
   Show-Help-And-Quit;
   Exit;
  }
}
$desiredAction = "";
$desiredCommit = "";

Parse-Command-Line $args;
Canary-Main;