###################################################################################################################
# Powershel script fait par Ounet pour la communaute du LYS 23 feb 2022
#
# Recueration de la page https://robertsspaceindustries.com/citizens/$name
# avec le nom du Citizen afin de l'ajouter dans une blacklist.
# 
# l'ajout se fait seulement si le Citizen n'est pas deja dans la liste

################################################################
#class a recuperer
################################################################

#className                   R : entry
#id                           : 
#tagName                      : P
#parentElement                : System.__ComObject
#style                        : System.__ComObject
#onhelp                       : 
#onclick                      : 
#ondblclick                   : 
#onkeydown                    : 
#onkeyup                      : 
#onkeypress                   : 
#onmouseout                   : 
#onmouseover                  : 
#onmousemove                  : 
#onmousedown                  : 
#onmouseup                    : 
#document                     : mshtml.HTMLDocumentClass
#title                        : 
#language                     : 
#onselectstart                : 
#sourceIndex                  : 212
#recordNumber                 : 
#lang                         : 
#offsetLeft                   : 0
#offsetTop                    : 0
#offsetWidth                  : 0
#offsetHeight                 : 0
#offsetParent                 : System.__ComObject
#innerHTML                    : <A class="value data8" style="BACKGROUND-POSITION: -170px center" href="/orgs/LYS">Gardiens du Lys</A> 
#innerText                    : Gardiens du Lys 

#https://www.altaro.com/msp-dojo/web-scraping-tool-for-msps/#:~:text=%20Creating%20Web%20Scraping%20Tools%20for%20MSPs%20with,I%20want%20to%20be%20notified%20by...%20More%20

cls
$env:USERPROFILE
$outfile = "$env:USERPROFILE\Documents\Citizen_of_Star_Citizen.txt"

if (Test-Path -Path $outfile)
{
    $FileList = Get-ChildItem -Path $outfile
}
else
{
    $info="Name,Handle Name,Role,Organisation,Spectrum Iden,Organisation Rank,Enlisted,Location,Fluency,"
    Add-Content -Path $outfile -Value $info
}

$name=$(write-host "Entre le nom du Citizen que vous cherchez : " -nonewline -foregroundColor green;read-host)
$uri= "https://robertsspaceindustries.com/citizens/$name"

if ($WebResponse=Invoke-WebRequest -Uri $uri)
{
    #recherche de l'existance du citizen
    if($Success = $FileList | Select-String -Pattern $name)
    {
        write-host "exist deja" -ForegroundColor red
        Write-Host $Success
    }
    else
    {
        #$WebResponse.ParsedHtml.all.tags("a") | ForEach-Object -MemberName innertext
        $WebResponse.ParsedHtml.all.tags("p") | Where{ $_.className -eq 'entry' } | ForEach-Object -MemberName innertext
    
        $test = ($WebResponse.ParsedHtml.all.tags("p") | Where{ $_.className -eq 'entry' } | ForEach-Object -MemberName innertext)
        $count = $test.Count
        $info =""
        for ($i=0;$i -lt $count;$i++)
        {
            #Write-Host $test[$i] -NoNewline -ForegroundColor Green
            $info = $info + $test[$i] + ","
        }

        Add-Content -Path $outfile -Value $info
    }
}
