package com.studycompanion.security;

import com.studycompanion.repository.RevokedTokenRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;

@Component
@RequiredArgsConstructor
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtTokenProvider tokenProvider;
    private final RevokedTokenRepository revokedTokenRepository;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String token = extractToken(request);
        if (token != null) {
            if (!tokenProvider.validateToken(token)) {
                rejectUnauthorized(response);
                return;
            }
            String jti = tokenProvider.getJtiFromToken(token);
            if (revokedTokenRepository.existsByJti(jti)) {
                rejectUnauthorized(response);
                return;
            }
            String userId = tokenProvider.getUserIdFromToken(token);
            var auth = new UsernamePasswordAuthenticationToken(
                    userId, null, Collections.emptyList());
            SecurityContextHolder.getContext().setAuthentication(auth);
        }
        filterChain.doFilter(request, response);
    }

    private void rejectUnauthorized(HttpServletResponse response) throws IOException {
        response.setStatus(HttpStatus.UNAUTHORIZED.value());
        response.setContentType("application/json");
        response.getWriter().write("{\"error\":\"Token is invalid or has been revoked\"}");
    }

    private String extractToken(HttpServletRequest request) {
        String bearer = request.getHeader("Authorization");
        if (StringUtils.hasText(bearer) && bearer.startsWith("Bearer ")) {
            return bearer.substring(7);
        }
        return null;
    }
}
