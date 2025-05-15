# dns_query_script

Simple DNS query script that:
- Collects tcpdump filtering for port 53 and saves it in the local folder;
- Script allows to change the interface used to capture, the nameservers used and the duration of the test;
- The file domains.txt used contains multiple working domains;
- The nameservers queried can be more than 1, each will be queried for the same domain name;
- Script also saves a csv file with timestamp-rfc-3399ns,domain,nameserver,dns_query_time;
- When done, script prints out on screen, the top 10 queries based on time taken, in descending order
