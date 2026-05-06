# PowMailSender

Sistema simples em PowerShell para envio de emails HTML por configuracao, com suporte a template, anexo e execucao via Batch/CMD.

## Estrutura do projeto

- `config.ps1`: configuracao global SMTP e perfis de envio por ID.
- `PowMailSender.ps1`: script executor que le configuracao e envia email.
- `Send.bat`: exemplo de chamada para uso em batch/agendador.

## Funcionalidades

- Selecao de configuracao por ID (`-ID` obrigatorio).
- Corpo em HTML com template externo (`TEMPLATE_PATH`).
- Suporte a anexo de ficheiro (`ANEXO_PATH`).
- Modo especial para `.txt` no corpo:
  - Se `ANEXO_AS_BODY = $true` e `ANEXO_PATH` for `.txt`, o conteudo do ficheiro e incorporado no email dentro de `<pre>`, preservando quebras de linha.
- Leitura de ficheiros em UTF-8.
- Envio com `SubjectEncoding` e `BodyEncoding` em UTF-8.
- Logs curtos com `Write-Host` para acompanhar progresso em CMD/Batch.
- SMTP global sem repeticao:
  - Definido uma vez em `$SmtpConfig`.
  - Possibilidade de override por ID (`SMTP_*` no bloco do ID).
- Autenticacao SMTP opcional:
  - Se `USER/PASS` existirem, usa credenciais.
  - Se nao existirem, tenta envio sem autenticacao (util em SMTP interno com relay permitido).

## Requisitos

- Windows com PowerShell disponivel.
- Acesso ao servidor SMTP configurado.
- Permissoes de relay/autenticacao conforme politica do SMTP.

## Configuracao

Editar `config.ps1`.

### 1) SMTP global (recomendado)

```powershell
$SmtpConfig = @{
    SERVER     = "smtp.empresa.pt"
    PORT       = 587
    ENABLE_SSL = $true
    USER       = "smtp_user"
    PASS       = "smtp_password"
}
```

Se o teu SMTP interno nao exigir autenticacao, podes remover ou deixar vazio `USER` e `PASS`.

### 2) Perfis por ID

```powershell
$Config = @{
    "Relatorio_Diario" = @{
        FROM          = "sistema@empresa.pt"
        TO            = "tecnicos@empresa.pt"
        SUBJECT       = "Relatorio Diario"
        TEMPLATE_PATH = "C:\Scripts\Templates\base.html"
        ANEXO_PATH    = "C:\Scripts\Logs\status.txt"
        ANEXO_AS_BODY = $true

        # Opcional: override SMTP apenas para este ID
        # SMTP_SERVER     = "smtp-outro.empresa.pt"
        # SMTP_PORT       = 25
        # SMTP_ENABLE_SSL = $false
        # SMTP_USER       = "outro_user"
        # SMTP_PASS       = "outra_password"
    }
}
```

Notas:

- `TO` pode ter varios destinatarios separados por `;` ou `,`.
- `TEMPLATE_PATH` e `ANEXO_PATH` aceitam caminho absoluto ou relativo a pasta do script.

## How To Usar

### Opcao A: executar direto no PowerShell

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\PowMailSender.ps1" -ID "Relatorio_Diario"
```

### Opcao B: executar via Batch/CMD

Usar `Send.bat`:

```bat
@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0PowMailSender.ps1" -ID "Relatorio_Diario"
endlocal
```

## Fluxo de execucao

1. Carrega `config.ps1`.
2. Procura o bloco do ID recebido.
3. Resolve SMTP (override por ID -> global -> fallback).
4. Monta corpo HTML (template ou default).
5. Processa `ANEXO_PATH`:
   - `.txt` + `ANEXO_AS_BODY = $true`: incorpora no HTML com `<pre>`.
   - caso contrario: adiciona como anexo quando `ANEXO_AS_BODY = $false`.
6. Envia email e escreve progresso no ecran.

## Mensagens de consola (exemplo)

- `[PowMailSender] A iniciar...`
- `[PowMailSender] A carregar configuracao...`
- `[PowMailSender] A montar corpo HTML...`
- `[PowMailSender] A enviar email...`
- `[PowMailSender] Envio concluido com sucesso.`

## Troubleshooting rapido

- Erro `ID 'X' nao existe`: confirma se o ID esta definido em `$Config`.
- Erro de template/anexo nao encontrado: valida caminhos em `TEMPLATE_PATH` e `ANEXO_PATH`.
- Falha de envio SMTP:
  - confirma `SERVER`, `PORT`, `ENABLE_SSL`.
  - confirma se requer autenticacao (`USER/PASS`).
  - para SMTP interno sem autenticacao, valida permissoes de relay para o host onde o script corre.
- Caracteres estranhos no email:
  - garantir que ficheiros de template/txt estao em UTF-8.

## Boas praticas

- Nao guardar passwords reais em texto simples em repositorios partilhados.
- Em producao, preferir obter credenciais de um cofre/secret store.
- Manter `config.ps1` fora de controlo de versao se tiver dados sensiveis.
