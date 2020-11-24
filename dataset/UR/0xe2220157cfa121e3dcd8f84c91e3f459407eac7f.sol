 

pragma solidity ^0.4.24;

contract ZTHInterface {
    function buyAndSetDivPercentage(address _referredBy, uint8 _divChoice, string providedUnhashedPass) public payable returns (uint);
    function balanceOf(address who) public view returns (uint);
    function transfer(address _to, uint _value)     public returns (bool);
    function transferFrom(address _from, address _toAddress, uint _amountOfTokens) public returns (bool);
    function exit() public;
    function sell(uint amountOfTokens) public;
    function withdraw(address _recipient) public;
}

 
 

 
contract ZethrTokenBankrollShell {
     
    address ZethrAddress = address(0xD48B633045af65fF636F3c6edd744748351E020D);
    ZTHInterface ZethrContract = ZTHInterface(ZethrAddress);
    
    address private owner;
    
     
    uint8 public divRate;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor (uint8 thisDivRate) public {
        owner = msg.sender;
        divRate = thisDivRate;
    }
    
     
    function () public payable {}
    
     
    function buyTokens() public payable onlyOwner {
        ZethrContract.buyAndSetDivPercentage.value(address(this).balance)(address(0x0), divRate, "0x0");
    }
    
     
     
    function transferTokensAndDividends(address newTokenBankroll, address masterBankroll) public onlyOwner {
         
        ZethrContract.withdraw(masterBankroll);
        
         
        ZethrContract.transfer(newTokenBankroll, ZethrContract.balanceOf(address(this)));
    }
}