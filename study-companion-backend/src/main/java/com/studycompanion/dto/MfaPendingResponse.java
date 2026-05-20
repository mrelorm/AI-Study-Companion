package com.studycompanion.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class MfaPendingResponse {
    private boolean mfaRequired;
    private String pendingToken;
    /** e.g. "j***e@gmail.com" — tells the user which inbox to check without exposing the full address */
    private String maskedEmail;
}
