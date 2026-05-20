package com.studycompanion.filter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Sliding-window IP-based rate limiter for auth endpoints.
 * Limits each IP to {@code maxRequests} within a 60-second window.
 */
@Component
public class RateLimitFilter extends OncePerRequestFilter {

    private final int maxRequests;
    private static final long WINDOW_MS = 60_000L;

    // IP → timestamps of recent requests
    private final Map<String, Deque<Long>> requestLog = new ConcurrentHashMap<>();

    public RateLimitFilter(
            @Value("${app.rate-limit.auth-requests-per-minute:10}") int maxRequests) {
        this.maxRequests = maxRequests;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        // Only rate-limit auth endpoints
        return !request.getRequestURI().startsWith("/api/auth/");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String ip = resolveClientIp(request);
        long now = System.currentTimeMillis();

        Deque<Long> timestamps = requestLog.computeIfAbsent(ip, k -> new ArrayDeque<>());

        synchronized (timestamps) {
            // Evict timestamps outside the current window
            while (!timestamps.isEmpty() && now - timestamps.peekFirst() > WINDOW_MS) {
                timestamps.pollFirst();
            }
            if (timestamps.size() >= maxRequests) {
                response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
                response.setContentType("application/json");
                response.getWriter().write(
                        "{\"error\":\"Too many requests. Please wait before trying again.\"}");
                return;
            }
            timestamps.addLast(now);
        }

        filterChain.doFilter(request, response);
    }

    private String resolveClientIp(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            return forwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
