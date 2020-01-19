
## Adapted from https://www.leeholmes.com/blog/2018/09/05/producer-consumer-parallelism-in-powershell/

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

        ## current dir
        $Dir
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
            ## If we got a work item, do something with it. In this
            ## situation, we just create a string and sleep a bit.
            $Cmd = "openscad -o frame$workItem.png -D `$frameNo=$workItem --colorscheme Nature --imgsize 1280,720 --camera 0,0,0,0,0,0,100 ..\demo.scad"
            ##$Info = iex $Cmd | Tee-Object -Variable "Log" | Select-String -Pattern frameTime
            $Info = openscad -o frame$workItem.png -D `$frameNo=$workItem --colorscheme Nature --imgsize 1280,720 --camera 0,0,0,0,0,0,100 ..\demo.scad | Tee-Object -Variable "Log" | Select-String -Pattern frameTime
            echo "$Cmd`n$Log" >>log.txt

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
$dir = pwd
$asyncs = New-Object "IAsyncResult[]" $threads
for($counter = 0; $counter -lt $threads; $counter++)
{
    $asyncs[$counter] = $runspaces[$counter].AddScript($parallelScript).
        AddParameter("InputQueue", $inputQueue).
        AddParameter("OutputQueue", $outputQueue).
        AddParameter("OutputProgress", $outputProgress).
        AddParameter("ThreadId", $counter).
        AddParameter("ShouldExit", [ref] $shouldExit).
        AddParameter("Dir",$dir).BeginInvoke()
}

rm log.txt
$estimated = 589
for($counter = 0; $counter -lt $estimated; $counter++)
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
    ##foreach($runspace in $runspaces)
    for($counter = 0; $counter -lt $threads; $counter++)
    {
        $runspaces[$counter].EndInvoke($asyncs[$counter])
        $runspaces[$counter].Stop()
        $runspaces[$counter].Dispose()
    }
}

##ffmpeg -framerate 60 -i frame%05d.png -pix_fmt yuv420p animation.mp4
