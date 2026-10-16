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
