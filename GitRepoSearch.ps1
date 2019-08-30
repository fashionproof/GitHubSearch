
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass
$VerbosePreference = "continue"
#set the location of the log file to be where the script runs from
$folder = Split-Path -parent $PSCommandPath

#set token HERE 
$token = "PUT YOUR TOKEN HERE"

#set header for authorization
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "token $token")
$headers.Add("Accept", "application/vnd.github.v3.text-match+json")

#quick rate limit test 
#$test = Invoke-RestMethod -Uri "https://api.github.com/rate_limit" -Headers $headers -Method Get

$SearchTerms = Get-Content -Path $folder\SearchTerms.txt
$OuputArray = @()

foreach ($SearchTerm in $SearchTerms)
{
    $iteration = 1
    $GitAPISearchResults= Invoke-RestMethod -Uri "https://api.github.com/search/code?q=$SearchTerm&page=$iteration&per_page=100" -Headers $headers -Method Get
    $TotalResultCountForSearchTerm = $GitAPISearchResults.total_count

    if ($TotalResultCountForSearchTerm -gt 0)
    {

        #iterations - the maxiumum records we can pull back for a search term is 1000
        #max iterations will be 10 with a page size of 100 results per page
        $Iterations = [math]::ceiling($TotalResultCountForSearchTerm / 100)
        if ($Iterations -gt 10)
        {
            $Iterations = 10
        }

        $OuputArray += $GitAPISearchResults.items

        for ($i = 2; $i -le $Iterations; $i++)
        {
            Start-Sleep -Seconds 15
            $GitAPISearchResults = Invoke-RestMethod -Uri "https://api.github.com/search/code?q=$SearchTerm&page=$i&per_page=100" -Headers $headers -Method Get
            $OuputArray += $GitAPISearchResults.items
        }
    }
}

$OuputArray | Select-Object -Property {$_.text_matches[0].matches[0].text}, sha, html_url | Export-Csv $folder\SearchTermsFound.csv 
write-output "Items Found: $($myArray.Count)"