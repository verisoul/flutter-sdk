.PHONY: bump-android bump-ios release-patch release-minor release-major

bump-android:
	@chmod +x scripts/bump-android-version.sh
	@./scripts/bump-android-version.sh

bump-ios:
	@chmod +x scripts/bump-ios-version.sh
	@./scripts/bump-ios-version.sh

release-patch:
	@echo "Creating patch release..."
	@chmod +x scripts/release-version.sh
	@./scripts/release-version.sh patch

release-minor:
	@echo "Creating minor release..."
	@chmod +x scripts/release-version.sh
	@./scripts/release-version.sh minor

release-major:
	@echo "Creating major release..."
	@chmod +x scripts/release-version.sh
	@./scripts/release-version.sh major
