# Cluster Passwords

This document records the passwords used in the ODP Ambari Cluster.

| Service | Username | Password | Notes |
| :--- | :--- | :--- | :--- |
| **Ambari Admin** | `admin` | `admin` | Default Ambari credentials |
| **Cluster Default** | (various) | `Ambari1234` | Applied to all service accounts by default |
| **Ranger UserSync**| `rangerusersync` | `Ambari1234` | Inherited from default |
| **Ranger TagSync** | `rangertagsync` | `Ambari1234` | Inherited from default |
| **Ranger Admin** | `keyadmin` | `Ambari1234` | Inherited from default |
| **Database** | (various) | `Ambari1234` | Hive, Oozie, Ranger DBs |

## Password Requirements (Ranger)
- Minimum 8 characters
- Minimum 1 alphabet
- Minimum 1 numeric
- **Forbidden characters**: `"`, `'`, `\`, Backtick
- **Chosen Pattern**: Alpha-Numeric only to ensure compatibility across all components and scripts.
