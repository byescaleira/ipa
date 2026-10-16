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
