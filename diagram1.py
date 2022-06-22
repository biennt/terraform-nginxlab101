from diagrams import Diagram
from diagrams.aws.compute import EC2
from diagrams.aws.network import ELB

with Diagram("basicnginxpluslab", show=False, direction="TB"):
    ELB("nginx1") >> [EC2("app server 1"),
            EC2("app server 2")] 

