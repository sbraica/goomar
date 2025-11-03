package com.goomar.security.services;

import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class GoomarUserDetailsService implements UserDetailsService {

    private static final Map<String, String> USERS = Map.of(
            "admin", "$2a$12$tljWS7pfA3cloE3XlQiS5exgb0ign5zefYD7Bn1VqVAjEeBpIBJtG"
    );

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        String password = USERS.get(username);

        return new GoomarUserDetails(username, password, List.of(
                new SimpleGrantedAuthority("ROLE_ADMIN")
        ));
    }
}
