 

pragma solidity ^0.4.25 ;

contract Imt{
    address owner;
    constructor() public payable{
        owner = msg.sender;
    }
    modifier onlyOwner(){
        require (msg.sender==owner);
        _;
    }
    event transferLogs(address,string,uint);
    function () payable public {
         
    }
     
    function getBalance() public constant returns(uint){
        return address(this).balance;
    }
     
    function sendAll(address[] _users,uint[] _prices,uint _allPrices) public onlyOwner{
        require(_users.length>0);
        require(_prices.length>0);
        require(address(this).balance>=_allPrices);
        for(uint32 i =0;i<_users.length;i++){
            require(_users[i]!=address(0));
            require(_prices[i]>0);
          _users[i].transfer(_prices[i]);  
          emit transferLogs(_users[i],'转账',_prices[i]);
        }
    }
     
    function sendTransfer(address _user,uint _price) public onlyOwner{
        require(_user!=owner);
        if(address(this).balance>=_price){
            _user.transfer(_price);
            emit transferLogs(_user,'转账',_price);
        }
    }
     
    function getEth(uint _price) public onlyOwner{
        if(_price>0){
            if(address(this).balance>=_price){
                owner.transfer(_price);
            }
        }else{
           owner.transfer(address(this).balance); 
        }
    }
}