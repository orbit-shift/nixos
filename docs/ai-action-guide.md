# AI Action Guide

## Execute Commands on Remote Server

- Use `ssh <host> '<cmds>'` to execute commands on the server.
- **Always ask the user for `<host>` before running any remote command.**

## nixos-rebuild

- **Never run `nixos-rebuild` directly.** Always notify the user to execute it manually and wait for confirmation.

## Runtime Cleanup vs Configuration Changes

- **Cleaning up stale resources** (e.g., deleting old Jobs, Secrets, Pods): Execute `kubectl delete` directly via SSH.
- **Changing installation/deployment flow** (e.g., image prefixes, manifest URLs, service scripts): Must sync changes to NixOS config, then notify the user to run `nixos-rebuild switch`.

## Fetch SRI Hash for `fetchurl`

Use the `fetch-sri` utility in `x.nu`:
```nushell
source x.nu
utils fetch-sri <URL>
```
> 📘 For detailed standards, see [Nushell Style Guide](nushell-style.md).

## Nushell Programming Style Guide

### Pipeline-First
Prefer transforming data through a stream (`|`) over intermediate variables (`let`).
```nushell
# Good
^curl -sL $url | hash sha256 | decode hex | encode base64 | $"sha256-($in)"
```

### Binary Safety
Always use the `^` escape for external commands processing binary data to prevent Nushell from parsing UTF-8/Table structures and corrupting the stream.
```nushell
^curl ... | hash sha256
```

## NixOS Configuration Guidelines

### Modular Declarations & Merge Logic
- **Keep Modular Structure**: Respect independent declarations across modules (e.g., `common`, `control`, `worker`). Do **NOT** consolidate list options (like firewall ports) into a single file just to avoid "multiple definitions" errors.
- **Use Custom Merge for Deduplication**: If list options need to be declared in multiple modules and merged, override the `merge` function to handle concatenation and deduplication:
  ```nix
  options.services.kubernetes.firewallPorts = lib.mkOption {
    type = lib.types.listOf lib.types.port;
    default = [];
    merge = loc: defs: lib.unique (lib.concatMap (def: def.value) defs);
  };
  ```
  This achieves the desired pattern: **Separate declarations → Automatic aggregation → Final deduplication → Apply to firewall**.
  The merged ports are then applied via: `networking.firewall.allowedTCPPorts = lib.unique config.services.kubernetes.firewallPorts;`

### Verify Original Code Context
- **Check Error Traces**: Before claiming code "wasn't there originally", strictly verify against the user-provided Error Trace or file context.
- **Lesson Learned**: `services.kubernetes.firewallPorts` (via `networking.firewall.allowedTCPPorts`) was present in the original file (Line 251-252 in the error trace). Always trust the evidence in the context.

### Post-Modification Verification
- **Run `sudo nix flake check`**: After modifying any configuration, execute `sudo nix flake check` to validate the syntax and options immediately. If `sudo` is not available in the current shell (e.g., in the AI agent environment), notify the user to run this command before `nixos-rebuild`.
