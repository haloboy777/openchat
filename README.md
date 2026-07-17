<div align="center">

<img src="assets/icon/icon.png" width="120" alt="OpenChat icon" />

# OpenChat

**One app. Every model.**

A fast, lightweight Android chat client for [OpenRouter](https://openrouter.ai) —
talk to Claude, GPT, Gemini, Llama, and 400+ other models from a single, clean interface.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)
![Storage](https://img.shields.io/badge/Storage-100%25%20on--device-4C8DFF)

</div>

---

## Why

Most AI chat apps lock you into one provider. OpenRouter already routes to every major
model behind one API key — OpenChat is the missing mobile front-end: no accounts, no
middleman servers, no telemetry. Your key and your conversations never leave your device.

## Features

- 🔀 **Every model on OpenRouter** — switch models mid-conversation from the app bar
- ⚡ **Real streaming** — tokens render as they arrive, with Markdown and code blocks
- 💬 **Sessions that persist** — chat history lives in a local SQLite database
- ✏️ **Edit & regenerate** — rewrite any of your messages and rerun the conversation from there
- 🎛️ **Provider filtering** — hide the providers you never use from the model picker
- 💰 **Usage & balance** — live account balance and daily/weekly/monthly spend straight from OpenRouter, plus on-device token and per-model stats
- 🔐 **Secure by default** — API key stored in Android's encrypted keystore, everything else stays on-device
- 🌗 **Light / dark / system** theme, with a custom system prompt option

## Getting started

1. Grab an API key from [openrouter.ai/keys](https://openrouter.ai/keys)
2. Build and install:

   ```sh
   flutter pub get
   flutter run --release
   ```

3. Open **Settings**, paste your key, pick a model, chat.

### Release builds

Release signing reads `android/key.properties` (gitignored). Create your own keystore:

```sh
keytool -genkeypair -v -keystore android/app/upload-keystore.jks \
  -alias openchat -keyalg RSA -keysize 2048 -validity 10000
```

```properties
# android/key.properties
storePassword=<password>
keyPassword=<password>
keyAlias=openchat
storeFile=upload-keystore.jks
```

Then `flutter build apk --release`. Without `key.properties` the build falls back to
debug signing so it still runs.

## Architecture

```
lib/
├── main.dart                  # App root, theming, routes
├── models/                    # ChatMessage, ChatSession, OpenRouterModel, usage stats
├── providers/
│   └── chat_provider.dart     # Single ChangeNotifier: sessions, streaming, usage
├── services/
│   ├── api_service.dart       # OpenRouter REST + SSE streaming client
│   ├── database_service.dart  # SQLite (sessions, messages, usage records)
│   └── storage_service.dart   # Secure key storage + preferences
├── screens/                   # Chat, Settings, Usage, Provider filter
└── widgets/                   # Message bubbles, model selector, session drawer
```

Plain Flutter + `provider` — no codegen, no DI framework, no backend. The whole app is
~2.5k lines of Dart.

## Privacy

OpenChat talks to exactly one host: `openrouter.ai`. There is no analytics SDK, no
crash reporter, and no server component. Delete the app and everything is gone.

---

<div align="center">
Built with Flutter · Powered by <a href="https://openrouter.ai">OpenRouter</a>
</div>
