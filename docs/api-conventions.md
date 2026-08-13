# API conventions

Base prefix: `/api/v1` through Nest URI versioning.

Success envelope:
```json
{"success":true,"data":{}}
```

Error envelope:
```json
{"success":false,"error":{"code":"CUSTOMER_NOT_REGISTERED","message":"...","details":{},"requestId":"..."}}
```

Large resources use cursor pagination:
```json
{"items":[],"pageInfo":{"hasNextPage":false,"nextCursor":null}}
```

IDs are opaque strings. ISO timestamps cross the network; Persian/Jalali conversion happens only at UI boundaries. Money values may serialize as decimal strings because the database uses 64-bit integer/BigInt.
