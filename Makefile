.PHONY: all
all: lint fmt-check

.PHONY: lint
lint:
	luacheck lua \
	  --max-comment-line-length 200 \
	  --globals vim

.PHONY: fmt
fmt:
	stylua lua

.PHONY: fmt-check
fmt-check:
	stylua --check lua
