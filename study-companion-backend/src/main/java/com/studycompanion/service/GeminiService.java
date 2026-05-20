package com.studycompanion.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class GeminiService {

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

        String response = client.post()
                .uri("/models/{model}:generateContent?key={key}", model, apiKey)
                .bodyValue(requestBody)
                .retrieve()
                .bodyToMono(String.class)
                .block();

        return extractText(response);
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
