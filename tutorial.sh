RED=$(tput setaf 1)
NORMAL=$(tput sgr0)

clear

#Welcome message
printf "Hey! Are you here to learn about Citus?\n"
printf "We prepared some tutorials for you! Would you like to check them?\n"

select show_tutorials in "Yes" "No"; do
		case $show_tutorials in
				Yes)
						break;;
				No)
						printf "Opening psql for you then, you can run 'docker exec -it citus_master psql -U postgres' to directly connect psql next time\n\n";
						psql -U postgres;
						exit;;
				*)
						printf "Invalid option! Please enter the number next to the option you want to choose\n\n";;
		esac
done

sleep 0.5
clear

#Available tutorials
printf "Which tutorial do you want to open?\n\n"
select tutorial_options in "Multi-tenant Applications Tutorial" "Real-time Analytics Tutorial" "Citus Reference Tutorial"; do
		case $tutorial_options in
				"Multi-tenant Applications Tutorial")
						break;;
				"Real-time Analytics Tutorial")
						printf "This tutorial is not ready yet! Please select another one.\n\n";;
				"Citus Reference Tutorial")
						printf "This tutorial is not ready yet! Please select another one.\n\n";;
				*)
						printf "Invalid option! Please enter the number next to the option you want choose\n\n";;
		esac
done

sleep 0.5
clear

#Multi-tenant tutorial - Introduction
printf "${RED}Multi-tenant Applications${NORMAL}\n\n"

printf "In this tutorial, we will use a sample ad analytics dataset to demonstrate \n"
printf "how you can use Citus to power your multi-tenant application.\n\n"

#Multi-tenant tutorial - Downloading the data
printf "${RED}Data model and sample data${NORMAL}\n\n"

printf "We will demo building the database for an ad-analytics app which companies \n"
printf "can use to view, change, analyze and manage their ads and campaigns. Such \n"
printf "an application has good characteristics of a typical multi-tenant system. Data \n"
printf "from different tenants is stored in a central database, and each tenant has an \n"
printf "isolated view of their own data.\n\n"

printf "We will use three Postgres tables to represent this data. To get started, you \n"
printf "will need to download sample data for these tables.\n\n"

printf "First download the file containing our tenants;\n\n"
printf "curl -O https://examples.citusdata.com/tutorial/companies.csv\n\n"
while [ ! -f companies.csv ];
do
		read -p ">" user_command
		$user_command
done

sleep 0.5
clear

printf "companies.csv is downloaded. Now download the campaigns.csv file;\n\n"
printf "curl -O https://examples.citusdata.com/tutorial/campaigns.csv\n\n"
while [ ! -f campaigns.csv ];
do
		read -p ">" user_command
		$user_command
done

sleep 0.5
clear

printf "campaigns.csv is also here. Finaly we will need ads.csv file;\n\n"
printf "curl -O https://examples.citusdata.com/tutorial/ads.csv\n\n"
while [ ! -f ads.csv ];
do
		read -p ">" user_command
		$user_command
done

sleep 0.5
clear

#Multi-tenant tutorial - Table creation
printf "${RED}Creating tables${NORMAL}\n\n"

printf "Everything looks perfect! Now you can create the tables by using standard PostgreSQL \n"
printf "CREATE TABLE commands. From now on, commands you issue will be run as they are run \n"
printf "from psql.\n\n"

printf "Let's start with creating companies table;\n\n"
printf "CREATE TABLE companies (\n"
printf "	id bigint NOT NULL,\n"
printf "	name text NOT NULL,\n"
printf "	image_url text,\n"
printf "	created_at timestamp without time zone NOT NULL,\n"
printf "	updated_at timestamp without time zone NOT NULL\n"
printf ");\n\n"

