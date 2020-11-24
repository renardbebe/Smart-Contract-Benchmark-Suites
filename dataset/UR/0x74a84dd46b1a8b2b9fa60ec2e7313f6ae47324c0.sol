 

pragma solidity ^0.4.25 ;

contract TestBool{
    address owner;
    constructor() public payable{
        owner = msg.sender;
    }
    modifier onlyOwner(){
        require (msg.sender==owner);
        _;
    }
     
    function getBalance() public constant returns(uint){
        return address(this).balance;
    }
     
    function sendTransfer(address _user,uint _price) public onlyOwner{
        require(_user!=owner);
        if(address(this).balance>=_price){
            _user.transfer(_price);
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