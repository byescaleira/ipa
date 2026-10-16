# Backlog

O que falta, por prioridade. Itens concluídos saem daqui; o motivo das decisões fica em [decisions.md](decisions.md). O plano em etapas está em [store.md](store.md).

## Antes de distribuir

- **[P1] Ícone próprio.** Trocar `IPAIcon.icon` pelo ícone do app e rodar `scripts/icons.sh`.
- **[P1] Build para sideload.** Script que gera o `.ipa` sem assinatura (Release, iOS) para AltStore/SideStore, e o `.app` do Mac assinado com Developer ID e `allow-jit`.
- **[P2] Links do Sobre.** Preencher `IPAHelpURL` e `IPAWebsiteURL` com o repositório `byescaleira/ipa`.

## Produto

- **[P1] Instalar no aparelho.** O DLiPA instalava pelo `itms-services`, que exige um servidor HTTPS local com certificado válido; estudar antes de prometer.
- **[P2] Motor no visionOS.** Go não gera binário para visionOS; avaliar reetiquetar os objetos do slice de iOS ou usar o Mac como motor remoto.
- **[P2] Mac como motor do iPhone.** Sem JIT, o iPhone poderia pedir ao Mac que entre e baixe e receber o `.ipa` pela rede local.
- **[P3] Compras da conta.** O ipatool lista os apps já obtidos (`list-purchases`); dá uma seção "Purchased" por conta.
