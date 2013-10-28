TypeScriptCanary
================

This is a PowerShell script that allows the user to fetch recent versions of TypeScript off the develop branch from the CodePlex site.

Usage:

    powershell .\GetLKGTypeScript.ps1

Once you've run the above, follow the instructions.

Then you can run this to get a specific version from the develop branch on CodePlex:

    powershell .\GetLKGTypeScript.ps1 use #######

Where ####### is the hash of the commit, or HEAD, or HEAD~n where n is the number of commits in the past from HEAD, or LKG which will automatically select the most recent commit where the TypeScript team put the string LKG in the commit message.
