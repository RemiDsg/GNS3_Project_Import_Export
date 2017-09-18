<#

.Synopsis
   Permet la copie des fichiers d'un project de la vm gns3 vers le serveur local

.DESCRIPTION
   Permet la copie des fichiers d'un project de la vm gns3 vers le serveur local

.EXAMPLE
   ./Nom du script

.INPUTS
   Pas d'entrée en pipe possible

.OUTPUTS
   
.NOTES
    NAME:    Backup GNS3
    AUTHOR:    Fabien Mauhourat

    VERSION HISTORY:

    1.0     2017.09.12
            Initial Version

.FUNCTIONALITY
   Backup gns3 file per project

#>

# Fonction qui verifie les paramètres du script
function verify-param {
    if ( ! (ping $ip_vm_gns3 -n 2 | Select-String "TTL=") ) {
        affiche_error "La vm GNS3 $ip_vm_gns3 n est pas accessible !"
        pause ; exit
    }
    if ( $gns3_proj_path_local -eq "" -or ! (Test-Path $gns3_proj_path_local) ) {
        affiche_error "La variable gns3_proj_path_local n est pas definie !"
        pause ; exit
    }
    if ( $vmware_path_vm_folder -eq "" -or ! (Test-Path $vmware_path_vm_folder) ) {
        affiche_error "La variable vmware_path_vm_folder n est pas definie !"
        pause ; exit
    }
    if ( $vmware_path_ovftool -eq "" -or ! (Test-Path $vmware_path_ovftool) ) {
        affiche_error "La variable vmware_path_ovftool n est pas definie !"
        pause ; exit
    }
    if ( $gns3_proj_path_src -eq "" -or ! (Test-Path $gns3_proj_path_src) ) {
        affiche_error "La variable gns3_proj_path_src n est pas definie !"
        pause ; exit
    }
	if ( ! (Invoke-Command {& plink}) ) {
        affiche_error "Putty n'est pas installe sur le poste ou le chemin n est pas dans la variable PATH !"
        pause ; exit
    }
	if ( ! (Invoke-Command {& pscp}) ) {
        affiche_error "Putty n'est pas installe sur le poste ou le chemin n est pas dans la variable PATH !"
        pause ; exit
    }
    if ( $temp_path -eq "" ) {
        affiche_error "La variable temp_path n est pas definie !"
        pause ; exit
    }
    if ( $pass_gns3_vm -eq "" ) {
        affiche_error "La variable pass_gns3_vm n est pas definie !"
        pause ; exit
    }
    if ( $user_gns3_vm -eq "" ) {
        affiche_error "La variable user_gns3_vm n est pas definie !"
        pause ; exit
    }
    if ( $gns3_images_path_vm -eq "" ) {
        affiche_error "La variable gns3_images_path_vm n est pas definie !"
        pause ; exit
    }
	New-Item -ItemType Directory -Force -Path "$temp_path\GNS3-TEMP" | Out-Null
    if ( $? -eq 0 ) {
        affiche_error "Creation du dossier GNS3-TEMP dans $temp_path echoue !"
        pause ; exit
    }
    $script:temp_path="$temp_path\GNS3-TEMP"

    Write-Host ""
    Write-Host "Verification des parametres terminee sans erreur !" -ForegroundColor Green
    Write-Host ""
    Write-Host "La configuration est la suivante :"
    Write-Host "     * Repertoire temporaire : $temp_path"
    Write-Host "     * Chemin projects : $gns3_proj_path_local"
    Write-Host "     * Chemin images : $gns3_images_path_vm"
    Write-Host "     * Chemin des VMs : $vmware_path_vm_folder"
    Write-Host "     * IpVM GNS3 : $ip_vm_gns3"
    Write-Host ""
}

# Fonction qui copie les images du project en ssh
function ssh_copie {

    Param(
      [string]$source,
      [string]$dest
    )

    pscp.exe -pw $pass_gns3_vm -r "$source" "$user_gns3_vm@$($ip_vm_gns3):$dest" | Out-Null

    if ( $? -eq 0 ) {
        affiche_error "Export de l image $images echoue !"
        delete_temp
    }
}

