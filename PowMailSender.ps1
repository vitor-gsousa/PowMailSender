[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)]
	[string]$ID
)

$ErrorActionPreference = 'Stop'

function Resolve-ConfigPath {
	param([string]$Path)

	if ([string]::IsNullOrWhiteSpace($Path)) {
		return $null
	}

	if ([System.IO.Path]::IsPathRooted($Path)) {
		return $Path
	}

	return (Join-Path -Path $PSScriptRoot -ChildPath $Path)
}

function Get-FileTextUtf8 {
	param([string]$Path)

	return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

try {
	Write-Host "[PowMailSender] A iniciar..."

	$configPath = Join-Path -Path $PSScriptRoot -ChildPath 'config.ps1'
	if (-not (Test-Path -LiteralPath $configPath)) {
		throw "Ficheiro de configuração não encontrado: $configPath"
	}

	Write-Host "[PowMailSender] A carregar configuração..."
	$configScriptText = Get-FileTextUtf8 -Path $configPath
	$configScriptBlock = [ScriptBlock]::Create($configScriptText)
	. $configScriptBlock

	if (-not $Config) {
		throw 'A variável $Config não foi encontrada em config.ps1'
	}

	if (-not $Config.ContainsKey($ID)) {
		throw "ID '$ID' não existe no ficheiro de configuração."
	}

	$job = $Config[$ID]

	$from = $job.FROM
	$to = $job.TO
	$subject = if ($job.SUBJECT) { [string]$job.SUBJECT } else { "PowMailSender - $ID" }
	$templatePath = Resolve-ConfigPath -Path ([string]$job.TEMPLATE_PATH)
	$anexoPath = Resolve-ConfigPath -Path ([string]$job.ANEXO_PATH)
	$anexoAsBody = [bool]$job.ANEXO_AS_BODY

	$smtpServer = if ($job.SMTP_SERVER) { [string]$job.SMTP_SERVER } elseif ($SmtpConfig.SERVER) { [string]$SmtpConfig.SERVER } else { 'localhost' }
	$smtpPort = if ($job.SMTP_PORT) { [int]$job.SMTP_PORT } elseif ($SmtpConfig.PORT) { [int]$SmtpConfig.PORT } else { 25 }
	$enableSsl = if ($null -ne $job.SMTP_ENABLE_SSL) { [bool]$job.SMTP_ENABLE_SSL } elseif ($null -ne $SmtpConfig.ENABLE_SSL) { [bool]$SmtpConfig.ENABLE_SSL } else { $false }
	$smtpUser = if ($job.SMTP_USER) { [string]$job.SMTP_USER } elseif ($SmtpConfig.USER) { [string]$SmtpConfig.USER } else { $null }
	$smtpPass = if ($job.SMTP_PASS) { [string]$job.SMTP_PASS } elseif ($SmtpConfig.PASS) { [string]$SmtpConfig.PASS } else { $null }

	if ([string]::IsNullOrWhiteSpace($from)) { throw "FROM não definido para ID '$ID'." }
	if ([string]::IsNullOrWhiteSpace($to)) { throw "TO não definido para ID '$ID'." }

	Write-Host "[PowMailSender] A montar corpo HTML..."
	$htmlBody = '<html><body><p>Mensagem automática.</p></body></html>'

	if (-not [string]::IsNullOrWhiteSpace($templatePath)) {
		if (-not (Test-Path -LiteralPath $templatePath)) {
			throw "TEMPLATE_PATH não encontrado: $templatePath"
		}
		$htmlBody = Get-FileTextUtf8 -Path $templatePath
	}

	$attachments = New-Object System.Collections.Generic.List[System.Net.Mail.Attachment]

	if (-not [string]::IsNullOrWhiteSpace($anexoPath) -and (Test-Path -LiteralPath $anexoPath)) {
		$extension = [System.IO.Path]::GetExtension($anexoPath)

		if ($anexoAsBody -and $extension -ieq '.txt') {
			Write-Host "[PowMailSender] A incorporar TXT no corpo do email..."
			$txtContent = Get-FileTextUtf8 -Path $anexoPath
			$safeContent = [System.Net.WebUtility]::HtmlEncode($txtContent)
			$bodyFromTxt = "<pre>$safeContent</pre>"
			if ($htmlBody.Contains('{{ANEXO_CONTEUDO}}')) {
				$htmlBody = $htmlBody.Replace('{{ANEXO_CONTEUDO}}', $bodyFromTxt)
			}
			else {
				$htmlBody += "`r`n<hr/>`r`n$bodyFromTxt"
			}
		}
		elseif (-not $anexoAsBody) {
			Write-Host "[PowMailSender] A adicionar anexo..."
			$attachment = New-Object System.Net.Mail.Attachment($anexoPath)
			$attachments.Add($attachment)
		}
	}
	elseif (-not [string]::IsNullOrWhiteSpace($anexoPath)) {
		Write-Host "[PowMailSender] Aviso: ANEXO_PATH não encontrado, a continuar sem anexo."
	}

	Write-Host "[PowMailSender] A preparar mensagem..."
	$mailMessage = New-Object System.Net.Mail.MailMessage
	$mailMessage.From = [System.Net.Mail.MailAddress]::new($from)

	foreach ($dest in ($to -split ';|,')) {
		$trimmed = $dest.Trim()
		if (-not [string]::IsNullOrWhiteSpace($trimmed)) {
			$mailMessage.To.Add($trimmed)
		}
	}

	$mailMessage.Subject = $subject
	$mailMessage.SubjectEncoding = [System.Text.Encoding]::UTF8
	$mailMessage.BodyEncoding = [System.Text.Encoding]::UTF8
	$mailMessage.HeadersEncoding = [System.Text.Encoding]::UTF8
	$mailMessage.IsBodyHtml = $true
	$mailMessage.Body = $htmlBody

	foreach ($att in $attachments) {
		$mailMessage.Attachments.Add($att)
	}

	$smtpClient = New-Object System.Net.Mail.SmtpClient($smtpServer, $smtpPort)
	$smtpClient.EnableSsl = $enableSsl
	if ($smtpUser -and $smtpPass) {
		$smtpClient.Credentials = New-Object System.Net.NetworkCredential($smtpUser, $smtpPass)
	}

	Write-Host "[PowMailSender] A enviar email..."
	$smtpClient.Send($mailMessage)
	Write-Host "[PowMailSender] Envio concluído com sucesso."

	$mailMessage.Dispose()
	$smtpClient.Dispose()
}
catch {
	Write-Host "[PowMailSender] Erro: $($_.Exception.Message)"
	exit 1
}