printf "CREATE TABLE campaigns (\n"
printf "	id bigint NOT NULL,\n"
printf "	company_id bigint NOT NULL,\n"
printf "	name text NOT NULL,\n"
printf "	cost_model text NOT NULL,\n"
printf "	state text NOT NULL,\n"
printf "	monthly_budget bigint,\n"
printf "	blacklisted_site_urls text[],\n"
printf "	created_at timestamp without time zone NOT NULL,\n"
printf "	updated_at timestamp without time zone NOT NULL\n"
printf ");\n\n"

printf "CREATE TABLE ads (\n"
printf "	id bigint NOT NULL,\n"
printf "	company_id bigint NOT NULL,\n"
printf "	campaign_id bigint NOT NULL,\n"
printf "	name text NOT NULL,\n"
printf "	image_url text,\n"
printf "	target_url text,\n"
printf "	impressions_count bigint DEFAULT 0,\n"
printf "	clicks_count bigint DEFAULT 0,\n"
printf "	created_at timestamp without time zone NOT NULL,\n"
printf "	updated_at timestamp without time zone NOT NULL\n"
printf ");\n"

while ! psql -U postgres -c "\d companies" -q &> dev/null || ! psql -U postgres -c "\d campaigns" -q &> dev/null || ! psql -U postgres -c "\d ads" -q &> dev/null;
do
		printf "psql>"
		user_command=""
		while ! [[ $user_command == *";" ]]
		do
				read user_command_add
				user_command=$user_command' '$user_command_add
		done

		eval 'psql -U postgres -c "$user_command"'
done

sleep 0.5
clear

#Multi-tenant tutorial - Distributing tables
printf "${RED}Distributing tables and loading data${NORMAL}\n\n"

printf "We will now go ahead and tell Citus to distribute these tables across the different \n"
printf "nodes we have in the cluster. To do so, you can run create_distributed_table and \n"
printf "specify the table you want to shard and the column you want to shard on. In this \n"
printf "case, we will shard all the tables on the company_id.\n\n"

printf "SELECT create_distributed_table('companies', 'id');\n"
printf "SELECT create_distributed_table('campaigns', 'company_id');\n"
printf "SELECT create_distributed_table('ads', 'company_id');\n"

while ! psql -U postgres -c "SELECT logicalrelid FROM pg_dist_partition WHERE logicalrelid = 'companies'::regclass" -q | grep -q "companies" &> dev/null || ! psql -U postgres -c "SELECT logicalrelid FROM pg_dist_partition WHERE logicalrelid = 'campaigns'::regclass" -q | grep -q "campaigns" &> dev/null || ! psql -U postgres -c "SELECT logicalrelid FROM pg_dist_partition WHERE logicalrelid = 'ads'::regclass" -q | grep -q "ads" &> dev/null;
do
		printf "psql>"
		user_command=""
		while ! [[ $user_command == *";" ]]
		do
				read user_command_add
				user_command=$user_command' '$user_command_add
		done

		eval 'psql -U postgres -c "$user_command"'
done

sleep 0.5
clear

#Multi-tenant tutorial - Loading data
printf "Sharding all tables on the company identifier allows Citus to colocate the tables \n"
printf "together and allow for features like primary keys, foreign keys and complex joins \n"
printf "across your cluster. You can learn more about the benefits of this approach here; \n"
printf "https://www.citusdata.com/blog/2016/10/03/designing-your-saas-database-for-high-scalability/\n\n"

printf "Then, you can go ahead and load the data we downloaded into the tables using the \n"
printf "standard PostgreSQL \COPY command. Please make sure that you specify the correct \n"
printf "file path if you downloaded the file to some other location.\n\n"

printf "\copy companies from '/companies.csv' with csv;\n"
printf "\copy campaigns from '/campaigns.csv' with csv;\n"
printf "\copy ads from '/ads.csv' with csv;\n"

while ! psql -U postgres -c "SELECT COUNT(id) FROM companies" -q | grep -q "100" &> dev/null || ! psql -U postgres -c "SELECT COUNT(id) FROM campaigns" -q | grep -q "978" &> dev/null || ! psql -U postgres -c "SELECT COUNT(id) FROM ads" -q | grep -q "7364" &> dev/null;
do
		printf "psql>"
		user_command=""
		while ! [[ $user_command == *";" ]]
		do
				read user_command_add
				user_command=$user_command' '$user_command_add
		done

		eval 'psql -U postgres -c "$user_command"'
