# Distribuição pelo AltStore PAL

Roteiro para publicar o IPA notarizado no AltStore PAL (UE, Japão e Brasil). A decisão está em [decisions.md](decisions.md); o sideload sem assinatura (AltStore Classic e SideStore) continua no `source.json` do [byescaleira/apps](https://github.com/byescaleira/apps).

Referências: [Distribute with AltStore PAL](https://faq.altstore.io/developers/distribute-with-altstore-pal), [REST API do AltStore](https://faq.altstore.io/developers/rest-api), [Submit for notarization (Apple)](https://developer.apple.com/help/app-store-connect/distributing-apps-in-the-european-union/submit-for-notarization).

## Passos

| # | Passo | Quem | Estado |
| --- | --- | --- | --- |
| 1 | Aceitar o *Alternative Terms Addendum* em App Store Connect › Business › Agreements | usuário (Account Holder) | — |
| 2 | Pegar o **Developer ID** em App Store Connect › nome no canto › Edit Profile (é um UUID, não o Team ID `Q7QLR2PH2X`) | usuário | — |
| 3 | `POST https://api.altstore.io/register` com o Developer ID e o e-mail; devolve um token | Claude, com o Developer ID | — |
| 4 | App Store Connect › Users and Access › Integrations › Marketplace › `+`: colar o token, escolher o IPA, "Yes, send notifications" | usuário | — |
| 5 | Criar o app em App Store Connect › Apps › `+` › New App (dados abaixo) | usuário | — |
| 6 | No Xcode: abrir `IPA.xcworkspace`, scheme **Production**, destino **Any iOS Device (arm64)**, Product › Archive › Distribute App › App Store Connect › Upload (assinatura automática) | usuário | — |
| 7 | Na página do app: preencher os metadados (abaixo), App Review › Review Type › **Notarization**, escolher o build 1.0 (2) e enviar | usuário | — |
| 8 | Depois da aprovação (o artigo citou cerca de 30 h): pegar o **ADP ID** do build e o **Apple ID** do app (App Information) | usuário | — |
| 9 | `POST https://api.altstore.io/adps` com o ADP ID, `GET …/adps/<id>` até ter o `downloadURL`, baixar o pacote e hospedar sem alterar nenhum arquivo em `byescaleira/apps/pal/ipa/<versão>/` | Claude | — |
| 10 | Criar `pal.json` (source separado do `source.json`) com `marketplaceID` e o `downloadURL` apontando para o `manifest.json` hospedado | Claude | — |
| 11 | Adicionar `https://byescaleira.github.io/apps/pal.json` no AltStore PAL | usuário | — |

## Dados do app (passo 5)

| Campo | Valor |
| --- | --- |
| Platforms | iOS |
| Name | IPA byescaleira |
| Primary Language | English (U.S.) |
| Bundle ID | `com.byescaleira.ipa` (criado pelo Xcode na primeira assinatura, ou em Certificates, Identifiers & Profiles) |
| SKU | `com.byescaleira.ipa` |
| User Access | Full Access |

## Metadados (passo 7)

**Subtitle** (até 30 caracteres)

```text
Search apps in any App Store
```

**Promotional Text**

```text
Search any App Store country and see every app detail and identifier: version, minimum iOS, size, price, bundle ID and app ID.
```

**Description**

```text
IPA searches apps in any App Store country and shows the details developers and testers look for: version, minimum iOS, size, price, seller, bundle ID, app ID and link, each one ready to copy or share.

• Search by name, bundle ID, App Store link or app ID.
• Switch the store country from the toolbar and compare local prices and availability.
• Copy identifiers with a tap, or share the App Store link.
• Guides explain sideloading and installing a package on a device.

Privacy first: IPA has no servers, no analytics and no ads, and it talks only to Apple's public search service.

IPA is a rebuild of DLiPA by Ahmed Bafkir, built on the ideas of ipatool by Majd Alfhaily.
```

**Keywords**

```text
ipa,app store,bundle id,app id,storefront,versions,sideload,altstore,developer,search
```

| Campo | Valor |
| --- | --- |
| Support URL | `https://github.com/byescaleira/ipa/issues` |
| Marketing URL | `https://byescaleira.github.io/apps/` |
| Privacy Policy URL | `https://byescaleira.github.io/apps/privacy/` |
| Category | Utilities (secundária: Developer Tools) |
| Copyright | `2026 Rafael Escaleira` |
| Age Rating | todas as respostas "None" / "No" |
| App Privacy | Data Not Collected |
| Price | Free |
| Review Type | Notarization |

**Screenshots:** se o App Store Connect pedir, gero o conjunto de 6,9" no simulador do iPhone 17 Pro Max (1320 × 2868). As capturas de `docs/screenshots/` são de 6,3".

## Observações

- O build notarizado usa o `UnavailableStoreEngine` (Release): busca e detalhes funcionam; login e download dizem que o motor ainda não está disponível. A descrição acima fala só do que o build faz (regra 2 do AltStore PAL: os metadados precisam refletir o app); quando o motor chegar, a descrição ganha contas e downloads.
- O source do PAL é separado (`pal.json`): o AltStore recusa misturar apps notarizados e de sideload no mesmo source.
- Cada versão nova: subir `CURRENT_PROJECT_VERSION` (e `MARKETING_VERSION` quando mudar), enviar, notarizar, processar o ADP e acrescentar a versão no `pal.json`.
- Taxas: a Apple cobra a Core Technology Commission de 5% sobre vendas digitais; o IPA é grátis e sem compras.
