#=================================================
# Desenvolvido por Francisco Neto                 
#       www.redesbasil.com                        
#=================================================

#=========== Instruções ===========================================================================================
# Tudo que estiver dentro do modulo será exportado e impotado nos clientes
# Se deseja que uma determinada configuração seja reescrita deverá conter "!==! -"
# Se deseja que uma determinada configuração não seja exportada o comentario deverá conter  "out-of-mirror"
#==================================================================================================================




#==========================================================================================
#======================= Cria arquivo de com as configurações =============================
#==========================================================================================

:global CreateConfigFile do={
:global b ""
:global GlobalModule
:global ModuleToExport
:global FileContentReturn

# Executa Export
[parse ($GlobalModule. " export verbose terse file=configs/" . $ModuleToExport)]
:delay 2


# Remove linhas desnecessarias do inicio de um arquivo de export
global a [file get ("configs/".$ModuleToExport) contents ]
global a [:pick $a ([find $a "#\r\n#\r\n#"]+7) 10000000]


# Altera alguns caracters =============================================================
:for i from=0 to=([:len $a] - 1) do={
  :global char [:pick $a $i]
  :global char1 [:pick $a ($i + 1)]

  :if ($char = "," ) do={:global char "\\,"} 
  # Coloca uma virgula para converter em array e retirar linhas com comentario out-of-mirror
  :if ($char = "/" and [:tonum $char1] < 0  ) do={:global char ",/"} 
  
  # Corrige caracter aspas para nao dar problema apos converter em array
  :if ($char = "\"" ) do={:global char "\\\""} 
  :global b ($b . $char)
  }

# Coloca acao no inicio do arquivo para remover regras antigas

if ( $GlobalModule="/ip service" or $GlobalModule="/ip dns" ) do={:global FileContentReturn ""} else={
:global FileContentReturn ($GlobalModule . " remove [find comment~\"!==! -\"] ") }

# Tira linhas que nao devem ser espelhadas
:global b [:toarray $b]
:foreach i in=$b do={:if ( [find [tostr $i]  "out-of-mirror"] < 0 ) do={:global FileContentReturn ( $FileContentReturn . $i )}}

#Descomente a linha abaixo caso queira o FTP ativo nos roteadores)
#if ( $GlobalModule="/ip service" ) do={:global FileContentReturn ( $FileContentReturn . "/ip service set ftp disabled=yes port=21" )}

# Gera arquivo com alteracoes
/file set ("configs/".$ModuleToExport) contents=$FileContentReturn

}

#==========================================================================================
#======================= Inicio do Script =================================================
#==========================================================================================


#Desabilita FTP antes de começar a execução
/ip service disable ftp


# Verifica arquivos para Update ==========================================================================

:global UpdateVersion [/ip tftp get [find req-filename~"UpdateVersion"] req-filename] 
#"
:global OldVersion [file get configs/version.txt  contents]
:global OldVersion [:pick $OldVersion ([find $OldVersion "="] + 1) 1000]
:global VersionToDownload [:pick $UpdateVersion 14 20]

:if ($VersionToDownload != $OldVersion) do={
/file remove [find name~"routeros/routeros-"]
:global DownloadFinished 0
:global AllPlatforms [toarray "x86,mipsbe,powerpc,tile,smips,arm,mmips"]
foreach Platform in=$AllPlatforms do={
:global URL ("https://download.mikrotik.com/routeros/".$VersionToDownload ."/routeros-".$Platform."-".$VersionToDownload .".npk")
:put $URL
:execute {/tool fetch url=$URL dst-path="routeros";:global DownloadFinished ($DownloadFinished + 1 )}
}

# Aguarda finalizar os Downloads
while condition=( $DownloadFinished  < 7 ) do={delay 5;/log warning message="Aguardando finalizar downloads"}

}
#===================================================================================





#Pega lista de modulos
:global ModuleList ""
:foreach i in=[/ip tftp  find disabled=no req-filename~"/" ] do={:global ModuleList ( $ModuleList . [/ip tftp  get $i req-filename  ].",")}

global ModuleList [:toarray $ModuleList ]
global VersionFile ""

# Executa acoes para cada modulo dentro da lista de modulos
foreach Module in=$ModuleList do={
:global GlobalModule $Module
:global ModuleToExport ""

#Retira espaços e coloca _ no nome do arquivo de export
:for i from=0 to=([:len $Module] - 1) do={
:local char [:pick $Module $i]
:if ($char = " ") do={:set $char "_"}
:global ModuleToExport ($ModuleToExport . $char)
}

# Retira o / do inicio do nome do modulo para fazer o nome do arquivo
global ModuleToExport [pick $ModuleToExport 1 100]

#==========================================================================================================================
#======================== Comeca  as verificaoes =================================================================================
#==========================================================================================================================


#Verifica se o arquivo de export nao existe ===========================================================================
if ([file print count-only  where name~($ModuleToExport . "_version_")] = 0 ) do={

#Gera nome do arquivo inicial
global ModuleToExport ($ModuleToExport . "_version_1.rsc")
put $ModuleToExport

$CreateConfigFile
} else={

# Se o arqvuivo de export já existe faz verificações e alterações nos arquivos ===========================================================================

#Pega tamanho do antigo arquivo de export
:global OldSize [file get [find name~($ModuleToExport . "_version_")] size ]

#Gera nome do arquivo temporario
global ModuleToExport ($ModuleToExport . "_tmp.rsc")
put $ModuleToExport

$CreateConfigFile

# Aguarda arquivo temporario ser gerado para pegar o tamanhos dele
:delay 2
:global NewSize [file get [find name=("configs/". $ModuleToExport)] size ]

#Verifica se o tamanho do arquivo antigo e igual o arquivo temporario
:if ( $NewSize != $OldSize ) do={
put "Aquivo alterado"

# Tira o final _tmp.rsc da variavel $ModuleToExport
:global ModuleToExport [pick  $ModuleToExport 0 ([len $ModuleToExport ] - 8)]

#Pega versao do arquivo antigo
:global Version [/file get [find name~($ModuleToExport . "_version")] name]
:global Version [pick $Version ([:len $ModuleToExport] +17) [find $Version "." ]]

#Remove o arquivo antigo
/file remove [find name~($ModuleToExport . "_version")]

#Gera nome do arquivo com a nova versao
global ModuleToExport ($ModuleToExport . "_version_".($Version + 1) .".rsc")

$CreateConfigFile

} else={put "Nada foi alterado"}
/file remove [find name~"_tmp.rsc"]

}
}

#==========================================================================================================================
#========================= Acoes finais ================================================================================
#==========================================================================================================================



# Gera arquivo de versao version.txt
:foreach i in=[file find name~"_version_"]  do={:global VersionFile ($VersionFile . [pick [file get $i name] ([find [file get $i name] "/"] + 1 ) 100] . ",")}
:global VersionFile  ($VersionFile .$UpdateVersion )
[file set configs/version.txt  contents=$VersionFile]


#Habilita FTP depois da exeução
/ip service enable ftp

/log error message="Script finalizado"