# PowMailSender

Sistema simples em PowerShell para envio de emails HTML por configuração, com suporte a template, anexo e execução via Batch/CMD.

## Estrutura do projeto

- `config.ps1`: configuração global SMTP e perfis de envio por ID.
- `PowMailSender.ps1`: script executor que lê a configuração e envia email.
- `Send.cmd`: exemplo de chamada para uso em batch/agendador.

## Funcionalidades

- Seleção de configuração por ID (`-ID` obrigatório).
- Corpo em HTML com template externo (`TEMPLATE_PATH`).
- Suporte a anexo de ficheiro (`ANEXO_PATH`).
- Modo especial para `.txt` no corpo:
  - Se `ANEXO_AS_BODY = $true` e `ANEXO_PATH` for `.txt`, o conteúdo do ficheiro é incorporado no email dentro de `<pre>`, preservando quebras de linha.
- Leitura de ficheiros em UTF-8.
- Envio com `SubjectEncoding` e `BodyEncoding` em UTF-8.
- Logs curtos com `Write-Host` para acompanhar progresso em CMD/Batch.
- SMTP global sem repetição:
  - Definido uma vez em `$SmtpConfig`.
  - Possibilidade de override por ID (`SMTP_*` no bloco do ID).
- Autenticação SMTP opcional:
  - Se `USER/PASS` existirem, usa credenciais.
  - Se não existirem, tenta envio sem autenticação (útil em SMTP interno com relay permitido).

## Requisitos

- Windows com PowerShell disponível.
- Acesso ao servidor SMTP configurado.
- Permissões de relay/autenticação conforme política do SMTP.

## Configuração

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

Se o teu SMTP interno não exigir autenticação ou SSL, podes remover ou deixar vazio `USER` e `PASS` ou `ENABLE_SSL = $false`.

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

- `TO` pode ter vários destinatários separados por `;` ou `,`.
- `TEMPLATE_PATH` e `ANEXO_PATH` aceitam caminho absoluto ou relativo à pasta do script.
- Placeholder de template: `{{ANEXO_CONTEUDO}}`
  - Quando `ANEXO_AS_BODY = $true` e `ANEXO_PATH` aponta para um `.txt`, o conteúdo é inserido neste placeholder como HTML seguro dentro de `<pre>`.
  - Se o placeholder nao existir no template, o script adiciona o conteúdo no fim do corpo com um `<hr/>`.

### 3) Exemplo simples de template HTML

```html
<!doctype html>
<html lang="pt">
<head>
    <meta charset="utf-8" />
    <title>Relatorio Diario</title>
</head>
<body>
    <h2>Relatorio Diario</h2>
    <p>Segue o conteudo processado automaticamente:</p>

    {{ANEXO_CONTEUDO}}

    <p>--<br/>PowMailSender</p>
</body>
</html>
```

## Como Utilizar

### Opção A: executar direto no PowerShell

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\PowMailSender.ps1" -ID "Relatorio_Diario"
```

### Opção B: executar via Batch/CMD

Usar `Send.cmd`:

```bat
@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "PowMailSender.ps1" -ID "Relatorio_Diario"
endlocal
```

## Fluxo de execução

1. Carrega `config.ps1`.
2. Procura o bloco do ID recebido.
3. Resolve SMTP (override por ID -> global -> fallback).
4. Monta corpo HTML (template ou default).
5. Processa `ANEXO_PATH`:
   - `.txt` + `ANEXO_AS_BODY = $true`: incorpora no HTML com `<pre>`.
   - caso contrario: adiciona como anexo quando `ANEXO_AS_BODY = $false`.
6. Envia email e escreve progresso no terminal.

## Mensagens de consola (exemplo)

- `[PowMailSender] A iniciar...`
- `[PowMailSender] A carregar configuracao...`
- `[PowMailSender] A montar corpo HTML...`
- `[PowMailSender] A enviar email...`
- `[PowMailSender] Envio concluido com sucesso.`

## Troubleshooting rápido

- Erro `ID 'X' nao existe`: confirma se o ID esta definido em `$Config`.
- Erro de template/anexo não encontrado: valida caminhos em `TEMPLATE_PATH` e `ANEXO_PATH`.
- Falha de envio SMTP:
  - confirma `SERVER`, `PORT`, `ENABLE_SSL`.
  - confirma se requer autenticação (`USER/PASS`).
  - para SMTP interno sem autenticação, valida permissões de relay para o host onde o script corre.
- Caracteres estranhos no email:
  - garantir que ficheiros de template/txt estão em UTF-8.

## Boas práticas

- Não guardar passwords reais em texto simples em repositórios partilhados.
- Em produção, preferir obter credenciais de um cofre/secret store.
- Manter `config.ps1` fora de controlo de versão se tiver dados sensíveis.
