package com.studycompanion.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

@Data
public class MfaVerifyRequest {

    @NotBlank
    private String pendingToken;

    @NotBlank
    @Pattern(regexp = "\\d{6}", message = "OTP must be exactly 6 digits")
    private String otp;
}
