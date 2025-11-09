package com.goomar.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class FrontendController {

    @GetMapping({"/login", "/login/"})
    public String forwardLogin() {
        // Forward to the Flutter Web index.html inside /login folder
        return "forward:/login/index.html";
    }
}
