package com.studycompanion.service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.thymeleaf.TemplateEngine;
import org.thymeleaf.context.Context;

@Slf4j
@Service
@RequiredArgsConstructor
public class EmailService {

    private final JavaMailSender mailSender;
    private final TemplateEngine templateEngine;

    @Value("${app.mfa.from-email}")
    private String fromEmail;

    @Value("${app.mfa.from-name}")
    private String fromName;

    @Value("${app.mfa.otp-expiry-minutes}")
    private int otpExpiryMinutes;

    @Async
    public void sendOtp(String toEmail, String name, String otp) {
        try {
            Context ctx = new Context();
            ctx.setVariable("name", name);
            ctx.setVariable("otp", otp);
            ctx.setVariable("expiryMinutes", otpExpiryMinutes);

            String html = templateEngine.process("mfa-otp-email", ctx);

            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            helper.setFrom(fromEmail, fromName);
            helper.setTo(toEmail);
            helper.setSubject("Your AI Study Companion sign-in verification code");
            helper.setText(html, true);

            mailSender.send(message);
            log.info("MFA OTP email sent to {}", maskEmail(toEmail));
        } catch (MessagingException | java.io.UnsupportedEncodingException e) {
            log.error("Failed to send MFA OTP email to {}: {}", maskEmail(toEmail), e.getMessage());
            // Don't propagate — caller already stored the OTP hash; email failure
            // is logged but the user can request a resend.
        }
    }

    private String maskEmail(String email) {
        int at = email.indexOf('@');
        if (at <= 0) return "***";
        String local = email.substring(0, at);
        String domain = email.substring(at);
        if (local.length() <= 2) return local.charAt(0) + "**" + domain;
        return local.charAt(0) + "***" + local.charAt(local.length() - 1) + domain;
    }
}
