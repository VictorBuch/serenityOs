# TODO

- [ ] Home assistant automation clean up
- [ ] SMART tests on Mal - send summary to ntfy
- [x] Easier live update dotfiles for Jayne
- [x] Icons, file managers and other services seem very scattered and not very unified. Lets fix that for Jayne
- [x] Install / configure crowd sec on wash
- [x] Copyparty instead of nextcloud, i just need a simple file upload/download ui like a NAS service
- [x] try <https://github.com/liixini/skwd-wall> for nice wallpapers
- [x] find more wallpapers
- [x] try to implement self expiring overrides <https://jezenthomas.com/2026/07/nix-overrides-that-expire-themselves/>
- [ ] Migrate auth to Authentik (single user store for friends)
      Pangolin is an OIDC _consumer_ only — its users just gate the proxy, they
      can't log into apps. Pocket ID is passkey-only, so it stays admin-only:
      non-technical friends will not enrol a passkey.

  Authentik gives one username+password per person, plus an LDAP outpost —
  and LDAP is the only thing that makes Jellyfin work on native TV clients
  (Android TV / Roku / Infuse can't run any browser redirect flow, so OIDC
  alone never fixes them). Collapses the per-user-per-app credentials
  currently kept in Bitwarden.

BookOrbit audiobook + ebook sync: put ebooks next to their audiobooks

Goal: each audiobook and its ebook live in one folder, so BookOrbit treats them as one book.
Indexers and requests stay the same. Chaptarr still grabs each format as its own release.

[ ] 0. Back up first - Chaptarr: /home/serenity/chaptarr (chaptarr.db, config.xml) - BookOrbit database - Save a file list of /mnt/pool/media/books

[ ] 1. Chaptarr: turn the Audiobooks root folder into a mixed root - Settings > Media Management > Root Folders > Audiobooks (/mnt/pool/media/books/audiobooks) - Turn on "Import Mixed Content" - Turn on "Place eBooks with Audiobooks" - Set it as the default ebook root folder - Check the ebook quality profile on it (same as the eBooks root uses)

[ ] 2. Chaptarr: point every author's ebook root at the mixed root - Mass editor: set the ebook root folder to /mnt/pool/media/books/audiobooks - Choose "don't move files" (step 3 moves them by hand) - Authors still pointing at ebooks/: Scott Meyer, Joe Abercrombie, J.R.R. Tolkien,
Frank Herbert, Andrzej Sapkowski, Andy Weir, Cixin Liu, David Wong, Matt Dinniman
(and Robert Glover, whose ebook Chaptarr doesn't track yet)

[ ] 3. Move the existing ebooks (use mv --no-copy on the mergerfs pool)
Ebooks that go into their audiobook's folder: - Andrzej Sapkowski/Time of Contempt -> Time of Contempt - The Witcher, Book 2/ - David Wong/Futuristic Violence and Fancy Suits -> Futuristic Violence and Fancy Suits - Christy Romano/ - David Wong/This Book Is Full of Spiders -> This Book Is Full of Spiders - Seriously, Dude, ... (Book 2)/ - Joe Abercrombie/Before They Are Hanged -> Before they are hanged/ (epub + azw3) - Joe Abercrombie/The Blade Itself -> The Blade Itself/ - Joe Abercrombie/Last Argument of Kings -> Last Argument Of Kings/ (next to the mp3s, which works) - Matt Dinniman/Dungeon Crawler Carl -> Dungeon Crawler Carl - Jeff Hays/ - Scott Meyer/Master of Formalities -> Master of Formalities/ - Scott Meyer/Off to Be the Wizard -> Off to Be the Wizard - Magic 2.0, Book 1/ - Scott Meyer/Spell or High Water -> Spell or High Water - Magic 2.0, Book 2/ - Robert Glover/No More Mr. Nice Guy -> No More Mr. Nice Guy - A Proven Plan ... (Updated)/
Ebook-only books (move the whole folder to audiobooks/<Author>/<Title>/): - Andrzej Sapkowski/Baptism of Fire - Andy Weir/Project Hail Mary - Cixin Liu/The Three-Body Problem - Frank Herbert/Dune Saga Collection - Books 1-3 (omnibus, stays its own book) - J.R.R. Tolkien/The Fellowship of the Ring, The Two Towers, The Return of the King - Then check that ebooks/ is empty

[ ] 4. Chaptarr: rescan and clean up - Rescan the mixed root and check for no unmapped files - Check wanted/missing for duplicate empty books - Remove the old eBooks root folder (id 4) once nothing refers to it - Test with one new ebook grab for a book that has an audiobook:
it should land next to the m4b

[ ] 5. BookOrbit: use one library - Library path /books/audiobooks, scan mode "Folder as Book", watch folder on - Allowed formats: leave empty (all formats) - Remove the old separate ebook library - Turn off writing metadata into files if you don't want BookOrbit changing Chaptarr's files - Check: Off to Be the Wizard shows both audiobook and ebook, and progress syncs between them

[ ] 6. Syncthing: keep the Kindle share ebook-only - Swap the share of ebooks/ for the mixed folder, with this ignore file (.stignore):
!**/\*.epub
!**/_.azw3
_ - Check that no audio files reach the Kindle

[ ] 7. Audiobookshelf: check only - Library bb6b310d… keeps pointing at audiobooks/, nothing to change - Check that ebooks show up as supplementary ebooks and nothing is double-counted

Later (optional):
[ ] Rename audiobooks/ to something like library/ (needs Chaptarr, BookOrbit, Audiobookshelf
and Syncthing re-pointed)
[ ] Storyteller for read-along EPUBs (Chaptarr says this setting is required for it)
