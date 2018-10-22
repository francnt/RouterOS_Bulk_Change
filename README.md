# MikroTik RouterOS Bulk Change

Esse projeto foi desenvolvido para ajudar alterações em massa no MikroTik RouterOS.


O script trabalha de um forma bem simples, tudo que eu fizer em um determinado roteador será replicado para os outros.

---------------------------------------
Oque já temos até agora.
---------------------------------------
– Espelhamento de configurações separadas por módulos (cada menu/sub-menu de configuração chamo de módulo).

– Os módulos para export de configurações são definidos dentro do menu “/ip tftp” (se você usa esse menu poderá ser escolhido outro qualquer que você não faça uso).

– Apaga e reescreve toda configuração que tenha a string “!==! -” dentro do comentário.

– Não exporta a configuração que contiver “out-of-mirror” dentro do comentário.

– Faz atualização do RouterOS em todos os clientes de espelhamento.
---------------------------------------