1. k8s server certificate has been rotated and we decided to create a separate server CA to sign the new server cert.  certificate-authority-data in kubeconfig is not the cert that signed k8s server cert any more. Auth doesn't work

2. expired certs
3. Client doesn't have the matching private key
4. AuthenticationConfiguration
5. External identity provider (Microsoft Entra ID, Okta, Keycloak, GitHub, Corporate LDAP or Active Directory servers)

