/^#$/ { printf "#line %d \"/mnt/e/p4-verify/Procurator/argo/code/Translator/build-host/ir/%s\"\n", NR+1, name; next; } 1
