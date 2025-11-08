.PHONY: compiledb

ifeq ($(strip $(RUN_TESTS)),)
  EXTRA_FILTER_FLAGS :=
else
  RUN_LIST := $(subst ;, ,$(RUN_TESTS))
  EXTRA_FILTER_FLAGS := $(foreach t,$(RUN_LIST),-f "$(t)*")
endif

erase:
	@echo "Erasing the board"
	pio run -t erase --environment $(ENV)

compiledb:	
	@echo "Generating compile_commands.json"
	rm -rf compile_commands.json .pio/ .cache/ && pio run -t compiledb --environment $(ENV) 


upload_and_monitor: upload monitor

upload:
	@echo "Uploading"
	pio run -t upload --environment ${ENV}

monitor: 
	@echo "Monitoring"
	pio run -t monitor
