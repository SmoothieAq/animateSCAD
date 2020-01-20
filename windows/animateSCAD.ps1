<#
.SYNOPSIS
    .
.DESCRIPTION
    .
.EXAMPLE
    C:\PS>..\..\windows\animateSCAD.ps1 ..\myModel.scad -Fps 24
    Will result in myModel.mp4 in the current directory
.NOTES
    Author: Jesper Lauritsen, but largly adapted from  https://www.leeholmes.com/blog/2018/09/05/producer-consumer-parallelism-in-powershell/
#>

param (
    [Parameter(Mandatory=$true,Position=0,HelpMessage="Specify an .scad file that follows the AnimateSCAD convetions.")][String]$File ## An .scad file that follows the AnimateSCAD convetions.
    ,[Int]$Fps = 30 ## Frames per second, defaults to 30
    ,[String]$Colorscheme = "Nature" ## OpenSCAS colorscheme, defaults to Nature
    ,[String]$Imgsize = "1280,720" ## Image size and movie resolution, defaults to 1280,720 (not all values may work)
)
$BaseFile = [System.IO.Path]::GetFileNameWithoutExtension($File)
$LogFile = "$BaseFile.log"
$MovieFile = "$BaseFile.mp4"

if (Test-Path $LogFile)
{
    ## Remove any previous log file
    Remove-Item $LogFile
}

$OpenScadArgs = "-D ```$fps=$Fps --colorscheme $Colorscheme --imgsize $Imgsize --camera 0,0,0,0,0,0,100 $File"

## We make the first frame, and grap the output from animateSCAD to find the total time of the animation
## We can then calculate the total number of frames to later generate
$Cmd = "openscad -o frame00000.png -D ```$frameNo=0 $OpenScadArgs"
$Info = iex $Cmd | Tee-Object -Variable "Log" | Select-String -Pattern total_time
echo "$Cmd`r`n$Log" >>$LogFile
$Match = $Info -match "total_time = (?<totalTime>\d+(\.\d+)?)"
$TotalFrames = [int][math]::Floor([Double]$Matches.totalTime * $Fps)
Write-Output ">>>> $BaseFile, $TotalFrames frames"
echo ">>>> $BaseFile, $TotalFrames frames" >>$LogFile
if (!( $TotalFrames -gt 0))
{
    Write-Output "Exiting because we could not calculate number of frames - check the log file for errors, and make sure your .scad file follows the AnimateSCAD conventions."
    exit
}

## The script block we want to run in parallel. Threads will all
## retrieve work from $InputQueue, and send results to $OutputQueue
$parallelScript = {
    param(
        ## An Input queue of work to do
        $InputQueue,

        ## The output buffer to write responses to
        $OutputQueue,

        ## State tracking, to help threads communicate
        ## how much progress they've made
        $OutputProgress, $ThreadId, $ShouldExit,

        ## current dir, log file, openscad args
        $Dir, $LogFile, $OpenScadArgs
    )

    cd $dir

    ## Continually try to fetch work from the input queue, until
    ## the 'ShouldExit' flag is set
    $processed = 0
    $workItem = $null
    while(! $ShouldExit.Value)
    {
        if($InputQueue.TryDequeue([ref] $workItem))
        {
            ## If we got a work item, we use openscad to make a singe frame.
            $Cmd = "openscad -o frame$workItem.png -D ```$frameNo=$workItem $OpenScadArgs"
            $Info = iex $Cmd | Tee-Object -Variable "Log" | Select-String -Pattern frameTime
            echo "$Cmd`r`n$Log" >>$LogFile

            ## Add the result to the output queue
            $OutputQueue.Enqueue("$Cmd`n$Info")

            ## Update our progress
            $processed++
            $OutputProgress[$ThreadId] = $processed
        }
        else
        {
            ## If there was no work, wait a bit for more.
            Start-Sleep -m 100
        }
    }
}

## Create a set of background PowerShell instances to do work, based on the
## number of available processors.
$threads = Get-WmiObject Win32_Processor | Foreach-Object NumberOfLogicalProcessors
$runspaces = 1..$threads | Foreach-Object { [PowerShell]::Create() }
$outputProgress = New-Object 'Int[]' $threads
$inputQueue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[String]'
$outputQueue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[String]'
$shouldExit = $false

## Spin up each of our PowerShell runspaces. Once invoked, these are actively
## waiting for work and consuming once available.
$Dir = pwd
$asyncs = New-Object "IAsyncResult[]" $threads
for($counter = 0; $counter -lt $threads; $counter++)
{
    $asyncs[$counter] = $runspaces[$counter].AddScript($parallelScript).
        AddParameter("InputQueue", $inputQueue).
        AddParameter("OutputQueue", $outputQueue).
        AddParameter("OutputProgress", $outputProgress).
        AddParameter("ThreadId", $counter).
        AddParameter("ShouldExit", [ref] $shouldExit).
        AddParameter("Dir",$Dir).
        AddParameter("LogFile",$LogFile).
        AddParameter("OpenScadArgs",$OpenScadArgs).BeginInvoke()
}

## Queue all frames
$estimated = $TotalFrames
for($counter = 1; $counter -lt $estimated; $counter++)
{
    $currentInput = $counter.toString("0000#")
    $inputQueue.Enqueue($currentInput)
}

## Wait for our worker threads to complete processing the
## work.
try
{
    do
    {
        ## Update the status of how many items we've processed, based on adding up the
        ## output progress from each of the worker threads
        $totalProcessed = $outputProgress | Measure-Object -Sum | Foreach-Object Sum
        Write-Progress "Processed $totalProcessed of $estimated" -PercentComplete ($totalProcessed * 100 / $estimated)

        ## If there were any results, output them.
        $scriptOutput = $null
        while($outputQueue.TryDequeue([ref] $scriptOutput))
        {
            $scriptOutput
        }

        ## If the threads are done processing the input we gave them, let them know they can exit
        if($inputQueue.Count -eq 0)
        {
            $shouldExit = $true
        }

        Start-Sleep -m 100

        ## See if we still have any busy runspaces. If not, exit the loop.
        $busyRunspaces = $runspaces | Where-Object { $_.InvocationStateInfo.State -ne 'Complete' }
    } while($busyRunspaces)
}
finally
{
    ## Clean up our PowerShell instances
    for($counter = 0; $counter -lt $threads; $counter++)
    {
        ##$runspaces[$counter].EndInvoke($asyncs[$counter])
        $runspaces[$counter].Stop()
        $runspaces[$counter].Dispose()
    }
}

## make the .mp4 movie from all the frames
$Cmd = "ffmpeg -framerate $Fps -i frame%05d.png -pix_fmt yuv420p -hide_banner -loglevel error -stats -y $MovieFile"
Write-Output $Cmd
iex $Cmd | Tee-Object -Variable "Log"
$Ec = $LASTEXITCODE
echo $Log >>$LogFile

if ($Ec -eq 0)
{
    ## remove all the frames and leave just the log and the .mp4 movie
    rm *.png
    Write-Output "**** Animation is ready in $MovieFile"
}
