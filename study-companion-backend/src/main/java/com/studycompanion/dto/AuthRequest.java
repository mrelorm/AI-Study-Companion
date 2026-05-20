package com.studycompanion.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class AuthRequest {
    private String name;

    @Email @NotBlank
    private String email;

    @NotBlank
    @Size(min = 8, max = 128)
    @Pattern(
        regexp = "^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>/?]).+$",
        message = "Password must contain at least one uppercase letter, one number, and one special character"
    )
    private String password;
}
