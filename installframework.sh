#!/bin/bash

function ghost(){
	echo "let's install Ghost";
	dirLoop=true;
	while [ "${dirLoop}" == 'true' ];
	do
	read -p "Please enter the name of the document root you would like to use:" docRoot;
	    if [ ! -d /var/www/${docRoot} ];
	    then
	        mkdir -p /var/www/${docRoot};
	        dirLoop=false;
	    else
	        invalid=true;
	        while [ "${invalid}" == "true" ];
	        do
	            read -p "That directory already exists. Do you want to overwrite it? y/n:" overWrite;
	            case ${overWrite} in
	                "y" | "Y") mkdir -p /var/www/${docRoot};
	                       dirLoop=false;
	                       invalid=false;;
	                "n" | "N") break;;
	                *) echo "Please enter a valid choice.";
	                    invalid=true;;
	            esac
	        done
	    fi
	done
	#lets get the port number
	read -p "Please enter the port number you want this to run on:" primPort;
	#lets get the domain name
	read -p "Please enter the domain name you would like to use:" domName;
	#get new username to run the ghost installation
	read -p "Please enter in the username you would like to run Ghost:" userName;
	#set up the environment
	mkdir -p /var/www/${docRoot};
	cd $_;
	curl -L https://ghost.org/zip/ghost-latest.zip -o latest.zip
	unzip latest.zip
	rm -f $_
	#this section will set up ghost's configuration
	cp config.example.js config.js;
	sed -i "/http:\/\/my-ghost-blog.com/c\url: \'http://${domName}\'," ./config.js
	sed -i "/127.0.0.1/c\host: '0.0.0.0'," ./config.js
	sed -i "/2368/c\port: \'${primPort}\'" ./config.js
	adduser ${userName};
	chown -R ${userName}:${userName} /var/www/${docRoot};
    #get the Ghost installation running using FOREVER
	npm install --production;
	npm -g install forever;
	NODE_ENV=production forever start index.js;
	echo "#!/bin/bash
	NODE_ENV=production forever start index.js" > /var/www/$docRoot/ghostStart.sh;
	chmod +x /var/www/$docRoot/ghostStart.sh;
	echo "#!/bin/bash
	forever stop index.js" > /var/www/$docRoot/ghostStop.sh;
	chmod +x /var/www/$docRoot/ghostStop.sh;
	chown ${userName}:${userName} ghostStart.sh ghostStop.sh;
	clear;
	echo "Ghost has successfully been installed. You should be able to visit your site by going to http://${domName}";
	echo "To set up the new admin for your site, visit: http://${domName}/ghost";
	exit 0;
}

function installGhost(){
    loop=true;
	while [ "$loop" == "true" ]
	do
		read -p "Would you like to install Ghost CMS?" response;
			case $response in
				"y") ghost;
					 loop=false;;
				"n") echo "Ghost will not be installed.";
					 read -t 1 bye;
					 exit;;
				*) echo "Please enter in a valid choice:";;
			esac
	done
}

function installnodeDPKG(){
    apt-get update
    apt-get -y install build-essential
    apt-get -y install curl
     #set a new part of the PATH env variable
    echo 'export PATH=$HOME/local/bin:$PATH' >> ~/.bashrc
    . ~/.bashrc
    mkdir ~/local
    mkdir ~/node-latest-install
    cd ~/node-latest-install
    curl http://nodejs.org/dist/node-latest.tar.gz | tar xz --strip-components=1
    ./configure --prefix=~/local
    make install
    npm -g install express supervisor
    curl https://npmjs.org/install.sh | sh
    node -v
    installGhost;
}

function installnodeRPM(){
    yum -y update
    yum -y groupinstall "Development Tools"
    yum -y install screen
    curl -O http://download-12.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
    rpm -ivh epel-release-6-8.noarch.rpm
    curl -O http://download-12.fedoraproject.org/pub/epel/6/i386/epel-release-6-9.noarch.rpm
    curl -O http://download-12.fedoraproject.org/pub/epel/6/i386/epel-release-6-9yum.noarch.rpm
    yum repolist
    yum update
    rpm -Uvh http://dl.fedoraproject.org/pub/epel/x86_64/epel-release-5-4.noarch.rpm
    rpm -Uvh http://dl.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm
    yum install python26
    cd /
    ln -s /usr/bin/python26 /bin/python
    echo 'export Path=$HOME/bin:$PATH' >> ~/.bashrc
    source ~/.bashrc
    python -V
    cd /usr/src
    wget http://nodejs.org/dist/v0.10.24/node-v0.10.25.tar.gz 
    tar xvzf node-v0.10.25.tar.gz
    cd node-v0.10.25/
    ./configure
    make
    make install
    npm -g install express supervisor
    installGhost;
}

function installrubyRPM(){
    yum -y install ruby
	yum -y install gcc g+= make automake autoconf curl-devel openssl-devel zlib-devel httpd-devel apr-devel apr-util-devel sqlite-devel yum install ruby-rdoc ruby-devel
	yum -y install rubygems
	clear;
	echo "Looks like Ruby Gems was installed successfully. Installing Rails...";
	sleep 1;
    gem update
    gem update --system
    gem install rails
    	clear;
	echo "Rails has been installed successfully";
	sleep 1;
}

function unknownDistro(){
    loop1=true;
    while [ "$loop1" == true ];
    do
        clear;
        cat <<- _EOF_
Unknown Distro of Linux. Please select a version:
1: Debian/Ubuntu
2: Fedora/Red Hat/CentOS
#3: Arch
#4: OpenSUSE
q: quit
_EOF_
        read -p "Enter your selection >" distroChoice
            case $distroChoice in
                "1") installnodeDPKG;
                     loop1=false;;
                "2") installnodeRPM;
                     loop1=false;;
               "q"|"Q") echo "Node.js will not be installed";
                        sleep 2
                        exit;;
                  *) echo "Please enter a valid option";
                     sleep 1;;
            esac
    done  
}

function installnode(){
    #get the distro version and call the appropriate function
    DISTRO=$(head -1 /etc/issue | cut -d " " -f 1)
    case $DISTRO in
        "Ubuntu"|"ubuntu") installnodeDPKG;; 
        "CentOS"|"Fedora") echo "install on red hat";; 
        "Arch") echo "Installing Arch version";; 
        *) unknownDistro;;
	esac
}

while [[ $REPLY != 0 ]];
do
    clear;
    cat <<- _EOF_
    Please Select:
            
    1. Install Node.js
    2. Install Ruby Gems/Rails
    0. Quit
        
_EOF_
    read -p "Enter selection [0-2] > "
    
    if [[ $REPLY =~ ^[0-2]$ ]];
    then
        case $REPLY in
            "1") installnode;;
            "2") installruby;;
            "0") exit 0;;
        esac
    else
        echo "Invalid Entry";
        sleep 1;
    fi
done
