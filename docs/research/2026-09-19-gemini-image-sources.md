# Can the Gemini API give us real destination photos? (research, 2026-09-19)

Audience: the teacher and the two students on the Voyz project. Context: the app uses `google_generative_ai` with `gemini-3.1-flash-lite` on the Gemini API free tier. The AI returns destination JSON with a name, then `ImageService` asks the Wikipedia REST summary endpoint (vi, then en) and Commons search for a photo, and `CachedNetworkImage` renders it on Flutter web.

Everything below was checked against primary sources on 2026-09-19 (Google docs, pub.dev, Wikimedia docs, plus live HTTP header checks with curl). Anything I could not confirm is marked "not verified".

## Short answer

No, not on the free tier, and only partly on a paid tier. The Gemini API has no tool that returns a photo of a real place as a stable, CORS-safe image URL for a text model. Google Search grounding returns web page URIs and titles, not images. Google Maps grounding returns a place name, a Maps URI, a `placeId` and review snippets, no photos. Image generation models produce synthetic pictures with a SynthID watermark, are not available on the free tier at all, and a generated "Ha Long Bay" is an illustration of the idea, not a photograph of the place. URL context can read a Wikipedia page, but it costs input tokens, adds a model hop, and the model still has to copy a URL out of the page, which is exactly the fabrication risk the repo already documented. Asking the model to recall an image URL from memory is the failure mode from `docs/lessons/2026-08-31-image-stability-walkthrough.md` (4 of 5 seed filenames were invented). The one primary source with a real `imageUri` field is the new Image Search type of the Google Search tool, but the docs only expose it for the paid `gemini-3.1-flash-image` model, so it does not help a free tier text model. The current Wikipedia lookup remains the only option that is free, CORS-safe on web, returns a real photo of the real place, and matches the AI text (because the AI provides the name and Wikipedia resolves the same name). Keep it.

## Comparison table

