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
  nixosIp = hl.nixosIp;
  local = "http://127.0.0.1";

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
  options = {
    dashboard = {
      homarr.enable = lib.mkEnableOption "Enables the homarr dashboard";
      glance.enable = lib.mkEnableOption "Enables the glance dashboard";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.dashboard.homarr.enable {
      systemd.tmpfiles.rules = [
        "d /home/${user.userName}/dashboard 0770 ${toString user.uid} ${user.group} -"
        "d /home/${user.userName}/dashboard/homarr 0770 ${toString user.uid} ${user.group} -"
      ];
      virtualisation.oci-containers.containers.homarr = {
        image = "ghcr.io/ajnart/homarr:latest";
        autoStart = true;
        volumes = [
          "/home/${user.userName}/dashboard/homarr:/app/data/configs"
          "homarr:/app/public/icons"
        ];
        ports = [ "7575:7575" ];
      };
    })
    (lib.mkIf config.dashboard.glance.enable {
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
            port = 8080;
          };
          theme = {
            backgroundColor = [
              240
              21
              15
            ];
            contrastMultiplier = 1.2;
            primaryColor = [
              217
              92
              83
            ];
            positiveColor = [
              115
              54
              76
            ];
            negativeColor = [
              347
              70
              65
            ];
          };
          pages = [
            {
              name = "Home";
              hideDesktopNavigation = true;
              columns = [
                {
                  size = "small";
                  widgets = [
                    {
                      type = "weather";
                      location = "Brno, Czechia";
                      units = "metric";
                      hourFormat = "12h";
                    }
                    # Immich Stats Widget
                    {
                      type = "custom-api";
                      title = "Immich Stats";
                      title-url = "https://photos.${hl.domain}";
                      cache = "5m";
                      options = {
                        api-base-url = "http://localhost:2283";
                        key = {
                          _secret = "/run/credentials/glance.service/immich-api_key";
                        };
                      };
                      template = ''
                        {{ $apiKey := .Options.StringOr "key" "" }}
                        {{ $baseUrl := .Options.StringOr "api-base-url" "" }}

                        {{ if or (eq $apiKey "") (eq $baseUrl "") }}
                          <div class="widget-error-header">
                            <div class="color-negative size-h3">ERROR</div>
                            <p>Missing API key or base URL</p>
                          </div>
                        {{ else }}
                          {{ $statsUrl := printf "%s/api/server-info/statistics" $baseUrl }}
                          {{ $stats := newRequest $statsUrl
                            | withHeader "Accept" "application/json"
                            | withHeader "x-api-key" $apiKey
                            | getResponse }}

                          <div class="flex flex-column gap-10">
                            <div class="flex gap-10 items-center">
                              <div class="color-primary">Photos & Videos</div>
                            </div>

                            {{ $photos := $stats.JSON.Int "photos" }}
                            {{ $videos := $stats.JSON.Int "videos" }}
                            {{ $total := add $photos $videos }}

                            <div class="flex flex-column gap-5">
                              <div class="flex justify-between">
                                <span class="color-subdue">Photos:</span>
                                <span class="font-mono">{{ $photos | printf "%d" }}</span>
                              </div>
                              <div class="flex justify-between">
                                <span class="color-subdue">Videos:</span>
                                <span class="font-mono">{{ $videos | printf "%d" }}</span>
                              </div>
                              <div class="flex justify-between font-bold">
                                <span>Total:</span>
                                <span class="font-mono">{{ $total | printf "%d" }}</span>
                              </div>
                            </div>

                            {{ $usage := $stats.JSON.Int "usage" }}
                            {{ $usageByUser := $stats.JSON.Int "usageByUser" }}

                            <div class="margin-top-10 padding-top-10 border-top">
                              <div class="flex gap-10 items-center margin-bottom-10">
                                <div class="color-primary">Storage</div>
                              </div>

                              {{ $gb := div $usage 1073741824.0 }}
                              {{ $userGb := div $usageByUser 1073741824.0 }}

                              <div class="flex flex-column gap-5">
                                <div class="flex justify-between">
                                  <span class="color-subdue">Total:</span>
                                  <span class="font-mono">{{ $gb | printf "%.2f GB" }}</span>
                                </div>
                                <div class="flex justify-between">
                                  <span class="color-subdue">By Users:</span>
                                  <span class="font-mono">{{ $userGb | printf "%.2f GB" }}</span>
                                </div>
                              </div>
                            </div>
                          </div>
                        {{ end }}
                      '';
                    }
                    # TV Shows Widget
                    {
                      type = "custom-api";
                      title = "TV Shows";
                      title-url = "https://shows.${hl.domain}";
                      cache = "30m";
                      options = {
                        service = "sonarr";
                        type = "upcoming";
                        size = "medium";
                        collapse-after = 3;
                        show-grabbed = false;
                        timezone = "-04";
                        interval = 20;
                        api-base-url = "http://localhost:8989";
                        key = {
                          _secret = "/run/credentials/glance.service/sonarr-api_key";
                        };
                        url = "https://shows.${hl.domain}";
                      };
                      template = servarrTemplate;
                    }
                    # Movies Widget
                    {
                      type = "custom-api";
                      title = "Movies";
                      title-url = "https://movies.${hl.domain}";
                      cache = "30m";
                      options = {
                        service = "radarr";
                        type = "upcoming";
                        size = "medium";
                        collapse-after = 3;
                        show-grabbed = false;
                        timezone = "-04";
                        interval = 20;
                        api-base-url = "http://localhost:7878";
                        key = {
                          _secret = "/run/credentials/glance.service/radarr-api_key";
                        };
                        url = "https://movies.${hl.domain}";
                      };
                      template = servarrTemplate;
                    }
                  ];
                }
                {
                  size = "full";
                  widgets = [
                    {
                      type = "search";
                      searchEngine = "duckduckgo";
                      bangs = [
                        {
                          title = "YouTube";
                          shortcut = "!yt";
                          url = "https://www.youtube.com/results?search_query={QUERY}";
                        }
                      ];
                    }
                    # Media Stack Monitor Group
                    {
                      type = "monitor";
                      cache = "1m";
                      title = "Media Stack";
                      sites = [
                        {
                          title = "Jellyfin";
                          url = "https://jellyfin.${hl.domain}";
                          icon = "sh:jellyfin";
                          check-url = "${local}:8096";
                        }
                        {
                          title = "Plex";
                          url = "https://plex.${hl.domain}/web/index.html";
                          icon = "sh:plex";
                          check-url = "${local}:32400";
                        }
                        {
                          title = "Jellyseerr";
                          url = "https://request.${hl.domain}";
                          icon = "sh:jellyseerr";
                          check-url = "${local}:5055";
                        }
                        {
                          title = "Sonarr";
                          url = "https://shows.${hl.domain}";
                          icon = "sh:sonarr";
                          check-url = "${local}:8989";
                        }
                        {
                          title = "Radarr";
                          url = "https://movies.${hl.domain}";
                          icon = "sh:radarr";
                          check-url = "${local}:7878";
                        }
                        {
                          title = "Lidarr";
                          url = "https://music.${hl.domain}";
                          icon = "sh:lidarr";
                          check-url = "${local}:8686";
                        }
                        {
                          title = "Readarr";
                          url = "https://books.${hl.domain}";
                          icon = "sh:readarr";
                          check-url = "${local}:8787";
                        }
                        {
                          title = "Prowlarr";
                          url = "https://prowlarr.${hl.domain}";
                          icon = "sh:prowlarr";
                          check-url = "${local}:9696";
                        }
                        {
                          title = "Bazarr";
                          url = "https://subtitles.${hl.domain}";
                          icon = "sh:bazarr";
                          check-url = "${local}:6767";
                        }
                        {
                          title = "AudioBookshelf";
                          url = "https://audiobooks.${hl.domain}";
                          icon = "sh:audiobookshelf";
                          check-url = "${local}:8004";
                        }
                        {
                          title = "Music Assistant";
                          url = "https://ma.${hl.domain}";
                          icon = "sh:music-assistant";
                          check-url = "${local}:8095";
                        }
                        {
                          title = "Deluge";
                          url = "https://downloads.${hl.domain}";
                          icon = "sh:deluge";
                          check-url = "${local}:8112";
                        }
                      ];
                    }
                    # Infrastructure Monitor Group
                    {
                      type = "monitor";
                      cache = "1m";
                      title = "Infrastructure";
                      sites = [
                        {
                          title = "Home Assistant";
                          url = "http://192.168.0.16:8123/";
                          icon = "sh:home-assistant";
                          "allow-insecure" = true;
                        }
                        {
                          title = "Uptime Kuma";
                          url = "https://status.${hl.domain}";
                          icon = "sh:uptime-kuma";
                          check-url = "${local}:3001";
                        }
                        {
                          title = "AdGuard Home";
                          url = "https://ad.${hl.domain}";
                          icon = "sh:adguard-home";
                          check-url = "${local}:1411";
                        }
                        {
                          title = "Gitea";
                          url = "https://git.${hl.domain}/";
                          icon = "sh:gitea";
                          check-url = "${local}:3004";
                        }
                        {
                          title = "NextCloud";
                          url = "https://nextcloud.${hl.domain}";
                          icon = "sh:nextcloud";
                        }
                        {
                          title = "HyperHDR";
                          url = "http://${nixosIp}:8090";
                          icon = "sh:hyperhdr";
                          check-url = "${local}:8090";
                        }
                      ];
                    }
                    # Productivity & Tools Monitor Group
                    {
                      type = "monitor";
                      cache = "1m";
                      title = "Productivity & Tools";
                      sites = [
                        {
                          title = "Immich";
                          url = "https://photos.${hl.domain}/";
                          icon = "sh:immich";
                          check-url = "${local}:2283";
                        }
                        {
                          title = "Mealie";
                          url = "https://cooking.${hl.domain}/";
                          icon = "sh:mealie";
                          check-url = "${local}:9000";
                        }
                        {
                          title = "Paperless";
                          url = "https://paperless.${hl.domain}/";
                          icon = "sh:paperless-ngx";
                          check-url = "${local}:28981";
                        }
                        {
                          title = "Filebrowser";
                          url = "https://files.${hl.domain}";
                          icon = "sh:file-browser";
                          check-url = "${local}:3030";
                        }
                        {
                          title = "Wallos";
                          url = "https://subscriptions.${hl.domain}";
                          icon = "sh:wallos";
                          check-url = "${local}:8282";
                        }
                        {
                          title = "It-Tools";
                          url = "https://tools.${hl.domain}";
                          icon = "sh:it-tools";
                          check-url = "https://tools.${hl.domain}";
                        }
                        {
                          title = "Crafty";
                          url = "https://crafty.${hl.domain}";
                          icon = "sh:minecraft";
                          check-url = "https://127.0.0.1:8443";
                        }
                      ];
                    }
                    # Bookmarks
                    {
                      type = "bookmarks";
                      groups = [
                        {
                          title = "General";
                          links = [
                            {
                              title = "Proton Mail";
                              url = "https://mail.proton.me/";
                            }
                            {
                              title = "Amazon";
                              url = "https://www.amazon.de/";
                            }
                            {
                              title = "Github";
                              url = "https://github.com/";
                            }
                            {
                              title = "ChatGPT";
                              url = "https://chatgpt.com";
                            }
                          ];
                        }
                        {
                          title = "Entertainment";
                          links = [
                            {
                              title = "YouTube";
                              url = "https://www.youtube.com/";
                            }
                          ];
                        }
                      ];
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
                          name = "Serenity";
                        }
                      ];
                    }
                    {
                      type = "releases";
                      cache = "1d";
                      repositories = [
                        "glanceapp/glance"
                        "immich-app/immich"
                        "mealie-recipes/mealie"
                        "steveiliop56/tinyauth"
                        "pocket-id/pocket-id"
                        "LazyVim/LazyVim"
                      ];
                    }
                    {
                      type = "custom-api";
                      title = "Next Race";
                      cache = "1d";
                      url = "https://f1api.dev/api/current/next?timezone=Europe/London";
                      template = ''
                        <div class="flex flex-column gap-10">
                            {{ $session := index (.JSON.Array "race") 0 }}
                            <p class="size-h5">
                              Round {{ .JSON.String "round" }}
                            </p>

                            <div class="margin-block-4">
                              <p class="color-highlight">{{ $session.String "raceName" }}</p>

                              <div class="margin-block-10"></div>

                              <!-- Race -->
                              <p class="color-primary">
                                <span>Race</span>
                                {{ $raceDate := $session.String "schedule.race.date" }}
                                {{ $raceTime := $session.String "schedule.race.time" }}
                                {{ $raceDateTime := concat $raceDate "T" $raceTime }}
                                {{ $parsedRaceTime := parseLocalTime "2006-01-02T15:04:05" $raceDateTime }}
                                {{ $now := now }}
                                {{ if $parsedRaceTime.Before $now }}
                                  <span class="color-highlight">Completed</span>
                                {{ else }}
                                  <span class="color-highlight" {{ $parsedRaceTime | toRelativeTime }}></span>
                                {{ end }}
                              </p>
                              <p class="size-h5">{{ $raceDate }} at {{ $raceTime }}</p>

                              <!-- Qualifying -->
                              <p class="color-primary">
                                <span>Qualifying</span>
                                {{ $qualyDate := $session.String "schedule.qualy.date" }}
                                {{ $qualyTime := $session.String "schedule.qualy.time" }}
                                {{ $qualyDateTime := concat $qualyDate "T" $qualyTime }}
                                {{ $parsedQualyTime := parseLocalTime "2006-01-02T15:04:05" $qualyDateTime }}
                                {{ $now := now }}
                                {{ if $parsedQualyTime.Before $now }}
                                  <span class="color-highlight">Completed</span>
                                {{ else }}
                                  <span class="color-highlight" {{ $parsedQualyTime | toRelativeTime }}></span>
                                {{ end }}
                              </p>
                              <p class="size-h5">{{ $qualyDate }} at {{ $qualyTime }}</p>

                              <!-- Free Practice 1 -->
                              <p class="color-primary">
                                <span>Free Practice 1</span>
                                {{ $fp1Date := $session.String "schedule.fp1.date" }}
                                {{ $fp1Time := $session.String "schedule.fp1.time" }}
                                {{ $fp1DateTime := concat $fp1Date "T" $fp1Time }}
                                {{ $parsedFP1Time := parseLocalTime "2006-01-02T15:04:05" $fp1DateTime }}
                                {{ $now := now }}
                                {{ if $parsedFP1Time.Before $now }}
                                  <span class="color-highlight">Completed</span>
                                {{ else }}
                                  <span class="color-highlight" {{ $parsedFP1Time | toRelativeTime }}></span>
                                {{ end }}
                              </p>
                              <p class="size-h5">{{ $fp1Date }} at {{ $fp1Time }}</p>

                              <!-- Free Practice 2 -->
                              <p class="color-primary">
                                <span>Free Practice 2</span>
                                {{ $fp2Date := $session.String "schedule.fp2.date" }}
                                {{ $fp2Time := $session.String "schedule.fp2.time" }}
                                {{ $fp2DateTime := concat $fp2Date "T" $fp2Time }}
                                {{ $parsedFP2Time := parseLocalTime "2006-01-02T15:04:05" $fp2DateTime }}
                                {{ $now := now }}
                                {{ if $parsedFP2Time.Before $now }}
                                  <span class="color-highlight">Completed</span>
                                {{ else }}
                                  <span class="color-highlight" {{ $parsedFP2Time | toRelativeTime }}></span>
                                {{ end }}
                              </p>
                              <p class="size-h5">{{ $fp2Date }} at {{ $fp2Time }}</p>

                              <!-- Free Practice 3 -->
                              <p class="color-primary">
                                <span>Free Practice 3</span>
                                {{ $fp3Date := $session.String "schedule.fp3.date" }}
                                {{ $fp3Time := $session.String "schedule.fp3.time" }}
                                {{ $fp3DateTime := concat $fp3Date "T" $fp3Time }}
                                {{ $parsedFP3Time := parseLocalTime "2006-01-02T15:04:05" $fp3DateTime }}
                                {{ $now := now }}
                                {{ if $parsedFP3Time.Before $now }}
                                  <span class="color-highlight">Completed</span>
                                {{ else }}
                                  <span class="color-highlight" {{ $parsedFP3Time | toRelativeTime }}></span>
                                {{ end }}
                              </p>
                              <p class="size-h5">{{ $fp3Date }} at {{ $fp3Time }}</p>

                              <!-- Sprint Qualifying - only if date is not null -->
                              {{ if and (ne ($session.String "schedule.sprintQualy.date") "null") (ne ($session.String "schedule.sprintQualy.date") "") }}
                              <p class="color-primary">
                                <span>Sprint Qualifying</span>
                                {{ $sprintQualyDate := $session.String "schedule.sprintQualy.date" }}
                                {{ $sprintQualyTime := $session.String "schedule.sprintQualy.time" }}
                                {{ $sprintQualyDateTime := concat $sprintQualyDate "T" $sprintQualyTime }}
                                {{ $parsedSprintQualyTime := parseLocalTime "2006-01-02T15:04:05" $sprintQualyDateTime }}
                                {{ $now := now }}
                                {{ if $parsedSprintQualyTime.Before $now }}
                                  <span class="color-highlight">Completed</span>
                                {{ else }}
                                  <span class="color-highlight" {{ $parsedSprintQualyTime | toRelativeTime }}></span>
                                {{ end }}
                              </p>
                              <p class="size-h5">{{ $sprintQualyDate }} at {{ $sprintQualyTime }}</p>
                              {{ end }}

                              <!-- Sprint Race - only if date is not null -->
                              {{ if and (ne ($session.String "schedule.sprintRace.date") "null") (ne ($session.String "schedule.sprintRace.date") "") }}
                              <p class="color-primary">
                                <span>Sprint Race</span>
                                {{ $sprintRaceDate := $session.String "schedule.sprintRace.date" }}
                                {{ $sprintRaceTime := $session.String "schedule.sprintRace.time" }}
                                {{ $sprintRaceDateTime := concat $sprintRaceDate "T" $sprintRaceTime }}
                                {{ $parsedSprintRaceTime := parseLocalTime "2006-01-02T15:04:05" $sprintRaceDateTime }}
                                {{ $now := now }}
                                {{ if $parsedSprintRaceTime.Before $now }}
                                  <span class="color-highlight">Completed</span>
                                {{ else }}
                                  <span class="color-highlight" {{ $parsedSprintRaceTime | toRelativeTime }}></span>
                                {{ end }}
                              </p>
                              <p class="size-h5">{{ $sprintRaceDate }} at {{ $sprintRaceTime }}</p>
                              {{ end }}
                            </div>

                            <ul class="size-h5 attachments">
                              <li>{{ $session.String "circuit.country" }}</li>
                              <li>{{ $session.String "circuit.city" }}</li>
                              <li>{{ $session.String "laps" }} Laps</li>
                              <li>{{ $session.String "circuit.circuitName" }}</li>
                            </ul>
                          </div>
                      '';
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
    })
  ];
}
