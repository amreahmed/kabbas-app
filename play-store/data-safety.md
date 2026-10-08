# Data safety worksheet — review before submitting

This describes the inspected client and configured backend. It is a draft for the owner to compare with actual support, fulfillment and retention practices; it is not a submitted declaration.

| Data | Where it is used | Collection / purpose |
|---|---|---|
| Name, email, user ID | Firebase Authentication and users profile | Account management and app functionality; required for the email account flow |
| Phone number and customer name | Maintenance, scrap and pipe installation orders | Required to contact the customer and fulfill a service request |
| Address | Pipe installation inspection address | Required for this service to arrange an inspection; include under personal information/address |
| Photos | Optional chosen image embedded in the customer's order | App functionality; optional |
| Precise or approximate location | Optional user-requested coordinates saved with an order | Service location; optional, no background tracking |
| Other user-generated content | Service descriptions, scrap type/weight, installation unit count | Order fulfillment |
| IP address / technical authentication metadata | Firebase Authentication | Security and fraud prevention; assess the applicable Play data categories using Firebase's disclosure guide |
| Cart selections | In-memory local cart; user can explicitly send the prepared message via WhatsApp | The app does not submit these as a backend order; external conversations follow the service's policy |

- Network transport uses HTTPS/TLS through Firebase and HTTPS external links.
- In-app and public external deletion-request paths are provided.
- No advertising or analytics SDK is explicitly enabled by app code. Do not infer that all bundled SDKs collect no technical data.
- Location and photos are optional. OS permission denial must not prevent a request without those attachments.
- Data processed by Firebase as a service provider and data explicitly sent through a user-initiated external action may qualify for Google's sharing exceptions. Decide using the current definitions and your actual business arrangements; do not automatically mark every external recipient as either shared or not shared.
- If technicians or other businesses receive data outside the app, account for that sharing and update the privacy policy where necessary.
- Internal checkout concerns physical goods/services. There is no implemented digital-goods payment or in-app payment processing.

Sources: [Firebase Android disclosure guide](https://firebase.google.com/docs/android/play-data-disclosure), [Firebase privacy](https://firebase.google.com/support/privacy), [Play User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311).
