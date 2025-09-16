# Automatically generated clients for

- [Enhance](https://enhance.com/)
- [Nginx Proxy Manager](https://nginxproxymanager.com/)
- [Listmonk](https://listmonk.app/)
- [Mailcow](https://mailcow.email/)
- [Authentik](https://goauthentik.io/)
- [Kutt](https://kutt.it/)

# How to use

## Installation

In your project run

`npm i openapi-fetch @rallisf1/ts-client-THE_API_YOU_NEED`

## Code example

```js
import createClient from "openapi-fetch";
import type { paths } from "@rallisf1/ts-client-THE_API_YOU_NEED";

const client = createClient<paths>({ baseUrl: "https://myapi.dev/v1/" });

const {
  data, // only present if 2XX response
  error, // only present if 4XX or 5XX response
} = await client.GET("/blogposts/{post_id}", {
  params: {
    path: { post_id: "123" },
  },
});

await client.PUT("/blogposts", {
  body: {
    title: "My New Post",
  },
});

```

# Other API Clients I use

- [Postiz](https://www.npmjs.com/package/@postiz/node)
- [Grist](https://www.npmjs.com/package/grist-api)