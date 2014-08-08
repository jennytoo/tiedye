NAME=TieDye
VERSION=1.30
PACKAGE=$(NAME)-$(VERSION).zip

DATA=$(NAME)/data
COLORS=$(DATA)/colors.lua
RAMPS=$(DATA)/ramps.lua

default:
	@echo "  clean data install package"
	@echo "  $(COLORS) $(RAMPS)"

$(COLORS): data/rgb.txt scripts/make_color_table
	if scripts/make_color_table TieDyeData.colors < data/rgb.txt \
	  > "$(COLORS).tmp"; then \
	  rm -f "$(COLORS)" && mv "$(COLORS).tmp" "$(COLORS)"; \
	else \
	  [ -f "$(COLORS).tmp" ] && rm -f "$(COLORS).tmp" || true; \
	fi

$(RAMPS): data/ramps.png scripts/WildStar_DyeRamps
	if scripts/WildStar_DyeRamps -l "$(RAMPS).tmp" -t TieDyeData.ramps \
	  -s data/ramps.png; then \
	  rm -f "$(RAMPS)" && mv "$(RAMPS).tmp" "$(RAMPS)"; \
	else \
	  [ -f "$(RAMPS).tmp" ] && rm "$(RAMPS).tmp" || true; \
	fi

data: $(COLORS) $(RAMPS)
$(NAME): data

install: $(NAME)
	cp -av -t "$(APPDATA)/NCSOFT/WildStar/Addons" TieDye

clean:
	rm $(NAME)-*.zip

package: $(PACKAGE)

$(PACKAGE): $(NAME)
	if [ -f "$(PACKAGE)" ]; then rm "$(PACKAGE)"; fi
	zip -r "$(PACKAGE)" "$(NAME)"

.PHONY: clean data default install package $(NAME)