| Option | What it returns | Free tier? | Cost if paid | CORS-safe on web? | Real photo of the real place? | Consistency with AI text | Verdict |
|---|---|---|---|---|---|---|---|
| Google Search grounding (web search) | Text answer plus `groundingChunks[].web.uri/title`, `webSearchQueries`, `searchEntryPoint` HTML. No images. | No for Gemini 3.x ("Not available"). Yes for 2.5 models, 500 RPD. | 5,000 free search queries per month shared across Gemini 3.x, then $14 per 1,000 queries | Not applicable (no image) | No | High for facts, irrelevant for photos | Does not solve the problem |
| Google Search grounding, Image Search type | `groundingChunks[].image` with `imageUri`, `sourceUri`, `title`, `domain` | No. Documented only for `gemini-3.1-flash-image`, which has no free tier | Same search pricing plus image model output ($0.067 per 1K image) | Not verified. `imageUri` is an arbitrary third party host, so most will lack `Access-Control-Allow-Origin` | Sometimes (it is a web image search result), but the model then generates a new image | Medium | Not usable from a free tier text model |
| Google Maps grounding | `groundingChunks[].maps` with `uri`, `title`, `text`, `placeId`, `placeAnswerSources.reviewSnippets`; `googleMapsWidgetContextToken`. No photo field. | No for Gemini 3.x ("Not available"). Yes for 2.5 models, 500 RPD. | 5,000 free prompts per month shared across Gemini 3, then $14 per 1,000 queries | Not applicable (no image) | No | High for place facts | Does not return photos |
| Gemini image generation (Nano Banana: 2.5 Flash Image, 3.1 Flash Lite Image, 3.1 Flash Image, 3 Pro Image) | Inline base64 image bytes, SynthID watermark | No ("Not available" for all four) | $0.039 (2.5), about $0.02 to $0.08 (3.1 Lite, 747 to 2520 tokens at $30 per 1M), $0.067 (3.1 Flash, 1K), $0.134 (3 Pro, 1K/2K) per image | Yes (bytes, no fetch) but you would host them yourself | No, synthetic | Looks consistent but is invented imagery of a real place | Not free, not a photo; conflicts with the project rule that AI output must be labeled as estimate |
| Imagen | Shut down | No | n/a | n/a | n/a | n/a | Gone (shut down 2026-08-17) |
| URL context tool | Model reads up to 20 public URLs (HTML, JSON, images, PDF, 34MB each) and answers in text; `url_context_metadata` lists fetched URLs | Free tier limits not verified (tool is billed as input tokens, and flash-lite input is free of charge) | Input tokens at model price | Not applicable (model side fetch). Any URL the model copies out still has to be CORS-safe | Only if the model copies a real URL correctly from the page; it may still invent one | Medium | More code and one more model hop than calling Wikipedia directly |
| Model recalls an image URL from memory | A plausible looking string | Yes | Free | Whatever host it invents | Usually no (see lesson doc: 4 of 5 fabricated) | Low | Rejected, already documented |
| Wikipedia REST summary (current) | `thumbnail.source`, `originalimage.source`, `extract`; server built thumbnail URL | Yes, public API, 200 req/s guidance, User-Agent required | Free | Yes: API sends `access-control-allow-origin: *`, and the thumbnail host serves `access-control-allow-origin: *` with a direct 200 (checked live) | Yes, the lead image of the article about that place | High: the AI gives the name, Wikipedia resolves the same name | Keep |
| Wikidata P18 (wbgetclaims or SPARQL) | A Commons filename (wbgetclaims) or a `Special:FilePath` URL (SPARQL) | Yes, `origin=*` supported, ACAO `*` on both endpoints (checked live) | Free | The lookup is CORS-safe, but the result is a filename or a redirecting URL; you still need the REST summary or imageinfo call to get a direct URL | Yes | Medium: you first need the QID, which needs another lookup from the name | Possible second source, but extra concept for little gain |
| Commons `Special:FilePath` | 302 to `Special:Redirect/file`, then 301 to the thumbnail host | Yes | Free | No: the two `commons.wikimedia.org` hops carry no `Access-Control-Allow-Origin` (checked live) | Yes | n/a | Already rejected in the lesson doc |
| Google Places Photos (New) | `photos[].name` from Place Details, then `/v1/{name}/media` redirects to the image or returns `photoUri` | Requires a Cloud project with a billing account. 1,000 free events per month (Enterprise SKU) | $7.00 per 1,000 photo events plus $20.00 per 1,000 Place Details Enterprise calls | Not verified; the API key would be in the browser, which Google says to avoid for web service calls | Yes (user uploaded photos) | High | Not free in practice, key exposure on web, no caching allowed. Reject |

## 1. Google Search grounding

What it returns. The Gemini API reference defines `GroundingMetadata` with `groundingChunks[]`, `groundingSupports[]`, `webSearchQueries[]`, `imageSearchQueries[]`, `searchEntryPoint` (HTML for the required Google Search suggestions widget), `retrievalMetadata` and `googleMapsWidgetContextToken`. A `GroundingChunk` is a union of `web` (`uri`, `title`), `image` (`sourceUri`, `imageUri`, `title`, `domain`), `retrievedContext` (File Search) and `maps`. `GroundingSupport` maps a text `segment` to `groundingChunkIndices` with `confidenceScores`. Source: https://ai.google.dev/api/generate-content (sections GroundingMetadata, GroundingChunk, Web, Image, Maps).

The Search grounding guide describes the response as text with `url_citation` annotations plus `search_suggestions` HTML, and lists the benefit "Increase factual accuracy: Reduce model hallucinations by basing responses on real-world information." It says nothing about images for text models. Source: https://ai.google.dev/gemini-api/docs/google-search

