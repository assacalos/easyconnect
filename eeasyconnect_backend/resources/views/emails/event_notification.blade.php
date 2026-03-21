@php
    // Laravel Mail injecte automatiquement $message (objet Illuminate\Mail\Message). Ne pas l'utiliser dans la vue.
    unset($message);
    // Utiliser uniquement les données passées par le Mailable (EventNotificationMail).
    $safeTitre = is_string($titre ?? null) ? $titre : '';
    $safeBody = is_string($body ?? null) ? $body : '';
    $safeRecipientName = is_string($recipientName ?? null) ? $recipientName : null;
    $safeActionUrl = is_string($actionUrl ?? null) ? $actionUrl : null;
    $safeActionLabel = is_string($actionLabel ?? null) ? $actionLabel : 'Voir dans l\'application';
@endphp
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $safeTitre }}</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f4f4f5; color: #18181b;">
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #f4f4f5; padding: 24px 16px;">
        <tr>
            <td align="center">
                <table role="presentation" width="600" cellspacing="0" cellpadding="0" style="max-width: 600px; width: 100%; background-color: #ffffff; border-radius: 12px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); overflow: hidden;">
                    <tr>
                        <td style="padding: 28px 32px; border-bottom: 1px solid #e4e4e7;">
                            <h1 style="margin: 0; font-size: 20px; font-weight: 600; color: #18181b;">{{ $safeTitre }}</h1>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 28px 32px;">
                            @if(!empty($safeRecipientName))
                                <p style="margin: 0 0 16px; font-size: 15px; line-height: 1.6; color: #3f3f46;">Bonjour {{ $safeRecipientName }},</p>
                            @endif
                            <p style="margin: 0 0 24px; font-size: 15px; line-height: 1.6; color: #3f3f46;">{!! nl2br(e($safeBody)) !!}</p>
                            @if(!empty($safeActionUrl))
                                <p style="margin: 0;">
                                    <a href="{{ $safeActionUrl }}" style="display: inline-block; padding: 12px 24px; background-color: #7c3aed; color: #ffffff; text-decoration: none; font-size: 14px; font-weight: 500; border-radius: 8px;">{{ $safeActionLabel }}</a>
                                </p>
                            @else
                                <p style="margin: 0; font-size: 13px; color: #71717a;">Connectez-vous à l'application EasyConnect pour plus de détails.</p>
                            @endif
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 16px 32px; background-color: #fafafa; border-top: 1px solid #e4e4e7;">
                            <p style="margin: 0; font-size: 12px; color: #71717a;">Cet email a été envoyé automatiquement par {{ config('app.name', 'EasyConnect') }}. Ne pas répondre à ce message.</p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
