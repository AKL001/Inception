benif of using docker or containers in general : 
    -saving time , by reducing time for VM to boot 
    -resource, CPU , RAM
    -capital, 

Windows containers vs Linux containers : 
    - containerized Widnows app will not run on a Lunux-based Docker host and vice-versa 
    - how ever it is possible to run linux containers on windows machine . if docker desktop on windows has two modes , ( windows container and linux containers ) , linux containers run either inside a lightweigh Hyper-v VM or WSL (windows sub linux) 

What about kubernetes ?? :
    - `containerd` is the small specialized part of Docker that does the low-level tasks of starting and stopping containers.

Docker technology :
    1- The runtime
    2- The daemon (engine)
    3- The orchestrator 

1) The runtime :
    - there is 2 levels or runtime 
    1- the low-level 
    2- the higher-level

    #low-level is called `runc` and is the reference implemetation of Open COntainers Initiative 
    its job is to interface with the undelying OS and start and stop containers. each Docker node has a runc instance managing it 

    #higher-level runtime called `containerd` . this one does a lot more than `runc` is manage the entire lifecycle of a container, including pulling images, creating network interfaces , and managing lowe-level runc isntances. 

2) docker daemon (dockerd) :
    - sits above `containerd` and performs higher-level taks such as: exposing the docker remote API , managing images , managing volumes, networks and etc ...  

$notes:  managing clusters , Docker Swarm vs Kubernetes 


https://labs.play-with-doer.com/
