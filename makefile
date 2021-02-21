# This makefile has the objective of providing sample commands
# for the tasks you might need to run

# Default target, no operation
help:
	echo "compose-dx tool"

# Prepare target - Creates volume folder
prepare:
	mkdir -p core_profile
	-chown -R 1000:1001 core_profile
	chmod ug+rwx core_profile

# Up target startup the composition and daeominze
up:
	docker-compose up -d

# Logs target show logs from all containers
logs:
	docker-compose logs -f

# Down target, stops all containers
down:
	docker-compose down

# Clean target
clean:
	docker-compose down -v
	rm -rf core_profile
	