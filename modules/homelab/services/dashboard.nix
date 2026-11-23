{
  flake.modules.nixos.homelab =
    {
      config,
      pkgs,
      lib,
      options,
      ...
    }:
    let
      hl = config.homelab;
      user = config.user;

      # One monitor site per Service Record whose tile is in `group`, by title.
      monitorSites =
        group:
        map
          (
            r:
            {
              inherit (r.tile) title icon;
              inherit (r) url;
            }
            // lib.optionalAttrs (r.tile.check && r.port != null) { check-url = r.upstream; }
          )
          (
            lib.sort (a: b: lib.toLower a.tile.title < lib.toLower b.tile.title) (
              lib.filter (r: r.tile != null && r.tile.group == group) (lib.attrValues hl.records)
            )
          );

      # Shared template for Sonarr/Radarr/Lidarr widgets
      servarrTemplate = ''
        {{ $collapseAfter := .Options.IntOr "collapse-after" 5 }}
        {{ $showGrabbed := .Options.BoolOr "show-grabbed" false }}
        {{ $tzOffset := .Options.StringOr "timezone" "+00" }}
        {{ $tzTime := (printf "2006-01-02T15:04:05%s:00" $tzOffset) | parseTime "rfc3339" }}
        {{ $timezone := $tzTime.Location }}
        {{ $sortTime := .Options.StringOr "sort-time" "desc" }}
        {{ $coverProxy := .Options.StringOr "cover-proxy" "" }}
        {{ $size := .Options.StringOr "size" "medium" }}
        {{ $service := .Options.StringOr "service" "" }}
        {{ $type := .Options.StringOr "type" "" }}
        {{ $intervalH := .Options.IntOr "interval" 0 | mul 24 }}

        {{ $nowUTC := offsetNow "0h" }}
        {{ $now := ($nowUTC.In $timezone) | formatTime "rfc3339" }}
        {{ $posInterval := ((offsetNow (printf "+%dh" $intervalH)).In $timezone) | formatTime "rfc3339" }}
        {{ $negInterval := ((offsetNow (printf "-%dh" $intervalH)).In $timezone) | formatTime "rfc3339" }}

        {{ $apiBaseUrl := .Options.StringOr "api-base-url" "" }}
        {{ $key := .Options.StringOr "key" "" }}
        {{ $url := .Options.StringOr "url" $apiBaseUrl }}

        {{ if or (and (ne $service "sonarr") (ne $service "radarr") (ne $service "lidarr"))
                 (and (ne $type "upcoming") (ne $type "recent") (ne $type "missing"))
                 (eq $apiBaseUrl "") (eq $key "") (eq $url "") }}
          <div class="widget-error-header">
              <div class="color-negative size-h3">ERROR</div>
              <svg class="widget-error-icon" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126ZM12 15.75h.007v.008H12v-.008Z"></path>
              </svg>
            </div>
            <p class="break-all">
              Some options are not set or malformed
                <table style="border-spacing: 1rem;">
                  <tr><td>service</td><td>{{ $service }}</td><td>must be sonarr, radarr, or lidarr</td></tr>
                  <tr><td>type</td><td>{{ $type }}</td><td>must be upcoming, recent, or missing</td></tr>
                  <tr><td>api-base-url</td><td>{{ $apiBaseUrl }}</td><td>should include http(s):// and port if needed</td></tr>
                  <tr><td>key</td><td>{{ $key }}</td><td></td></tr>
                </table>
            </p>
        {{ else }}
          {{ $requestUrl := "" }}

          {{ if eq $service "sonarr" }}
            {{ if eq $type "recent" }}
              {{ $requestUrl = printf "%s/api/v3/history/since?includeSeries=true&includeEpisode=true&eventType=grabbed&date=%s" $apiBaseUrl $negInterval }}
            {{ else if eq $type "missing" }}
              {{ $requestUrl = printf "%s/api/v3/wanted/missing?page=1&pageSize=50&includeSeries=true" $apiBaseUrl }}
            {{ else if eq $type "upcoming" }}
              {{ $requestUrl = printf "%s/api/v3/calendar?includeSeries=true&start=%s&end=%s" $apiBaseUrl $now $posInterval }}
            {{ end }}

          {{ else if eq $service "radarr" }}
            {{ if eq $type "recent" }}
              {{ $requestUrl = printf "%s/api/v3/history/since?includeMovie=true&eventType=grabbed&date=%s" $apiBaseUrl $negInterval }}
            {{ else if eq $type "missing" }}
              {{ $requestUrl = printf "%s/api/v3/wanted/missing?page=1&pageSize=50" $apiBaseUrl }}
            {{ else if eq $type "upcoming" }}
              {{ $requestUrl = printf "%s/api/v3/calendar?start=%s&end=%s" $apiBaseUrl $now $posInterval }}
            {{ end }}

          {{ else if eq $service "lidarr" }}
            {{ if eq $type "recent" }}
              {{ $requestUrl = printf "%s/api/v1/history/since?includeArtist=true&includeAlbum=true&eventType=grabbed&date=%s" $apiBaseUrl $negInterval }}
            {{ else if eq $type "missing" }}
              {{ $requestUrl = printf "%s/api/v1/wanted/missing?page=1&pageSize=50&includeArtist=true" $apiBaseUrl }}
            {{ else if eq $type "upcoming" }}
              {{ $requestUrl = printf "%s/api/v1/calendar?includeArtist=true&start=%s&end=%s" $apiBaseUrl $now $posInterval }}
            {{ end }}
          {{ end }}

          {{ $data := newRequest $requestUrl
            | withHeader "Accept" "application/json"
            | withHeader "X-Api-Key" $key
            | getResponse }}

          <ul class="list list-gap-14 collapsible-container single-line-titles" data-collapse-after="{{ $collapseAfter }}">
            {{ $array := "" }}
            {{ $sortByField := "" }}
            {{ $itemDisplayed := false }}
            {{ $itemDate := "" }}
            {{ $isAvailable := false }}

            {{ if eq $type "missing" }}
              {{ $array = "records" }}
              {{ if eq $service "sonarr" }}
                {{ $sortByField = "airDateUtc" }}
              {{ else }}
                {{ $sortByField = "releaseDate" }}
              {{ end }}
            {{ else if eq $type "recent" }}
              {{ $sortByField = "date" }}
            {{ else }}
              {{ if eq $service "sonarr" }}
                {{ $sortByField = "airDateUtc" }}
              {{ else }}
                {{ $sortByField = "releaseDate" }}
              {{ end }}
            {{ end }}

            {{ range $data.JSON.Array $array | sortByTime $sortByField "rfc3339" $sortTime }}

              {{ if eq $service "sonarr" }}
                {{ $itemDate = .String "airDateUtc" }}
                {{ $isAvailable = true }}
              {{ else if eq $service "radarr"}}
                {{ $isAvailable = .Bool "isAvailable" }}
                {{ $itemDate = .String "releaseDate" }}
              {{ else if eq $service "lidarr"}}
                {{ $itemDate = .String "releaseDate" }}
                {{ $isAvailable = true }}
              {{ end }}

              {{ if or (eq $type "upcoming") (eq $type "recent") (and (or (and (gt $itemDate $negInterval) ((lt $itemDate $now ))) (eq $intervalH 0))  $isAvailable) }}
                {{ $itemDisplayed = true }}
                {{ $title := "" }}
                {{ $subtitle := "" }}
                {{ $coverUrl := "" }}
                {{ $status := "" }}
                {{ $coverBase := "" }}
                {{ $height := "" }}
                {{ $width := "" }}
                {{ $popoverTitle := "" }}
                {{ $popoverSubtitle := "" }}
                {{ $popoverSummary := "" }}
                {{ $summary := "" }}
                {{ $link := "" }}
                {{ $grabbed := false }}
                {{ $date := now }}
                {{ $datetype := "" }}
                {{ $seString := "" }}
                {{ $genres := "" }}
                {{ $buttonJustify := "left" }}


                {{ if eq $service "sonarr" }}
                  {{ $series := "" }}
                  {{ if eq $coverProxy "" }}
                    {{ $coverBase = printf "%s/api/v3/mediacover" $apiBaseUrl }}
                    {{ $coverUrl = printf "%s/%s/poster-500.jpg?apikey=%s" $coverBase (.String "seriesId") $key }}
                  {{ else }}
                    {{ $coverBase = $coverProxy }}
                    {{ $coverUrl = printf "%s/%s/poster-500.jpg" $coverBase (.String "seriesId") }}
                  {{ end }}
                  {{ $title = .String "series.title" }}
                  {{ $link = printf "%s/series/%s#" $url (.String "series.titleSlug") }}
                  {{ $series = .Get "series" }}
                  {{ $genres = $series.Get "genres" }}

                  {{ if eq $type "recent" }}
                    {{ $date = (.String "date" | parseTime "rfc3339") }}
                    {{ $subtitle = .String "episode.title" }}
                    {{ $summary = .String "episode.overview" }}
                    {{ $seString = printf "S%02dE%02d" (.Int "episode.seasonNumber") (.Int "episode.episodeNumber") }}
                    {{ $datetype = "Downloaded" }}

                    {{ if $showGrabbed }}
                      {{ $popoverTitle = .String "episode.title" }}
                      {{ $popoverSubtitle = $seString }}
                      {{ $popoverSummary = .String "episode.overview" }}
                      {{ if .Bool "episode.hasFile" }}
                        {{ $grabbed = true }}
                      {{ end }}
                    {{ else }}
                      {{ $popoverTitle = .String "series.title" }}
                      {{ $popoverSummary = .String "series.overview" }}
                    {{ end }}

                  {{ else if eq $type "missing" }}
                    {{ $date = (.String "airDateUtc" | parseTime "rfc3339") }}
                    {{ $subtitle = .String "title" }}
                    {{ $summary = .String "overview" }}
                    {{ $seString = printf "S%02dE%02d" (.Int "seasonNumber") (.Int "episodeNumber") }}
                    {{ $datetype = "Aired" }}
                    {{ if $showGrabbed }}
                      {{ $popoverTitle = .String "title" }}
                      {{ $popoverSubtitle = $seString }}
                      {{ $popoverSummary = .String "overview" }}
                      {{ if .Bool "episode.hasFile" }}
                        {{ $grabbed = true }}
                      {{ end }}
                    {{ else }}
                      {{ $popoverTitle = .String "series.title" }}
                      {{ $popoverSummary = .String "series.overview" }}
                    {{ end }}
                  {{ else if eq $type "upcoming" }}
                    {{ $date = (.String "airDateUtc" | parseTime "rfc3339") }}
                    {{ $subtitle = .String "title" }}
                    {{ $summary = .String "overview" }}
                    {{ $seString = printf "S%02dE%02d" (.Int "seasonNumber") (.Int "episodeNumber") }}
                    {{ $datetype = "Airs" }}
                    {{ if $showGrabbed }}
                      {{ $popoverTitle = .String "title" }}
                      {{ $popoverSubtitle = $seString }}
                      {{ $popoverSummary = .String "overview" }}
                      {{ if .Bool "hasFile" }}
                        {{ $grabbed = true }}
                      {{ end }}
                    {{ else }}
                      {{ $popoverTitle = .String "series.title" }}
                      {{ $popoverSummary = .String "series.overview" }}
                    {{ end }}
                  {{ end }}


                {{ else if eq $service "radarr" }}
                  {{ $movie := "" }}
                  {{ $status = .String "status" }}
                  {{ if eq $coverProxy "" }}
                    {{ $coverBase = printf "%s/api/v3/mediacover" $apiBaseUrl }}
                  {{ else }}
                    {{ $coverBase = $coverProxy }}
                  {{ end }}
                  {{ if eq $status "announced"}}
                    {{ if ne (.String "inCinemas") "" }}
                      {{ $date = (.String "inCinemas" | parseTime "rfc3339") }}
                      {{ $datetype = "In Cinemas" }}
                    {{ else }}
                      {{ $date = (.String "releaseDate" | parseTime "rfc3339") }}
                      {{ $datetype = "Releases" }}
                    {{ end }}
                  {{ else if eq $status "inCinemas"}}
                    {{ $date = (.String "releaseDate" | parseTime "rfc3339") }}
                    {{ $datetype = "Releases" }}
                  {{ else if eq $status "released"}}
                    {{ $date = (.String "releaseDate" | parseTime "rfc3339") }}
                    {{ $datetype = "Released" }}
                  {{ end }}

                  {{ if eq $type "recent" }}
                    {{ if eq $coverProxy "" }}
                      {{ $coverUrl = printf "%s/%s/poster-500.jpg?apikey=%s" $coverBase (.String "movie.id") $key }}
                    {{ else }}
                      {{ $coverUrl = printf "%s/%s/poster-500.jpg" $coverBase (.String "movie.id") }}
                    {{ end }}
                    {{ $datetype = "Downloaded" }}
                    {{ $date = (.String "date" | parseTime "rfc3339") }}
                    {{ $title = .String "movie.title" }}
                    {{ $subtitle = "" }}
                    {{ $summary = .String "movie.overview" }}
                    {{ $popoverTitle = .String "movie.title" }}
                    {{ $popoverSubtitle = printf "%s %s" $datetype (($date.In $timezone) | formatTime "1/2/2006") }}
                    {{ $popoverSummary = .String "movie.overview" }}
                    {{ $link = printf "%s/movie/%s#" $url (.String "movie.titleSlug") }}
                    {{ $movie = .Get "movie" }}
                    {{ $genres = $movie.Get "genres" }}
                    {{ if and $showGrabbed (gt (.Int "movie.movieFileId") 0) }}
                      {{ $grabbed = true }}
                    {{ end }}
                  {{ else }}
                    {{ if eq $coverProxy "" }}
                      {{ $coverUrl = printf "%s/%s/poster-500.jpg?apikey=%s" $coverBase (.String "id") $key }}
                    {{ else }}
                      {{ $coverUrl = printf "%s/%s/poster-500.jpg" $coverBase (.String "id") }}
                    {{ end }}
                    {{ $title = .String "title" }}
                    {{ $subtitle = "" }}
                    {{ $summary = .String "overview" }}
                    {{ $link = printf "%s/movie/%s#" $url (.String "titleSlug") }}
                    {{ $popoverTitle = .String "title" }}
                    {{ $popoverSubtitle = printf "%s %s" $datetype (($date.In $timezone) | formatTime "1/2/2006") }}
                    {{ $popoverSummary = .String "overview" }}
                    {{ $genres = .Get "genres" }}
                    {{ if eq $type "missing" }}
                      {{ if and $showGrabbed (.Bool "movie.hasFile") }}
                        {{ $grabbed = true }}
                      {{ end }}
                    {{ else }}
                      {{ if and $showGrabbed (.Bool "hasFile") }}
                        {{ $grabbed = true }}
                      {{ end }}
                    {{ end }}
                  {{ end }}


                {{ else if eq $service "lidarr" }}
                  {{ $artist := "" }}
                  {{ $album := "" }}
                  {{ $albumId := "" }}
                  {{ if eq $coverProxy "" }}
                    {{ $coverBase = printf "%s/api/v1/mediacover" $apiBaseUrl }}
                  {{ else }}
                    {{ $coverBase = $coverProxy }}
                  {{ end }}

                  {{ if eq $type "recent" }}
                    {{ $album = .Get "album" }}
                    {{ $artist = $album.Get "artist" }}
                    {{ if eq $coverProxy "" }}
                      {{ $coverUrl = printf "%s/album/%s/cover-500.jpg?apikey=%s" $coverBase (.String "albumId") $key }}
                    {{ else }}
                      {{ $coverUrl = printf "%s/album/%s/cover-500.jpg" $coverBase (.String "albumId") }}
                    {{ end }}
                    {{ $grabbed = true }}
                    {{ $title = $album.String "title" }}
                    {{ $date = (.String "date" | parseTime "rfc3339") }}
                    {{ $datetype = "Downloaded" }}
                    {{ $subtitle = $artist.String "artistName" }}
                    {{ $genres = $artist.Get "genres" }}
                    {{ $link = printf "%s/artist/%s#" $url ($artist.String "foreignArtistId") }}
                    {{ $summary = $album.String "overview" }}
                    {{ $popoverTitle = $album.String "title" }}
                    {{ $popoverSubtitle = printf "%s %s" $datetype (($date.In $timezone) | formatTime "1/2/2006") }}
                    {{ $popoverSummary = $artist.String "overview" }}

                  {{ else }}
                    {{ $artist = .Get "artist" }}
                    {{ $album = .Get "album" }}
                    {{ if eq $type "missing" }}
                      {{ $datetype = "Released" }}
                    {{ else }}
                      {{ $datetype = "Releases" }}
                    {{ end }}
                    {{ range .Array "releases" }}
                      {{ $albumId = .String "albumId" }}
                      {{ break }}
                    {{ end }}
                    {{ if eq $coverProxy "" }}
                      {{ $coverUrl = printf "%s/album/%s/cover-500.jpg?apikey=%s" $coverBase $albumId $key }}
                    {{ else }}
                      {{ $coverUrl = printf "%s/album/%s/cover-500.jpg" $coverBase $albumId }}
                    {{ end }}
                    {{ $date = (.String "releaseDate" | parseTime "rfc3339") }}
                    {{ $title = .String "title" }}
                    {{ $subtitle = $artist.String "artistName" }}
                    {{ $summary = $album.String "overview" }}
                    {{ $genres = $artist.Get "genres" }}
                    {{ $link = printf "%s/artist/%s#" $url ($artist.String "foreignArtistId") }}
                    {{ $popoverTitle = .String "title" }}
                    {{ $popoverSubtitle = printf "%s %s" $datetype (($date.In $timezone) | formatTime "1/2/2006") }}
                    {{ $popoverSummary = .String "artist.overview" }}
                  {{ end }}
                {{ end }}

                {{ if eq $size "small" }}
                  {{ $buttonJustify = "right" }}
                  {{ $height = "9rem" }}
                  {{ if eq $service "lidarr" }}
                    {{ $width = "9rem" }}
                  {{ else }}
                    {{ $width = "6rem" }}
                  {{ end }}
                {{ else if eq $size "medium" }}
                  {{ $height = "12rem" }}
                  {{ if eq $service "lidarr" }}
                    {{ $width = "12rem" }}
                  {{ else }}
                    {{ $width = "8rem" }}
                  {{ end }}
                {{ else if eq $size "large" }}
                  {{ $height = "15rem" }}
                  {{ if eq $service "lidarr" }}
                    {{ $width = "15rem" }}
                  {{ else }}
                    {{ $width = "10rem" }}
                  {{ end }}
                {{ else if eq $size "huge" }}
                  {{ $height = "18rem" }}
                  {{ if eq $service "lidarr" }}
                    {{ $width = "18rem" }}
                  {{ else }}
                    {{ $width = "12rem" }}
                  {{ end }}
                {{ end }}

                <li style="position: relative;">
                  <div class="flex gap-10 items-start thumbnail-container thumbnail-parent">
                    <div>
                      <div data-popover-type="html" data-popover-position="above" data-popover-show-delay="500" style="width: {{ $width  }}; height: {{ $height }}; align-content: center;">
                        <div data-popover-html>
                          <div style="margin: 5px;">
                            <strong class="size-h4 color-primary" title="{{ $popoverTitle }}">{{ $popoverTitle }}</strong>
                            <div class="size-h4 text-truncate text-very-compact color-subdue" title="{{ $popoverSubtitle }}">{{ $popoverSubtitle }}</div>
                            <p class="margin-top-20" style="overflow-y: auto; text-align: justify; max-height: 20rem;">
                              {{ if ne $popoverSummary "" }}
                                {{ $popoverSummary }}
                              {{ else }}
                                TBA
                              {{ end }}
                            </p>
                           {{ if gt (len ($genres.Array "")) 0 }}
                            <ul class="attachments margin-top-20">
                              {{ range $genres.Array "" }}
                                <li>{{ .String "" }}</li>
                              {{ end }}
                            </ul>
                            {{ end }}
                          </div>
                        </div>
                        <img class="thumbnail" src="{{ $coverUrl }}" alt="Cover for {{ .String "title" }}" loading="lazy" style="width: 100%; height: 100%; box-shadow: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1); object-fit: cover; border-radius: 0.5rem;">
                      </div>
                  </div>
                    <div class="shrink min-width-0" style="height: 9rem; position: relative; padding-top: 5px; padding-right: 5px;">
                      <strong class="size-h4 block text-truncate color-primary" title="{{ $title }}">{{ $title }}</strong>
                      <div class="text-truncate text-very-compact" title="{{ $subtitle }}">{{ $subtitle }}</div>
                      <div class="text-very-compact text-truncate">
                        {{ if eq $service "sonarr" }}
                          <div>{{ $seString }} - {{ $datetype }} {{ ($date.In $timezone).Format "1/2 03:04PM" }}</div>
                        {{ else }}
                          <span>{{ $datetype }} {{ ($date.In $timezone).Format "1/2" }}</span>
                        {{ end }}
                      </div>

                      {{ if $showGrabbed }}
                        {{ if eq $buttonJustify "right" }}
                          </div>
                          <a href="{{ $link }}" class="bookmarks-link size-h4 color-primary" target="_blank" rel="noreferrer"
                            style="position: absolute; bottom: 1rem; right: 1rem;
                              {{ if $grabbed }} color: var(--color-positive); border: 1px solid var(--color-positive); {{ else }} color: var(--color-negative); border: 1px solid var(--color-negative); {{ end }}
                              font-weight: bold; padding: 2px 5px; border-radius: 3px; display: inline-block; margin-top: 5px; text-decoration: none;">
                          {{ if $grabbed }}Grabbed{{ else }}Missing{{ end }}
                          </a>
                        {{ else }}
                          <a href="{{ $link }}" class="bookmarks-link size-h4 color-primary" target="_blank" rel="noreferrer"
                            style="{{ if $grabbed }} color: var(--color-positive); border: 1px solid var(--color-positive); {{ else }} color: var(--color-negative); border: 1px solid var(--color-negative); {{ end }}
                              font-weight: bold; padding: 2px 5px; border-radius: 3px; display: inline-block; margin-top: 5px; text-decoration: none;">
                          {{ if $grabbed }}Grabbed{{ else }}Missing{{ end }}
                          </a>
                          </div>
                        {{ end }}
                      {{ else }}
                        <div class="{{ if eq $size "small" }}text-truncate{{ if eq $service "radarr" }} margin-top-5{{ end }}{{ else }}text-truncate-2-lines margin-top-5{{ end }}">
                          {{ $summary }}
                        </div>
                      {{ end }}
                  </div>
                </li>
              {{ end }}
            {{ end }}
            {{ if not $itemDisplayed }}
              <li>No items found.</li>
            {{ end }}
          </ul>
        {{ end }}
      '';
    in
    {
      config = {
        homelab.records.glance = {
          subdomain = "dashboard";
          port = 8080;
          # Glance's Sonarr/Radarr widgets emit poster <img> tags that the
          # *browser* loads, so they cannot point at the arrs' loopback ports.
          # These same-origin paths proxy the covers and inject the API key
          # server-side, which also keeps the keys out of the dashboard HTML.
          # Paired with `cover-proxy` below; keys come from caddy.nix.
          caddy.extraRoutes = ''
            handle_path /covers/sonarr/* {
              rewrite * /api/v3/mediacover{path}
              reverse_proxy ${hl.records.sonarr.upstream} {
                header_up X-Api-Key {env.SONARR_API_KEY}
              }
            }
            handle_path /covers/radarr/* {
              rewrite * /api/v3/mediacover{path}
              reverse_proxy ${hl.records.radarr.upstream} {
                header_up X-Api-Key {env.RADARR_API_KEY}
              }
            }
          '';
        };
        systemd.tmpfiles.rules = [
          "d /home/${user.userName}/dashboard 0770 ${toString user.uid} ${user.group} -"
          "d /home/${user.userName}/dashboard/glance 0770 ${toString user.uid} ${user.group} -"
        ];
        services.glance = {
          enable = true;
          package = pkgs.glance;
          openFirewall = true;
          settings = {
            server = {
              host = "127.0.0.1";
              inherit (hl.records.glance) port;
            };
            theme = {
              background-color = "240 21 15";
              contrast-multiplier = 1.2;
              primary-color = "217 92 83";
              positive-color = "115 54 76";
              negative-color = "347 70 65";
            };
            pages = [
              {
                name = "Home";
                hide-desktop-navigation = true;
                columns = [
                  {
                    size = "small";
                    widgets = [
                      {
                        type = "calendar";
                        first-day-of-week = "monday";
                      }
                      {
                        type = "weather";
                        location = "Brno, Czechia";
                        units = "metric";
                        hour-format = "24h";
                      }
                      {
                        type = "custom-api";
                        title = "Photos";
                        title-url = hl.records.immich.url;
                        cache = "30m";
                        options = {
                          api-base-url = hl.records.immich.upstream;
                          key = {
                            _secret = "/run/credentials/glance.service/immich-api_key";
                          };
                        };
                        template = ''
                          {{ $base := .Options.StringOr "api-base-url" "" }}
                          {{ $key := .Options.StringOr "key" "" }}
                          {{ $stats := newRequest (concat $base "/api/server/statistics") | withHeader "x-api-key" $key | getResponse }}
                          {{ $disk := newRequest (concat $base "/api/server/storage") | withHeader "x-api-key" $key | getResponse }}

                          {{ if ne $stats.Response.StatusCode 200 }}
                            <p class="color-negative">Immich said: {{ $stats.Response.Status }}</p>
                            <p class="color-subdue size-h6 margin-top-5">Needs an admin API key with server.statistics and server.storage.</p>
                          {{ else }}
                            <div class="flex justify-between text-center">
                              <div>
                                <div class="color-highlight size-h3">{{ $stats.JSON.Int "photos" }}</div>
                                <div class="size-h6">PHOTOS</div>
                              </div>
                              <div>
                                <div class="color-highlight size-h3">{{ $stats.JSON.Int "videos" }}</div>
                                <div class="size-h6">VIDEOS</div>
                              </div>
                              <div>
                                <div class="color-highlight size-h3">{{ div ($stats.JSON.Int "usage" | toFloat) 1073741824.0 | printf "%.0f" }}</div>
                                <div class="size-h6">GB</div>
                              </div>
                            </div>

                            {{ if eq $disk.Response.StatusCode 200 }}
                              <div class="margin-top-15">
                                <div class="flex justify-between size-h6">
                                  <span>Disk</span>
                                  <span>{{ $disk.JSON.String "diskUse" }} / {{ $disk.JSON.String "diskSize" }}</span>
                                </div>
                                <div class="progress-bar margin-top-5">
                                  <div class="progress-value{{ if ge ($disk.JSON.Float "diskUsagePercentage") 85.0 }} progress-value-notice{{ end }}" style="--percent: {{ $disk.JSON.Float "diskUsagePercentage" | printf "%.0f" }}"></div>
                                </div>
                              </div>
                            {{ end }}

                            <ul class="list list-gap-4 margin-top-15">
                              {{ range $stats.JSON.Array "usageByUser" }}
                                <li class="flex justify-between">
                                  <span>{{ .String "userName" }}</span>
                                  <span class="color-subdue">{{ .Int "photos" }} photos · {{ div (.Int "usage" | toFloat) 1073741824.0 | printf "%.1f" }} GB</span>
                                </li>
                              {{ end }}
                            </ul>
                          {{ end }}
                        '';
                      }
                      {
                        type = "group";
                        widgets = [
                          {
                            type = "custom-api";
                            title = "TV";
                            title-url = hl.records.sonarr.url;
                            cache = "30m";
                            options = {
                              service = "sonarr";
                              type = "upcoming";
                              size = "medium";
                              collapse-after = 3;
                              show-grabbed = false;
                              timezone = "+01";
                              interval = 14;
                              api-base-url = hl.records.sonarr.upstream;
                              # Posters are fetched by the browser, not by glance, so
                              # they go through Caddy's same-origin cover proxy
                              # instead of api-base-url (see the glance record above).
                              cover-proxy = "/covers/sonarr";
                              key = {
                                _secret = "/run/credentials/glance.service/sonarr-api_key";
                              };
                              url = hl.records.sonarr.url;
                            };
                            template = servarrTemplate;
                          }
                          {
                            type = "custom-api";
                            title = "Movies";
                            title-url = hl.records.radarr.url;
                            cache = "30m";
                            options = {
                              service = "radarr";
                              type = "upcoming";
                              size = "medium";
                              collapse-after = 3;
                              show-grabbed = false;
                              timezone = "+01";
                              interval = 30;
                              api-base-url = hl.records.radarr.upstream;
                              cover-proxy = "/covers/radarr";
                              key = {
                                _secret = "/run/credentials/glance.service/radarr-api_key";
                              };
                              url = hl.records.radarr.url;
                            };
                            template = servarrTemplate;
                          }
                        ];
                      }
                    ];
                  }
                  {
                    size = "full";
                    widgets = [
                      {
                        type = "search";
                        search-engine = "duckduckgo";
                        autofocus = true;
                        placeholder = "Search, or !yt !gh !np !no !hm";
                        bangs = [
                          {
                            title = "YouTube";
                            shortcut = "!yt";
                            url = "https://www.youtube.com/results?search_query={QUERY}";
                          }
                          {
                            title = "GitHub";
                            shortcut = "!gh";
                            url = "https://github.com/search?q={QUERY}&type=repositories";
                          }
                          {
                            title = "Nix packages";
                            shortcut = "!np";
                            url = "https://search.nixos.org/packages?channel=unstable&query={QUERY}";
                          }
                          {
                            title = "NixOS options";
                            shortcut = "!no";
                            url = "https://search.nixos.org/options?channel=unstable&query={QUERY}";
                          }
                          {
                            title = "Home Manager options";
                            shortcut = "!hm";
                            url = "https://home-manager-options.extranix.com/?release=master&query={QUERY}";
                          }
                        ];
                      }
                      {
                        type = "bookmarks";
                        groups = [
                          {
                            title = "Everyday";
                            links = [
                              {
                                title = "Proton Mail";
                                url = "https://mail.proton.me/";
                              }
                              {
                                title = "Proton Calendar";
                                url = "https://calendar.proton.me/";
                              }
                              {
                                title = "Amazon";
                                url = "https://www.amazon.de/";
                              }
                              {
                                title = "YouTube";
                                url = "https://www.youtube.com/";
                              }
                            ];
                          }
                          {
                            title = "Code";
                            links = [
                              {
                                title = "GitHub";
                                url = "https://github.com/";
                              }
                              {
                                title = "Gitea";
                                url = hl.records.gitea.url;
                              }
                              {
                                title = "WannaShare";
                                url = "https://git.victorbuch.com/Smoothless/WannaShare";
                              }
                              {
                                title = "serenityOs";
                                url = "https://github.com/VictorBuch/serenityOs";
                              }
                            ];
                          }
                          {
                            title = "Nix";
                            links = [
                              {
                                title = "Packages & options";
                                url = "https://search.nixos.org/";
                              }
                              {
                                title = "Home Manager options";
                                url = "https://home-manager-options.extranix.com/";
                              }
                              {
                                title = "Noogle";
                                url = "https://noogle.dev/";
                              }
                            ];
                          }
                          {
                            title = "Guitar";
                            links = [
                              {
                                title = "TrueFire";
                                url = "https://truefire.com/";
                              }
                              {
                                title = "FeedForge";
                                url = "https://feedforge.org/";
                              }
                            ];
                          }
                        ];
                      }
                      {
                        type = "monitor";
                        cache = "1m";
                        title = "Media";
                        sites = monitorSites "media";
                      }
                      {
                        type = "monitor";
                        cache = "1m";
                        title = "Productivity & Tools";
                        sites = monitorSites "productivity";
                      }
                      {
                        type = "monitor";
                        cache = "1m";
                        title = "Infrastructure";
                        sites = monitorSites "infrastructure";
                      }
                    ];
                  }
                  {
                    size = "small";
                    widgets = [
                      {
                        type = "server-stats";
                        servers = [
                          {
                            type = "local";
                            name = "Mal";
                          }
                        ];
                      }
                      {
                        type = "dns-stats";
                        title = "DNS";
                        title-url = hl.records.adguard.url;
                        service = "adguard";
                        url = hl.records.adguard.upstream;
                        hour-format = "24h";
                      }
                      {
                        type = "custom-api";
                        title = "Formula 1";
                        cache = "1h";
                        url = "https://api.jolpi.ca/ergast/f1/current/next.json";
                        template =
                          let
                            # Jolpica nests each session under its own key; the
                            # race itself is the top-level date/time.
                            session = label: prefix: ''
                              {{ if $race.Exists "${prefix}time" }}
                                {{ $t := parseTime "rfc3339" (concat ($race.String "${prefix}date") "T" ($race.String "${prefix}time")) }}
                                <li class="flex justify-between{{ if $t.Before now }} color-subdue{{ end }}">
                                  <span>${label}</span>
                                  <span>{{ $t.Local | formatTime "Mon 2 Jan 15:04" }}</span>
                                </li>
                              {{ end }}
                            '';
                          in
                          ''
                            {{ $races := .JSON.Array "MRData.RaceTable.Races" }}
                            {{ if eq (len $races) 0 }}
                              <p class="color-subdue">No more races this season.</p>
                            {{ else }}
                              {{ $race := index $races 0 }}
                              {{ $start := parseTime "rfc3339" (concat ($race.String "date") "T" ($race.String "time")) }}
                              <a class="size-h3 color-highlight block" href="{{ $race.String "url" }}" target="_blank" rel="noreferrer">{{ $race.String "raceName" }}</a>
                              <p class="size-h6">
                                Round {{ $race.String "round" }} · {{ $race.String "Circuit.Location.locality" }}, {{ $race.String "Circuit.Location.country" }}
                              </p>
                              <p class="color-primary margin-top-5">Lights out in <span {{ $start | toRelativeTime }}></span></p>
                              <ul class="list list-gap-2 margin-top-10">
                                ${session "Practice 1" "FirstPractice."}
                                ${session "Practice 2" "SecondPractice."}
                                ${session "Practice 3" "ThirdPractice."}
                                ${session "Sprint quali" "SprintQualifying."}
                                ${session "Sprint" "Sprint."}
                                ${session "Qualifying" "Qualifying."}
                                ${session "Race" ""}
                              </ul>
                            {{ end }}

                            {{ $standings := newRequest "https://api.jolpi.ca/ergast/f1/current/driverStandings.json?limit=5" | getResponse }}
                            {{ if eq $standings.Response.StatusCode 200 }}
                              <p class="size-h6 margin-top-15">STANDINGS</p>
                              <ul class="list list-gap-2 margin-top-5">
                                {{ range $standings.JSON.Array "MRData.StandingsTable.StandingsLists.0.DriverStandings" }}
                                  <li class="flex justify-between">
                                    <span>{{ .String "position" }}. {{ .String "Driver.familyName" }}</span>
                                    <span class="color-subdue">{{ .String "points" }} pts</span>
                                  </li>
                                {{ end }}
                              </ul>
                            {{ end }}
                          '';
                      }
                      {
                        type = "releases";
                        cache = "1d";
                        collapse-after = 4;
                        repositories = [
                          "glanceapp/glance"
                          "immich-app/immich"
                          "mealie-recipes/mealie"
                          "pocket-id/pocket-id"
                          "bookorbit/bookorbit"
                          "CodeWithCJ/SparkyFitness"
                        ];
                      }
                    ];
                  }
                ];
              }
            ];
          };
        };

        # Configure glance service credentials
        systemd.services.glance.serviceConfig.LoadCredential = [
          "sonarr-api_key:${config.sops.secrets."sonarr_api_key".path}"
          "radarr-api_key:${config.sops.secrets."radarr_api_key".path}"
          "immich-api_key:${config.sops.secrets."immich_api_key".path}"
        ];
      };
    };
}
