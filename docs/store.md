# Loja: busca, contas e downloads

Spec do produto do IPA: buscar apps da App Store em qualquer loja, entrar com Apple IDs, listar versões antigas, obter licença de apps grátis e baixar o `.ipa` para compartilhar ou instalar. A arquitetura está em [architecture.md](architecture.md); as decisões que levaram a esta forma, em [decisions.md](decisions.md); o que falta, em [backlog.md](backlog.md).

O IPA é a reconstrução do [DLiPA](https://github.com/AhmedBafkir/DLiPA) (o fork só tinha README e capturas, guardadas em `docs/reference/`) sobre o protocolo do [ipatool](https://github.com/majd/ipatool).

## Princípios

- **Busca funciona sem conta e sem motor.** Lojas, busca e detalhes do app usam a API pública do iTunes (`itunes.apple.com/search` e `/lookup`) em Swift, em todas as plataformas.
- **Login, versões, licença e download passam pelo motor do ipatool.** Desde 28/08/2026 (ipatool 2.4.0) a Apple exige assinatura SAP no login e `kbsync` no download; o ipatool emula o `storeagent` do macOS com o Unicorn. O IPA embute o ipatool como biblioteca (`IPAToolCore.xcframework`, Go `c-archive`) e conversa com ele por JSON.
- **O motor precisa de JIT.** No Mac funciona com o entitlement `com.apple.security.cs.allow-jit`. No iPhone, iPad e visionOS sem jailbreak, só com JIT ativado por fora (StikDebug ou similar); sem isso o app diz o motivo e mostra o guia, nunca trava.
- **Só apps grátis.** A licença é obtida só para apps de preço zero, como no ipatool; app pago mostra o preço e o motivo, sem botão que falha depois.
- **Cada conta tem os seus downloads.** O arquivo fica em `Documents/Downloads/<conta>/`, visível no app Arquivos; o registro (app, versão, tamanho, data) fica no SwiftData local.
- **Segredos só no Keychain.** Senha, token e cookies da conta nunca vão para `UserDefaults`, SwiftData ou log.
- **Distribuição por sideload**, sem StoreKit nem App Store Connect (decisão do usuário em 15/10/2026).

## Onde fica

| Peça | Target |
| --- | --- |
| `Storefront`, `StoreApp`, `AppQuery`, `Account`, `AppVersion`, `DownloadRecord`, `DownloadProgress`, `DeviceIdentity`, `StoreError`; protocolos `StoreCatalog`, `StoreEngine`, `AccountVault`, `DownloadRepository` | `IPADomain` |
| `ITunesCatalog` (busca e lookup), `KeychainAccountVault`, `DownloadEntity` e `SwiftDataDownloadRepository`, `DownloadFolder` | `IPAData` |
| `IPAToolEngine` (ponte Swift ↔ Go), `JITStatus` | `IPAEngine` (depende do binário `IPAToolCore` só em iOS e macOS) |
| Ponte Go (`bridge/`), patches do ipatool, `scripts/ipatool.sh` | raiz do repo |
| `AccountsModel` (conta ativa), `DownloadCenter` (fila, progresso, cancelamento), textos de exibição | `FeatureCore` |
| Busca, lojas, detalhe do app e versões | `FeatureSearch` |
| Downloads (biblioteca) | `FeatureLibrary` |
| Contas e entrada | `FeatureAccounts` |
| Ajustes (busca, identidade do aparelho, motor, apagar tudo) | `FeatureSettings` |
| Motor simulado para o simulador e as prévias | `IPAMock` |

## Abas e telas

Quatro abas (`TabView` `.sidebarAdaptable`), como no DLiPA: **Search**, **Downloads**, **Accounts**, **Settings**.

### Busca (`SearchScreen`)

- Barra de busca nativa (`.searchable`), placeholder "Name, bundle ID, link or app ID". `AppQuery` decide: texto vira busca; `com.exemplo.app` vira lookup por bundle; número vira lookup por ID; link `apps.apple.com/.../id123` vira lookup pelo ID.
- Loja atual na toolbar: bandeira e nome ("🇧🇷 Brazil"); o toque abre a lista de lojas (`StorefrontScreen`, busca por nome, a atual marcada). Padrão: a loja da conta ativa; sem conta, a região do aparelho.
- Resultados: ícone do app, nome, linha "v20.22.1 · iOS 16.0 · 330.5 MB" e chip de preço quando não é grátis. Rodapé: quantos resultados e em qual loja.
- Vazio antes de buscar: `EmptyStateView` com exemplo de duas linhas reais de resultado e o texto dizendo o que pode ser digitado.

### App (`AppScreen`, rota `.app(id:)`)

- Herói: ícone grande, nome, desenvolvedor, chips (versão atual, sistema mínimo, tamanho, preço ou "Free").
- Ação principal (`primaryButton()`): "Download v20.22.1". Sem conta: "Sign In to Download" abre Contas. App pago: chip com o preço e rodapé explicando que só apps grátis podem ser obtidos. Motor indisponível: o botão abre o guia do JIT.
- Seção **Versions**: carrega os IDs de versão pelo motor; cada linha mostra a versão legível quando o metadado já chegou (busca sob demanda, em lotes, só das linhas visíveis) e o ID externo em `.secondary`. Toque numa versão abre a confirmação (`GuideSheet` de uma página) com versão, data e tamanho, e o botão "Download vX".
- Seção **Identifiers**: bundle ID, app ID e link, cada um copiável (toque copia e vibra) e `ShareLink` para o link.
- Campo "Download by Version ID" no fim, para quem já tem o ID.

### Downloads (`LibraryScreen`)

- Seção **In Progress** no topo quando há download: ícone, nome e versão, barra que preenche (`ProgressView` linear), "82.2 MB of 206.5 MB" e botão de cancelar. Fases: "Preparing the store engine" (primeira vez, baixa os componentes do macOS), "Getting license", "Downloading", "Signing package".
- Uma seção por conta (título: nome da conta, rodapé com o e-mail e o total ocupado), linhas com ícone, nome, "v20.19.2 · 205.8 MB" e data relativa.
- Busca local por nome ou bundle ID. Ações por linha: Share (`ShareLink` do `.ipa`), Show in Finder (Mac), Delete (com confirmação). Install fica para depois (ver backlog).
- Vazio: exemplo preenchido com duas linhas e o botão "Search Apps".

### Contas (`AccountsScreen`)

- Herói com a conta ativa: nome, e-mail e chip com a bandeira e a loja da conta.
- Lista das outras contas (toque troca a ativa; deslizar remove, com confirmação). Toolbar `person.badge.plus` abre a entrada.
- Entrada (`SignInScreen`, folha): e-mail e senha; quando a Apple pede o código, a mesma folha troca para o campo de 6 dígitos ("Enter the code sent to your devices"). Rodapé: a senha fica só no Keychain deste aparelho.
- Seção **Store Engine**: estado do motor ("Ready", "Needs JIT", "Not available on this device") com o guia de JIT.

### Ajustes

- **Store › Search**: "Results per Search" com escolhas 25, 50, 100, 200 (padrão 50; o iTunes aceita até 200). Substitui o "Search Limit 0" do DLiPA.
- **Store › Device Identity**: herói com o identificador que a Apple vê ("MAC" gerado localmente) e "Generate New Identity", com confirmação (`GuideSheet`) explicando que as contas precisam entrar de novo; ao confirmar, as contas saem do Keychain.
- **Store › Store Engine**: estado do motor ("Ready", "Needs JIT", "Not Available") num chip, "How to Turn On JIT" (guia `.jit`) e "Check Again" quando falta JIT.
- **Data › Storage**: espaço ocupado pelos downloads no herói e "Erase Everything" (apaga contas, downloads, preferências e a identidade), com confirmação em duas páginas.
- Aparência, Idioma, Guias e Sobre do template; o Sobre credita o ipatool (Majd Alfhaily) e o DLiPA (Ahmed Bafkir) e tem o código-fonte (`byescaleira/ipa`). As linhas da loja só existem na janela (a cena `Settings` do Mac não tem sessão).

### Guias

- **Meet IPA**: buscar, entrar, baixar (três páginas).
- **Turn On JIT**: por que o motor precisa de JIT, como ativar com o StikDebug (passos e link) e o que funciona sem JIT.
- **Install an IPA**: AltStore/SideStore (passos e link), AirDrop para outro aparelho, Sideloadly no computador (passos e link).
- **Privacy**: onde ficam contas, identidade e pacotes; o app só fala com a Apple.

## Motor (`IPAEngine`)

- A ponte Go exporta funções C que recebem e devolvem JSON (`ipa_login`, `ipa_list_versions`, `ipa_version_metadata`, `ipa_purchase`, `ipa_download_start`, `ipa_task_status`, `ipa_task_cancel`, `ipa_free`). Downloads longos devolvem um identificador; o Swift consulta o progresso.
- O Swift guarda a conta (o JSON da conta do ipatool, com token e senha) no Keychain, um item por e-mail, e entrega à ponte a cada chamada. Quando a Apple expira o token, a ponte entra de novo com a senha guardada e devolve a conta atualizada.
- A identidade do aparelho (6 bytes, MAC localmente administrado) é gerada uma vez e guardada no Keychain; o GUID enviado à Apple é o hexadecimal dela.
- Os componentes SAP (o `storeagent` extraído do IPSW do macOS por leitura parcial) e os cookies ficam em `Application Support/Engine/`.
- `JITStatus` decide antes de chamar a ponte: no Mac sempre pronto; no iOS pronto só com `CS_DEBUGGED`; no visionOS, indisponível nesta versão (Go não gera binário para visionOS).

## Links

| Link | Abre |
| --- | --- |
| `ipa://search?q=<texto>` | Busca com o texto |
| `ipa://apps/<id>` | Detalhe do app |
| `ipa://downloads` | Downloads |
| `ipa://accounts` | Contas |
| `ipa://accounts/new` | Entrada de conta |
| `ipa://settings` | Ajustes |

## Etapas

| Etapa | Entrega |
| --- | --- |
| 1 | Domínio e dados (`Storefront`, `StoreApp`, `AppQuery`, `Account`, `DownloadRecord`, protocolos), `ITunesCatalog`, `KeychainAccountVault`, downloads no SwiftData, `AccountsModel` e `DownloadCenter`, motor simulado, quatro abas com telas mínimas; remoção do exemplo `Item` |
| 2.1 | Motor: ponte Go, `scripts/ipatool.sh`, `IPAToolCore.xcframework` (iOS, simulador, macOS), `IPAToolEngine`, `JITStatus` |
| 2.2 | Busca, lojas, detalhe do app e versões — feita |
| 2.3 | Downloads e contas — feita |
| 2.4 | Ajustes e guias — feita |
| 3 | Integração, suíte inteira, verificação no simulador e no Mac, README e build para sideload |
