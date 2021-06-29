Import-Module $env:SyncroModule

# Credit for the PInvoke code to Andy Arismendi
# (see https://stackoverflow.com/questions/15845508/get-idle-time-of-machine)
# Adaptation for Syncro by Bill Bardon

#NOTE: Add a custom asset field named "Idle time", or choose your own name and modify the last line of this script to match

Add-Type @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace PInvoke.Win32 {

    public static class UserInput {

        [DllImport("user32.dll", SetLastError=false)]
        private static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

        [StructLayout(LayoutKind.Sequential)]
        private struct LASTINPUTINFO {
            public uint cbSize;
            public int dwTime;
        }

        public static DateTime LastInput {
            get {
                DateTime bootTime = DateTime.UtcNow.AddMilliseconds(-Environment.TickCount);
                DateTime lastInput = bootTime.AddMilliseconds(LastInputTicks);
                return lastInput;
            }
        }

        public static TimeSpan IdleTime {
            get {
                return DateTime.UtcNow.Subtract(LastInput);
            }
        }

        public static int LastInputTicks {
            get {
                LASTINPUTINFO lii = new LASTINPUTINFO();
                lii.cbSize = (uint)Marshal.SizeOf(typeof(LASTINPUTINFO));
                GetLastInputInfo(ref lii);
                return lii.dwTime;
            }
        }
    }
}
'@

$Last = [PInvoke.Win32.UserInput]::LastInput
$Idle = [PInvoke.Win32.UserInput]::IdleTime
$DTnow = [DateTimeOffset]::Now

$LastStr = $Last.ToLocalTime().ToString("MMM d h:mm tt")
$IdleStr = $Idle.ToString("d\d\ h\h\ m\m")
$DTnowStr = $DTnow.ToString("MMM d h:mm tt")
Write-Host "$DTnowStr, last input was at $LastStr, Idle for $IdleStr"

Set-Asset-Field -Subdomain $subdomain -Name "Idle time" -Value "Last input was at $LastStr, Idle for $IdleStr"
