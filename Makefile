.PHONY: help init fmt validate plan apply destroy destroy-all lint ssh

help init fmt validate plan apply destroy destroy-all lint ssh:
	$(MAKE) -C ch02 $@