Does it return images? With the default web search type, no. The `SearchTypes` object has `webSearch` ("Only text results are returned") and `imageSearch` ("Image bytes are returned"). The image search type is documented only in the image generation guide, under "Grounding with Google Search for images (3.1 Flash)", with the note "This feature is only available for the Gemini 3.1 Flash Image model." Whether `gemini-3.1-flash-lite` accepts `imageSearch` and returns `groundingChunks[].image.imageUri` is not verified (not documented). The image generation guide also says that when web search is used with image generation, "image-based search results are not passed to the generation model and are excluded from the response." Sources: https://ai.google.dev/api/generate-content (SearchTypes), https://ai.google.dev/gemini-api/docs/image-generation

Whether the `web.uri` values are redirect links (vertexaisearch) and how long they stay valid: not verified. The Vertex AI page that used to document this now redirects to a navigation page I could not read.

Free tier and price. The pricing page shows, for Gemini 3.1 Flash-Lite, Gemini 3.5 Flash and Gemini 3.1 Pro Preview, Grounding with Google Search on the Free Tier as "Not available", and on the Paid Tier as "5,000 free search requests per month (shared across all Gemini 3.x models), then $14 per 1,000 requests." For Gemini 2.5 Flash-Lite and 2.5 Flash the Free Tier says "Free of charge, up to 500 RPD (limit shared with Flash RPD)" and the Paid Tier "1,500 RPD (free, limit shared with Flash RPD), then $35 / 1,000 grounded prompts." Gemini 3 models are billed per search query the model executes; 2.5 and older are billed per prompt. Sources: https://ai.google.dev/gemini-api/docs/pricing, https://ai.google.dev/gemini-api/docs/google-search

Model support. The `gemini-3.1-flash-lite` model page lists Search grounding, Google Maps grounding, URL context, code execution, function calling and thinking as supported, and image generation as not supported. Source: https://ai.google.dev/gemini-api/docs/models/gemini-3.1-flash-lite

Also required by the terms: display the Search suggestions from `searchEntryPoint.renderedContent` and show the sources. Source: https://firebase.google.com/docs/ai-logic/grounding-google-search

## 2. Google Maps grounding

What it returns. A `Maps` chunk "corresponds to a single place" and has `uri`, `title`, `text`, `placeId` ("in `places/{placeId}` format. A user can use this ID to look up that place") and `placeAnswerSources`, which "Currently we only support review snippets as sources." There is no photo field. `googleMapsWidgetContextToken` is "Resource name of the Google Maps widget context token that can be used with the PlacesContextElement widget in order to render contextual data." The guide says the service queries Maps for "places, reviews, photos, addresses, opening hours" as inputs to the model, but the response schema exposes no photo. The Firebase AI Logic docs add that their SDKs "do not yet support... Place Answer Sources (like for getting reviews)." Sources: https://ai.google.dev/api/generate-content (Maps, PlaceAnswerSources), https://ai.google.dev/gemini-api/docs/maps-grounding, https://firebase.google.com/docs/ai-logic/grounding-google-maps

Availability and price. Free Tier for Gemini 3.x models: "Not available". Paid Tier: "5,000 prompts per month (free, shared across Gemini 3), then $14 / 1,000 search queries". For 2.5 Flash and 2.5 Flash-Lite the Free Tier shows "500 RPD" and Paid Tier "1,500 RPD (free), then $25 / 1,000 grounded prompts". Supported models include Gemini 3.1 Flash-Lite, 3 Flash Preview, 3.1 Pro Preview, 3.5 Flash, 3.5 Flash-Lite, 3.6 to 3.8 Flash, and the 2.5 family. Maps grounding became generally available on 2025-10-17 and was extended to Gemini 3 models on 2026-03-18. Sources: https://ai.google.dev/gemini-api/docs/pricing, https://ai.google.dev/gemini-api/docs/maps-grounding, https://ai.google.dev/gemini-api/docs/changelog

The `placeId` could be fed to the Places Photos API, but that is a separate paid Google Maps Platform product (section 8).

