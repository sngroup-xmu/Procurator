SWITCH_DIR=/home/netarchlab/onos-p4-dev/onos-bmv2/targets/simple_switch
CONTROLLER_DIR=/home/netarchlab/odb/router
CONTROLLER_IP=101.6.30.157
CONTROLLER_PORT=40123
INTF=-i 1@peth1 -i 2@peth2
LOG=-L off

compile:
	@echo Compileing action snippet test
	@p4c-bmv2 tests/action/router.p4 --json tests/action/router.json
	@p4c-bmv2 tests/break/router.p4 --json tests/break/router.json
	@p4c-bmv2 tests/match/router.p4 --json tests/match/router.json
	@p4c-bmv2 tests/predication/router.p4 --json tests/predication/router.json
	@p4c-bmv2 tests/router/router.p4 --json tests/router/router.json
	@p4c-bmv2 tests/watch/router.p4 --json tests/watch/router.json
	@p4c-bmv2 tests/router/router.p4 --json tests/router/router.json
	@p4c-bmv2 tests/damper/router.p4 --json tests/damper/router.json

compile-damper:
	@p4c-bmv2 tests/damper/router.p4 --json tests/damper/router.json

install-action:
	@cp tests/action/router.json $(CONTROLLER_DIR)/src/main/resources
	@cd $(CONTROLLER_DIR)&&mvn clean install -D skipTests
	@cd $(CONTROLLER_DIR)&&./install

install-router:
	@cp tests/router/router.json $(CONTROLLER_DIR)/src/main/resources
	@cd $(CONTROLLER_DIR)&&mvn clean install -D skipTests
	@cd $(CONTROLLER_DIR)&&./install

install-match:
	@cp tests/match/router.json $(CONTROLLER_DIR)/src/main/resources
	@cd $(CONTROLLER_DIR)&&mvn clean install -D skipTests
	@cd $(CONTROLLER_DIR)&&./install

install-break:
	@cp tests/break/router.json $(CONTROLLER_DIR)/src/main/resources
	@cd $(CONTROLLER_DIR)&&mvn clean install -D skipTests
	@cd $(CONTROLLER_DIR)&&./install

install-predication:
	@cp tests/predication/router.json $(CONTROLLER_DIR)/src/main/resources
	@cd $(CONTROLLER_DIR)&&mvn clean install -D skipTests
	@cd $(CONTROLLER_DIR)&&./install

install-watch:
	@cp tests/watch/router.json $(CONTROLLER_DIR)/src/main/resources
	@cd $(CONTROLLER_DIR)&&mvn clean install -D skipTests
	@cd $(CONTROLLER_DIR)&&./install

install-damper:
	@cp tests/damper/router.json $(CONTROLLER_DIR)/src/main/resources
	@cd $(CONTROLLER_DIR)&&mvn clean install -D skipTests
	@cd $(CONTROLLER_DIR)&&./install

run-scale-1:
	@cp tests/damper/router.json $(SWITCH_DIR)
	@cd bin&&sudo bash run_switch_1

run-scale-2:
	@cp tests/damper/router.json $(SWITCH_DIR)
	@cd bin&&sudo bash run_switch_2

run-scale-3:
	@cp tests/damper/router.json $(SWITCH_DIR)
	@cd bin&&sudo bash run_switch_3
	
run-scale-4:
	@cp tests/damper/router.json $(SWITCH_DIR)
	@cd bin&&sudo bash run_switch_4

run-scale-5:
	@cp tests/damper/router.json $(SWITCH_DIR)
	@cd bin&&sudo bash run_switch_5

run-scale-6:
	@cp tests/damper/router.json $(SWITCH_DIR)
	@cd bin&&sudo bash run_switch_6

run-scale-7:
	@cp tests/damper/router.json $(SWITCH_DIR)
	@cd bin&&sudo bash run_switch_7

run-scale-8:
	@cp tests/damper/router.json $(SWITCH_DIR)
	@cd bin&&sudo bash run_switch_8

