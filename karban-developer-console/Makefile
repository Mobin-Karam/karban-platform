.PHONY: test syntax package
syntax:
	./tests/syntax.sh

test:
	./tests/selftest.sh

package: test
	tar -czf ../karban-developer-console.tar.gz .