## 3. Gemini image generation models

Models today (all branded Nano Banana): `gemini-2.5-flash-image` (legacy), `gemini-3.1-flash-lite-image` (1K only, GA 2026-06-30), `gemini-3.1-flash-image` (up to 4K, stable 2026-05-28), `gemini-3-pro-image` (stable 2026-05-28). Imagen: the Imagen page now says "Imagen models are shut down. Use Nano Banana for image generation." The changelog dates the Imagen 4 shutdown to 2026-08-17. Sources: https://ai.google.dev/gemini-api/docs/image-generation, https://ai.google.dev/gemini-api/docs/imagen, https://ai.google.dev/gemini-api/docs/changelog

Output format. Images come back as inline base64 bytes in the response, not as URLs. The app would have to store them (Supabase Storage or similar) to render them again, which is new infrastructure. Source: https://ai.google.dev/gemini-api/docs/image-generation

Cost and free tier. The pricing page shows the Free Tier as "Not available" for all four image models. Paid: Gemini 2.5 Flash Image "$0.039 per image"; Gemini 3.1 Flash Image "$0.067 per 1K image" (image output $60.00 per 1M tokens); Gemini 3 Pro Image "$0.134 per 1K/2K image" (image output $120.00 per 1M tokens); Gemini 3.1 Flash Lite Image image output "$30.00 (images)" per 1M tokens, with 3.1 images costing 747 to 2520 tokens depending on size, so roughly $0.02 to $0.08 per image (my arithmetic from the quoted numbers, not a quoted price). Source: https://ai.google.dev/gemini-api/docs/pricing

Realism and real places. The guide has a "Photorealistic scenes" prompt template ("A photorealistic [type of shot] of a [subject description] in a [setting description]"), so outputs can look like photos, but they are synthesized. The guide's own landmark example is a stylized "isometric miniature 3D cartoon scene of London". There is no documented policy that forbids generating real places. The one landmark-adjacent rule is "gemini-3.1-flash-image Grounding with Google Search does not support using real-world images of people from web search at this time." The general reminder applies: "Don't generate content that infringe on others' rights, including videos or images that deceive, harass, or harm", subject to the Prohibited Use Policy, which bans "Misrepresenting the provenance of generated content by claiming it was created solely by a human, in order to deceive." Sources: https://ai.google.dev/gemini-api/docs/image-generation, https://policies.google.com/terms/generative-ai/use-policy

Watermark. "All generated images include a SynthID watermark." Source: https://ai.google.dev/gemini-api/docs/image-generation

For this project a generated picture of Hoi An is an AI estimate of what Hoi An looks like. AGENTS.md says every AI-generated figure must be labeled as an estimate and not stored as real data. The same logic applies to pictures: they would need an "AI illustration" label, which weakens the travel use case where a user wants to see the actual place.

## 4. URL context tool

What it does. "The URL context tool lets you provide URLs to enhance model responses." Limits: "The tool can process up to 20 URLs per request" and "The maximum size for content retrieved from a single URL is 34MB." Supported content: HTML, JSON, plain text, XML, CSS, JavaScript, CSV, RTF, images (PNG, JPEG, BMP, WebP) and PDF. Not supported: paywalled pages, YouTube, Google Workspace files, video and audio. Content fetched from the URLs is billed as input tokens ("Charged as input tokens per model pricing"). The response has `url_context_metadata` listing the URLs fetched and their status. Supported on all current Gemini models including 3.1 Flash-Lite. It went GA on 2025-08-18. Sources: https://ai.google.dev/gemini-api/docs/url-context, https://ai.google.dev/gemini-api/docs/pricing, https://ai.google.dev/gemini-api/docs/changelog, https://firebase.google.com/docs/ai-logic/url-context

Free tier limits for URL context: not verified. The docs give no per-day cap for the tool itself; flash-lite input tokens are "Free of charge" on the free tier, so it likely works, but the model's normal RPM and RPD still apply.

