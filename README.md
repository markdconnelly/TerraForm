# TerraForm
It's July 2024 and designing and architecting things at scale really requires an enterprise solution. For that, I decided to teach myself TF. 
This repository will serve as my playground to teach myself and develop standards for security in Azure using TF.

Import TF Block Update:
https://www.youtube.com/watch?v=znfh_00EDZ0

terraform plan -generate-config-out="{object}.tf"

User Existing Resources:
https://www.youtube.com/watch?v=QrSfASpVE14&list=PLnWpsLZNgHzVVslxs8Bwq19Ng0ff4XlFv&index=6

To illustrate this learning exercise, we must understand the intent behind the architecture getting built. This exercise will focus on an enterprise grade environment that is both close, secure, and highly available inter region and cross region. 

In my case, this uses Central US and East US 2 for its region pairing. When thinking through your example, use your closest region pairing. If you were in Europe for example, my regions wouldn't make sense. 

This environment has two primary on premise data centers in the United States. It's primary location is based in Champaign, IL and it's secondary location is in Atlanta, GA. There is 100Gbps private fiber connectivity between the primary and secondary on premise locations. 

Because this environment has such high speed connectivity between regions, equivelent cross connectivity between Azure regions is critical. We will use redundant connections between multiple carriers for our express routes. 

There are two primary failover scenarios. Regional failover, and then network provider failover. Because the main network providers are all based out of the same physical locations. It is neccesarry, in my opinion, to have a primary/secondary per on premise location, where the primary is the best connectivity to get to your primary Azure data ceneter (Central US), and your secondary route is the next best path to get to your primary Azure data center. A network connectivity failure on a provider does not mean that the regional services have failed over. Your services would still be destined to the central region, even though the best connectivity path failed. To avoid hopping to your secondary data center, to the east region, and then back to central, your seconary location should also have a primary link to your primary azure region. In that event, your next best route would be over the 100Gbps link to Atlanta and then onto the Microsoft backbone back up to Central. 

We acomplish this best route logic by using Fortinet's SD-WAN Technology. We set latency, jitter, and packet loss thresholds, and let it seemlessly switch over our internal links to their best routes internally. This ensures that at either on premise location, we are always taking the best and most effective path to the Central US region. It can also prioritize the circuits we pay for unlmited vs metered for, so we can always use our metered connections as 3rd and 4th best routing options in addition to the main metrics. 

In the event of a regional services failover, DNS would take over a large portion of the automated failover effort. The design incorporates separate DNS zones for each region, and in the event of a regional failover (network is still working as intended), the services would then failover to the secondary region until the primary region was restored. In this instance, you would still want them to take the best network path to where the resources are, and again, this is where Fortinet's SD-WAN really accellerates. 

In the event of a central regional serviecs failure, both on premise locations would have the quickest path to the services (Now communicating via East US 2), via their quickest physical hop to an Azure connectivity point. For Atlanta, this would be it's direct Express Route to east and for central it be its path through central from a latency perspective. Keep in mind that the Microsoft backbone is 100Gbps, so the best path isnt always the direct express route. It is the quickest path to a functional microsoft point of presense. The SD-WAN will prioritize routes based on the logic you set. If you set the cost of a circuit as a priority, Atlanta would take the unlimited circuit to central, then cross over to the east region. There is some flexibility with it. I like to factor in cost, and having a metered set of backup circuits gives you the ability to have peace of mind without paying for it every month. You only pay for it in the vent of a failover, so it's much cheaper over a 5 year total cost of ownership calculation. 

1. Champaign's primary Express Route will be connected to the Central US region via Chicago, IL. This will provide the best network connectivity and Should be set to Unlimited. 
2. Champaign's secondary Express Route will be connected to the East US 2 region via Dallas, TX. This will provide the next best network connectivity and should have 
3. Atlanta's primary Express Route will connected to the Central US region via Atlanta, GA. This will provide the best network connectivity and Should be set to Unlimited. 
4. Atlanta's secondary Express Route will be connected to the East US 2 region via Miami, FL. 

