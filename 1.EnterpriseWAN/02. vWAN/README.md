# GitHub Copilot
I have built most of these things by hands so many times in the portal, so I am going to start off with just using GitHub Copilot to outline the various components I need for my standard design and going from there. 

# Module Components
As always, you have to get started with connectivity. 

This module is going to contain the Log Analytic workspaces that are going to be used in future progressions. It also contains the Express Route objects, as well as the vWAN objects. The vWAN is multi object class in Azure and as such, is rather complex. It contains the user VPN gateway information, and if I end up testing Fortinet's VPN tunnel, it will include site to site as well. 

This is mostly good as of 7-20-24. It still needs diagnostic settings updated in it, but that is error prone so the templates should be tested before its copied into the vwan build file. 

