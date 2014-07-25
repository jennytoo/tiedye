NAME=TieDye
VERSION=1.0
PACKAGE=$(NAME)-$(VERSION).zip

COLORS=$(NAME)/data/colors.lua

default:
	@echo "clean install package"

$(COLORS): data/rgb.txt scripts/make_color_table
	scripts/make_color_table TieDyeData.colors < data/rgb.txt > $(COLORS)

$(NAME): $(COLORS)

install: $(NAME)
	cp -av -t "$(APPDATA)/NCSOFT/WildStar/Addons" TieDye

clean:
	rm $(NAME)-*.zip

package: $(PACKAGE)

$(PACKAGE): $(NAME)
	if [ -f "$(PACKAGE)" ]; then rm "$(PACKAGE)"; fi
	zip -r "$(PACKAGE)" "$(NAME)"

.PHONY: clean default install package $(NAME)
