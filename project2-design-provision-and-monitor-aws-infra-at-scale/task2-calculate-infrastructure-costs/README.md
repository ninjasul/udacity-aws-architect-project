# [Initial Cost Estimate](Initial_Cost_Estimate.csv) 
Estimated Cost: Monthly - **9,063.05 USD**

Rationale: 
 - A highly performing database backend with provisioned IOPS and web/app tiers can handle consistent load, 
   can perform well up to specific of 1000 concurrent users per instance. 

*SPEC*
Single spec for EC2 instance for all web/app tier. 
 - Total 8 instances. 
 - 4 x t3a.2xlarge (general purpose, web server) - 2 each in AZ's
 - 4 x m4.2xlarge  (memory optimized, app server) - associated to private subnet 
 - 1 x Application Load Balancer
 - 1 x Network Load Balancer  
 - 2 x RDS for MySQL Storage for each RDS instance (Provisioned IOPS SSD (io1)), 
   Storage amount (100 GB), Instance type (db.r5.4xlarge), Additional backup storage (10 TB)

# [Low Cost Estimate](Reduced_Cost_Estimate.csv)  
Estimated Cost: Monthly - **6,355.98 USD**

Rationale: 
 - A good performing database backend with read replicas in multi-az single region and web/app tiers can perform well up to specific of 500 concurrent users per instance. 

*SPEC*
Added specific t3.large for EC2 in web and m4.large for app tier.
 - 4x t3.large web tier instances 
 - 4x m4.large app tier instances
 - 2 x RDS for MySQL Storage for each RDS instance - (Provisioned IOPS SSD (io1), Storage amount to (100 GB), instance type to db.r5.4xlarge, backup storage to 2TB
 
# [High Cost Estimate](Increased_Cost Estimate.csv) 
Estimated Cost: Monthly - **19,151.64 USD**

Rationale: 
 - Extremely performing database multi-az server with read replicas in single region, 
   and web/app tiers can perform well up to 1000 concurrent users per instance. 
 - Additional Ec2 instance included to support 2 * multiple  requests 
 - Additional read replicas/slave added to make database more redundant

*SPEC* 
 - Increased EC2 instances shape to t3a.x2large and m6.x2large accordingly and increased desired instance count to 8 from 4, for each web/app. 
 - Increased NAT throughput
 - Added 2 more replicas to RDS storage/size to handle more read workload. Instance also updated to better fitting one. (db.m5.4xlarge). IOPS to 2000, Storage to 2tb, Backup storage to 8 tb
 - 8x t3a.2xlarge web tier instances 
 - 8x m6g.2xlarge app tier instances 
 - EBS storage size per instance increased 
 - Updated S3 to 100TB per month
 - Added s3 glacier storage with 10TB per month