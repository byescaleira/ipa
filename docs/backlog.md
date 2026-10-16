# Backlog

O que falta, por prioridade. Itens concluídos saem daqui; o motivo das decisões fica em [decisions.md](decisions.md). O plano em etapas está em [store.md](store.md).

## Antes de distribuir

- **[P1] Ícone próprio.** Trocar `IPAIcon.icon` pelo ícone do app e rodar `scripts/icons.sh`.
- **[P2] App do Mac para distribuição.** O `.app` do Mac assinado com Developer ID e `allow-jit`, quando o motor existir.
- **[P2] Release automático.** Rodar o `scripts/release.sh` num workflow do GitHub Actions por tag, quando houver runner com o Xcode 27.

## Produto

- **[P1] Instalar no aparelho.** O DLiPA instalava pelo `itms-services`, que exige um servidor HTTPS local com certificado válido; estudar antes de prometer.
- **[P2] Motor no visionOS.** Go não gera binário para visionOS; avaliar reetiquetar os objetos do slice de iOS ou usar o Mac como motor remoto.
- **[P2] Mac como motor do iPhone.** Sem JIT, o iPhone poderia pedir ao Mac que entre e baixe e receber o `.ipa` pela rede local.
- **[P2] Download em segundo plano.** Hoje o download roda numa `Task` do `DownloadCenter` e para quando o sistema suspende o app; o rodapé de In Progress pede para manter o IPA aberto. Com o motor real (2.1), avaliar `URLSession` em segundo plano para o arquivo e uma Live Activity com a barra.
- **[P3] Miniatura do tema igual ao herói de Downloads.** O herói ficou "ON THIS DEVICE" · "5 packages" · "412.5 MB used"; a `ThemePreview` (etapa 2.4) ainda mostra "Packages on this device" e "5".

- **[P2] Progresso no hub de guias.** A receita do Cashly tem o cartão "x of y guides done" e "Next for you", que dependem de registrar a conclusão de cada guia; o IPA ainda não grava isso (sem eventos nem XP), então o hub mostra só as categorias.

- **[P2] Tamanho das versões antigas.** `AppVersion` não traz tamanho; a confirmação de uma versão mostra versão, data e ID. Quando o motor real devolver o tamanho (metadado do `ipa_version_metadata`), acrescentar a linha "Size".
- **[P2] Ordem e lotes com o motor real.** A Busca ordena os IDs de versão do maior para o menor e pede o metadado em lotes de 10 das linhas visíveis; conferir com o `IPAToolEngine` (2.1) se o limite de pedidos da Apple aceita esse ritmo.
- **[P3] Compras da conta.** O ipatool lista os apps já obtidos (`list-purchases`); dá uma seção "Purchased" por conta.

## Motor e revisão

- **[P1] Motor real do ipatool (etapa 2.1).** A frente parou num bloqueio do classificador de segurança; por decisão do usuário, as telas seguem com o `SimulatedStoreEngine` e o motor é retomado na sessão principal, com ele acompanhando.
- **[P1] Revisão de design de tudo.** Religar a lista `ui` do `.apple-sdd.json` e rodar o `apple-sdd:design-reviewer` sobre a etapa 2 integrada.

## Motor e JIT

- **[P1] get-task-allow para o JIT.** O motor só roda com JIT, e o JIT (StikDebug) exige `get-task-allow`. Builds de distribuição (TestFlight, notarizado PAL) não têm esse direito; só os de sideload (AltStore/SideStore, que reassinam). Para testar o motor no aparelho, instalar o `.ipa` por sideload, não pelo TestFlight.
- **[P2] StikDebug embutido.** Por ora o JIT vem do app StikDebug separado; o StikJIT embutido (extensão helper + XPC, AGPL) fica para depois. `StikJIT.xcframework` 1.9.0 já baixado em `IPAKit/Frameworks/` (ignorado). Spec em docs/jit.md.
- **[P2] Plataforma fixa no motor.** A ponte usa `PlatformIPhone` fixo; apps só de iPad ou de outras plataformas podem falhar. Passar a plataforma do app pela ponte.
- **[P2] Revisão e licenças.** A trava de design está pausada (`ui: []`) na feature/engine; religar e revisar na integração. Declarar as licenças: ipatool (MIT) e Unicorn (GPLv2) embutidos.
- **[P3] Motor no Mac e visionOS.** Hoje o `binaryTarget` só cobre iOS; o Mac tem JIT nativo e poderia rodar o motor com uma fatia `macos-arm64`.
