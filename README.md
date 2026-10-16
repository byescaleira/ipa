# IPA

App para iPhone, iPad, Mac e Apple Vision que busca apps da App Store em qualquer loja, entra com o seu Apple ID, lista versões antigas, obtém a licença de apps grátis e baixa o `.ipa` para compartilhar ou instalar por sideload.

É a reconstrução do [DLiPA](https://github.com/AhmedBafkir/DLiPA), de Ahmed Bafkir, sobre o protocolo do [ipatool](https://github.com/majd/ipatool), de Majd Alfhaily. Busca e detalhes usam a API pública do iTunes; login, versões e download usam o motor do ipatool embutido no app.

- [Loja: produto e etapas](docs/store.md)
- [Arquitetura](docs/architecture.md)
- [Design system](docs/design-system.md)
- [Decisões](docs/decisions.md)
- [Backlog](docs/backlog.md)

## Limites

- Só apps grátis podem ser obtidos; app pago mostra o preço.
- O motor do ipatool precisa de JIT. No Mac funciona direto; no iPhone, iPad e Apple Vision sem jailbreak, só com JIT ativado por fora (por exemplo, StikDebug).
- O app usa APIs privadas da App Store e é distribuído por sideload, não pela App Store.

## Instalar

Adicione o source `https://byescaleira.github.io/apps/source.json` no AltStore ou no SideStore. Para publicar uma versão: `scripts/release.sh --publish --notes "<novidades>"`.

## Começando

Abra `IPA.xcworkspace` no Xcode 27 e use o scheme `Production` para o app ou `IPAKitTests` para os testes.

```sh
scripts/format.sh
scripts/lint.sh
scripts/build.sh Debug
scripts/strings.sh
scripts/test.sh
```

Os dados ficam só neste aparelho: downloads em `Documents/Downloads/<conta>/` (visíveis no app Arquivos), registros no SwiftData e contas no Keychain.
