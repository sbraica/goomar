package com.goomar.security.services;

import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import java.util.Map;

@Service
public class FlexiUserDetailsService implements UserDetailsService {

    private static final Map<String, String> USERS = Map.of("admin", "admin");

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        String password = USERS.get(username);

        if (password == null) {
            throw new UsernameNotFoundException("User not found: " + username);
        }

        return User.withUsername(username)
                .password("{noop}" + password) // no password encoding for demo
                .roles(username.equals("admin") ? "ADMIN" : "USER")
                .build();
    }
}
