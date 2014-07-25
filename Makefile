NAME=TieDye
VERSION=1.0
PACKAGE=$(NAME)-$(VERSION).zip

default:
	@echo "clean install package"

install:
	cp -av -t "$(APPDATA)/NCSOFT/WildStar/Addons" TieDye

clean:
	rm $(NAME)-*.zip

package: $(PACKAGE)

$(PACKAGE): $(NAME)
	if [ -f "$(PACKAGE)" ]; then rm "$(PACKAGE)"; fi
	zip -r "$(PACKAGE)" "$(NAME)"

.PHONY: clean default install package
