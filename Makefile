SRC ?= src
SIM_SRC ?= sim_src
OUT ?= bin
BUILDDIR ?= build
V_DIR ?= sim

TOP_MODULE ?= top

LOG ?= build.log

VERILATOR_PREFIX ?=
VERILATOR := $(VERILATOR_PREFIX)verilator

rwildcard=$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))

srcs := $(call rwildcard,$(SRC),*.v)
srcs += $(call rwildcard,$(SRC),*.sv)

sim_srcs := $(call rwildcard,$(SIM_SRC),*.cpp)
deps := $(call rwildcard,$(V_DIR),*.d)

CCFLAGS := -g -ffast-math -Wall -O3 -I$(SIM_SRC)
ifeq ($(OS),Windows_NT)
  LDFLAGS := -lmingw32 -lSDL2main -lSDL2
else
  LDFLAGS := -lSDL2
endif

.PHONY: all clean sim

all: sim

$(V_DIR)/Vsim_$(TOP_MODULE): sim_$(TOP_MODULE).cpp $(sim_srcs) $(srcs)
	$(VERILATOR) -Wall --MMD --MP -DRUN_SIM --Mdir $(V_DIR) --cc -O3 -CFLAGS "$(CCFLAGS)" -LDFLAGS "$(LDFLAGS)" -I$(SRC) --exe sim_$(TOP_MODULE).cpp $(sim_srcs) -sv --top-module sim_$(TOP_MODULE) --trace $(srcs) || true
	@echo "============================================================================================"
	@make -j -C $(V_DIR) -f Vsim_$(TOP_MODULE).mk Vsim_$(TOP_MODULE)
	@echo "============================================================================================"

sim: $(V_DIR)/Vsim_$(TOP_MODULE)

clean:
	rm -rf $(OUT) $(BUILDDIR) $(V_DIR) $(LOG)

-include $(deps)
