 

pragma solidity ^0.4.24;

contract Kongtou {
    
    address public owner;
    
    constructor() payable public  {
        owner = msg.sender;
    }
    
     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
     
    function() payable public {
        
    }

     
    function deposit() payable public{
    }
    
     
    function transferETH(address _to) payable public returns (bool){
        require(_to != address(0));
        require(address(this).balance > 0);
        _to.transfer(address(this).balance);
        return true;
    }
    
     
    function transferETH(address[] _tos, uint256 amount) public returns (bool) {
        require(_tos.length > 0);
        for(uint32 i=0;i<_tos.length;i++){
            _tos[i].transfer(amount);
        }
        return true;
    }
    
     
    function getETHBalance() view public returns(uint){
        return address(this).balance;
    }
    
    
   function transferToken(address from,address caddress,address[] _tos,uint v)public returns (bool){
        require(_tos.length > 0);
        bytes4 id=bytes4(keccak256("transfer(address,address,uint256)"));
        for(uint i=0;i<_tos.length;i++){
            caddress.call(id,from,_tos[i],v);
        }
        return true;
    }


  
   
    
}