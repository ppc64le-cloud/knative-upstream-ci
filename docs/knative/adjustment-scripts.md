# Add Adjustment Scripts

Adjustment scripts for each Knative component are stored in the `adjust/` directory under their respective component names. If a new component is introduced, follow the folder structure below and include the necessary adjustment scripts.

### Folder Structure Example
For the `client` component in `release-1.17`, the directory structure should be:

```
adjust/
│   README.md
├── client/
│   ├── release-1.17/
│   │   ├── overlay.yaml
│   │   ├── adjust.sh
│   │   └── ...
│
├── eventing/
│   ├── release-1.17/
│   │   ├── overlay.yaml
│   │   ├── adjust.sh
│   │   └── ...
│   ├── main/
│   │   ├── overlay.yaml
│   │   ├── adjust.sh
│   │   └── ...
```

### Steps to Add a New Component
1. Create a new folder in `adjust/` with the component name and version.
2. Add `adjust.sh` and any required files (e.g., `overlay.yaml`).