# Fonction qui execute une commande ssh
function ssh_command {

    Param(
      [string]$command
    )

    plink.exe -pw "$pass_gns3_vm" "$user_gns3_vm@$ip_vm_gns3" "$command" | Out-Null 

    if ( $? -eq 0 ) {
        affiche_error "Commande $command a echoue sur l hote $ip_vm_gns3 avec l utilisateur $user_gns3_vm !"
        delete_temp
    }
}

# Fonction qui affiche les erreurs du script
function affiche_error {

    Write-Host ""
    Write-Error "$args"
    Write-Host ""

}

# Fonction qui supprime les fichiers temporaires du script
function delete_temp {

    Remove-Item -Force -Recurse $temp_path
    pause ; exit

}

write-output "###########################################################################"
write-output "################## Script d exportation des projets GNS3 ##################"
write-output "###########################################################################"

# Définition des variables
$gns3_proj_path_local="C:\Users\fabien\GNS3\projects"
$gns3_proj_path_src="C:\Users\fabien\Desktop"
$ip_vm_gns3="192.168.146.128"
$gns3_images_path_vm="/opt/gns3/images"
$pass_gns3_vm="gns3"
$user_gns3_vm="gns3"
$vmware_path_ovftool="C:\Program Files (x86)\VMware\VMware Workstation\OVFTool\ovftool.exe"
$vmware_path_vm_folder="C:\\Users\\fabien\\Documents\\Virtual Machines"
$temp_path="C:\Temp"

# Vérification des paramètres
verify-param

# Choix du project GNS3 à exporter

Write-Host "Liste des projects GNS3 a importer :" -ForegroundColor Green
Write-Host ""

