package com.studycompanion.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * Login request — only validates that email and password are present.
 * Password complexity is NOT re-validated here; that was enforced at registration.
 */
@Data
public class LoginRequest {

    @Email @NotBlank
    private String email;

    @NotBlank
    private String password;
}
