package com.studycompanion.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class AuthResponse {
    private String accessToken;
    private String refreshToken;
    private String userId;
    private String email;
    private String name;
}
