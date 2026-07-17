package com.bes.cloud;


import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;


@SpringBootApplication
public class Controller {


    public static void main(String[] args) {

        System.out.println(
            "[BES Controller] Starting..."
        );


        SpringApplication.run(
            Controller.class,
            args
        );

    }

}