setup:
	@cd bin&&sudo bash setup

run-action:
	@cp tests/action/commands $(SWITCH_DIR)
	@cp tests/action/router.json $(SWITCH_DIR)
	@cd $(SWITCH_DIR)&&sudo bash simple_switch router.json $(INTF) $(LOG) -- --controller-ip=$(CONTROLLER_IP) --controller-port=$(CONTROLLER_PORT) 

run-break :
	@cp tests/break/commands $(SWITCH_DIR)
	@cp tests/break/router.json $(SWITCH_DIR)
	@cd $(SWITCH_DIR)&&sudo bash simple_switch router.json $(INTF) $(LOG) -- --controller-ip=$(CONTROLLER_IP) --controller-port=$(CONTROLLER_PORT) 

run-match :
	@cp tests/match/commands $(SWITCH_DIR)
	@cp tests/match/router.json $(SWITCH_DIR)
	@cd $(SWITCH_DIR)&&sudo bash simple_switch router.json $(INTF) $(LOG) -- --controller-ip=$(CONTROLLER_IP) --controller-port=$(CONTROLLER_PORT) 

run-predication :
	@cp tests/predication/commands $(SWITCH_DIR)
	@cp tests/predication/router.json $(SWITCH_DIR)
	@cd $(SWITCH_DIR)&&sudo bash simple_switch router.json $(INTF) $(LOG) -- --controller-ip=$(CONTROLLER_IP) --controller-port=$(CONTROLLER_PORT) 

run-router:
	@cp tests/router/commands $(SWITCH_DIR)
	@cp tests/router/router.json $(SWITCH_DIR)
	@cd $(SWITCH_DIR)&&sudo bash simple_switch router.json $(INTF) $(LOG) -- --controller-ip=$(CONTROLLER_IP) --controller-port=$(CONTROLLER_PORT) 

run-watch:
	@cp tests/watch/commands $(SWITCH_DIR)
	@cp tests/watch/router.json $(SWITCH_DIR)
	@cd $(SWITCH_DIR)&&sudo bash simple_switch router.json $(INTF) $(LOG) -- --controller-ip=$(CONTROLLER_IP) --controller-port=$(CONTROLLER_PORT) 

run-damper:
	@cp tests/damper/commands $(SWITCH_DIR)
	@cp tests/damper/router.json $(SWITCH_DIR)
	@cd $(SWITCH_DIR)&&sudo bash simple_switch router.json $(INTF) $(LOG) -- --controller-ip=$(CONTROLLER_IP) --controller-port=$(CONTROLLER_PORT) 

populate-scale-1:
	@cp tests/damper/commands $(SWITCH_DIR)
	@cd $(SWITCH_DIR)&&./runtime_CLI <commands

populate-scale-2:
	@cp tests/damper/commands $(SWITCH_DIR)
	@cd $(SWITCH_DIR)&&./runtime_CLI <commands
	@cd $(SWITCH_DIR)&&./runtime_CLI --thrift-port 9091 <commands

populate-scale-3:
	@cp tests/damper/commands $(SWITCH_DIR)
	@cd $(SWITCH_DIR)&&./runtime_CLI <commands
	@cd $(SWITCH_DIR)&&./runtime_CLI --thrift-port 9091 <commands
	@cd $(SWITCH_DIR)&&./runtime_CLI --thrift-port 9092 <commands

populate-scale-4:
	@cp tests/damper/commands $(SWITCH_DIR)
	@cd $(SWITCH_DIR)&&./runtime_CLI <commands
	@cd $(SWITCH_DIR)&&./runtime_CLI --thrift-port 9091 <commands
	@cd $(SWITCH_DIR)&&./runtime_CLI --thrift-port 9092 <commands
	@cd $(SWITCH_DIR)&&./runtime_CLI --thrift-port 9093 <commands
	
