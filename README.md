# cloudera-managerizer
Cloudera Manager (CM) is a great tool to manage Hadoop (CDH) clusters. It consists of CM server and agents. Both of them run on a Linux box, but need some prerequisite software (e.g. JDK, RDB) before installation. CM has 3 installation path (which is called Installation Path A, B, C) and the cloudera-managerizer here is currently for Installation Path B on AWS EC2 hosts.

## How it works
### For CM agent
A CM agent is prepared with the following software automatically installed
- set hostname
- set /etc/hosts for cluster
- set cloudera repo for yum
- install JDK (currently jdk-8u102)
- install MySQL Connector (currently mysql-connector-java-5.1.39)
- set some kernel parameters for CM not to complain about it (e.g. change vm.swappiness)

### For CM server
A CM server is prepared with the following software automatically installed
- all agent software (above)
- install cloudera-manager-daemons and cloudera-manager-server
- install/configure external DB (currently the latest mariadb)
- start CM server

## Support Environment
- Mac or Linux (Client)
- AMI image should be RHEL or CentOS

## Requirement
### Mac (client machine)
- install awscli & configure AWS API key
```sh
$ brew install awscli
$ aws configure
```      

### AWS
- create a VPC and a public subnet in it
- create a security group for cluster hosts
- create a key-pair

## Usage
- Edit a cluster.csv file (which contains a cluster hosts information)
```sh
$ vi cluster.csv
$ cat cluster.csv
# role (server|agent), private-ip, hostname, security-group-ids, instance-type, volume-size (gb), subnet-id, ebs-opt (yes|no), tags
server, 10.0.1.20, kobe,   sg-27afd14e, t2.large, 50, subnet-2d59df44, no, owner=tsuyo testkey=testval
agent,  10.0.1.21, tokyo,  sg-27afd14e, t2.large, 50, subnet-2d59df44, no, owner=tsuyo testkey=testval
```
- Launch cluster (ami-c74789a9 is CentOS 7.2)
```sh
$ ./cloudera-managerizer --region <region> --key-name <key-name> --image-id ami-c74789a9 --db-pass <db-password>
```

## FAQ

- Why not just use all-set customized AMI?
A custom AMI, once created, becomes obsoleted too quickly. Also storing AMI is *not free of charge* on AWS. On the other hand, this repo's scripts just use AWS-prepared standard AMIs (of course, no charge at all) and every time create new instances from scratch.

- Why not use Cloudera Director?
Yes, Cloudera Director is a great tool for fairly large clusters. Basically cloudera-managerizer solves another problem - e.g. you need a 3-node cluster for a demo *just now with least effort*. Also you can use cloudera-managerizer to create bootstrap scripts so that they can be used on your non-cloud (on-premise) environment.
