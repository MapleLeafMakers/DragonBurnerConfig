#!/usr/bin/env bash
gh api '/repos/chirpy2605/voron/git/trees/{branch}?recursive=true' -q '.tree[]|select(.type == "blob")|.path' | \
    grep "^V0/Dragon_Burner/STLs/v0.2/" | \
    sed -e 's/^V0\/Dragon_Burner\/STLs\/v0.2\//"/' | \
    sed -e 's/$/",/' | \
    sed '$ s/.$/\]/' | \
    sed '1s;^;[;' > src/files.json