populate-scale-5:
	@cp tests/damper/commands $(SWITCH_DIR)
	@cd $(SWITCH_DIR)&&./runtime_CLI <commands
	@cd $(SWITCH_DIR)&&./runtime_CLI --thrift-port 9091 <commands
	@cd $(SWITCH_DIR)&&./runtime_CLI --thrift-port 9092 <commands
	@cd $(SWITCH_DIR)&&./runtime_CLI --thrift-port 9093 <commands
	@cd $(SWITCH_DIR)&&./runtime_CLI --thrift-port 9094 <commands

populate-scale-6:
	@cp tests/damper/commands $(SWITCH_DIR)
	@cd $(SWITCH_DIR)&&./runtime_CLI <commands
	@cd $(SWITCH_DIR)&&./runtime_CLI --thrift-port 9091 <commands
	@cd $(SWITCH_DIR)&&./runtime_CLI --thrift-port 9092 <commands
	@cd $(SWITCH_DIR)&&./runtime_CLI --thrift-port 9093 <commands
	@cd $(SWITCH_DIR)&&./runtime_CLI --thrift-port 9094 <commands
	@cd $(SWITCH_DIR)&&./runtime_CLI --thrift-port 9095 <commands

populate-scale-7:
	@cp tests/damper/commands $(SWITCH_DIR)
	@cd $(SWITCH_DIR)&&./runtime_CLI <commands
	@cd $(SWITCH_DIR)&&./runtime_CLI --thrift-port 9091 <commands
	@cd $(SWITCH_DIR)&&./runtime_CLI --thrift-port 9092 <commands
	@cd $(SWITCH_DIR)&&./runtime_CLI --thrift-port 9093 <commands
	@cd $(SWITCH_DIR)&&./runtime_CLI --thrift-port 9094 <commands
	@cd $(SWITCH_DIR)&&./runtime_CLI --thrift-port 9095 <commands
	@cd $(SWITCH_DIR)&&./runtime_CLI --thrift-port 9096 <commands

populate-scale-8:
	@cp tests/damper/commands $(SWITCH_DIR)
	@cd $(SWITCH_DIR)&&./runtime_CLI <commands
	@cd $(SWITCH_DIR)&&./runtime_CLI --thrift-port 9091 <commands
	@cd $(SWITCH_DIR)&&./runtime_CLI --thrift-port 9092 <commands
	@cd $(SWITCH_DIR)&&./runtime_CLI --thrift-port 9093 <commands
	@cd $(SWITCH_DIR)&&./runtime_CLI --thrift-port 9094 <commands
	@cd $(SWITCH_DIR)&&./runtime_CLI --thrift-port 9095 <commands
	@cd $(SWITCH_DIR)&&./runtime_CLI --thrift-port 9096 <commands
	@cd $(SWITCH_DIR)&&./runtime_CLI --thrift-port 9097 <commands

populate-action:
	@cp tests/action/commands $(SWITCH_DIR)
	@cd $(SWITCH_DIR)&&./runtime_CLI <commands

populate-break:
	@cp tests/break/commands $(SWITCH_DIR)
	@cd $(SWITCH_DI)&&./runtime_CLI <commands
	
populate-match:
	@cp tests/match/commands $(SWITCH_DIR)
	@cd $(SWITCH_DIR)
	@bash runtime_CLI <commands
	
populate-predication:
	@cp tests/predication/commands $(SWITCH_DIR)
	@cd $SWITCH_DIR
	@bash runtime_CLI <commands
	
populate-router:
	@cp tests/router/commands $(SWITCH_DIR)
	@cd $SWITCH_DIR
	@bash runtime_CLI <commands
	
populate-watch:
	@cp tests/watch/commands $(SWITCH_DIR)
	@cd $SWITCH_DIR
	@bash runtime_CLI <commands

populate-damper:
	@cp tests/damper/commands $(SWITCH_DIR)
	@cd $SWITCH_DIR
	@bash runtime_CLI <commands
	
teardown:
	@sudo bin/teardown