A global vWAN is established with a hub in the primary and seconday regions. Centralized connectivity with Global scale VPN user acess is granted in the primary region. A secondary VPN landing zone is available to scale in the secondary region as needed. 
Global load balancers are placed in front of the VPN gateways for failover scenarios. The scaling up of the secondary region will be managed via automation in the infrastructure operations spoke workload. 
Site to Site VPN connectivity will not be used in this scenario, but it is a viable option when express routes are cost prohibitive. For smaller scale deployments, Fortinet's VPN solution works flawlessly to replace these express route components. 

A firewall is deployed in each regions hub and is the central point of network flow between any workloads. A centralized firewall policy is used to manage all regions with a single policy set. 

A set of core infrastructure spokes are established to provide critical services that make the environment useable, including security services, DNS, identity, infrastructure encryption, logging, monitoring, backups, certificate services, and other misc 
automation that is used to optimize the various workflows of IT and cybersecurity. These services should be highly available and fully redundant by defualt. 

These include:
  - Private DNS Services
  - Active Directory Services
  - Infrastructure as Code Services
  - Application Gateway Services
  - API Gateway Services
  - Web Application Firewall Services
  - DDOS Protection Services
  - Azure Front Door Services
  - Azure Traffic Manager Services
  - Various Defender Services
  - Monitoring Services
  - Infrastructure Encryption Services
  - Certificate Operations
  - Azure Arc Services
  - IT Operation Workloads
  - Security Operations Workloads

From these Enterprise Spokes, we derive the core functionality of the systems. They provide the building blocks for us to build out a scalable architecture as well as a blueprint for a high availabilty design for various workload spokes. 

After the enterprise spokes have been established, we can layer in a network management system. This is pretty critical to avoid IP conflicts. They are a nightmare to troubleshoot in azure and an ounce of prevention is worth a pound of cure. 
You should call some IP Address Management Sytstem (IPAM) and establish a workflow for determining the IP address spaces used in your spokes. Fortinet has an IPAM built into their suite and a full range of APIs that are accessible to accomplish this. 
That integration is beyond the scope of this exercise though. We will be assigning IP addresses manually in a range that has been dedicated for this. 

You should replace this manual flow with an enterprise grade automation process if actually deploying this to a prod env. 

When a workload is needed, a request is made. We must first determine if the sytsem requires any high availability. If it does, we deploy a network in each paired region with matching IP ranges to signify the connection. Only a single octet should be different 
between the two networks. These IPs are pulled from a designated block for this operation. 

If high availability (HA) is not needed, we grab a network block from the single region range. Again, to avoid IP conflicts this should be notably different from your HA ranges. 

We then provision a resource group in our primary region. 
Then we deploy a network based on the above criteria (single region vs multi region)
 - Diagnostic logs are sent to the infrastructure encryption log analytics workspaces

A corresponding Network Security Group is created is made for each virtual network. 
 - Diagnostic logs are sent to the secops sentinel workspace
 - NSG Flow logs are configured to go to the infrastructure storage accounts in their corresponding region
 - NSG Flow logs are enabled for traffic analytics and those analytics go to the infrastructure log analytics workspaces

From there, various workload components are built to provide a range of services to the organization. Each of these workloads should be designed by an architect, tested by engineers, deployed to production via TerraForm and introduced into the support lifecycle for long term managment. 

My role as a DevSecOps architect (Focus on the Sec ;)), covers all of the main areas of this example. Because of that, most of the Security and IT based workloads are covered in the previous steps. For the spoke workloads, I will focus on a few cloud based Developer centric designs. 

The ability to use tools like Azure Data Factory, pipelines, storage accounts, functions, and PaaS based sql databases, will be the main focus of these branch workloads. Any other service that supports integration with Azure private endpoints will also be viable though. All you need to do is integrate any new private DNS zones (pretty much unique per PaaS service) into your DNS systems, and drop that service's private endpoints into your existing vitural network design. 

After your workload has been built and requires connectivity, network peering is the next step to connect it to the enterprise infrastructire.

After it has been peered, a firewall policy collection is created for the work load. Various address groups are created to define the workloads scope, and all network and application rule sets are contained within this collection. 

 Once peered, and the appropriate firewall rules given, your workload should be in a connected state. 

