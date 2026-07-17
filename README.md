# BES-OPENCLOUD

<p align="center">
  <b>BES OpenCloud Platform</b><br>
  An open-source distributed cloud infrastructure platform for modern computing.
</p>

---

## Overview

BES OpenCloud is an experimental open-source cloud infrastructure platform developed by **BES Systems**.

The goal is to create a modular, scalable, and decentralized cloud platform that allows organizations, data centers, and independent operators to build and operate their own cloud infrastructure.

BES OpenCloud combines virtualization, distributed computing, and peer-to-peer networking to create a next-generation cloud ecosystem.

Designed for:

- Private cloud infrastructure
- Data centers
- Edge computing
- RISC-V infrastructure
- Enterprise deployments
- Community-powered cloud networks

---

## Architecture

BES OpenCloud consists of multiple core components:

### BES Controller

The cloud control plane responsible for:

- User management
- Resource scheduling
- API services
- Authentication
- Infrastructure orchestration


### BES Node

A lightweight node daemon running on cloud servers.

Responsibilities:

- Hardware discovery
- VM lifecycle management
- Resource monitoring
- Secure communication
- Workload execution


### BES Mesh

A distributed networking layer for connecting independent BES OpenCloud nodes.

Features:

- Peer-to-peer node discovery
- Secure node communication
- Distributed infrastructure
- Future workload federation

---

## Features

Current development goals:

- Virtual machine management
- KVM/QEMU integration
- Multi-node infrastructure
- REST and gRPC APIs
- Cloud dashboard
- User authentication
- Resource scheduling
- Monitoring system
- Distributed networking
- Storage abstraction
- RISC-V cloud support
- Edge computing support

---

## Technology Stack

### Control Plane
- Java
- REST APIs
- PostgreSQL

### Node Infrastructure
- Go
- gRPC
- Linux
- KVM/QEMU

### Low-Level Components
- C
- System-level interfaces
- Performance-critical services

### Networking
- P2P networking
- QUIC
- Secure tunnels

---

## Supported Platforms

### Current Targets

- x86_64 Linux servers

### Planned

- RISC-V servers
- ARM servers
- Edge devices
- BES hardware platforms

---

## Development

Requirements:

- Linux development environment
- Java JDK
- Go toolchain
- C compiler
- KVM support

Clone:

```bash
git clone https://github.com/BES-Systems/BES-OPENCLOUD-MR.git BES-OC-MR
cd BES-OC-MR
```

## Vision

BES OpenCloud aims to provide an open alternative for the future of cloud computing.

A cloud platform where organizations can own their infrastructure, connect resources, and build scalable computing networks.

## License

Copyright © BES Systems.

This project is currently under active development.
