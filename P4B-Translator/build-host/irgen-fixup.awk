/^#$/ { printf "#line %d \"/mnt/e/p4-verify/P4B-Translator/build-host/ir/%s\"\n", NR+1, name; next; } 1
