# compose-dx - A docker compose based toolkit for HCL DX developers

## Preparation

By default DX images run as dx_user/dx_groups.

uid: 1000
gid: 1001

When creating volumes please ensure you set write rights accordingly.

For instance:

> mkdir -p core_profile
> 
> chown -R 1000:1001 core_profile
> 
> chmod ug+rwx core_profile

A utility shortahand is (where gnu make is available)

> make prepare

## Operating the took

Check out "makefile" to see commands you can use for different tasks or just run "make <target>"

## Access the server

When services are started you can access DX and Ring API as:

### Portal
* http://localhost:10039/wps/portal

### Ring API Explorer + Graph QL
* http://localhost:3000/dx/api/core/v1/explorer/
* http://localhost:3000/dx/api/core/v1/graphql

### WebSphere Administrative Console
* https://localhost:10041/ibm/console

Note: If not working try replacing localhost with the IP of your machine's network interface