 

 
   

contract depletable {
    address owner;
    function depletable() { 
        owner = msg.sender;
    }
    function withdraw() { 
        if (msg.sender == owner) {
            while(!owner.send(this.balance)){}
        }
    }
}

contract blockchain2email is depletable {
	event EmailSent(address Sender, string EmailAddress, string Message);
	
	function SendEmail(string EmailAddress, string Message) returns (bool) { 
		if(msg.value>999999999999999){
			EmailSent(msg.sender, EmailAddress, Message);
			return (true);
		}else{
		    while(!msg.sender.send(msg.value)){}
		    return (false);
		}
    } 
}