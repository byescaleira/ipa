# Backlog

O que falta, por prioridade. Itens concluídos saem daqui; o motivo das decisões fica em [decisions.md](decisions.md). O plano em etapas está em [store.md](store.md).

## Antes de distribuir

- **[P1] Ícone próprio.** Trocar `IPAIcon.icon` pelo ícone do app e rodar `scripts/icons.sh`.
- **[P1] Build para sideload.** Script que gera o `.ipa` sem assinatura (Release, iOS) para AltStore/SideStore, e o `.app` do Mac assinado com Developer ID e `allow-jit`.

## Produto

- **[P1] Instalar no aparelho.** O DLiPA instalava pelo `itms-services`, que exige um servidor HTTPS local com certificado válido; estudar antes de prometer.
- **[P2] Motor no visionOS.** Go não gera binário para visionOS; avaliar reetiquetar os objetos do slice de iOS ou usar o Mac como motor remoto.
- **[P2] Mac como motor do iPhone.** Sem JIT, o iPhone poderia pedir ao Mac que entre e baixe e receber o `.ipa` pela rede local.
- **[P2] Download em segundo plano.** Hoje o download roda numa `Task` do `DownloadCenter` e para quando o sistema suspende o app; o rodapé de In Progress pede para manter o IPA aberto. Com o motor real (2.1), avaliar `URLSession` em segundo plano para o arquivo e uma Live Activity com a barra.
- **[P3] Miniatura do tema igual ao herói de Downloads.** O herói ficou "ON THIS DEVICE" · "5 packages" · "412.5 MB used"; a `ThemePreview` (etapa 2.4) ainda mostra "Packages on this device" e "5".

- **[P2] Progresso no hub de guias.** A receita do Cashly tem o cartão "x of y guides done" e "Next for you", que dependem de registrar a conclusão de cada guia; o IPA ainda não grava isso (sem eventos nem XP), então o hub mostra só as categorias.
- **[P3] Compras da conta.** O ipatool lista os apps já obtidos (`list-purchases`); dá uma seção "Purchased" por conta.

## Motor e revisão

- **[P1] Motor real do ipatool (etapa 2.1).** A frente parou num bloqueio do classificador de segurança; por decisão do usuário, as telas seguem com o `SimulatedStoreEngine` e o motor é retomado na sessão principal, com ele acompanhando.
- **[P1] Revisão de design de tudo.** Religar a lista `ui` do `.apple-sdd.json` e rodar o `apple-sdd:design-reviewer` sobre a etapa 2 integrada.
