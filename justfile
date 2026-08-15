target := "js"

default: check test

fmt:
    moon fmt

info:
    moon info

check:
    moon check --deny-warn --target {{target}}

test:
    moon test --target {{target}}

release-check: fmt info check test
