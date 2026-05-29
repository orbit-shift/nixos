{ pkgs, user, ... }:

let
  hermesSrc = "/home/master/world/hermes-agent";

  hermesEnv = pkgs.python3.withPackages (ps: with ps; [
    pip
    setuptools
    python-dotenv
    fire
    httpx
    socksio        # httpx[socks] 的 socks 支持
    rich
    tenacity
    pyyaml
    ruamel-yaml
    requests
    jinja2
    pydantic
    prompt-toolkit
    croniter
    pyjwt
    psutil
    tzdata
    # Optional: LLM providers
    anthropic
    # Optional: Web search backends
    exa-py
    firecrawl-py
    # parallel-web  # nixpkgs 中暂无，按需 pip install
    # Optional: Image generation
    # fal-client    # nixpkgs 中暂无，按需 pip install
    # Optional: CLI
    simple-term-menu
    # Optional: ACP
    agent-client-protocol
    # Optional: Feishu integration
    # lark-oapi     # nixpkgs 中暂无，按需 pip install
    qrcode
  ]);

  hermesService = pkgs.writeShellScriptBin "hermes-service" ''
    export PATH="${hermesEnv}/bin:$PATH"
    export PYTHONPATH="${hermesSrc}:$PYTHONPATH"
    cd ${hermesSrc}
    exec ${hermesEnv}/bin/python -m gateway.run
  '';
in {
  systemd.services.hermes-agent = {
    description = "Hermes Agent Gateway";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      ExecStart = "${hermesService}/bin/hermes-service";
      Restart = "always";
      RestartSec = "10s";
      User = user;
      WorkingDirectory = hermesSrc;

      StartLimitBurst = 3;
      StartLimitIntervalSec = 60;
    };
  };
}
