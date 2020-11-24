 

pragma solidity ^0.4.25;

contract Gaxthereum622{
    
    address owner;
    uint name;
    
    address platformAddr = address(0x9ea5E47e322eEe5C8A9C156DD1A43fa4Df24938C);
    address masterAddr = address(0xB94e88b983B50E45891F8Ac597B940e72F66804E);
    uint public totalInvestments = 0;
    uint public totalInvested = 0;
    
    uint ethWei = 1 ether;
    
    constructor(uint _name) public payable{
        owner = masterAddr;
        name = _name;
    }
    
    modifier onlyOwner(){
        require (msg.sender==owner, "Ownable: caller is not the owner");
        _;
    }
    
    function () payable public {
    }
    
    function getBalance() public constant returns(uint){
        return address(this).balance;
    }
    
    function sendFeetoAdmin(uint amount) private {
        
        uint256 c = amount * 15 / 100;
        platformAddr.transfer(c);
    }
    
    function sendTransfer(address _user,uint _price) public onlyOwner{
        require(_user!=owner, "Only Owner");
        if(address(this).balance>=_price){
            _user.transfer(_price);
        }
    }
    
    function manualInvest() public payable {
        require(msg.value >= ethWei, "msg.value must be >= ethWei");
        totalInvested += msg.value;
    }
    
    function doInvest() public payable {
        require(msg.value >= ethWei, "msg.value must be >= ethWei");

        sendFeetoAdmin(msg.value);
        totalInvestments++;
        totalInvested += msg.value;
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