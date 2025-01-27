all        :; forge build
build      :; forge clean && forge build
.PHONY: test
test       :; ./scripts/forge_test.sh --v=$(v) --mt=$(mt) --mc=$(mc)
coverage   :; forge coverage
clean      :; forge clean
