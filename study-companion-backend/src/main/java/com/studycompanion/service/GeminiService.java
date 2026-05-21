package com.studycompanion.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class GeminiService {

    private static final Logger log = LoggerFactory.getLogger(GeminiService.class);

    private static final int MAX_RETRIES = 3;
    private static final long[] BACKOFF_MS = {2000, 5000, 10000}; // 2s, 5s, 10s

    @Value("${gemini.api-key}")
    private String apiKey;

    @Value("${gemini.model}")
    private String model;

    @Value("${gemini.base-url}")
    private String baseUrl;

    private final WebClient.Builder webClientBuilder;
    private final ObjectMapper objectMapper;

    public String generate(String prompt) {
        WebClient client = webClientBuilder.baseUrl(baseUrl).build();

        Map<String, Object> requestBody = Map.of(
                "contents", new Object[]{
                        Map.of("parts", new Object[]{
                                Map.of("text", prompt)
                        })
                },
                "generationConfig", Map.of(
                        "temperature", 0.7,
                        "maxOutputTokens", 4096
                )
        );

        Exception lastException = null;
        for (int attempt = 0; attempt < MAX_RETRIES; attempt++) {
            try {
                String response = client.post()
                        .uri("/models/{model}:generateContent?key={key}", model, apiKey)
                        .bodyValue(requestBody)
                        .retrieve()
                        .bodyToMono(String.class)
                        .block();
                return extractText(response);
            } catch (WebClientResponseException e) {
                lastException = e;
                if (e.getStatusCode() == HttpStatus.TOO_MANY_REQUESTS ||
                    e.getStatusCode() == HttpStatus.BAD_GATEWAY ||
                    e.getStatusCode() == HttpStatus.SERVICE_UNAVAILABLE) {
                    long delay = BACKOFF_MS[Math.min(attempt, BACKOFF_MS.length - 1)];
                    log.warn("Gemini transient error {} (attempt {}/{}), retrying in {}ms",
                            e.getStatusCode(), attempt + 1, MAX_RETRIES, delay);
                    try { Thread.sleep(delay); } catch (InterruptedException ie) { Thread.currentThread().interrupt(); }
                } else {
                    // Non-retryable error (4xx other than 429)
                    throw new RuntimeException("Gemini API error: " + e.getStatusCode(), e);
                }
            }
        }
        log.error("Gemini rate limit exceeded after {} retries", MAX_RETRIES);
        throw new RuntimeException("The AI is currently busy. Please try again in a moment.", lastException);
    }

    private String extractText(String jsonResponse) {
        try {
            JsonNode root = objectMapper.readTree(jsonResponse);
            return root.path("candidates")
                    .get(0)
                    .path("content")
                    .path("parts")
                    .get(0)
                    .path("text")
                    .asText();
        } catch (Exception e) {
            throw new RuntimeException("Failed to parse Gemini response", e);
        }
    }
}
