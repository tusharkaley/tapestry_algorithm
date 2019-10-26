# Tapestry

Problem Statement:  
The goal of this project is to implement in Elixir using the actor model the Tapestry Algorithm  

# Team Members
Tushar Kaley  
UFID: 9126-1421  

Nishtha Shrivastav  
UFID: 2594-5398  

# How to run  

- Navigate to the tapestry folder  
- Run the following command  
	`mix compile`  
- Now run the following command  
	`mix run proj3.exs 2000 4`  

where 2000 is the number of nodes and 4 is the number of requests

# Sample output 
mix run proj3.exs 2000 4  

Triggering creation of routing tables for 2800 nodes.  
Rest of the 200 will be added dynamically  
Routing tables ready for 2800 nodes. Can send messages now  
Creation of routing tables takes 17464 milliseconds  
Started sending messages  
  
19:17:25.414 module=Tapestryclasses.Aggregator function=handle_cast/2 file=lib/tapestryclasses/aggregator.ex line=75 [debug] Dynamic nodes coming one by one now  

19:17:48.062 module=Tapestryclasses.Aggregator function=handle_cast/2 file=lib/tapestryclasses/aggregator.ex line=41 [debug] Max updated! Its 3 now  

19:17:48.062 module=Tapestryclasses.Aggregator function=handle_cast/2 file=lib/tapestryclasses/aggregator.ex line=41 [debug] Max updated! Its 4 now  

19:17:48.062 module=Tapestryclasses.Aggregator function=handle_cast/2 file=lib/tapestryclasses/aggregator.ex line=41 [debug] Max updated! Its 5 now  

19:17:48.069 module=Tapestryclasses.Aggregator function=handle_cast/2 file=lib/tapestryclasses/aggregator.ex line=41 [debug] Max updated! Its 6 now  
Maximum hops: 6  
Terminating Supervisor  
Total time taken 49118 milliseconds  

# What is working

We have implemented the following functionalities  
- Add `num_nodes` to the supervisor and assign a unique GUID to each one of these nodes   
- We have kept the value of the number of dynamically added nodes configurable, which is set to 10 by default  
- The requirement of sending a message per second results in the overall program taking a lot of time to execute so that part has been commented out but can be enforced by uncommenting just one line    
- Once the message sending starts the dynamic nodes start coming in one by one    

# Largest network we managed to deal with

We could run this code on 6000 nodes with 4 requests.   
