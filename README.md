##Storm守护进程sdaemon，主要的功能包括：
- 根据/etc/sysconfig/network中的主机名，每隔5秒钟守护Storm进程，当发现其不存在时，将启动对应的进程；
- 将该服务注册成linux服务，使得linux服务器重启后不需要人工干预即可正常启动Storm服务；
- 除了以上功能为，该脚本其实还应该实现以下功能：
```
a)	当supervisor节点因为某些原因启动不起来，需要重建logs文件夹、storm.local.dir文件夹时，能够自动实现；
b)	Storm异常退出时，可以调用sendmail自动提醒Storm集群的owner对集群进行日常维护等；
```
- 	在nimbus节点上运行nimbus相关进程，在supervisor节点上运行supervisor进程；
- 	为方便系统的运维，该脚本既能仅仅单纯启停storm进程，也能守护storm进程；
实现以上1、2、4点的脚本见StormDeamon.sh