Could it replace the Wikipedia call? Technically the model could fetch `https://vi.wikipedia.org/wiki/Vịnh_Hạ_Long` and be asked to return the lead image URL. That costs a second model round trip (or a bigger first one), spends tokens on a whole article, is slower than a direct REST call, and still relies on the model to transcribe a long `thumb.wikimedia.org/.../330px-....jpg` URL character by character. The REST summary endpoint gives the same field as structured JSON in one request with no model in the loop. URL context adds code and a new concept without removing the verification step.

## 5. Can the model emit a real image URL from memory?

Official guidance. Google frames grounding as the cure for this exact problem: "Reduce model hallucinations by basing responses on real-world information", "Answer questions about recent events", "Build user trust by showing the sources for the model's claims." A URL recalled without grounding is ungrounded output. Source: https://ai.google.dev/gemini-api/docs/google-search (Overview)

Project evidence. `docs/lessons/2026-08-31-image-stability-walkthrough.md` records that the `_curatedLandmarks` map contained filenames such as `Halong_bay_boats.jpg` and `Hoi_An_night.jpg` that "look very real, but were generated by AI and nobody verified them by machine"; in the seed migration "4 of 5 filenames were invented." It also documents the second trap: even a real filename needs a server computed hash path (`7/76` versus the real `b/bf`), so hand built thumbnail URLs 404. The lesson's checklist rule 1: a URL that the AI (or you) "remembers" is invented until the verify script says otherwise. Source: repo file above.

Verdict: rejected. This is settled in the repo, and nothing in the Google docs contradicts it.

## 6. Which Dart package exposes which tools

`google_generative_ai` (what the app uses, `^0.4.7`). pub.dev shows version 0.4.7, published 17 months ago, marked discontinued. The notice: "With Gemini 2.0, we took the chance to create a unified SDK for mobile developers", "We don't plan to add anything to this SDK or make any further changes." Its `Tool` class has exactly two members, `functionDeclarations` and `codeExecution`. No `googleSearch`, no `googleMaps`, no `urlContext`. Sources: https://pub.dev/packages/google_generative_ai, https://pub.dev/documentation/google_generative_ai/latest/google_generative_ai/Tool-class.html, https://github.com/google-gemini/deprecated-generative-ai-dart/blob/main/README.md

`firebase_ai` (the recommended replacement). Version 4.0.0, published about 25 days before 2026-09-19, by firebase.google.com. Its `Tool` class has `Tool.functionDeclarations`, `Tool.googleSearch()`, `Tool.googleMaps()`, `Tool.urlContext()` and `Tool.codeExecution()`. It supports web, Android, iOS and macOS, and both the Gemini Developer API and Vertex AI backends. It depends on `firebase_core`, `firebase_auth` and `firebase_app_check`, so the app would need a Firebase project even when using the Gemini Developer API free tier. Firebase's pricing page says the Gemini Developer API free tier "lets you get started without having to provide a payment method" with "limited access to certain models and access to many basic features." Sources: https://pub.dev/packages/firebase_ai, https://pub.dev/documentation/firebase_ai/latest/firebase_ai/Tool-class.html, https://firebase.google.com/docs/ai-logic/pricing

`google_genai` on pub.dev is a placeholder ("Coming soon") at version 0.0.1+1 from labs.dart.dev, pointing to experimental `google_cloud_ai_generativelanguage_v1beta`. Not a usable SDK today. Source: https://pub.dev/packages/google_genai

Practical consequence: to call any grounding tool from Dart the app would have to migrate `GeminiService` to `firebase_ai` and add Firebase to the project. That is a new package, a new console, and a new concept set, and the tools it unlocks are "Not available" on the free tier for Gemini 3.x anyway. Also worth noting: `google_generative_ai` is frozen, so it will never gain new 3.x features; if the app hits a wall with it, the migration to `firebase_ai` is the sanctioned route. That is a separate decision from images.

