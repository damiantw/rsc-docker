# RSC Docker

Self-host a RuneScape Classic server and web client using Docker.

**Demo:** http://rsc.damian.lol

## The Backstory

I was recently reminiscing with some friends when someone brought up *RuneScape*.

![theres-a-name-ive-not-heard-in-many-years](https://github.com/user-attachments/assets/66cb9bf9-21d9-4479-93a2-9aaf6516b03b)

Have you ever heard of RuneScape? If you're like me and were in elementary/middle school during the early 2000s, I'd bet you have.

The dawn of the millennium was an era before applications like Steam were commonplace. A kid who wanted to play video games on a computer beyond the realm of Solitaire, Minesweeper, or 3D Space Cadet Pinball was likely to reach for good ol' Internet Explorer as their gateway.

The World Wide Web was in its infancy. It was long before the days of many modern browser gizmos like the Canvas element and WebGL. The browser games of the time were primarily implemented in now-defunct web technologies like Flash, Shockwave, and Java applets.

Websites like Miniclip, eBaum's World, and Newgrounds compiled lists of the best browser games. If you found yourself killing time in the school library, you'd inevitably end up on these websites. It is just what you did back then. 

Among these popular browser games was RuneScape, a massively multiplayer online role-playing game with a medieval setting. Level up your character's stats, collect weapons and armor, slay the dragon, etc.

Admittedly, MMORPGs are not my cup of tea, but I vividly remember RuneScape being my first introduction to the genre. The idea that player characters from all across the globe could simultaneously co-exist in an expansive digital world blew my 11-year-old mind. It seemed like magic. 

Anyways, fueled with nostalgia, I jumped down the Google rabbit hole to learn more about this relic of my childhood.

### RuneScape Classic

I was somewhat surprised to find that RuneScape is still alive and well in 2024, with a relatively large active player base. 

The original version of the game, and the version of the game I recall playing as a child, launched in 2001.

Jagex, the developers behind RuneScape, overhauled the game engine and released "RuneScape 2" in 2004, but servers for the original version of the game, now dubbed "RuneScape Classic" (RSC), remained online.

The game continued to evolve and eventually led to the release of "RuneScape 3" in 2013. Based on feedback from long-time players who were unhappy with certain updates in the new version of the game, Jagex also re-released servers for RuneScape 2 as "Old School RuneScape" (OSRS) based on a recovered backup of the game codebase from 2007.

Both RuneScape 3 and OSRS are actively developed to this day.

However, on August 6th, 2018, Jagex shut down the RuneScape Classic servers. RSC became abandonware.

### OpenRSC

Even before the RSC servers were decommissioned, dedicated RSC fans collaborated to reverse-engineer Jagex's RSC server and client.

These efforts culminated in the [OpenRSC Project](https://github.com/Open-RSC).

The project provides an open-source server that accurately preserves the original RuneScape classic experience. 

Like the authentic Jagex RSC server, the OpenRSC server is written in Java. It aims to support a wide range of authentic and third-party RSC clients. Clients communicated with the official Jagex server using a proprietary protocol via a direct TCP socket connection. However, OpenRSC also supports network traffic via WebSocket to support modern web clients (more on that later).

I found a few other RSC server projects written in more modernly preferable technologies, such as [rsc-server](https://github.com/2003scape/rsc-server) (NodeJS) and [RSCGo](https://github.com/spkaeros/RSCGo) (Go), but OpenRSC seems to provide the most feature-complete and authentic open-source RSC server at this time.

### Clients

The original official Jagex RSC client was distributed as a [Java applet](https://en.wikipedia.org/wiki/Java_applet) served on the official RuneScape website.

Java applets allowed a web page to embed a Java application, which ran using a Java runtime installed on the client machine.

Over time, it became apparent that allowing a web page to tap into a local JVM presents a serious security risk (lookup Java drive-by download attacks). As such, support for applets has been removed from all modern browsers and Java runtimes.

OpenRSC provides a Java RSC client build on top of official Jagex client reverse engineering efforts, and the OpenRSC server supports third-party clients such as [RSC+](https://rsc.plus/) that were compatible with the original Jagex servers before RSC was shut down. 

RSC+ seems to be the preferred client for RSC if you're serious about playing the game, but both RSC+ and the OpenRSC client are Java desktop applications. 

Part of what made RuneScape special back in the day came from the ease of access to it as a game playable in the web browser. I want to preserve that experience.

My original thought was to embed the OpenRSC client on a webpage using [cheerpj](https://cheerpj.com/), which provides a full JVM runtime isolated within a webpage context. However, because the OpenRSC Java client communicates with the server directly on a TCP socket (this is a no-no for web browsers), getting the networking to work without rewriting the client to communicate using a browser-friendly channel like WebSockets requires incorporating a [proxy server](https://cheerpj.com/docs/guides/Networking#why-tailscale) into the stack. Not very elegant.

Fortunately, I stumbled upon [rsc-c](https://github.com/2003scape/rsc-c), a port of a reverse-engineered Java RSC client to C.

Thanks to [Emscripten](https://emscripten.org/), this client can be compiled into WebAssembly with all TCP socket networking [seamlessly translated to WebSocket communications](https://emscripten.org/docs/porting/networking.html#emscripten-websockets-api).

## Usage

### Quickstart

Install [Docker](https://docs.docker.com/get-started/get-docker/).

Create an environment file.

```bash
cp .env.example .env
```


Build the containers.

```bash
docker compose build
```


(**On ARM/Apple Silicon:** `docker compose build --build-arg EMSDK_VERSION=3.1.74-arm64`)

**Optional:** Edit `server/local.conf` to match your preferences.

Start The Containers

```bash
docker compose up
```

(`docker compose up -d` to run the containers in the background)

Open the web client in your browser http://localhost:3333.

**Grant Admin Privileges:**

```bash
docker compose exec \
-e ADMIN="'USERNAME'" \
mariadb sh -c 'echo "UPDATE players SET group_id = 0 WHERE username = $ADMIN;" | mariadb -u"$MARIADB_ROOT_USER" -p"$MARIADB_ROOT_PASSWORD" openrsc'
```

See: [OpenRSC Commands](https://github.com/Open-RSC/Core-Framework/blob/develop/Commands.md)
### RSC+

[Download](https://rsc.plus/) and run the RSC+ client.

```bash
java -jar rscplus.jar
```

Settings ⚙️ -> World List

Configure a world for your server's hostname and `OPENRSC_TCP_PORT`.

The RSA modulus and exponent are output when the server starts up.

```bash
docker compose logs server | grep 'RSA'
```

```
Server: - RSA exponent: EXPONENT
Server: - RSA modulus: PUBLIC_KEY
```

If you're using the included keys use the following values.

* Public Key: `7224304829646393970767024278869816063676049880765746467312191801246808669338629956289486451942833536191577784408651515562985085796097970954939979556591591`
* Exponent: `65537`

<img width="799" alt="RSC+ World Config" src="https://github.com/user-attachments/assets/cc2f3991-8ca9-47ee-af8f-1b4874be6e79" />

### Changing RSA Keys

**Note:** The RSA keys are only relevant to clients that support the ISAAC networking protocol (not the web client).

Delete or rename the existings keys in the `server/keys` directory.

Generate a new key pair with OpenSSL and rebuild the server image.

```bash
openssl genrsa -out server/keys/server.pem 512
openssl rsa -in server/keys/server.pem -outform PEM -pubout -out server/keys/client.pem
docker compose build server
```

**Optional:**

The RSA modulus and exponent in the client's `worlds.cfg` are binary values.

(the exponent and modulus are each world's last two configuration values).

[Convert the decimal modulus and exponent values to binary](https://www.rapidtables.com/convert/number/decimal-to-binary.html).

Ensure the exponent and modulus binary values are zero-left-padded to a multiple of 8 digits.

Rebuild the client container after editing `worlds.cfg`.
### Public Server Hosting

Ensure `OPENRSC_TCP_PORT`, `OPENRSC_WS_PORT`, and `CLIENT_PORT` are publicly accessible. 

Ensure `client/worlds.cfg` includes your server's hostname and `OPENRSC_WS_PORT`.

Rebuild the client container image.

```bash
docker-compose build client
# ARM/Apple Silicon
docker compose build --build-arg EMSDK_VERSION=3.1.74-arm64 client
```

**See:** [OpenRSC Wiki](https://rsc.vet/wiki/index.php?title=Running_your_own_server) 

## Known Limitations

### Revision 177 Web Client

The web client is based on a decompiled official Jagex client, specifically [revision 177](https://github.com/RSCPlus/mudclient177-deob).

Later revisions of the official Jagex client introduced [ISAAC](https://en.wikipedia.org/wiki/ISAAC_(cipher)) encryption to the client-server networking protocol.

OpenRSC is compatible with the earlier (non-encrypted) and later (encrypted) official Jagex client networking protocols.

However, for some reason, registration requests from rsc-c compiled with ISAAC encryption networking enabled results in an error.

Registration requests from RSC+ (which does use the ISAAC encryption scheme) work fine.

### SSL

The client should be served using HTTP, not HTTPS.

Modern browsers require all WebSocket traffic on a page loaded via `https://` to be handled via `wss://`.

Unfortunately, the [Emscripten WebSockets API](https://emscripten.org/docs/porting/networking.html#emscripten-websockets-api) only supports `ws://`.
