package com.studycompanion.dto;

import lombok.Data;

@Data
public class LogoutRequest {
    // Refresh token is optional on logout — if provided it is immediately revoked
    private String refreshToken;
}
