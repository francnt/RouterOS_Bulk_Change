
:global log 0
:global FTPServer 10.20.30.1
:global FTPPort 64111 
:global User admin
:global Pass 123

/tool fetch mode=ftp  address=$FTPServer user=$User password=$Pass  port=$FTPPort src-path=configs/version.txt

:if ($log = 1 ) do={/log warning message="Arquivo biaxado"}

:global ModuleList [:toarray [file get version.txt contents ]]

:foreach RemoteModule in=$ModuleList do={
put $RemoteModule
# Verifica se é o modulo de Update
:if ($RemoteModule ~ "UpdateVersion") do={
:global VersionToDownload [:pick $RemoteModule 14 20] 
:global MyRouterOSVersion [/system resource get version];
:global MyRouterOSVersion [pick $MyRouterOSVersion 0 ([find $MyRouterOSVersion "("] - 1) ]

# Compara versão para download com a versao local
:if ($VersionToDownload != $MyRouterOSVersion ) do={
:global Platform [/system resource get architecture-name];
:if ($Platform = "x86_64" ) do={:global Platform "x86"}
:global DownloadPath ("routeros/routeros-".$Platform."-".$VersionToDownload.".npk")

:if ($log = 1 ) do={/log warning message="Iniciando download do pacote de atualização"}
/tool fetch mode=ftp  address=$FTPServer user=$User password=$Pass port=$FTPPort src-path=($DownloadPath)
:if ($log = 1 ) do={/log warning message="Download finalizado, vamos pro reboot"}
:delay 4
# Executa comando de reboot ou de downgrade
:if ($VersionToDownload > $MyRouterOSVersion) do={/system reboot} else={/system package downgrade}
} else={
:if ($log = 1 ) do={/log warning message="Sem alterações para a versão do RouterOS"}
/quit}

}

# Pega nome do modulo sem a versao
:global NoVersionFileName [pick $RemoteModule 0 ([find $RemoteModule "_version_"]+8)]

#Verifica se o modulo existe
if ([/file print count-only  where name~$NoVersionFileName] = 0 ) do={
/tool fetch mode=ftp  address=$FTPServer user=$User password=$Pass  port=$FTPPort src-path=("configs/" . $RemoteModule)
delay 3
/import $RemoteModule
:if ($log = 1 ) do={/log warning message=("Criando modulo = " . $NoVersionFileName )}
} else={

# Se o modulo ja exite faz verificacoes de versao 
:global RemoteModuleVersion [pick $RemoteModule ([find $RemoteModule "_version_"]+9) [find $RemoteModule "." ]]
:global LocalModule [/file get [find name~$NoVersionFileName] name ]
:global LocalModuleVersion [pick $LocalModule ([find $LocalModule "_version_"]+9) [find $LocalModule "." ]]

# Compara versão remota com a local e atualiza se necessario
if ($RemoteModuleVersion > $LocalModuleVersion ) do={
/file remove [find name~$LocalModule]
/tool fetch mode=ftp  address=$FTPServer user=$User password=$Pass port=$FTPPort src-path=("configs/" . $RemoteModule)
delay 3
/import $RemoteModule
:if ($log = 1 ) do={/log warning message=("Efetuada alterações para o modulo = " . $NoVersionFileName )}

} else={:if ($log = 1 ) do={/log warning message=("Sem alterações para o modulo = " . $NoVersionFileName )}}



}   

}


