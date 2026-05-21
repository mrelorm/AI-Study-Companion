package com.studycompanion.filter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Iterator;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Sliding-window IP-based rate limiter for auth endpoints.
 * Limits each IP to {@code maxRequests} within a 60-second window.
 *
 * Note: state is in-memory — resets on restart. For production use
 * a distributed store (e.g. Redis) to persist across restarts/instances.
 */
@Component
public class RateLimitFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(RateLimitFilter.class);

    private final int maxRequests;
    private static final long WINDOW_MS = 60_000L;

    // IP → timestamps of recent requests
    private final Map<String, Deque<Long>> requestLog = new ConcurrentHashMap<>();

    public RateLimitFilter(
            @Value("${app.rate-limit.auth-requests-per-minute:10}") int maxRequests) {
        this.maxRequests = maxRequests;
    }

    /** Evict stale IP entries every 5 minutes to prevent unbounded memory growth. */
    @Scheduled(fixedDelay = 300_000)
    public void evictStaleEntries() {
        long cutoff = System.currentTimeMillis() - WINDOW_MS;
        Iterator<Map.Entry<String, Deque<Long>>> it = requestLog.entrySet().iterator();
        int removed = 0;
        while (it.hasNext()) {
            Map.Entry<String, Deque<Long>> entry = it.next();
            Deque<Long> timestamps = entry.getValue();
            synchronized (timestamps) {
                while (!timestamps.isEmpty() && timestamps.peekFirst() < cutoff) {
                    timestamps.pollFirst();
                }
                if (timestamps.isEmpty()) {
                    it.remove();
                    removed++;
                }
            }
        }
        if (removed > 0) log.debug("Rate limiter evicted {} stale IP entries", removed);
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
        // Only trust X-Forwarded-For when the direct connection comes from localhost
        // (i.e. a trusted reverse proxy like nginx running on the same host).
        // If the request arrives directly from the internet, use the socket address
        // to prevent attackers from spoofing the header.
        String remoteAddr = request.getRemoteAddr();
        boolean fromTrustedProxy = "127.0.0.1".equals(remoteAddr) || "0:0:0:0:0:0:0:1".equals(remoteAddr);
        if (fromTrustedProxy) {
            String forwarded = request.getHeader("X-Forwarded-For");
            if (forwarded != null && !forwarded.isBlank()) {
                return forwarded.split(",")[0].trim();
            }
        }
        return remoteAddr;
    }
}
