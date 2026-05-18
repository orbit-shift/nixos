{ pkgs, lib, config, ... }: let
  kubeconfig = pkgs.writeText "kubeconfig" ''
    apiVersion: v1
    clusters:
    - cluster:
        certificate-authority: /var/lib/kubernetes/secrets/ca.pem
        server: https://127.0.0.1:6443
      name: default
    contexts:
    - context:
        cluster: default
        user: admin
      name: default
    current-context: default
    kind: Config
    users:
    - name: admin
      user:
        client-certificate: /var/lib/kubernetes/secrets/cluster-admin.pem
        client-key: /var/lib/kubernetes/secrets/cluster-admin-key.pem
  '';
  kubectl = "${pkgs.kubectl}/bin/kubectl --kubeconfig ${kubeconfig}";
  istioctl = "${pkgs.istioctl}/bin/istioctl --kubeconfig ${kubeconfig}";
in {
  config = {
    # ── Istio Gateway + Gateway API CRDs ─────────────────────
    # Deploys Istio, Gateway API Standard CRDs, and Gateway resources
    # (web HTTPS/HTTP + ssh TCP)

    # ── Istio Installation ────────────────────────────────────
    systemd.services.deploy-istio = {
      description = "Install Istio service mesh";
      after = [ "kubelet.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = ''
        if ! ${kubectl} get namespace istio-system &>/dev/null; then
          echo "Installing Istio..."
          ${istioctl} install -y --set profile=demo
        else
          echo "Istio already installed"
        fi
      '';
    };

    # ── Scale Ingress Gateway ─────────────────────────────────
    systemd.services.scale-ingressgateway = {
      description = "Scale Istio ingressgateway replicas";
      after = [ "deploy-istio.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = ''
        echo "Scaling istio-ingressgateway..."
        ${kubectl} scale deployments -n istio-system \
          istio-ingressgateway --replicas=1
      '';
    };

    # ── Expose Ingress Gateway via NodePort ───────────────────
    systemd.services.expose-istio-nodeport = {
      description = "Expose Istio ingressgateway ports via NodePort";
      after = [ "deploy-istio.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = ''
        echo "Exposing istio-ingressgateway ports 80/443 via NodePort..."
        ${kubectl} patch svc -n istio-system istio-ingressgateway \
          -p '{"spec":{"type":"NodePort","ports":[{"port":80,"nodePort":80},{"port":443,"nodePort":443}]}}'
      '';
    };

    # ── Set ExternalTrafficPolicy to Local ────────────────────
    systemd.services.set-external-traffic-policy = {
      description = "Set externalTrafficPolicy to Local on istio-ingressgateway";
      after = [ "expose-istio-nodeport.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = ''
        echo "Setting externalTrafficPolicy to Local..."
        ${kubectl} patch svc -n istio-system istio-ingressgateway \
          -p '{"spec":{"externalTrafficPolicy":"Local"}}'
      '';
    };

    # ── Gateway API CRDs ──────────────────────────────────────
    systemd.services.deploy-gateway-api-crds = {
      description = "Deploy Gateway API Standard CRDs";
      after = [ "deploy-istio.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = let
        gatewayApiVersion = "v1.4.1";
      in ''
        echo "Deploying Gateway API CRDs..."
        ${kubectl} apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/${gatewayApiVersion}/standard-install.yaml
      '';
    };

    # ── Gateway Resources (web + ssh) ─────────────────────────
    systemd.services.deploy-gateways = {
      description = "Deploy Gateway resources (web and ssh)";
      after = [ "deploy-gateway-api-crds.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = let
        gatewayManifest = pkgs.writeText "gateways.yaml" ''
          apiVersion: gateway.networking.k8s.io/v1
          kind: Gateway
          metadata:
            name: web
            namespace: istio-system
          spec:
            addresses:
            - value: istio-ingressgateway.istio-system.svc.cluster.local
              type: Hostname
            gatewayClassName: istio
            listeners:
            - name: web-https
              port: 443
              protocol: HTTPS
              allowedRoutes:
                namespaces:
                  from: Selector
                  selector:
                    matchLabels:
                      shared-gateway-access: "true"
              tls:
                mode: Terminate
                certificateRefs:
                  - name: cert-web
                    kind: Secret
                    group: core
            - name: web-http
              port: 80
              protocol: HTTP
              allowedRoutes:
                namespaces:
                  from: Selector
                  selector:
                    matchLabels:
                      shared-gateway-access: "true"
          ---
          apiVersion: gateway.networking.k8s.io/v1
          kind: Gateway
          metadata:
            name: ssh
            namespace: istio-system
          spec:
            addresses:
            - value: istio-ingressgateway.istio-system.svc.cluster.local
              type: Hostname
            gatewayClassName: istio
            listeners:
            - name: ssh
              port: 22
              protocol: TCP
              allowedRoutes:
                namespaces:
                  from: Selector
                  selector:
                    matchLabels:
                      shared-gateway-access: "true"
        '';
      in ''
        echo "Deploying Gateway resources..."
        ${kubectl} apply -f ${gatewayManifest}
      '';
    };
  };
}
