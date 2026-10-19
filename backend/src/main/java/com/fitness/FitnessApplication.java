package com.fitness;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * Main Spring Boot Application class.
 * We exclude DataSourceAutoConfiguration because we manage dynamic,
 * multi-user DataSources per PostgreSQL user role & session.
 */
@SpringBootApplication(exclude = {DataSourceAutoConfiguration.class})
@EnableScheduling
public class FitnessApplication {

    public static void main(String[] args) {
        SpringApplication.run(FitnessApplication.class, args);
    }
}
