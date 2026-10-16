# IPA

Siga a skill `apple-sdd` em todo trabalho neste repositório (processo, arquitetura, código, design, idiomas, testes, verificação e release). Responda em pt-BR; código, chaves de texto e commits em inglês.

- Documentação: `docs/architecture.md`, `docs/design-system.md`, `docs/decisions.md`, `docs/backlog.md`, `docs/roadmap.md`.
- Scripts: `scripts/format.sh`, `scripts/lint.sh`, `scripts/build.sh Debug`, `scripts/strings.sh`, `scripts/test.sh` (simulador só pelo sim-monitor), `scripts/icons.sh`, `python3 scripts/animations.py`.
- Fiscalização: `.apple-sdd.json` (auditoria do plugin) e `.swiftlint.yml`.
- Cache de build: `~/Library/Developer/IPABuild` (ou `IPA_BUILD_ROOT` por agente).
- Git flow: `main` (loja), `development` (integração) e `feature/<assunto>` saindo da `development` e voltando com `git merge --no-ff`; `main` só por merge pedido pelo usuário.