## 7. Free tier rate limits for gemini-3.1-flash-lite

The rate limits page no longer publishes per model RPM, TPM and RPD tables. It says "Rate limits depend on a variety of factors (such as your usage tier) and can be viewed in Google AI Studio" and links https://aistudio.google.com/rate-limit. It defines RPM, TPM (input) and RPD, says limits are per project and RPD resets at midnight Pacific, that "Rate limits are more restricted for experimental and preview models", and that the Free tier qualification is an "Active project or free trial" with no spend cap. Exact RPM, TPM and RPD for gemini-3.1-flash-lite on the free tier: not verified from a public page; the students should read them from the AI Studio rate limit page with the project's own key. Source: https://ai.google.dev/gemini-api/docs/rate-limits

Grounding tool limits on the free tier: for Gemini 3.x, "Not available" (pricing page). For 2.5 Flash and Flash-Lite, 500 RPD shared. Source: https://ai.google.dev/gemini-api/docs/pricing

Pricing for the model itself: Free Tier input and output "Free of charge", context caching "Not available"; Paid Tier $0.25 per 1M input tokens and $1.50 per 1M output tokens. Released GA 2026-05-07. Sources: https://ai.google.dev/gemini-api/docs/pricing, https://ai.google.dev/gemini-api/docs/changelog

Free tier data use: outside the EEA, UK and Switzerland, "Google uses the content you submit to the Services and any generated responses to provide, improve, and develop Google products and services." Source: https://ai.google.dev/gemini-api/terms

## 8. Free, CORS-safe alternatives on the web

Wikipedia REST summary (current approach). `GET https://{lang}.wikipedia.org/api/rest_v1/page/summary/{title}` returns `thumbnail.source`, `originalimage.source`, `extract` and page type; the endpoint is marked stable. The API description asks clients to stay under "200 requests/s to this API" and to "Set a unique User-Agent or Api-User-Agent header". The Wikimedia access policy says "The API requires an HTTP User-Agent header for all requests" and clients without one "may be blocked without notice". Live check 2026-09-19 on `vi.wikipedia.org/api/rest_v1/page/summary/Vịnh_Hạ_Long`: HTTP 200, `access-control-allow-origin: *`, and the returned `thumbnail.source` on `thumb.wikimedia.org` answered 200 `image/jpeg` with `access-control-allow-origin: *` and no redirect. Sources: https://en.wikipedia.org/api/rest_v1/?spec, https://www.mediawiki.org/wiki/Wikimedia_REST_API, https://www.mediawiki.org/wiki/Wikimedia_APIs/Access_policy, https://foundation.wikimedia.org/wiki/Policy:Wikimedia_Foundation_User-Agent_Policy

Observation for the team: the summary endpoint now returns thumbnails on `thumb.wikimedia.org` (with `?utm_source=...` query parameters), not `upload.wikimedia.org`. The `Special:FilePath` chain also ends on `thumb.wikimedia.org`. `tool/verify_image_urls.dart` only scans `upload.wikimedia.org` and `commons.wikimedia.org` URLs in migrations, so it would silently skip a `thumb.wikimedia.org` seed URL. Nothing in `lib/` currently allowlists hosts, so the app itself is not blocking these. Roadmap 2.4 says not to touch the verifier, so this is a note for the teacher, not a task.

