
spec = jobspec.yaml

spec_section = awk '/spec:/{flag=1;next}/^[a-z].*/{flag=0}flag' $(spec)
repo_section = awk '/recipe:/{flag=1;next}/^[a-z].*/{flag=0}flag' $(spec)

SPEC_REF = $(shell $(spec_section) | awk '/git_ref/{print$$NF;exit;}')
SPEC_URL = $(shell $(spec_section) | awk '/git_url/{print$$NF;exit;}')
PREFIX = $(shell read -p "enter the prefix for your job: " prefix; echo $$prefix)

.PHONY: info
info:
	@echo -e "\
Job Git Ref: $(SPEC_REF)\n\
Job Git URL: $(SPEC_URL)\n"


.PHONY: publish
publish:
	oc process -f pipeline.yaml \
	    --param=PREFIX=$(PREFIX) \
	    --param=SPEC_REF=$(SPEC_REF) \
	    --param=SPEC_URL=$(SPEC_URL) \
	    | oc apply -f -
