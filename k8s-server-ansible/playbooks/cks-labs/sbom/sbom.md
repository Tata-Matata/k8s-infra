### Software Bill of Materials

<details>
<summary>Answer</summary>

A Software Bill of Materials (SBOM) is a comprehensive inventory of all components, libraries, and modules within a piece of software. It is crucial for ensuring software supply chain security by providing transparency and allowing organizations to identify and address vulnerabilities efficiently.

SBOMs enable:

    Better management of software dependencies,
    Improved compliance with licensing requirements,
    Quick responses to security threats.

By adopting SBOMs, organizations can enhance their security posture and reduce risks associated with third-party software components.


Licenses, patches, dependencies

clear visibility of components

```


```

</details>


Base (Parent) image footprint

FROM scratch

then this is base image
modular images for one specific purpose (web server)
each component can scale up and down then
we do not store data in containers. they are ephemeral
external volume or caching service like Redis

how to choose base

keep image slim, lean, minimal. faster pull
spin up more instances faster

dev tools not include in prod
diff images for diff envs


distroless docker images

trivy image shows vulnerabilities






### SBOM format

spdx
cyclonedx


### SBOM Workflow

1. Generate SBOM
2. store in secure location
3. scan SBOM
4. analyze results and remediate issues
5. monitor consistently

### Generate SBOM with Syft

<details>
<summary>Answer</summary>

bom generate
kubernetes-sigs

# SBOM to stdout
syft <image> -o cyclonedx-json

# Multiple SBOMs to files
syft <image> -o spdx-json=./spdx.json -o cyclonedx-json=./cdx.json

syft docker.io/kodekloud/webapp-color:latest -o spdx-json=/root/webapp-spdx.sbom
</details>


### Scan SBOM with grype
jq -r '[.matches[] | select(.vulnerability.severity == "Critical")] | length' /root/grype-report.json

grype sbom:/root/webapp-sbom.json -o json > /root/grype-report.json