# Image registry definition
#
# In case you loaded images to a remote registry (not available locally, not loaded with "docker load" from HCL package)
# then you need to set the registry. If not set or empty we lookup local images
#

#
# Example for a remote registy at https://registry.myodmain.mytld
#
# Ensure you have the trailng / that is needed to compose the full image name.
# 
# Image names are defined in the env_images.sh script
#

#export REGISTRY="registry.mydomain.mytld/"

# Default settings for security

export WAS_ADMIN=wpsadmin 
export WAS_PASSWORD=wpsadmin
export DX_ADMIN=wpsadmin 
export DX_PASSWORD=wpsadmin