Wikidata P18. `Property:P18` (image) is a "Commons media file" for an "image of relevant illustration of the subject". `wbgetclaims` with `entity=Q190128&property=P18&origin=*` returned filenames (`Halong Bay in Vietnam.jpg`, `Halong ensemble (colour corrected).jpg`) with `access-control-allow-origin: *`. The SPARQL endpoint `https://query.wikidata.org/sparql` also sends `access-control-allow-origin: *`, has a 60 second query deadline, per client limits (60 s of processing per minute, 30 error queries per minute, 5 parallel queries) and requires a compliant User-Agent; it returned `http://commons.wikimedia.org/wiki/Special:FilePath/...`, a redirecting URL that the browser cannot load cross origin (next item). Either way you get a filename, not a direct image URL, so you still need a second call (REST summary or Commons `imageinfo`) to obtain a loadable URL, and you need the QID first. It is free, but it is a third API and two extra hops for the same photo that the REST summary already returns. Sources: https://www.wikidata.org/wiki/Property:P18, https://www.wikidata.org/w/api.php?action=help&modules=wbgetclaims, https://www.mediawiki.org/wiki/Wikidata_Query_Service/User_Manual, https://www.mediawiki.org/wiki/API:Cross-site_requests

Commons `Special:FilePath`. Live check: `commons.wikimedia.org/wiki/Special:FilePath/Halong Bay in Vietnam.jpg?width=640` returns 302 to `Special:Redirect/file`, which returns 301 to `thumb.wikimedia.org/...`. The two Commons hops have no `Access-Control-Allow-Origin` header; only the final hop does. Browsers check CORS on each hop, so this still fails on Flutter web, exactly as section 3.5 of the lesson doc describes. Commons also says hotlinking "is also possible, but is not recommended" and that each file's license sets the attribution duty. Sources: live curl 2026-09-19, https://commons.wikimedia.org/wiki/Commons:Reusing_content_outside_Wikimedia

Google Places Photos (New). Flow: get `photos[].name` from Place Details, then `GET https://places.googleapis.com/v1/{name}/media?maxWidthPx=...&key=...`, which "performs an HTTP redirect to the image" or, with `skipHttpRedirect=true`, returns `photoUri`. You "cannot cache a photo name", must show `authorAttributions`, and the key goes in the URL. Pricing: "Places API Place Details Photos" is an Enterprise SKU with 1,000 free events per month then $7.00 per 1,000; Place Details Enterprise is 1,000 free then $20.00 per 1,000. Google Maps Platform requires "a project with a billing account and the Places API enabled" and recommends a "secure proxy server" rather than exposing web service keys in client code. Whether the redirected photo host sends CORS headers: not verified. For a student web app with no backend this means a credit card, a key in the browser, and a monthly cap of roughly 1,000 photos. Sources: https://developers.google.com/maps/documentation/places/web-service/place-photos, https://developers.google.com/maps/billing-and-pricing/pricing, https://developers.google.com/maps/billing-and-pricing/overview, https://developers.google.com/maps/documentation/places/web-service/cloud-setup, https://developers.google.com/maps/api-security-best-practices

Which are free: Wikipedia REST summary, Commons search and imageinfo, Wikidata wbgetclaims and SPARQL are free with no key. Google Search and Maps grounding are free only on 2.5 models (500 RPD) and "Not available" on the free tier for 3.x. Image generation is paid only. Places Photos needs a billing account.

## Recommendation for this project

Keep the current architecture: AI returns the destination name, `ImageService` resolves the photo through the Wikipedia REST summary (vi then en) with Commons search as fallback, empty string plus placeholder as the final state. This is the conclusion the evidence supports, and it is what roadmap item 2.4 already says ("do not change the image source architecture; only make broken images look consistent and reduce redundant requests"). The project rule "prefer less code and fewer concepts" points the same way: every Gemini option above adds a package migration (`firebase_ai` plus Firebase), a paid tier, or both, and none returns a photo of the real place as a loadable URL.

Concretely:

