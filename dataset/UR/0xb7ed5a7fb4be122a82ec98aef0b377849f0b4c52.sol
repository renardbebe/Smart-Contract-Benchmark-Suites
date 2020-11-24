 

pragma solidity ^0.4.24;

contract hbys{

    mapping(uint=>address) public addr;
    uint public counter;
    uint public bingo;
    address owner;
    
    event Lucknumber(address holder,uint startfrom,uint quantity);
    modifier onlyowner{require(msg.sender == owner);_;}
    
    
    constructor() public{owner = msg.sender;}
    
    
    function() payable public{
        require(msg.value>0 && msg.value<=5*10**18);
        getticket();
    }
    
    
    function getticket() internal{
             
            uint fee;
            fee+=msg.value/10;
	        owner.transfer(fee);
	        fee=0;
	        
	        
	        address _holder=msg.sender;
	        uint _startfrom=counter;
	        
	        uint ticketnum;
            ticketnum=msg.value/(0.1*10**18);
            uint _quantity=ticketnum;
	        counter+=ticketnum;
	        
	        uint8 i=0;
            for (i=0;i<ticketnum;i++){
                	   addr[_startfrom+i]=msg.sender;
                
            }
            emit Lucknumber(_holder,_startfrom,_quantity);
    }
    
    
    
    
 
    function share(uint dji) public  onlyowner{
       require(dji>=0 && dji<=99999999);

       bingo=uint(keccak256(abi.encodePacked(dji)))%counter;

       addr[bingo].transfer(address(this).balance/50);
    }
       
}