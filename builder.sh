#!/bin/sh

stage() {
    STAGE="$1"
    echo
    echo starting stage: $STAGE
}

end_stage() {
    if [ $? -ne 0 ]; then
        >&2 echo error at \'$STAGE\'
        exit 1
    fi
    echo finished stage: $STAGE ✓
    echo
}


module() {
    mkdir -p /caddy
    cd /caddy # build dir
    cat > go.mod <<EOF
    module caddy

    go 1.14

    require (
        github.com/caddyserver/caddy v1.0.5
        github.com/caddyserver/dnsproviders v0.4.0
        github.com/grpc-ecosystem/grpc-gateway v1.16.0
        github.com/lucas-clemente/quic-go v0.19.3
        github.com/captncraig/caddy-realip v0.0.0-20190710144553-6df827e22ab8
        github.com/echocat/caddy-filter v0.14.0
        github.com/epicagency/caddy-expires v1.1.1
        github.com/hacdias/caddy-minify v1.0.2
        github.com/nicolasazrak/caddy-cache v0.3.4
        github.com/pquerna/cachecontrol v0.0.0-20180517163645-1555304b9b35 // indirect
    )
EOF
    # main and telemetry
    cat > main.go <<EOF
    package main

    import (
        "github.com/caddyserver/caddy/caddy/caddymain"

        _ "github.com/caddyserver/dnsproviders/cloudflare"
        _ "github.com/caddyserver/forwardproxy"                 //http.forwardproxy
        _ "github.com/pyed/ipfilter"                            //http.ipfilter
        _ "github.com/echocat/caddy-filter"
        _ "github.com/nicolasazrak/caddy-cache"
        _ "github.com/hacdias/caddy-minify"
        _ "github.com/epicagency/caddy-expires"
        _ "github.com/captncraig/caddy-realip"
    )

    func main() {
        caddymain.EnableTelemetry = false
        caddymain.Run()
    }
EOF

    # setup module
    # go mod init caddy
    go get github.com/caddyserver/caddy
}

# check for modules support
# export GO111MODULE=on

# add plugins and telemetry
stage "customising plugins and telemetry"
module
end_stage

# build
stage "building caddy"
go build -o caddy
end_stage

# copy binary
stage "copying binary"
mkdir -p /install \
    && mv caddy /install \
    && /install/caddy -version
end_stage

echo "installed caddy version at /install/caddy"