1. Do not add Search or Maps grounding for images. They return text, page URIs, place IDs and review snippets, never photos, and they are "Not available" on the free tier for the 3.x model the app uses.
2. Do not generate destination images. Not free, watermarked synthetic pictures, and they would need an "AI illustration" label under the project's own rule about AI output. A travel app showing an invented Hoi An is worse than a tasteful placeholder.
3. Do not ask the model for image URLs, with or without URL context. The lesson doc already proved the failure mode, and URL context just moves the transcription into a paid token stream.
4. Consistency with the AI text is already good: the AI emits a name, Wikipedia resolves that exact name. If a name resolves to the wrong article, the fix is in the name normalisation in `ImageService` (roadmap 2.4 already plans the vi/en ordering heuristic), not in the image source.
5. Two small facts for the teacher, outside 2.4 scope: the REST summary now serves thumbnails from `thumb.wikimedia.org`, which the verifier regex does not recognise; and `google_generative_ai` is frozen at 0.4.7, so `firebase_ai` is the eventual migration path if the team ever needs a Gemini tool.

## Sources

Gemini API and Google
- https://ai.google.dev/gemini-api/docs/google-search
- https://ai.google.dev/gemini-api/docs/maps-grounding
- https://ai.google.dev/gemini-api/docs/image-generation
- https://ai.google.dev/gemini-api/docs/imagen
- https://ai.google.dev/gemini-api/docs/url-context
- https://ai.google.dev/gemini-api/docs/pricing
- https://ai.google.dev/gemini-api/docs/rate-limits
- https://ai.google.dev/gemini-api/docs/models/gemini-3.1-flash-lite
- https://ai.google.dev/gemini-api/docs/changelog
- https://ai.google.dev/api/generate-content (GroundingMetadata, GroundingChunk, Web, Image, Maps, PlaceAnswerSources, SearchTypes)
- https://ai.google.dev/gemini-api/terms
- https://policies.google.com/terms/generative-ai/use-policy
- https://developers.google.com/maps/documentation/places/web-service/place-photos
- https://developers.google.com/maps/billing-and-pricing/pricing
- https://developers.google.com/maps/billing-and-pricing/overview
- https://developers.google.com/maps/documentation/places/web-service/cloud-setup
- https://developers.google.com/maps/api-security-best-practices

Dart packages
- https://pub.dev/packages/google_generative_ai
- https://pub.dev/documentation/google_generative_ai/latest/google_generative_ai/Tool-class.html
- https://github.com/google-gemini/deprecated-generative-ai-dart/blob/main/README.md
- https://pub.dev/packages/firebase_ai
- https://pub.dev/documentation/firebase_ai/latest/firebase_ai/Tool-class.html
- https://firebase.google.com/docs/ai-logic/grounding-google-search
- https://firebase.google.com/docs/ai-logic/grounding-google-maps
- https://firebase.google.com/docs/ai-logic/url-context
- https://firebase.google.com/docs/ai-logic/pricing
- https://pub.dev/packages/google_genai

Wikimedia
- https://en.wikipedia.org/api/rest_v1/?spec (REST API description: 200 req/s, User-Agent, page summary endpoint)
- https://www.mediawiki.org/wiki/Wikimedia_REST_API
- https://www.mediawiki.org/wiki/Wikimedia_APIs/Access_policy
- https://foundation.wikimedia.org/wiki/Policy:Wikimedia_Foundation_User-Agent_Policy
- https://www.mediawiki.org/wiki/API:Cross-site_requests
- https://www.wikidata.org/wiki/Property:P18
- https://www.wikidata.org/w/api.php?action=help&modules=wbgetclaims
- https://www.mediawiki.org/wiki/Wikidata_Query_Service/User_Manual
- https://commons.wikimedia.org/wiki/Commons:Reusing_content_outside_Wikimedia

Repo
- docs/lessons/2026-08-31-image-stability-walkthrough.md
- docs/project_phase3_roadmap_ai_first.md (item 2.4)
- lib/services/image_service.dart, tool/verify_image_urls.dart

Live checks (curl with a descriptive User-Agent and an `Origin` header, 2026-09-19): Wikipedia REST summary (vi), `thumb.wikimedia.org` thumbnail, Commons search API with `origin=*`, Wikidata `wbgetclaims` with `origin=*`, Wikidata SPARQL, and the `Special:FilePath` redirect chain.
