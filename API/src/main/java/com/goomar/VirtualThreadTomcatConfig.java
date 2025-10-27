package com.goomar;

import org.apache.coyote.AbstractProtocol;
import org.apache.coyote.ProtocolHandler;
import org.springframework.boot.web.embedded.tomcat.TomcatProtocolHandlerCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.concurrent.Executors;

@Configuration
public class VirtualThreadTomcatConfig {

    @Bean
    public TomcatProtocolHandlerCustomizer<ProtocolHandler> protocolHandlerVirtualThreads() {
        return protocolHandler -> {
            if (protocolHandler instanceof AbstractProtocol<?> protocol) {
                protocol.setExecutor(Executors.newVirtualThreadPerTaskExecutor());
            }
        };
    }
}
