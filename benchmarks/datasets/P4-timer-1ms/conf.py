import json

file = open("/root/bf-sde-9.2.0/install/share/p4/targets/tofino/timer.conf","r")

f = json.load(file)

file.close()


print(f["p4_devices"][0]["p4_programs"][0]["p4_pipelines"][0]["pipe_scope"])
print(f["p4_devices"][0]["p4_programs"][0]["p4_pipelines"][1]["pipe_scope"])
f["p4_devices"][0]["p4_programs"][0]["p4_pipelines"][0]["pipe_scope"] = [1]
f["p4_devices"][0]["p4_programs"][0]["p4_pipelines"][1]["pipe_scope"] = [0]

file = open("/root/bf-sde-9.2.0/install/share/p4/targets/tofino/timer.conf","w")

json.dump(f, file)

file.close()
