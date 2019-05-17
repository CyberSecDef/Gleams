[CmdletBinding()]
param(
	[Parameter(Mandatory = $false, ValueFromPipeLine = $false,ValueFromPipelineByPropertyName = $false)][string] $computerName = $null
)
Begin{
	Class Gleams{
		[string] 	$computerName = $script:computerName;
		[object] 	$os = $null;
		[object] 	$network = $null;
		[object]	$netPerf = $null;
		[object] 	$cpu = $null;
		[object] 	$cpuLoad = $null;
		[object]	$compSys = $null;
		[object]	$diskIo = $null;
		[object]	$disk = $null;
		[object]	$process = $null;
		[object]	$procPerf = $null;

		[int] 		$windowWidth = [console]::WindowWidth;
		
		[int] WriteToPos (
			[string] $str,
			[int] $x = 0,
			[int] $y = 0,
			[string] $bgc = [console]::BackgroundColor,
			[string] $fgc = [Console]::ForegroundColor 
		){

			if($x -ge 0 -and $y -ge 0 -and $x -le [Console]::WindowWidth -and $y -le [Console]::WindowHeight){
				$saveY = [console]::CursorTop
				$offY = [console]::WindowTop
				[console]::setcursorposition($x,$offY+$y)
				Write-Host -Object $str -BackgroundColor $bgc -ForegroundColor $fgc -NoNewline
				$offX = [console]::CursorLeft
				[console]::setcursorposition(0,$saveY)
				return $x + $str.length + 1;
			}else{
				return 0;
			}
		}
	
		[int] ShowHost(){
            if([console]::WindowWidth -ne $this.windowWidth){
                $this.ClearScreen()
            }
			$row = 0
			$xOffset = $this.WriteToPos("$($this.computerName)",0,$row,'Black','White')
			if([console]::WindowWidth -ge 100){
				$xOffset = $this.WriteToPos("($($this.os.caption) $($this.os.version) $($this.os.OSArchitecture))", ($this.computerName.length + 2), $row, 'Black','Gray')
			}
			return $xOffset;
		}
		
		[int] ShowNetSummary( $xOffset = 0){
            if([console]::WindowWidth -ne $this.windowWidth){
                $this.ClearScreen()
            }
			$row = 0;
			$progressPreference = 'silentlyContinue'
			try{
				# $publicIp = curl 'https://api.ipify.org?format=txt' -errorAction silentlyContinue | select -expand content
			}catch{
				# $publicIp = "UNKNOWN"
			}
			$xOffset = $this.WriteToPos("IP", 			($xOffset + 2), $row, 'Black', 'White')
			$xOffset = $this.WriteToPos("$($this.network | select -first 1 -expand IPAddress | ? { $_ -notLike '*:*' })", 		($xOffset), 	$row, 'Black', 'Gray')
			# $xOffset = $this.WriteToPos("PUB", 		($xOffset + 1), $row, 'Black', 'White')
			# $xOffset = $this.WriteToPos("$($publicIp)", ($xOffset), 	$row, 'Black', 'Gray')
			return $xOffset
		}
		
		[void] ShowUptime( $xOffset = 0){
            if([console]::WindowWidth -ne $this.windowWidth){
                $this.ClearScreen()
            }
			$row = 0
			$bootTime = (get-date) - [Management.ManagementDateTimeConverter]::ToDateTime( ( $this.os |select -expand lastBootUpTime ) )

			$uptime = @"
Uptime: $($bootTime.days) Days, $($bootTime.hours.toString().padLeft(2,'0')):$($bootTime.minutes.toString().padLeft(2,'0')):$($bootTime.seconds.toString().padLeft(2,'0'))
"@

			if($xOffset + $uptime.length -gt [console]::WindowWidth){
				$row++
			}
			$this.WriteToPos("$($uptime)",$([console]::WindowWidth - $uptime.length), $row, 'Black', 'Gray')| out-null 
		}
	
		[void] ShowSysSummary(){
			if([console]::WindowWidth -ne $this.windowWidth){
                $this.ClearScreen()
            }
            $row = 2
			$fgc = 'Gray'
			$colWidth =  ( [math]::floor( [console]::windowWidth / 4 ) - 4 );
			$this.cpuLoad = $this.cpuLoad + '000000'

			$totalPhys = $this.compSys.TotalPhysicalMemory / 1GB;
			$freePhys = $this.os.FreePhysicalMemory / 1MB;
			$totalVirt = $this.os.TotalVirtualMemorySize / 1MB;
			$freeVirt = $this.os.FreeVirtualMemory / 1MB

			$this.WriteToPos(''.padLeft($colWidth, ' '), 0, $row, 'Black', 'Gray') | out-null
			
			if($colWidth -ge 55){
				$this.WriteToPos($($this.cpu.Name.ToString() + ' - '), 0, $row, 'Black', 'Gray') | out-null
                $this.WriteToPos( $($this.cpu.CurrentClockSpeed.ToString()) + ' / ' + $($this.cpu.MaxClockSpeed.ToString()) + ' MHz', ($this.cpu.Name.ToString().length + 4), $row, 'Black', 'Gray') | out-null
			}else{
                $this.WriteToPos( $($this.cpu.CurrentClockSpeed.ToString()) + ' / ' + $($this.cpu.MaxClockSpeed.ToString()) + ' MHz', 0, $row, 'Black', 'Gray') | out-null
            }
            
    
			$row++
			$this.WriteToPos(''.padLeft($colWidth, ' '), 0, $row, 'Black', 'Gray') | out-null
			$this.WriteToPos("CPU", 0, $row, 'Black', 'Gray') | out-null
			if(!$this.cpuLoad){ $this.cpuLoad = '0.00000' }
			switch($true){
				($this.cpuLoad -lt 50){ $fgc = 'Green'; break;}
				($this.cpuLoad -lt 75){ $fgc = 'Cyan'; break;}
				($this.cpuLoad -lt 100){ $fgc = 'Red'; break;}
				default{ $fgc = 'Gray'; break;}
			}

			if($colWidth -gt 20){
				$this.WriteToPos( ''.PadLeft( ( $this.cpuLoad /100 * ( $colWidth - 18 ) ),'|'), 6, $row, 'Black', 'Green') | out-null
			}
			
			$this.WriteToPos($( ( $this.cpuLoad   ).toString().subString(0,5) + '%').padLeft(4,' '), ($colWidth - 6), $row, 'Black', $fgc ) | out-null

			$row ++;
			$this.WriteToPos(''.padLeft($colWidth, ' '), 0, $row, 'Black', 'Gray') | out-null
			$this.writeToPos("MEM", 0, $row, 'Black', 'Gray' ) | out-null
			switch($true){
				(( ((100 * (1 - ($freePhys/$totalPhys))) + .5)  ) -lt 50){ $fgc = 'Green'; break;}
				(( ((100 * (1 - ($freePhys/$totalPhys))) + .5)  ) -lt 75){ $fgc = 'Cyan'; break;}
				(( ((100 * (1 - ($freePhys/$totalPhys))) + .5)  ) -lt 100){ $fgc = 'Red'; break;}
				default{ $fgc = 'Gray'; break;}
			}

			if($colWidth -gt 20){
				$this.WriteToPos( ''.PadLeft( ( ((100 * (1 - ($freePhys/$totalPhys))) + .5) /100 * ( $colWidth - 12 ) )   ,'|'), 6, $row, 'Black', 'Green') | out-null
			}
			$this.WriteToPos( $( ( ((100 * (1 - ($freePhys/$totalPhys))) + .5) ).toString().subString(0,5) + '%').padLeft(4,' '), ($colWidth - 6), $row, 'Black', $fgc ) | out-null

			$row ++;
			$this.WriteToPos(''.padLeft($colWidth, ' '), 0, $row, 'Black', 'Gray' ) | out-null
			$this.WriteToPos("SWAP", 0, $row, 'Black', 'Gray' ) | out-null
			switch($true){
				(( ((100 * (1 - ($freeVirt/$totalVirt))) + .5)  ) -lt 50){ $fgc = 'Green'; break;}
				(( ((100 * (1 - ($freeVirt/$totalVirt))) + .5)  ) -lt 75){ $fgc = 'Cyan'; break;}
				(( ((100 * (1 - ($freeVirt/$totalVirt))) + .5)  ) -lt 100){ $fgc = 'Red'; break;}
				default{ $fgc = 'Gray'; break;}
			}
			if($colWidth -gt 20){
				$this.WriteToPos(''.PadLeft( ( ((100 * (1 - ($freeVirt/$totalVirt))) + .5) /100 * ( $colWidth - 12 ) )   ,'|'), 6, $row, 'Black', 'Green' ) | out-null
			}
			$this.WriteToPos( $( ( ((100 * (1 - ($freeVirt/$totalVirt))) + .5) ).toString().subString(0,5) + '%').padLeft(4,' '), ($colWidth - 6), $row, 'Black', $fgc ) | out-null 
		}

		[void] ShowRam(){
			if([console]::WindowWidth -ne $this.windowWidth){
                $this.ClearScreen()
            }
            $row = 2
			$colWidth =  ( [math]::floor( [console]::windowWidth / 4 ) - 4 );

			$totalPhys = $this.compSys.TotalPhysicalMemory / 1GB;
			$freePhys = $this.os.FreePhysicalMemory / 1MB;
			$totalVirt = $this.os.TotalVirtualMemorySize / 1MB;
			$freeVirt = $this.os.FreeVirtualMemory / 1MB

			$this.WriteToPos("MEM", ($colWidth + 2), $row, 'Black', 'White') | out-null
			$this.WriteToPos( $( ( ((100 * (1 - ($freePhys/$totalPhys))) + .5)).toString().subString(0,5) + '%').padLeft(4,' '), ($colWidth + 7), $row, 'Black', 'Gray') | out-null

			$row++
			$this.WriteToPos(''.padLeft($colWidth, ' '), ($colWidth + 2), $row, 'Black', 'Gray') | out-null
			$this.WriteToPos("Total", ($colWidth + 2), $row, 'Black', 'Gray') | out-null
			$this.WriteToPos( ( ( -join( [math]::round($totalPhys,2).toString(), ' GB') ).padLeft(10, ' ')  ), ($colWidth + 8), $row, 'Black', 'Gray' ) | out-null

			$row++
			$this.WriteToPos(''.padLeft($colWidth, ' '), ($colWidth + 2), $row, 'Black', 'Gray' ) | out-null
			$this.WriteToPos("Used", ($colWidth + 2), $row, 'Black', 'Gray' ) | out-null
			$this.WriteToPos( ( ( -join( [math]::round($totalPhys - $freePhys,2).toString(), ' GB') ).padLeft(10, ' ')  ), ($colWidth + 8), $row, 'Black', 'Gray' ) | out-null

			$row++
			$this.WriteToPos( ''.padLeft($colWidth, ' '), ($colWidth + 2), $row, 'Black',  'Gray' ) | out-null
			$this.WriteToPos( "Free", ($colWidth + 2), $row, 'Black', 'Gray' ) | out-null
			$this.WriteToPos( ( ( -join( [math]::round($freePhys,2).toString(), ' GB') ).padLeft(10, ' ')  ), ($colWidth + 8), $row, 'Black', 'Gray' ) | out-null
		}

        [void] ShowCpu(){
        	if([console]::WindowWidth -ne $this.windowWidth){
                $this.ClearScreen()
            }
            $row = 2
			$colWidth =  ( [math]::floor( [console]::windowWidth / 4 ) - 4 );
            $this.WriteToPos( "CPU", (3*$colWidth + 2), $row, 'Black', 'White' ) | out-null
            $this.WriteToPos($( ( $this.cpuLoad   ).toString().subString(0,5) + '%').padLeft(5,' '), (3*$colWidth + 7), $row, 'Black', 'Gray' ) | out-null
            
            $this.procPerf |
                select-object -property Name, 
                    @{Name = "CPU"; Expression = {($_.PercentProcessorTime/$this.cpu.NumberOfLogicalProcessors)}}, 
                    @{Name = "PID"; Expression = {$_.IDProcess}}, 
                    @{"Name" = "Memory(MB)"; Expression = {[int]($_.WorkingSetPrivate/1mb)}} |
                Where-Object {$_.Name -match "^(idle|_total|system)$"} |
                Sort-Object -Property CPU -Descending |
                Select-Object * | % {
                    $row++
                    $this.WriteToPos( $_.Name, (3*$colWidth + 2), $row, 'Black', 'Gray' ) | out-null
                    $this.WriteToPos( $_.CPU,  (3*$colWidth + 10), $row, 'Black', 'Gray' ) | out-null
                }
        }
        
		[void] ShowSwap(){
			if([console]::WindowWidth -ne $this.windowWidth){
                $this.ClearScreen()
            }
            $row = 2
			$colWidth =  ( [math]::floor( [console]::windowWidth / 4 ) - 4 );

			$totalPhys = $this.compSys.TotalPhysicalMemory / 1GB;
			$freePhys = $this.os.FreePhysicalMemory / 1MB;
			$totalVirt = $this.os.TotalVirtualMemorySize / 1MB;
			$freeVirt = $this.os.FreeVirtualMemory / 1MB

			$this.WriteToPos("SWAP", (2*$colWidth + 4), $row, 'Black', 'White') | out-null
			$this.WriteToPos( $( ( ((100 * (1 - ($freeVirt/$totalVirt))) + .5)).toString().subString(0,5) + '%').padLeft(4,' '), (2*$colWidth + 10), $row, 'Black', 'Gray') | out-null

			$row++
			$this.WriteToPos(''.padLeft($colWidth, ' '), (2*$colWidth + 4), $row, 'Black', 'Gray') | out-null
			$this.WriteToPos("Total", (2*$colWidth + 4), $row, 'Black', 'Gray') | out-null
			$this.WriteToPos( ( ( -join( [math]::round($totalVirt,2).toString(), ' GB') ).padLeft(10, ' ')  ), (2*$colWidth + 10), $row, 'Black', 'Gray' ) | out-null

			$row++
			$this.WriteToPos(''.padLeft($colWidth, ' '), (2*$colWidth + 4), $row, 'Black', 'Gray' ) | out-null
			$this.WriteToPos("Used", (2*$colWidth + 4), $row, 'Black', 'Gray' ) | out-null
			$this.WriteToPos( ( ( -join( [math]::round($totalVirt - $freeVirt,2).toString(), ' GB') ).padLeft(10, ' ')  ), (2*$colWidth + 10), $row, 'Black', 'Gray' ) | out-null

			$row++
			$this.WriteToPos( ''.padLeft($colWidth, ' '), (2*$colWidth + 4), $row, 'Black',  'Gray' ) | out-null
			$this.WriteToPos( "Free", (2*$colWidth + 4), $row, 'Black', 'Gray' ) | out-null
			$this.WriteToPos( ( ( -join( [math]::round($freeVirt,2).toString(), ' GB') ).padLeft(10, ' ')  ), (2*$colWidth + 10), $row, 'Black', 'Gray' ) | out-null		
		}
		
		[int] ShowNetwork(){
			if([console]::WindowWidth -ne $this.windowWidth){
                $this.ClearScreen()
            }
            $row = 6
			$colWidth =  ( [math]::floor( [console]::windowWidth / 4 ) - 4 );

            $this.WriteToPos( ''.padLeft($colWidth, '-'), 0, $row, 'Black',  'Gray' ) | out-null
			$row++
            
			$this.WriteToPos("RX", 0, $row, 'Black', 'White') | out-null
			$this.WriteToPos("TX", ($colWidth - 2), $row, 'Black', 'White') | out-null
			$this.WriteToPos("NETWORK", ([math]::floor( $colWidth/2 - 3)), $row, 'Black', 'White') | out-null
			
			foreach($net in $this.netPerf){
				$row++
				$name = $net.Name
				if($name.length -ge $colWidth){
					$name = $name.substring(0,$colWidth-1)
				}
				$this.WriteToPos($name, 0, $row, 'Black', 'White') | out-null
				$row++
				
				$this.WriteToPos( ''.padLeft($colWidth, ' '), 0, $row, 'Black',  'Gray' ) | out-null
				$bps = 0
				switch($true){
					($net.BytesReceivedPerSec -le 1000){
						$bps = ([math]::round( $net.BytesReceivedPerSec, 2)).toString() + 'bs';
						break;
					}
					($net.BytesReceivedPerSec -le 1000000){
						$bps = ([math]::round( $net.BytesReceivedPerSec/1KB, 2)).toString() + 'kbs';
						break;
					}
					($net.BytesReceivedPerSec -le 1000000000){
						$bps = ([math]::round( $net.BytesReceivedPerSec/1MB, 2)).toString() + 'mbs';
						break;
					}
					($net.BytesReceivedPerSec -le 1000000000000){
						$bps = ([math]::round( $net.BytesReceivedPerSec/1GB, 2)).toString() + 'gbs';
						break;
					}
				}
				$this.WriteToPos($bps, 0, $row, 'Black', 'Green') | out-null
				
				$bps = 0
				switch($true){
					($net.BytesSentPerSec -le 1000){
						$bps = ([math]::round( $net.BytesSentPerSec, 2)).toString() + 'bs';
						break;
					}
					($net.BytesSentPerSec -le 1000000){
						$bps = ([math]::round( $net.BytesSentPerSec/1KB, 2)).toString() + 'kbs';
						break;
					}
					($net.BytesSentPerSec -le 1000000000){
						$bps = ([math]::round( $net.BytesSentPerSec/1MB, 2)).toString() + 'mbs';
						break;
					}
					($net.BytesSentPerSec -le 1000000000000){
						$bps = ([math]::round( $net.BytesSentPerSec/1GB, 2)).toString() + 'gbs';
						break;
					}
				}
				$this.WriteToPos($bps, ($colWidth - $bps.length ), $row, 'Black', 'Red') | out-null
			}
			return $row;
		}
		
		[int] ShowDiskIO($row){
			if([console]::WindowWidth -ne $this.windowWidth){
                $this.ClearScreen()
            }
            $colWidth =  ( [math]::floor( [console]::windowWidth / 4 ) - 4 );
            $row++
            $this.WriteToPos( ''.padLeft($colWidth, '-'), 0, $row, 'Black',  'Gray' ) | out-null
			$row++
			
			
			$this.WriteToPos("R/s", 0, $row, 'Black', 'White') | out-null
			$this.WriteToPos("W/s", ($colWidth - 3), $row, 'Black', 'White') | out-null
			$this.WriteToPos("DISK I/O", ([math]::floor( $colWidth/2 - 3)), $row, 'Black', 'White') | out-null
			
			foreach($net in $this.diskIo | ? { $_.Name -notlike '*_Total*'} ){
				$row++
				$name = $net.Name
				if($name.length -ge $colWidth){
					$name = $name.substring(0,$colWidth-1)
				}
				$this.WriteToPos(''.padLeft($colWidth, ' '), 0, $row, 'Black', 'Gray') | out-null
				$this.WriteToPos($name, 0, $row, 'Black', 'White') | out-null
				$row++
				
				$this.WriteToPos( ''.padLeft($colWidth, ' '), 0, $row, 'Black',  'Gray' ) | out-null
				$bps = 0
				switch($true){
					($net.DiskReadBytesPerSec -le 1000){
						$bps = ([math]::round( $net.DiskReadBytesPerSec, 2)).toString() + 'bs';
						break;
					}
					($net.DiskReadBytesPerSec -le 1000000){
						$bps = ([math]::round( $net.DiskReadBytesPerSec/1KB, 2)).toString() + 'kbs';
						break;
					}
					($net.DiskReadBytesPerSec -le 1000000000){
						$bps = ([math]::round( $net.DiskReadBytesPerSec/1MB, 2)).toString() + 'mbs';
						break;
					}
					($net.DiskReadBytesPerSec -le 1000000000000){
						$bps = ([math]::round( $net.DiskReadBytesPerSec/1GB, 2)).toString() + 'gbs';
						break;
					}
				}
				$this.WriteToPos($bps, 0, $row, 'Black', 'Green') | out-null
				
				$bps = 0
				switch($true){
					($net.DiskWriteBytesPerSec -le 1000){
						$bps = ([math]::round( $net.DiskWriteBytesPerSec, 2)).toString() + 'bs';
						break;
					}
					($net.DiskWriteBytesPerSec -le 1000000){
						$bps = ([math]::round( $net.DiskWriteBytesPerSec/1KB, 2)).toString() + 'kbs';
						break;
					}
					($net.DiskWriteBytesPerSec -le 1000000000){
						$bps = ([math]::round( $net.DiskWriteBytesPerSec/1MB, 2)).toString() + 'mbs';
						break;
					}
					($net.DiskWriteBytesPerSec -le 1000000000000){
						$bps = ([math]::round( $net.DiskWriteBytesPerSec/1GB, 2)).toString() + 'gbs';
						break;
					}
				}
				$this.WriteToPos($bps, ($colWidth - $bps.length), $row, 'Black', 'Red') | out-null
				
			}
			
			return $row;
		}
		
		[int] ShowDisk($row){
			if([console]::WindowWidth -ne $this.windowWidth){
                $this.ClearScreen()
            }
            $fgc = 'Gray'
			$colWidth =  ( [math]::floor( [console]::windowWidth / 4 ) - 4 );
            $row++
            $this.WriteToPos( ''.padLeft($colWidth, '-'), 0, $row, 'Black',  'Gray' ) | out-null
			$row++
			
			
			$this.WriteToPos(''.padLeft($colWidth, ' '), 0, $row, 'Black', 'Gray') | out-null
			$this.WriteToPos('', 0, $row, 'Black', 'Gray') | out-null
			$this.WriteToPos("Used", 0, $row, 'Black', 'White') | out-null
			$this.WriteToPos("Total", ($colWidth - 5), $row, 'Black', 'White') | out-null
			$this.WriteToPos("FILE SYS", ([math]::floor( $colWidth/2 - 4)), $row, 'Black', 'White') | out-null
			
			foreach($d in $this.disk){
				$row++
				$this.WriteToPos(''.padLeft($colWidth, ' '), 0, $row, 'Black', 'Gray') | out-null
				$this.WriteToPos($d.name, 0, $row, 'Black', 'Gray') | out-null
				if($d.size -gt 0){
					$this.WriteToPos( ''.PadLeft( ([math]::floor(($d.size-$d.freespace)/$d.size*($colWidth-4))) ,'|'), 4, $row, 'Black', 'Green') | out-null
				}
				
				$row++
				$this.WriteToPos(''.padLeft($colWidth, ' '), 0, $row, 'Black', 'Gray') | out-null
				$this.WriteToPos( [math]::floor(($d.size-$d.freespace)/1Gb).toString() + ' Gb' , 0, $row, 'Black', 'Green') | out-null
				$this.WriteToPos( ([math]::floor(($d.size)/1Gb).toString() + ' Gb').padLeft(7,' ') , ($colWidth-7), $row, 'Black', 'White') | out-null
			}
			
			return $row;
		}
		
		[int] ShowProc(){
			if([console]::WindowWidth -ne $this.windowWidth){
                $this.ClearScreen()
            }
            $row = 6
			$colStart =  ( [math]::floor( [console]::windowWidth / 4 ) - 2 );
			$colWidth =  ( [math]::floor( 3 * [console]::windowWidth / 4 ) - 2 );
			$limit = [console]::windowHeight - 12
			$this.WriteToPos( ''.padLeft(($colWidth +2), '-'), $colStart, $row, 'Black',  'Gray' ) | out-null
            $row++
            
            switch($true){
                ($colWidth -gt 100){
                    $this.WriteToPos("CPU%     MEM(M)     PID USER                 PRI  TIME          THRD   HNDL  Command", ($colStart + 1), $row, 'Black', 'White') | out-null
                    break;
                }
                ($colWidth -gt 80){
                    $this.WriteToPos("CPU%     MEM(M)     PID USER                 PRI  TIME          Command", ($colStart + 1), $row, 'Black', 'White') | out-null
                    break;
                }
                default{
                    $this.WriteToPos("CPU%     MEM(M)    PID USER                 Command", ($colStart + 1), $row, 'Black', 'White') | out-null
                    break;
                }
            }
            
			foreach($perf in ($this.procPerf | ? { $_.Name -notin '_Total','_idle','' -and $_.IDProcess -ne 0 } | sort PercentProcessorTime, WorkingSet -Descending | select -first $limit) ){
				$row++
			
                $this.WriteToPos(''.padLeft( ([console]::windowWidth - $colStart ), ' '), $colStart, $row, 'Black', 'Gray') | out-null
                
				$processData = $this.process | ? { $_.ProcessId -eq $perf.IDProcess}
				
				$this.WriteToPos($perf.PercentProcessorTime.ToString().padLeft(4,' '), ($colStart + 1), $row, 'Black', 'White') | out-null
                $this.WriteToPos(( [math]::round( $processData.WS/1MB,2)  ).ToString().padLeft(9,' '), ($colStart + 7), $row, 'Black', 'Gray') | out-null
                
				$this.WriteToPos($perf.IDProcess.ToString().padLeft(6,' '), ($colStart + 18), $row, 'Black', 'Gray') | out-null
				$this.WriteToPos($processData.UserName, ($colStart + 25), $row, 'Black', 'Gray') | out-null
				
                switch($true){
                    ($colWidth -gt 100){
                        $this.WriteToPos( ('' + $processData.Priority).padLeft(3,' '), ($colStart + 46), $row, 'Black', 'Gray') | out-null
                        $ts = [timespan]::fromseconds($perf.ElapsedTime)
                        $this.WriteToPos(  ( $ts.toString("dd\:hh\:mm\:ss") ) , ($colStart + 51), $row, 'Black', 'Gray') | out-null
                        $this.WriteToPos($perf.ThreadCount.toString().padLeft(4,' '), ($colStart + 65), $row, 'Black', 'Gray') | out-null
                        $this.WriteToPos($perf.HandleCount.toString().padLeft(5,' '), ($colStart + 71), $row, 'Black', 'Gray') | out-null
                        $cmd = ('' + $processData.commandLine)
                        $this.WriteToPos(  $cmd.substring(0,[math]::min($cmd.length, ([console]::windowWidth - $colStart - 78  )) ), ($colStart + 78), $row, 'Black', 'White') | out-null
                        break;
                    }
                    ($colWidth -gt 80){
                        $this.WriteToPos( ('' + $processData.Priority).padLeft(3,' '), ($colStart + 46), $row, 'Black', 'Gray') | out-null
                        $ts = [timespan]::fromseconds($perf.ElapsedTime)
                        $this.WriteToPos(  ( $ts.toString("dd\:hh\:mm\:ss") ) , ($colStart + 51), $row, 'Black', 'Gray') | out-null
                        $cmd = ('' + $processData.commandLine)
                        $this.WriteToPos(  $cmd.substring(0,[math]::min($cmd.length, ([console]::windowWidth - $colStart - 65  )) ), ($colStart + 65), $row, 'Black', 'White') | out-null
                        break;
                    }
                    default{
                        $cmd = ('' + $processData.commandLine)
                        $this.WriteToPos(  $cmd.substring(0,[math]::min($cmd.length, ([console]::windowWidth - $colStart - 45  )) ), ($colStart + 45), $row, 'Black', 'White') | out-null
                        break;
                    }
                }
			}
			
			return $row;
		}

        [void] ClearScreen(){
            clear;
            $this.windowWidth = [console]::WindowWidth;
            for($y=0; $y -lt [console]::WindowHeight; $y++){
                $this.WriteToPos( ''.padLeft([console]::windowWidth,' '), 0, $y, 'Black', 'Gray') | out-null
            }
            
        }
        
		[void] Dispose(){
			<#
			.DESCRIPTION
				This function disposes the objects and variables created for this script
			#>
			$this = $null
		}
		
		#constructor
		Gleams(){
			if($this.computerName -eq $null -or $this.computerName.trim() -eq ''){
				$this.computerName = (hostname);
			}
			$this.ClearScreen()
			
			while($true){
                $this.os = gwmi win32_operatingSystem -computerName $this.computerName
				$xOffset = $this.ShowHost();
                $this.ShowUptime( $xOffset + 2);
                
                $this.network = gwmi win32_networkAdapterConfiguration -computerName $this.computerName |? { $_.IPEnabled} | select -first 1
				$xOffset = $this.ShowNetSummary( $xOffset );
                
                $this.cpu = gwmi win32_processor -computerName $this.computerName | select *
                if($this.computerName -eq (hostname) ){
                    $this.cpuLoad = (Get-Counter -Counter "\Processor(_Total)\% Processor Time"  | select -expand CounterSamples | select -expand CookedValue )
                }else{
                    $this.cpuLoad = (Get-Counter -computerName $this.computerName -Counter "\Processor(_Total)\% Processor Time"  | select -expand CounterSamples | select -expand CookedValue )
                }
                $this.compSys = gwmi  Win32_ComputerSystem -computerName $this.computerName;
                $this.process = gwmi win32_process -computerName $this.computerName | select *, @{Name="UserName";Expression={$_.GetOwner().User}}
                $this.procPerf = gwmi Win32_PerfFormattedData_PerfProc_Process -computerName $this.computerName
				$this.ShowSysSummary();
				$this.ShowRam();
				$this.ShowSwap();
                $this.ShowCpu();
                
                $this.netPerf = gwmi win32_PerfFormattedData_Tcpip_NetworkInterface -computerName $this.computerName	
				$yOffset = $this.ShowNetwork();
            
                $this.diskIo = gwmi win32_PerfFormattedData_PerfDisk_LogicalDisk -computerName $this.computerName
                $this.disk = gwmi win32_logicalDisk -computerName $this.computerName
				$yOffset = $this.ShowDiskIO($yOffset);
				$yOffset = $this.ShowDisk($yOffset);
			
                
                
				$this.ShowProc();
				
				# sleep 1
			}
			
			
			
			$error.clear()
			$this.WriteToPos($this.computerName,10,10,'Black','Gray')
			$error
		}
	}
	
	$gleams = [Gleams]::new()
}
Process{

}
End{

}