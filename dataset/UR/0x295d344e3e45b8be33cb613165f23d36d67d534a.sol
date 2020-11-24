 

pragma solidity ^0.5.0;
contract ClothesStores{
	
	mapping (uint => address) Indicador;
	
	struct Person{
		string name;
		string nick;
		string email;
	}
    
	Person[] private personProperties;
	
	event createdPerson(string name,string nick,string email);
	
	function createPerson(string memory _name, string memory _nick, string memory _email) public {
	   uint identificador = personProperties.push(Person(_name,_nick,_email))-1;
	    Indicador[identificador]=msg.sender;
	    emit createdPerson(_name,_nick,_email);
	}
	
	function getPersonProperties(uint _identificador) external view returns(string memory, string memory, string memory)  {
	    
	     
	    
	    Person memory People = personProperties[_identificador];
	    
	    return (People.name,People.nick,People.email);
	}
}