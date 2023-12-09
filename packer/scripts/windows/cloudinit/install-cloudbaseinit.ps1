$ErrorActionPreference="Stop"
# install Cloudbase-Init
mkdir "c:\setup"; 
echo "Copy CloudbaseInitSetup_Stable_x64.msi"; 
wget "https://cloudbase.it/downloads/CloudbaseInitSetup_x64.msi" -outfile "c:\setup\CloudbaseInitSetup_x64.msi"; 
# copy-item "G:\sysprep\CloudbaseInitSetup_Stable_x64.msi" "c:\setup\CloudbaseInitSetup_Stable_x64.msi" -force
#Start-Sleep 5

echo "Start process CloudbaseInitSetup_Stable_x64.msi"; 
start-process -FilePath 'c:\setup\CloudbaseInitSetup_x64.msi' -ArgumentList '/qn /l*v C:\setup\cloud-init.log' -Wait
