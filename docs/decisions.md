# Decisões

Registro das decisões que moldam o código, em ordem. Cada entrada diz o que foi decidido e por quê; o detalhe de implementação está no código e no histórico do git.

## 15/10/2026: criação do IPA

- **Estrutura do template `apple-sdd`.** Projeto Xcode fino com pasta sincronizada, pacote `IPAKit` com um target por feature (`FeatureHome`, `FeatureGuides`, `FeatureSettings`), `FeatureCore` para o compartilhado e `AppShell` como único ponto que conhece todas. É a forma do Cashly, para que cada app novo saia igual.
- **iOS, iPadOS, macOS e visionOS 27** com o mesmo código, Swift 6 e `ENABLE_DEBUG_DYLIB = NO` (App Intents registram em Debug).
- **Dados em SwiftData com CloudKit** no container `iCloud.ipa`, desligado no simulador; App Group `group.com.byescaleira`.
- **Design system completo** copiado do Cashly, com tokens obrigatórios pelo lint; nada de anéis circulares, toolbar sem `.fill`, `.fontDesign(.rounded)`.
- **Dez idiomas** (en, pt-BR, es, de, fr, it, ja, ko, zh-Hans, ru) num catálogo único, todos traduzidos.
- **`Item` como exemplo vertical** (domínio, dados, Início, editor e testes) para mostrar o caminho completo; é substituído pela primeira entidade real.
- **Sem widget, assinatura ou onboarding no início.** Entram quando o produto pedir, seguindo as referências da skill (`platform-integrations.md`, `monetization.md`, `onboarding-and-guides.md`).
- **Exceções da auditoria (`.apple-sdd.json › allow`).** `literal-color` vale no `IPADesignSystem`, onde as cores são definidas, e no `IPADesignSystemTests`, que testa o `Color(hex:)` com textos de cor; `foreign-localization` vale em `IPADomain/Localization`, que implementa o `String(appLocalized:)`.

## 15/10/2026: reconstrução do DLiPA sobre o ipatool

- **O fork vira um app novo no padrão do apple-sdd, por decisão do usuário.** O repositório do DLiPA só tem README e capturas (o código nunca foi publicado; só o `.ipa` nas Releases). As capturas foram para `docs/reference/` como referência do que o app fazia.
- **Nome `IPA`, pacote `IPAKit`, bundle `com.byescaleira.ipa`, iOS, macOS e visionOS, por decisão do usuário.** As funções geradas pelo template seguem o camelCase de sigla (`.ipaSettings`, `.ipaWindow`), não `.iPASettings`.
- **Distribuição por sideload, sem assinatura nem loja, por decisão do usuário.** O app usa APIs privadas da App Store e não passaria na revisão; StoreKit, paywall e App Store Connect ficam fora.
- **Motor do ipatool embutido como biblioteca, por decisão do usuário.** Desde 28/08/2026 (ipatool 2.4.0) o login exige assinatura SAP e o download exige `kbsync`; o ipatool resolve emulando o `storeagent` do macOS com o Unicorn, que precisa de JIT. Embutir o ipatool (Go `c-archive`) mantém o app em dia com as correções dele, em vez de reescrever cerca de 5 mil linhas de emulação. No Mac funciona com `allow-jit`; no iPhone, iPad e visionOS, só com JIT ativado por fora, e o app explica isso num guia.
- **Busca e detalhes em Swift puro, pela API pública do iTunes.** Funcionam sem conta, sem motor e em todas as plataformas; só login, versões, licença e download passam pelo motor.
- **Dados só locais (CloudKit desligado).** Downloads são arquivos deste aparelho e o sideload costuma tirar os entitlements de iCloud e App Group; um `ModelContainer` com CloudKit sem o entitlement falharia ao abrir.
- **Crítica das telas do DLiPA:** a loja aparecia só como título, sem dizer que muda os resultados; a lista de versões eram 537 números (`875214761`) sem versão legível nem data; o progresso do download era um cartão flutuante cobrindo a lista; os downloads tinham o e-mail como título e nenhuma ação visível; "Search Limit 0" era um número mágico; "Generate new GUID" e "Reset All" não explicavam a consequência nem pediam confirmação.
- **Plano em etapas em `docs/store.md`.** Etapa 1 (domínio, dados, modelos compartilhados e abas) por mim; etapas 2.1 a 2.4 (motor, busca, downloads e contas, ajustes e guias) em frentes paralelas; etapa 3 de integração e verificação.
- **Menu da conta ativa na toolbar de Busca e Downloads (`AccountMenu`, `FeatureCore`).** A receita pede o menu do perfil à esquerda nas abas; aqui o "perfil" é o Apple ID em uso, que decide a loja padrão e onde caem os downloads. O menu troca a conta ativa e tem "Add Account".
- **Prévia do tema mostra a aba Downloads.** A miniatura de Aparência é uma tela real do app (herói com a contagem de pacotes, uma linha baixando com barra e outra pronta), com a barra de abas em cápsula e a Busca no círculo à direita, como o sistema desenha a aba de papel `.search`.
- **Guias e Sobre sem iCloud.** O tour fala das quatro abas; a página de privacidade diz que contas ficam no Keychain e pacotes no app Arquivos, e que o app só conversa com os servidores da Apple.
- **Motor simulado enquanto a etapa 2.1 não chega.** `IPAServices` usa o `SimulatedStoreEngine` em todas as builds até o `IPAToolEngine` existir; a troca é parte da 2.1.
- **Miniatura do tema mostra Downloads, por decisão do usuário (15/10/2026).** A receita pede a tela inicial real e, ao mesmo tempo, herói com número e barras na cor de destaque; a Busca (aba inicial) não tem nem um nem outro. Fica Downloads, com a estrutura da receita, como exceção registrada.
- **Avatar da conta igual ao perfil do Cashly.** `Avatar` (design system) com monograma, símbolo ou imagem; `AccountAvatar` (FeatureCore) usa as iniciais do primeiro e do último nome (`Account.initials`, no domínio) ou, sem nome, da parte local do e-mail; `AccountMenu` repete o `UserMenu` (avatar renderizado nas linhas do picker, `.menuStyle(.button)`).
- **Tour com Lottie próprias (`find`, `setup`, `direct`).** Cada página nova ganhou cena no gerador em vez de reaproveitar uma arte que mostra outra coisa; a `backup` saiu.

