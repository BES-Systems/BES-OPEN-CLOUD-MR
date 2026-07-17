package com.bes.cloud.api;


import org.springframework.web.bind.annotation.*;


@RestController
@RequestMapping("/api")
public class CloudController {

    // Status route, this is early
    // and work in progress.
    @GetMapping("/status")
    public String status() {

        return """
        {
          "service": "BES OpenCloud Controller",
          "status": "online",
          "version": "0.1.0"
        }
        """;

    }



    @GetMapping("/nodes")
    public String nodes() {

        return """
        {
          "nodes": []
        }
        """;

    }

}
