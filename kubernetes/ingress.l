apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: cvapp-ingress
  
  annotations:
    # kubernetes.io/ingress.class: "nginx"
    #nginx.ingress.kubernetes.io/affinity-mode: "persistent"
    #nginx.ingress.kubernetes.io/affinity: "cookie"
    nginx.ingress.kubernetes.io/use-regex: "true"
    #nginx.ingress.kubernetes.io/rewrite-target: /$2
    # nginx.ingress.kubernetes.io/configuration-snippet: |
    #   more_set_headers "server: hide";
    #   more_set_headers "X-Content-Type-Options: nosniff"
    #   more_set_headers "Cross-Origin-Resource-Policy: same-site";
spec:
  ingressClassName: nginx
  rules:
  - host: app.cvapplication.xyz
    http:
      paths:
      - path: /
        pathType: Prefix #Exact
        backend:
          service:
            name: cvapp-web-svc
            port:
              number: 80

      # - path: /login
      #   pathType: Exact
      #   backend:
      #     service:
      #       name: cvapp-web-svc
      #       port:
      #         number: 80
      # - path: /register
      #   pathType: Exact
      #   backend:
      #     service:
      #       name: cvapp-web-svc
      #       port:
      #         number: 80
      
      - path: /api/v1/?(.*)
        pathType: ImplementationSpecific #Prefix
        backend:
          service:
            name: cvapp-api-svc
            port:
              number: 5000