## 15/10/2026: peças compartilhadas da loja (etapa 1.1)

- **Textos de exibição da loja no `FeatureCore/Display`.** `StoreApp+Display` (linha "v20.22.1 · iOS 16.0 · 330.5 MB", preço ou "Free"), `DownloadRecord+Display`, `DownloadProgress+Display` (fase e "82.2 MB of 206.5 MB"), `Storefront+Display` (bandeira e nome no idioma do app) e `ByteCount`, porque Busca, Downloads e Ajustes mostram os mesmos números e não podem divergir.
- **`AppArtwork` (`FeatureCore/Icons`) mostra o ícone do app pela URL do iTunes**, com a máscara de ícone (mesma proporção do `AppIconImage`), fio de separação de 1 pt e um símbolo `app.dashed` enquanto carrega ou quando falha; a troca respeita Reduzir movimento.
- **Guias `.jit` e `.install` na categoria nova "Sideloading", com Lottie próprias (`jit`, `install`).** Contas e o detalhe do app abrem o guia de JIT quando o motor não está pronto; a etapa 2.4 completa as páginas.
- **Revisão de design adiada para o fim, por pedido do usuário (15/10/2026).** "Podemos validar com apple-sdd ao final do processo para agilizar, por enquanto só seguimos as orientações de implementação." A lista `ui` do `.apple-sdd.json` fica vazia enquanto as frentes da etapa 2 são integradas; antes do último commit ela volta ao padrão e o `apple-sdd:design-reviewer` revisa tudo de uma vez.

## 15/10/2026: Ajustes e guias (etapa 2.4)

- **Crítica dos Ajustes do DLiPA (captura 5):** "Search Limit 0" com stepper de 1 em 1 era número mágico (0 = todos) para um limite que o iTunes corta em 200; "Generate new GUID" não mostrava o identificador nem avisava que as contas caem; "Reset All" não dizia o que apaga nem pedia confirmação; o motor e o JIT não apareciam; o crédito ao ipatool ficava num rodapé cortado pela barra de abas. **Crítica do template:** os Ajustes só tinham Aparência e Idioma; o Sobre tinha "Rate IPA" (não faz nada fora da App Store), "Website" e "Help Center" apontando para o mesmo repositório e compartilhamento sem link; o tour falava das abas em vez do fluxo; "Make It Yours" repetia a tela de Aparência; JIT e instalação tinham uma página sem passos.
- **Grupos Store (Search, Device Identity, Store Engine) e Data (Storage) entre General e Help**, cada linha um `SettingsRow` com o valor atual (50, Ready, 1,2 GB) e a página em `SettingsPage`, como na receita. "Storage" em vez de "Data" para a linha não repetir o título do grupo.
- **`StoreSettingsModel` por janela, criado num `ModelHost` dentro dos Ajustes.** Ele recebe `SettingsModel`, `SessionModel`, `StorePreferences`, `AccountsModel` e `DownloadCenter` pelo `init`; os models da janela chegam como opcionais do ambiente, então a cena `Settings` do Mac (sem sessão) esconde as linhas da loja sozinha, sem mexer no `AppShell`.
- **Herói em cada página da loja** (receita 1.1): identificador em `.amountTitle` monoespaçado, espaço ocupado em `.amountHero` e a Lottie `jit` com o chip do estado do motor. Cada número aparece uma vez por tela.
- **Nova identidade tira as contas do Keychain.** O token da Apple fica preso ao GUID antigo; deixar as contas daria erro no próximo download. A folha mostra o identificador atual e quantas contas vão sair.
- **"Erase Everything" em duas páginas, como o `EraseScreen` do Cashly** (confirmação com a lixeira que balança e `GuideValueList` do que sai; depois "Everything Erased" com a `done`). Aparência, cor e idioma voltam ao padrão só ao fechar a folha, porque trocar o idioma recria as abas e fecharia a página de conclusão.
- **Sobre:** "Source Code" no lugar de "Website", links repetidos aparecem uma vez, compartilhar manda o link do repositório quando não há ID da App Store, "Rate IPA" só com URL de avaliação, e créditos ao ipatool (MIT) e ao DLiPA.
- **Guias: Meet IPA, Turn On JIT, Install an IPA e Privacy em três categorias (Start Here, Sideloading, Data and Privacy).** O guia "Make It Yours" e a categoria "Personalize" saíram: repetiam a tela de Aparência. JIT e instalação ganharam três páginas, com `GuideSteps` e `GuideLink` (StikDebug, AltStore, Sideloadly) para o que acontece fora do app.
- **Lottie novas pelo gerador: `download`, `identity`, `share` e `computer`;** `editor` e `widgets` saíram por falta de uso. `arrow.triangle.2.circlepath` ficou abaixo de 0,85 no casamento de glifos e foi trocado por `arrow.counterclockwise`.
