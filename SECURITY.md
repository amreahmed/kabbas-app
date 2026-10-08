# Security

Do not post credentials, customer records, private keys or exploitable production details in public issues. Use GitHub's private vulnerability reporting feature if enabled; otherwise contact the repository owner privately through an available profile contact before sharing sensitive details.

The client uses Firebase Authentication. Administrator access is granted through the server-issued `admin: true` custom claim and enforced by Firestore rules. A profile field or an email address does not grant administrator permissions.

Production Firebase configuration and upload-signing files are excluded from Git. Client Firebase API keys are project identifiers rather than administrator credentials, but this repository intentionally omits production configuration to avoid connecting forks to the live backend. Never put service-account credentials in the app.

If a secret is committed, revoke or rotate it before addressing Git history. Deleting the file in a later commit does not remove prior exposure.

The repository guard and emulator tests are useful checks, not a guarantee that every security issue will be detected.
