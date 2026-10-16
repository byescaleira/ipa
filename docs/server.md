# Motor no servidor

O motor real (ipatool + emulador da storeagent) precisa de JIT. No iOS, JIT só
liga com o device conectado ao Xcode (`CS_DEBUGGED`) ou com um ativador on-device
que o sistema expõe como VPN. Para rodar sem cabo e sem VPN, o motor sai do
telefone: um serviço HTTP roda o ipatool num servidor comum (Linux ou macOS, onde
o Unicorn executa nativo, sem as restrições de W^X do iOS) e o app vira um cliente
fino que fala HTTPS com ele.

Trade-off: o e-mail, a senha e o código 2FA do Apple ID trafegam até o servidor.
Use só um servidor seu, sob HTTPS, com `IPA_SERVER_TOKEN` definido.

## API

Todas as rotas `POST` recebem e devolvem JSON e exigem `Authorization: Bearer
<token>` quando `IPA_SERVER_TOKEN` está definido. Erros vêm como
`{"error":{"code","message"}}` com os mesmos códigos do bridge embarcado
(`code_required`, `license_required`, `token_expired`, `not_found`, `cancelled`,
`other`).

- `GET /health` → `{"ok":true}`.
- `POST /v1/login` ← `{email,password,code,macAddress}` → `{account}`. O `account`
  é a credencial opaca do ipatool; o app guarda no vault e reenvia como
  `credential` nas demais chamadas.
- `POST /v1/versions` ← `{credential,macAddress,appID,bundleID}` →
  `{versions,latest}`.
- `POST /v1/version` ← `{...,versionID}` → `{displayVersion,releaseDate}`.
- `POST /v1/download` ← `{credential,macAddress,appID,bundleID,versionID}` → corpo
  `application/octet-stream` com o `.ipa` já assinado (`ReplicateSinf`), tamanho em
  `Content-Length` e versão em `X-IPA-Version`. O servidor compra a licença
  sozinho quando falta e baixa para um diretório temporário que apaga ao fim.

O `macAddress` é a identidade de device do app (`DeviceIdentity`); mande o mesmo
valor no login e nas chamadas seguintes para o ipatool manter o mesmo vínculo.

## Configuração

- `IPA_SERVER_ADDRESS` — endereço de escuta (padrão `:8080`).
- `IPA_SERVER_TOKEN` — token exigido no `Authorization`. Sem ele o servidor **não
  sobe** (fail-closed); para teste local sem token, defina
  `IPA_SERVER_ALLOW_NO_AUTH=1`.
- `IPA_SERVER_CACHE` — diretório dos assets da SAP (storeagent) e dos downloads
  temporários. Padrão: `UserCacheDir/ipa-server`.

O servidor mantém a sessão do ipatool viva por conta (chaveada pelo DSID) para
reusar os cookies do login nas chamadas seguintes; sessões expiram em 30 min de
ociosidade e o cache é limitado a 64 contas. Ele encerra de forma graciosa em
`SIGINT`/`SIGTERM` (até 20 s), tem timeouts de leitura e limita o corpo das
requisições a 1 MiB. Faça o build com um Go atual: o `govulncheck` aponta CVEs da
biblioteca padrão (`net/http`) corrigidas a partir do `go1.26.6`, que a imagem
`golang:1.26-bookworm` do `Dockerfile` já traz.

## Build e deploy

Binário local:

```bash
scripts/server.sh
IPA_SERVER_TOKEN=... engine/build/ipa-server
```

Imagem de container (clona o ipatool no commit fixo, não depende do `.ipatool`
local):

```bash
scripts/server.sh --docker
docker run -p 8080:8080 -e IPA_SERVER_TOKEN=... -v ipa-cache:/var/lib/ipa-server ipa-server
```

Exponha sob HTTPS (proxy reverso ou túnel). Para servir de casa sem VPN no
telefone, um túnel público (ex.: Cloudflare Tunnel) dá uma URL HTTPS sem abrir
portas.
