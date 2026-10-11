# Base44 sandbox notes

- Run the web preview with `docker compose -f docker-compose.base44.yml up -d --build`; Nginx serves the Flutter build on port 3000.
- The `flutter` service rebuilds the static web bundle whenever Dart files in `lib/` change. It can take about a minute for a full rebuild.
- CouchDB is available to the browser only through Nginx at `/kou-database/`. The `seed` service remains healthy after preparing the required sample records; verify it with `docker compose -f docker-compose.base44.yml ps`.
- Check the rendered sign-in screen in the browser preview after a Flutter build; HTML DOM text is not representative of Flutter-rendered text.
