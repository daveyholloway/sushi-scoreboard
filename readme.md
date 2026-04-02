# Setup Guide

### Update the server



sudo apt update \&\& sudo apt upgrade -y



### Install MariaDB



sudo apt install mariadb-server

sudo mysql\_secure\_installation



### Database Setup



Run sushi-db.sql



### Install Apache and PHP



sudo apt install apache2

sudo apt install php libapache2-mod-php php-mysql



### Notes

Can test the API code from a browser:



#### Endpoints requiring GET

###### API call with no parameters - List all events

http://<<Your_Server_IP>>/sushi/api.php?action=list\_events



###### API call with a parameter - Return various datasets for a given event

http://<<Your_Server_IP>>/sushi/api.php?action=get\_event\_setup\&event\_id=1

http://<<Your_Server_IP>>/sushi/api.php?action=get\_totals\&event\_id=1

http://<<Your_Server_IP>>/sushi/api.php?action=get\_grid\_data\&event\_id=1



#### Endpoints requiring POST

Use the browser console (F12), examples below:



fetch("http://<<Your_Server_IP>>/sushi/api.php?action=create\_event", {

&#x20; method: "POST",

&#x20; headers: { "Content-Type": "application/json" },

&#x20; body: JSON.stringify({

&#x20;   name: "Test Event",

&#x20;   event\_date: "2026-04-20"

&#x20; })

}).then(r => r.json()).then(console.log);



fetch("http://<<Your_Server_IP>>/sushi/api.php?action=set\_event\_participants", {

&#x20; method: "POST",

&#x20; headers: { "Content-Type": "application/json" },

&#x20; body: JSON.stringify({

&#x20;   event\_id: 4,

&#x20;   participant\_ids: \[1, 2],

&#x20;   new\_names: \["Dave", "Declan"]

&#x20; })

}).then(r => r.json()).then(console.log);



