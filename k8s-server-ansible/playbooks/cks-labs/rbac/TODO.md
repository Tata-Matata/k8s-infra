1. certificate has wrong group (typo or just missing role/rolebinding for this group, or user is assigned wrong group)
2. webhook returns authenticated: true, but wrong group; or user instead of group is configured in role binding
   Use TokenReview object
3. service accounts token? (--service-account-signing-key)
4. OIDC (Keycloak, Okta, Azure AD, Google) → groups coming with a JWT claim.
5. binding in the wrong namespace
6. binding the wrong Role
7. typo in the subject name