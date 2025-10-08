.PHONY: bump-android bump-ios release-patch release-minor release-major

bump-android:
	@chmod +x bump-android-version.sh
	@./bump-android-version.sh

bump-ios:
	@chmod +x bump-ios-version.sh
	@./bump-ios-version.sh

release-patch:
	@echo "Creating patch release..."
	@chmod +x release-version.sh
	@./release-version.sh patch

release-minor:
	@echo "Creating minor release..."
	@chmod +x release-version.sh
	@./release-version.sh minor

release-major:
	@echo "Creating major release..."
	@chmod +x release-version.sh
	@./release-version.sh major
