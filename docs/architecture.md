# Arquitetura

O IPA segue a arquitetura padrão dos apps do Rafael (skill `apple-sdd`, `references/architecture.md`): um projeto Xcode fino que abre o banco e entrega a janela ao pacote `IPAKit`, com um target por feature. As features não se importam; navegam pedindo uma `Route` ao `AppShell`. Models `@MainActor @Observable` chegam às telas pelo `Environment`.

## Repositório

```text
ipa/
├── IPA.xcworkspace          projeto + pacote; scheme compartilhado IPAKitTests
├── IPA/
│   ├── IPA.xcodeproj        target IPA (pasta sincronizada); scheme Production
│   └── IPA/                 IPAApp.swift, Info.plist, entitlements, Assets, IPAIcon.icon, Localizable.xcstrings
├── IPAKit/                  Package.swift, Sources/<Target>, Tests/<Target>Tests
├── scripts/                     build, lint, format, test, strings, icons, animations, simulator
├── ci_scripts/                  Xcode Cloud
└── docs/                        este arquivo, design-system, decisions, backlog, roadmap
```

## Targets

| Target | Responsabilidade | Depende de |
| --- | --- | --- |
| `IPADomain` | Entidades (`StoreApp`, `Account`, `AppVersion`, `DownloadRecord`), valores (`Storefront` e a tabela das 134 lojas, `DeviceIdentity`, `DownloadProgress`, `EngineAvailability`), regras (`AppQuery`, `PackageName`), protocolos (`StoreCatalog`, `StoreEngine`, `AccountVault`, `DownloadRepository`), `StoreServices`, `DownloadFolder`, `IPAError`, `AppLanguage`/`String(appLocalized:)`, `RemoteFlag` | nada |
| `IPAData` | `ITunesCatalog` (busca e lookup na API pública do iTunes), `KeychainAccountVault` (contas e identidade do aparelho no Keychain), `IPADatabase` (SwiftData local, sem CloudKit), `IPAStore` (`@ModelActor`), `DownloadEntity`, schema versionado, `SwiftDataDownloadRepository` | Domain |
| `IPAMock` | `SimulatedStoreEngine` (motor sem rede: código de dois fatores para e-mails com `2fa`, versões e download falsos), `InMemoryAccountVault`, `SampleCatalog`, `SampleApps` | Domain |
| `IPADesignSystem` | Tokens, estilos, modifiers, layouts e componentes sem regra de negócio | nada |
| `IPAResource` | Prévia do ícone e animações Lottie embutidas (`IPAResourceAnimation`) | nada |
| `FeatureCore` | `AppArtwork` (`Icons/`), textos de exibição da loja (`Display/`), `AccountAvatar` e `AccountMenu` (`Accounts/`), `SessionModel` (repositórios, `StoreServices`, estado do motor), `StorePreferences` (loja e resultados por busca), `AccountsModel` (contas e a ativa), `DownloadCenter` (fila, progresso, licença de app grátis, registros e arquivos), navegação (`Route`, `AppSection`, `IPANavigation`, `\.open`, `\.close`), `FeatureFlag`/`FeatureFlags`, guias (`Guide*`), `EmptyStateView`, `errorAlert`, cores retrô, `IPAAnimationView` | Domain, DesignSystem, Resource, Lottie |
| `FeatureSearch` | Busca, lojas (`StorefrontScreen`), detalhe do app e versões (`AppModel`, `AppScreen`) | Domain, DesignSystem, FeatureCore |
| `FeatureLibrary` | Downloads: em andamento e por conta (`LibraryModel`, `LibraryScreen`) | Domain, DesignSystem, FeatureCore |
| `FeatureAccounts` | Contas e entrada com código de dois fatores (`SignInModel`, `AccountsScreen`, `SignInScreen`) | Domain, DesignSystem, FeatureCore |
| `FeatureGuides` | `GuideScreen` e páginas dos tutoriais | Domain, DesignSystem, FeatureCore |
| `FeatureSettings` | Ajustes: busca, identidade do aparelho, dados, Aparência, Idioma, Guias, Sobre, Desenvolvedor (flags) | Domain, DesignSystem, Resource, FeatureCore |
| `AppShell` | `IPAWindow` (cria os models da janela), `MainScreen` (quatro abas), `SectionStack`, `SectionScreen`, `RouteScreen`, `InspectorScreen`, `SplashScreen`/`LaunchProgress`, `DeepLinks`, `IPAServices` (banco e `StoreServices` do processo) | todas as features, Data, Mock |

A spec do produto (telas, motor, etapas) está em [store.md](store.md).

## Links

| Link | Abre |
| --- | --- |
| `ipa://search?q=<texto>` | Busca com o texto |
| `ipa://apps/<id>` | Detalhe do app |
| `ipa://downloads` | Downloads |
| `ipa://accounts` | Contas |
| `ipa://accounts/new` | Entrada de conta |
| `ipa://settings` | Ajustes |

## Receita: nova feature

Siga `references/architecture.md › Receita: adicionar uma feature` da skill `apple-sdd`: domínio, dados, target `Feature<Nome>` com model e telas, `Package.swift`, `Route`/`AppSection`, flag se não estiver pronta, testes e `TestableReference` no scheme `IPAKitTests`, textos nos 10 idiomas, `docs/decisions.md`.
