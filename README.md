##Storm守护进程stormDaemon，主要的功能包括：

- 	根据/etc/sysconfig/network中的主机名，每隔5秒守护Storm进程，当发现其不存在时启动对应的进程（作为Nimbus节点的主机，其hostname上会包含Nimbus的字符串，而作为Supervisor节点的主机，其hostname上会包含Supervisor的字符串）。
- 	将该服务注册成Linux服务，使得Linux服务器重启后不需要人工干预即可正常启动Storm服务（通过chkconfig --add）。
- 	当Supervisor节点因为某些原因启动不起来，需要重建logs目录以及storm.local.dir目录时，能够自动实现。
- 	Storm异常退出时，可以调用sendmail自动提醒Storm集群的owner对集群进行日常维护等。
- 	在Nimbus节点上运行Nimbus相关进程，在Supervisor节点上运行Supervisor进程。
- 	为方便系统的运维，该脚本既能仅仅单纯启停Storm进程，也能守护Storm进程；该脚本仅仅启停Storm的Nimbus、Supervisor、UI、Log Viewer进程，对已经在运行的Worker进程不做任何限制。
实现以上功能的脚本见StormDeamon.sh
