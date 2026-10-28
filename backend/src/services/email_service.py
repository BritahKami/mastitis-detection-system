import smtplib
import asyncio
import logging
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from src.config.config import settings

logger = logging.getLogger("mds.email_service")


class EmailService:
    """
    Asynchronous email service handling verification and notification emails via SMTP.
    In development / test environments without active SMTP credentials, it safely logs
    the OTP to the console.
    """

    @classmethod
    def _send_sync(cls, to_email: str, subject: str, html_content: str, text_content: str) -> bool:
        """
        Synchronous SMTP email dispatcher using Python built-in smtplib.
        """
        if not settings.SMTP_USER or not settings.SMTP_PASSWORD:
            logger.info(
                f"[DEV/MOCK EMAIL] To: {to_email} | Subject: '{subject}'\n"
                f"Content: {text_content}"
            )
            return True

        msg = MIMEMultipart("alternative")
        msg["Subject"] = subject
        msg["From"] = f"{settings.SMTP_FROM_NAME} <{settings.SMTP_FROM_EMAIL or settings.SMTP_USER}>"
        msg["To"] = to_email

        # Attach text and html versions
        part1 = MIMEText(text_content, "plain")
        part2 = MIMEText(html_content, "html")
        msg.attach(part1)
        msg.attach(part2)

        try:
            with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=15) as server:
                if settings.SMTP_TLS:
                    server.starttls()
                server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
                server.sendmail(settings.SMTP_FROM_EMAIL or settings.SMTP_USER, to_email, msg.as_string())
            logger.info(f"Verification email successfully sent to {to_email}")
            return True
        except Exception as e:
            logger.error(f"Failed to send email to {to_email} via SMTP: {str(e)}")
            # Log the fallback OTP message so development/testing is not blocked
            logger.info(
                f"[FALLBACK LOG] To: {to_email} | Subject: '{subject}' | Message: {text_content}"
            )
            return False

    @classmethod
    async def send_otp_email(
        cls,
        to_email: str,
        code: str,
        purpose: str = "login",
        expire_minutes: int = 10
    ) -> bool:
        """
        Dispatches an OTP verification code asynchronously.
        Purpose can be 'login' (2FA) or 'reset_password'.
        """
        is_login = purpose == "login"
        action_name = "Two-Factor Login Verification" if is_login else "Password Reset"
        subject = f"Your MDS Verification Code: {code}"

        text_content = (
            f"Hello,\n\n"
            f"Your verification code for {action_name} is: {code}\n\n"
            f"This code will expire in {expire_minutes} minutes. "
            f"If you did not request this code, please ignore this email or contact support.\n\n"
            f"Best regards,\n"
            f"Mastitis Detection System (MDS) Team"
        )

        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <style>
            body {{
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
              background-color: #F9FBF9;
              margin: 0;
              padding: 24px;
              color: #333333;
            }}
            .card {{
              max-width: 480px;
              margin: 0 auto;
              background: #ffffff;
              border: 1px solid #E0E5E0;
              border-radius: 12px;
              padding: 32px 24px;
              text-align: center;
              box-shadow: 0 4px 12px rgba(0,0,0,0.03);
            }}
            .header-badge {{
              display: inline-block;
              background: #E2F1E5;
              color: #215433;
              font-size: 13px;
              font-weight: 600;
              padding: 6px 14px;
              border-radius: 16px;
              margin-bottom: 16px;
            }}
            h2 {{
              color: #215433;
              font-size: 22px;
              margin: 0 0 8px 0;
            }}
            p {{
              color: #7A7A7A;
              font-size: 14px;
              line-height: 1.5;
              margin: 8px 0 24px 0;
            }}
            .code-box {{
              background: #F4F8F4;
              border: 1.5px dashed #215433;
              border-radius: 10px;
              padding: 18px;
              font-size: 32px;
              font-weight: 700;
              letter-spacing: 8px;
              color: #215433;
              margin: 0 auto 24px auto;
              max-width: 280px;
            }}
            .footer {{
              font-size: 12px;
              color: #999999;
              border-top: 1px solid #EAEAEA;
              padding-top: 16px;
              margin-top: 16px;
            }}
          </style>
        </head>
        <body>
          <div class="card">
            <div class="header-badge">Mastitis Detection System</div>
            <h2>{action_name}</h2>
            <p>Use the 6-digit verification code below to complete your request. This code is valid for <strong>{expire_minutes} minutes</strong>.</p>
            <div class="code-box">{code}</div>
            <p style="font-size: 13px; color: #7A7A7A;">
              If you did not request this verification code, please ignore this email or review your account security.
            </p>
            <div class="footer">
              &copy; Mastitis Detection System &bull; Intelligent Dairy Cattle Health Monitoring
            </div>
          </div>
        </body>
        </html>
        """

        return await asyncio.to_thread(
            cls._send_sync,
            to_email,
            subject,
            html_content,
            text_content
        )


email_service = EmailService()
