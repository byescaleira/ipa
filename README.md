# IPA

App SwiftUI para iOS, iPadOS, macOS e visionOS 27, com SwiftData local e sincronização CloudKit em aparelhos assinados. Criado com o template do plugin `apple-sdd`.

- [Arquitetura](docs/architecture.md)
- [Design system](docs/design-system.md)
- [Decisões](docs/decisions.md)
- [Backlog](docs/backlog.md)
- [Roadmap](docs/roadmap.md)

## Começando

Abra `IPA.xcworkspace` no Xcode 27 e use o scheme `Production` para o app ou `IPAKitTests` para os testes.

```sh
scripts/format.sh
scripts/lint.sh
scripts/build.sh Debug
scripts/strings.sh
scripts/test.sh
```

O simulador usa o banco local com CloudKit desligado. Nos aparelhos, o app usa o container `iCloud.ipa`.