# Liste les projets GNS3 du repertoire gns3_proj_path_local
$compteur=0
Get-ChildItem $gns3_proj_path_src | select Name | foreach { 
    if ((Test-Path "$gns3_proj_path_src\$($_.name)") -and ("$($_.name)" -match ".zip")) {
        $compteur=$compteur+1
        Write-Host "$compteur." $_.name`
    }
}

Write-Host ""
$num_project=$(Read-Host "Quel project ")
Write-Host ""

# Récuperation du nom du projet
$compteur=0
Get-ChildItem $gns3_proj_path_src | foreach { 
    if ((Test-Path "$gns3_proj_path_src\$($_.name)") -and ("$($_.name)" -match ".zip")) {
        $compteur=$compteur+1
        if ( $compteur -like $num_project ) {
            $nom_project=$_.Name.Split('.')[0]
            return
        }
    }
}

Write-Host "Projet $nom_project selectionne !" -ForegroundColor Green

# Decompression du project

Expand-Archive -Force -Path "$gns3_proj_path_src\$nom_project.zip" -DestinationPath "$temp_path\"

if ( $? -eq 0 ) {
    affiche_error "Decompression du projet $nom_project echoue !"
    delete_temp
}

Write-Host ""
Write-Host "Decompression de $nom_project reussi dans $temp_path\$nom_project !" -ForegroundColor Green

# Import des images du project

$images_path_folder=Get-ChildItem $temp_path\$nom_project\images

foreach ($folder_name in "QEMU","IOU","IOS") {
    ssh_command "mkdir -p $gns3_images_path_vm/$folder_name"
}

foreach ($folder in $images_path_folder.Name) {

    $images_local=Get-ChildItem $temp_path\$nom_project\images\$folder
    if ( "$images_local" -eq "" ) {
        continue
    }

    if ( "$folder" -eq "docker" ) {
        foreach ($images_docker in $images_local) {

            $images_ref_path=$images_docker.PSPath | ForEach-Object {$_.split('::')[2] + ":" + $_.split('::')[3]}
            $images_ref_name=$images_docker.name 
            ssh_copie "$images_ref_path" "/tmp/$images_ref_name"
            ssh_command "docker load < /tmp/$images_ref_name"

            Write-Host ""
            Write-Host "Import de l image $images_ref_name en terminee !" -ForegroundColor Green
            Write-Host ""
        }
        continue
    }

    $images_vm=ssh_command "ls $gns3_images_path_vm/$folder" | where {$_ -notmatch "md5sum"}

    ForEach ($images_ref in $images_local.Name) {
        $test_images=0

        ForEach ($images_dest in $images_vm) {

            if ("$images_ref" -like "$images_dest") {
                $test_images=1
                break
            }
        }

        if ($test_images -ne 1) {
            
            $images_ref_path=$images_local.PSPath | where {$_ -match "$images_ref"} | ForEach-Object {$_.split('::')[2] + ":" + $_.split('::')[3]}

            ssh_copie "$images_ref_path" "$gns3_images_path_vm/$folder"
            ssh_command "chmod a+x $gns3_images_path_vm/$folder/$images_ref"

            Write-Host ""
            Write-Host "Import de l image $images_ref en terminee !" -ForegroundColor Green
            Write-Host ""
        }
    }
    
}

Write-Host ""
Write-Host "Import des images dans $gns3_images_path_vm terminee avec succes !" -ForegroundColor Green
Write-Host ""

# Import des vm du project en ovf

$vm_path_temp=Get-ChildItem $temp_path -Recurse | where {$_ -match ".ovf$"}

if ("$vm_path_temp" -ne "") {

    $vm_path=$vm_path_temp.PSPath | ForEach-Object {$_.split('::')[2] + ":" + $_.split('::')[3]}
    
    foreach ($vm in $vm_path) {

        Write-Host ""
        Write-Host "Import de la VM $vm en cours !" -ForegroundColor Green
        Write-Host ""

        Invoke-Command {& $vmware_path_ovftool --lax --allowExtraConfig "$vm" "$vmware_path_vm_folder"}

        if ( $? -eq 0 ) {
            affiche_error "Import de la VM $vm echoue !"
            delete_temp
        }
    }

    Write-Host ""
    Write-Host "Import des vm dans $vmware_path_vm_folder terminee avec succes !" -ForegroundColor Green
    Write-Host ""

    # Backup du fichier GNS3

    Copy-Item -Force -Path "$temp_path\$nom_project\$nom_project.gns3" -Destination "$temp_path\$nom_project\$nom_project.gns3.back"

    if ( $? -eq 0 ) {
            affiche_error "Copie du fichier gns3 du projet $temp_path\$nom_project\$nom_project.gns3 echoue !"
            delete_temp
    }

    # Extrait le chemin des vm à changer

    $vm_path_temp=Get-ChildItem $temp_path

    $vm_path_gns3=Get-Content "$temp_path\$nom_project\$nom_project.gns3.back" | where {$_ -match "vmx"} | ForEach-Object {$_.split('"')[3]}

    foreach ($vm_name in $vm_path_temp.Name) {

        if ("$vm_path_gns3" -match "$vm_name") {
            $old_vm_path=$vm_path_gns3.replace("$vm_name\\$vm_name.vmx",'')
            break
        }
    }

    # Changement du repertoire des vm dans le fichier GNS3 du projet

    $new_gns3_content=Get-Content "$temp_path\$nom_project\$nom_project.gns3.back" | ForEach-Object {$_.replace("$old_vm_path","$vmware_path_vm_folder\\")}
    # Out-File "$temp_path\$nom_project\$nom_project.gns3" utf8

    if ( $? -eq 0 ) {
        affiche_error "Changement du repertoire de la VM $vm_path_projet echoue !"
        delete_temp
    }

    #$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
    [System.IO.File]::WriteAllLines("$temp_path\$nom_project\$nom_project.gns3", "$new_gns3_content")

    Write-Host ""
    Write-Host "Changement du repertoire de la VM du projet $nom_project terminee avec succes !" -ForegroundColor Green
    Write-Host ""

}

# Copie du project dans le répertoire de gns3

Copy-Item -Recurse -Force -Exclude images "$temp_path\$nom_project" "$gns3_proj_path_local\$nom_project"

if ( $? -eq 0 ) {
    affiche_error "Copie du projet $nom_project echoue !"
    delete_temp
}

Write-Host ""
Write-Host "Copie du projet $nom_project reussi dans $gns3_proj_path_local\$nom_project !" -ForegroundColor Green

Write-Host ""
Write-Host "Script termine avec succes !" -ForegroundColor Green

# Vidage des fichiers temporaire
delete_temp