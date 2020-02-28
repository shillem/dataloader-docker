# Salesforce Data Loader Docker
This is an dockerized version of [forcedotcom/dataloader](https://github.com/forcedotcom/dataloader).\
For more information consult the [Data Loader Guide](https://developer.salesforce.com/docs/atlas.en-us.dataLoader.meta/dataLoader/data_loader.htm).

## Image
Simply build the image using `docker image build -t <dataloader_image_name> .`.

## Container
The container can work in 2 ways, as a scheduler or interactive executable:

* __As an executable__: The container can be used to run as an executable and therefore run processes extemporaneously.
* __As a scheduler__: By leveraging [jobber](https://dshearer.github.io/jobber/) the container can be used to schedule Data Loader processes in a cron-like fashion but with much more flexibility. For more information about job configurations see the [jobber documentation](https://dshearer.github.io/jobber/doc/v1.4/).

### Options
The container expects to be receiving the Data Loader configurations and/or executable parameters:

* `-v <volume>:/opt/app/configs` should contain the Data Loader configurations
* `-v <volume>:/opt/app/libs` should contain any Java library required to support specific configurations
* `-v <jobber_file>:/home/dataloader/.jobber` shoudl contain all the scheduled jobs you want to run
* `--entrypoint dataloader <dataloader_image_name> <operation> <parameters...>` instructs the container to run as an executable

### As an Executable
Let's say you want to run the container as an executable and encrypt the password you will later specify in you Data Loader configuration.\
If it's the first time it runs the executable will create - unless it's already present - under `configs/` a new encryption key named `encryption.key`. For any other subsequent run it will reuse it.

To encrypt:
```
$ mkdir $(pwd)/configs && mkdir $(pwd)/libs
$ docker container run --rm -it \
    -v $(pwd)/configs:/opt/app/configs/ \
    --entrypoint dataloader <dataloader_image_name> encrypt <password>
```
To decrypt the password encypted above:
```
$ docker container run --rm -it \
    -v $(pwd):/opt/app/configs/ \
    --entrypoint dataloader <dataloader_image_name> decrypt <encrypted_password>
```

Once you have configured the Data Loader process you can store all the necessary information under a `configs/` subfolder for convienence.\
You will later indicate the specific config subfolder the Data Loader will read from.

To run a process:
```
$ mkdir $(pwd)/configs && mkdir $(pwd)/libs
$ docker container run --rm -it \
    -v $(pwd)/configs:/opt/app/configs/ \
    -v $(pwd)/libs:/opt/app/libs/ \
    --entrypoint dataloader <dataloader_image_name> process <conf_dir> <process_name>
```
For example, if you had created a `configs/production` subfolder with a process name named `accountMaster` your would type:
```
$ docker container run --rm -it \
    -v $(pwd)/configs:/opt/app/configs/ \
    -v $(pwd)/libs:/opt/app/libs/ \
    --entrypoint dataloader <dataloader_image_name> process production accountMaster
```

### As a Scheduler
To run the container so that it runs as scheduler you omit the `--entrypoint` we used so far and map your jobber file definition as follows:
```
$ docker container run \
    -v $(pwd)/jobber.yaml:/home/dataloader/.jobber \
    -v $(pwd)/configs:/opt/app/configs/ \
    -v $(pwd)/libs:/opt/app/libs/ \
    --name my-sfdc-dataloader <dataloader_image_name>
```