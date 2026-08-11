{ lib, ... }:

{
  serenity.cmds = ''
    appwrite          Appwrite CLI, installed into .devenv on first use
    appwrite-deploy   Deploy everything declared in appwrite.json
  '';

  scripts = {
    appwrite.exec = lib.mkDefault ''
      prefix="$DEVENV_STATE/npm"
      bin="$prefix/bin/appwrite"
      if [ ! -x "$bin" ]; then
        echo "Installing appwrite-cli into $prefix ..." >&2
        npm install --global --silent --prefix "$prefix" appwrite-cli >&2
      fi
      exec "$bin" "$@"
    '';

    appwrite-deploy.exec = lib.mkDefault ''
      exec appwrite deploy -a --force "$@"
    '';
  };
}
