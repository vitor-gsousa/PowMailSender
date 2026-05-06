$SmtpConfig = @{
    SERVER     = "example.com"
    PORT       = 587
    ENABLE_SSL = $false
    USER       = ""
    PASS       = ""
}

$Config = @{
    "Relatorio_Diario" = @{
        FROM          = "teste@empresa.pt"
        TO            = "tecnicos@empresa.pt"
        SUBJECT       = "Relatorio Diario"
        TEMPLATE_PATH = "C:\Scripts\Templates\base.html"
        ANEXO_PATH    = "C:\Scripts\Logs\status.txt"
        ANEXO_AS_BODY = $true

        # Opcional: pode sobrescrever SMTP apenas para este ID.
        # SMTP_SERVER     = "smtp-outro.empresa.pt"
        # SMTP_PORT       = 25
        # SMTP_ENABLE_SSL = $false
        # SMTP_USER       = "outro_user"
        # SMTP_PASS       = "outra_password"
    }
}
