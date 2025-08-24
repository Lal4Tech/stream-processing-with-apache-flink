# Docker Compose Service Architecture

```mermaid
graph TD
    redpanda["redpanda<br/>Ports: 18081:18081, 18082:18082, 19092:19092, 19644:9644<br/>📦 Image: docker.redpanda.com/redpandadata/redpanda:v23.1.7"]
    console["console<br/>Ports: 8080:8080<br/>📦 Image: docker.redpanda.com/redpandadata/console:v2.2.3<br/>⚙️ Env: 2 vars"]
    jobmanager["jobmanager<br/>Ports: 8081:8081, 9249:9249<br/>🔨 Build: .<br/>⚙️ Env: 1 vars"]
    taskmanager1["taskmanager1<br/>Ports: 9250:9249<br/>🔨 Build: .<br/>⚙️ Env: 1 vars"]
    taskmanager2["taskmanager2<br/>Ports: 9251:9249<br/>🔨 Build: .<br/>⚙️ Env: 1 vars"]
    postgres["postgres<br/>Ports: 5432:5432<br/>📦 Image: postgres:latest<br/>🔄 Restart: always<br/>⚙️ Env: 2 vars"]
    prometheus["prometheus<br/>Ports: 9090:9090<br/>📦 Image: prom/prometheus:latest"]
    grafana["grafana<br/>Ports: 3000:3000<br/>📦 Image: grafana/grafana<br/>🔄 Restart: unless-stopped<br/>⚙️ Env: 2 vars"]
    console -->|depends| redpanda
    taskmanager1 -->|depends| jobmanager
    taskmanager2 -->|depends| jobmanager
    console ==>|http| redpanda

    %% Styling for different connection types
    classDef external fill:#ffcccc,color:black,stroke:#ff6666,stroke-width:2px;
    classDef healthcheck fill:#ccffcc,color:black,stroke:#66ff66,stroke-width:2px;
    classDef logging fill:#cceeff,color:black,stroke:#6699ff,stroke-width:2px;
```

## Legend
- **→** Dependency connection (depends_on)
- **⇢** Shared volume connection (bind mounts)
- **⇨** Service-to-service connection (environment variables)
- **💓** Service has healthcheck configured
- **📝** Service has logging configured
- **Red dashed nodes** External services (not in current stack)

# Network Topology

```mermaid
graph TB
    network["Network: default"]
    redpanda["redpanda\nports: 18081,18082,19092,19644"] --> network
    console["console\nports: 8080"] --> network
    jobmanager["jobmanager\nports: 8081,9249"] --> network
    taskmanager1["taskmanager1\nports: 9250"] --> network
    taskmanager2["taskmanager2\nports: 9251"] --> network
    postgres["postgres\nports: 5432"] --> network
    prometheus["prometheus\nports: 9090"] --> network
    grafana["grafana\nports: 3000"] --> network

    %% Styling
    classDef healthcheck fill:#e1f5fe,color:black,stroke:#0277bd,stroke-width:2px;
    classDef logging fill:#f3e5f5,color:black,stroke:#7b1fa2,stroke-width:2px;
    classDef both fill:#e8f5e8,color:black,stroke:#2e7d32,stroke-width:2px;
```

## Network Topology Legend
- **HC** = Healthcheck configured
- **LOG** = Logging configured
- **Blue nodes** = Services with healthcheck
- **Purple nodes** = Services with logging
- **Green nodes** = Services with both healthcheck and logging
- **Dashed lines** = Same service across multiple networks

# Resource Allocation & Volumes

## Resource Limits
```mermaid
graph TD
    redpanda["redpanda<br/>No limits set"]
    console["console<br/>No limits set"]
    jobmanager["jobmanager<br/>No limits set"]
    taskmanager1["taskmanager1<br/>No limits set"]
    taskmanager2["taskmanager2<br/>No limits set"]
    postgres["postgres<br/>No limits set"]
    prometheus["prometheus<br/>No limits set"]
    grafana["grafana<br/>No limits set"]
```

## Volume Sharing
```mermaid
graph LR
    NoSharedVolumes["No shared volumes detected"]
```

## Resource Overview Legend
- **HC** = Healthcheck configured
- **LOG** = Logging configured

# Service Details

## redpanda

**📦 Image:** docker.redpanda.com/redpandadata/redpanda:v23.1.7

**🔌 Ports:** 18081:18081, 18082:18082, 19092:19092, 19644:9644

**🔄 Connected From:**
- **console** via http

**📁 Volumes (1):**
- 🗂️ Bind Mount: `./logs/redpanda` → `/var/lib/redpanda/data`

---

## console

**📦 Image:** docker.redpanda.com/redpandadata/console:v2.2.3

**🔌 Ports:** 8080:8080

**🔗 Dependencies:** redpanda

**🔄 Connects To:**
- **redpanda** via http

**⚙️ Environment Variables (2):**
- `CONFIG_FILEPATH`: /tmp/config.yml
- `CONSOLE_CONFIG_FILE`: kafka:
  brokers: ["redpanda:9092"]
  schemaRegist...

---

## jobmanager

**🔨 Build Context:** .

**🔌 Ports:** 8081:8081, 9249:9249

**⚙️ Environment Variables (1):**
- `FLINK_PROPERTIES`: 
jobmanager.rpc.address: jobmanager
metrics.report...

**📁 Volumes (2):**
- 🗂️ Bind Mount: `./jars/` → `/opt/flink/jars`
- 🗂️ Bind Mount: `./logs/flink/jm` → `/opt/flink/temp`

---

## taskmanager1

**🔨 Build Context:** .

**🔌 Ports:** 9250:9249

**🔗 Dependencies:** jobmanager

**⚙️ Environment Variables (1):**
- `FLINK_PROPERTIES`: 
jobmanager.rpc.address: jobmanager
taskmanager.nu...

**📁 Volumes (1):**
- 🗂️ Bind Mount: `./logs/flink/tm1` → `/opt/flink/temp`

---

## taskmanager2

**🔨 Build Context:** .

**🔌 Ports:** 9251:9249

**🔗 Dependencies:** jobmanager

**⚙️ Environment Variables (1):**
- `FLINK_PROPERTIES`: 
jobmanager.rpc.address: jobmanager
taskmanager.nu...

**📁 Volumes (1):**
- 🗂️ Bind Mount: `./logs/flink/tm2` → `/opt/flink/temp`

---

## postgres

**📦 Image:** postgres:latest

**🔄 Restart Policy:** always

**🔌 Ports:** 5432:5432

**⚙️ Environment Variables (2):**
- `POSTGRES_USER`: postgres
- `POSTGRES_PASSWORD`: postgres

---

## prometheus

**📦 Image:** prom/prometheus:latest

**🔌 Ports:** 9090:9090

**📁 Volumes (1):**
- 🗂️ Bind Mount: `./prometheus` → `/etc/prometheus`

---

## grafana

**📦 Image:** grafana/grafana

**🔄 Restart Policy:** unless-stopped

**🔌 Ports:** 3000:3000

**⚙️ Environment Variables (2):**
- `GF_SECURITY_ADMIN_USER`: grafana
- `GF_SECURITY_ADMIN_PASSWORD`: grafana

**📁 Volumes (2):**
- 🗂️ Bind Mount: `./grafana/provisioning` → `/etc/grafana/provisioning`
- 🗂️ Bind Mount: `./grafana/dashboards` → `/var/lib/grafana/dashboards`

---

# Service Connection Summary

## All Service-to-Service Connections

- **console** → **redpanda** via `http`
