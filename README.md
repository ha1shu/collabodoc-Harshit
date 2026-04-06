# CollaboDoc

A real-time collaborative plain-text editor backend built with Elixir, Phoenix Channels, and OTP.

## Setup
```bash
mix deps.get
mix phx.server
```

The server starts on `http://localhost:4000`.
Connect via WebSocket at `ws://localhost:4000/socket/websocket`.

## Architecture

### Document Process (GenServer)
Each document is managed by a `Collabodoc.DocumentServer` GenServer. It holds:
- `content` — the current document string
- `history` — ordered list of all applied operations
- `revision` — monotonically increasing counter

Documents are identified by UUID and looked up via a `Registry`.
New documents are started on demand by `DocumentManager` under a `DynamicSupervisor`.

### WebSocket Layer (Phoenix Channel)
Clients connect to `doc:<uuid>` channels via `UserSocket`.
On join, they receive the current full document state.
They send `op` events and receive broadcasts of other clients' transformed operations.

### Conflict Resolution: Operational Transformation (OT)

I chose OT over CRDT for the following reasons:
- **Simpler to reason about** for a plain-text string model
- **Lower overhead** — no metadata attached to each character
- **Fits the architecture** — single server with central authority is exactly what OT was designed for

The OT algorithm:
1. The server is the single source of truth
2. Each operation carries a `client_revision` — how many ops the client has seen
3. When an op arrives, the server transforms it against all ops the client hasn't seen
4. The transformed op is applied and broadcast to all other clients

**Known limitation:** Single-server OT model only. Not suitable for distributed multi-server setup.

### Supervision Tree


Collabodoc.Supervisor (one_for_one)
├── Registry (DocumentRegistry)
├── DynamicSupervisor (DocumentSupervisor)
│   ├── DocumentServer (doc-uuid-1)
│   └── DocumentServer (doc-uuid-2)
├── Phoenix.PubSub
└── CollabodocWeb.Endpoint

A crashing DocumentServer restarts cleanly (in-memory only).

## Channel API

**Join a document:**
```json
channel.join("doc:<uuid>", { "client_id": "optional-id" })
Returns: { "content": "current text", "revision": 0 }
```

**Send an operation:**
```json
channel.push("op", {
  "revision": 0,
  "op": { "type": "insert", "pos": 0, "char": "H" }
})
Returns: { "op": { "type": "insert", "pos": 0, "char": "H" }, "revision": 1 }
```

**Receive operations from other clients:**
```json
channel.on("op", ({ op, revision, client_id }) => { ... })
```

## Known Limitations
- In-memory only — state is lost on process restart
- No authentication or authorization
- Single-server OT (not distributed)

## What I Would Build Next
1. Persistence — PostgreSQL snapshots via Ecto
2. Phoenix.Presence — live user list per document
3. Undo — per-client undo stack with transformed inverse ops
4. Cursor tracking — broadcast cursor positions

## Demo
[[Loom recording link]](https://www.loom.com/share/d07b9a41625742d78fd28242f4121a4a)
