$CloudInitLog='C:\setup\cloud-init.log'

while (!(Test-Path $CloudInitLog)) {
    echo "Waiting for cloud-init install to begin"
    Start-Sleep 5
}

while (!(Select-String -Path $CloudInitLog  -Pattern 'Installation completed successfully' -Quiet)) {
    echo "Wait cloud-init installation end..."
    Start-Sleep 5
}

echo "Show cloudinit service"
Get-Service -Name cloudbase-init

echo "Move config files to location"
# Move conf files to Cloudbase directory
copy-item "E:\windows\cloudinit\cloudbase-init.conf" "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\cloudbase-init.conf" -force
copy-item "E:\windows\cloudinit\cloudbase-init-unattend.conf" "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\cloudbase-init-unattend.conf" -force
copy-item "E:\windows\cloudinit\cloudbase-init-unattend.xml" "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\cloudbase-init-unattend.xml" -force

# Fixes for using nocloudservice with proxmox where it uses _ instead of - for file names
(Get-Content "c:\program files\Cloudbase Solutions\cloudbase-init\python\Lib\site-packages\cloudbaseinit\metadata\services\nocloudservice.py").Replace('meta-data', 'meta_data').Replace('user-data', 'user_data').Replace('network-config','network_config') | Set-Content "c:\program files\Cloudbase Solutions\cloudbase-init\python\Lib\site-packages\cloudbaseinit\metadata\services\nocloudservice.py"

echo "Disable cloudbaseinit at start"
# disable cloudbase-init start
Set-Service -Name cloudbase-init -StartupType Disabled

# Run sysprep
cd "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\"
start-process -FilePath "C:/Windows/system32/sysprep/sysprep.exe" -ArgumentList "/generalize /oobe /mode:vm /unattend:cloudbase-init-unattend.xml" -wait

exit $lastExitCode