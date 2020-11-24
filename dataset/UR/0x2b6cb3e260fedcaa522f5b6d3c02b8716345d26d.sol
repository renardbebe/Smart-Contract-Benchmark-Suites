 

pragma solidity ^0.4.16;
 
contract owned{
     
    address public owner;
     
    function owned(){
        owner=msg.sender;
    }
     
    modifier onlyOwner{
        if(msg.sender != owner){
            revert();
        }else{
            _;
        }
    }
     
    function transferOwner(address newOwner) onlyOwner {
        owner=newOwner;
    }
}


contract tokenDemo is owned{
    string public name; 
    string public symbol; 
    uint8 public decimals=18; 
    uint public totalSupply; 
    
    uint public sellPrice=0.01 ether; 
    uint public buyPrice=0.01 ether; 
    
     
    mapping(address => uint) public balanceOf;
     
    mapping(address => bool) public frozenAccount;
    
    
     
    function tokenDemo(
        uint initialSupply,
        string _name,
        string _symbol,
        address centralMinter
        ) payable {
         
        if(centralMinter !=0){
            owner=centralMinter;
        }
        
        totalSupply=initialSupply * 10 ** uint256(decimals);
        balanceOf[owner]=totalSupply;
        name=_name;
        symbol=_symbol;
    }
    
    function rename(string newTokenName,string newSymbolName) public onlyOwner
    {
        name = newTokenName;
        symbol = newSymbolName;
    }
    
     
    function mintToken(address target,uint mintedAmount) onlyOwner{
         
        if(target !=0){
             
            balanceOf[target] += mintedAmount;
             
            totalSupply +=mintedAmount;
        }else{
            revert();
        }
    }
    
     
    function freezeAccount(address target,bool _bool) onlyOwner{
        if(target != 0){
            frozenAccount[target]=_bool;
        }
    }
        
    function transfer(address _to,uint _value){
         
        if(frozenAccount[msg.sender]){
            revert();
        }
         
        if(balanceOf[msg.sender]<_value){
            revert();
        }
         
        if((balanceOf[_to]+_value)<balanceOf[_to]){
            revert();
        }
         
        balanceOf[msg.sender] -=_value;
        balanceOf[_to] +=_value;
    }
    
    
     
    function setPrice(uint newSellPrice,uint newBuyPrice)onlyOwner{
        sellPrice=newSellPrice;
        buyPrice=newBuyPrice;
    }   
    
    
     
    function sell(uint amount) returns(uint revenue){
         
        if(frozenAccount[msg.sender]){
            revert();
        }
         
        if(balanceOf[msg.sender]<amount){
            revert();
        }
         
        balanceOf[owner] +=amount;
         
        balanceOf[msg.sender] -=amount;
         
        revenue=amount*sellPrice;
         
        if(msg.sender.send(revenue)){
            return revenue;
            
        }else{
             
            revert();
        }
    }
    
    
     
    function buy() payable returns(uint amount){
         
        if(buyPrice<=0){
             
            revert();
        }
         
        amount=msg.value/buyPrice;
         
        if(balanceOf[owner]<amount){
            revert();
        }
         
        if(!owner.send(msg.value)){
             
            revert();
        }
         
        balanceOf[owner] -=amount;
         
        balanceOf[msg.sender] +=amount;
        
        return amount;
    }
    
    
}