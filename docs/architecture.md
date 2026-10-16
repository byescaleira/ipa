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
| `IPADomain` | Entidades (`Item`), valores (`YearMonth`), protocolos de repositório, `IPAError`, `AppLanguage`/`String(appLocalized:)`, `RemoteFlag` | nada |
| `IPAData` | `IPADatabase` (SwiftData + CloudKit `iCloud.ipa`), `IPAStore` (`@ModelActor`), entidades `@Model`, schema versionado, repositórios, `CloudKitFlagSource` | Domain |
| `IPADesignSystem` | Tokens, estilos, modifiers, layouts e componentes sem regra de negócio | nada |
| `IPAResource` | Prévia do ícone e animações Lottie embutidas (`IPAResourceAnimation`) | nada |
| `FeatureCore` | `SessionModel`, navegação (`Route`, `AppSection`, `IPANavigation`, `\.open`, `\.close`), `FeatureFlag`/`FeatureFlags`, guias (`Guide*`), `EmptyStateView`, `MonthPicker`, editor (`EditorStatus`, `EditorActions`, `editorLifecycle`), `errorAlert`, cores retrô, `IPAAnimationView` | Domain, DesignSystem, Resource, Lottie |
| `FeatureHome` | Início: herói, lista e estado vazio; editor de exemplo (`ItemEditorModel`) | Domain, DesignSystem, FeatureCore |
| `FeatureGuides` | `GuideScreen` e páginas dos tutoriais | Domain, DesignSystem, FeatureCore |
| `FeatureSettings` | Ajustes: Aparência (tema, cor de destaque), Idioma, Guias, Sobre, Desenvolvedor (flags) | Domain, DesignSystem, Resource, FeatureCore |
| `AppShell` | `IPAWindow`, `MainScreen`, `SectionStack`, `SectionScreen`, `RouteScreen`, `InspectorScreen`, `SplashScreen`/`LaunchProgress`, `DeepLinks`, `IPAServices` | todas as features |

`Item` é o exemplo vertical que nasce com o template (domínio → dados → feature → testes). Renomeie para a primeira entidade real ou remova quando ela existir.

## Links

| Link | Abre |
| --- | --- |
| `ipa://home` | Início |
| `ipa://items/new` | Editor de item novo |
| `ipa://items/<id>` | Editor do item |
| `ipa://settings` | Ajustes |

## Receita: nova feature

Siga `references/architecture.md › Receita: adicionar uma feature` da skill `apple-sdd`: domínio, dados, target `Feature<Nome>` com model e telas, `Package.swift`, `Route`/`AppSection`, flag se não estiver pronta, testes e `TestableReference` no scheme `IPAKitTests`, textos nos 10 idiomas, `docs/decisions.md`.