done

sleep 0.5
clear

#Multi-tenant tutorial - Running queries
printf "${RED}Running queries${NORMAL}\n\n"

printf "Now that we have loaded data into the tables, let’s go ahead and run some \n"
printf "queries. Citus supports standard INSERT, UPDATE and DELETE commands for inserting \n"
printf "and modifying rows in a distributed table which is the typical way of interaction \n"
printf "for a user-facing application.\n\n"

#Multi-tenant tutorial - INSERT
printf "For example, you can insert a new company by running:\n\n"

printf "INSERT INTO companies VALUES (5000, 'New Company', 'https://randomurl/image.png', now(), now());\n"

while ! psql -U postgres -c "SELECT COUNT(id) FROM companies" -q | grep -q "101" &> dev/null;
do
		printf "psql>"
		user_command=""
		while ! [[ $user_command == *";" ]]
		do
				read user_command_add
				user_command=$user_command' '$user_command_add
		done

		eval 'psql -U postgres -c "$user_command"'
done

#Multi-tenant tutorial - UPDATE
printf "\nIf you want to double the budget for all the campaigns of a company, you can run \n"
printf "an UPDATE command:\n\n"

printf "UPDATE campaigns\n"
printf "SET monthly_budget = monthly_budget*2\n"
printf "WHERE company_id = 5;\n"

while ! psql -U postgres -c "SELECT monthly_budget FROM campaigns WHERE id = 36" -q | grep -q "3620" &> dev/null;
do
		printf "psql>"
		user_command=""
		while ! [[ $user_command == *";" ]]
		do
				read user_command_add
				user_command=$user_command' '$user_command_add
		done

		eval 'psql -U postgres -c "$user_command"'
done

sleep 0.5
clear

#Multi-tenant tutorial - Analytics 1
printf "${RED}Analytic queries${NORMAL}\n\n"

printf "You can also run analytics queries on this data \n"
printf "using standard SQL. One interesting query for a company to run would be to see details \n"
printf "about its campaigns with maximum budget.\n\n"

printf "SELECT name, cost_model, state, monthly_budget\n"
printf "FROM campaigns\n"
printf "WHERE company_id = 5\n"
printf "ORDER BY monthly_budget DESC\n"
printf "LIMIT 10;\n"

#Multi-tenant tutorial - Analytics 2
printf "\nWe can also run a join query across multiple tables to see information about running \n"
printf "campaigns which receive the most clicks and impressions.\n\n"

printf "SELECT campaigns.id, campaigns.name, campaigns.monthly_budget,\n"
printf "	   sum(impressions_count) as total_impressions, sum(clicks_count) as total_clicks\n"
printf "FROM ads, campaigns\n"
printf "WHERE ads.company_id = campaigns.company_id\n"
printf "AND campaigns.company_id = 5\n"
printf "AND campaigns.state = 'running'\n"
printf "GROUP BY campaigns.id, campaigns.name, campaigns.monthly_budget\n"
printf "ORDER BY total_impressions, total_clicks;\n"

printf "\nWith this, we come to the end of our tutorial on using Citus to power a simple \n"
printf "multi-tenant application. As a next step, you can look at the Distributing by Tenant ID \n"
printf "section to see how you can model your own data for multi-tenancy; \n"
printf "https://docs.citusdata.com/en/stable/sharding/data_modeling.html#distributing-by-tenant-id).\n\n"

printf "You can also run queries in this Citus cluster;\n\n"
while true;
do
		printf "psql>"
		user_command=""
		while ! [[ $user_command == *";" ]]
		do
				read user_command_add
				user_command=$user_command' '$user_command_add
		done

		eval 'psql -U postgres -c "$user_command"'
done
