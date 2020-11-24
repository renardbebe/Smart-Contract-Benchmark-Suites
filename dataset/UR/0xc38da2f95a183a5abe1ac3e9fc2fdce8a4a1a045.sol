 

pragma solidity ^0.5.10;

contract ERC20Token
{
    mapping (address => uint256) public balanceOf;
    function transfer(address _to, uint256 _value) public;
}

library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract EthToVMRExchange
{
    using SafeMath for uint256;
    
    address payable public owner = 0x17654d41806F446262cab9D0C586a79EBE7e457a;
    ERC20Token Token = ERC20Token(0x063b98a414EAA1D4a5D4fC235a22db1427199024);
    uint256 public rate = 100;

    modifier onlyOwner() {
        assert(msg.sender == owner);
        _;
    }
    
    function changeOwner(address payable newOwner) public onlyOwner {
        owner = newOwner;
    }
    
    function withdraw(uint256 amount) public onlyOwner {
        owner.transfer(amount);
    }
    
    function withdrawTokens (address token, uint256 amount) onlyOwner public {
        ERC20Token(token).transfer(owner, amount);
    }

    function changeRate(uint256 newRate) public onlyOwner {
        rate = newRate;
    }
    
    function balance() view public returns (uint256 ethBalance, uint256 tokenBalance) {
        ethBalance = address(this).balance;
        tokenBalance = Token.balanceOf(address(this));
    }
    
    function() payable external{
        assert(msg.sender == tx.origin);
        if (msg.sender == owner) return;
        uint256 amount = msg.value.mul(rate);
        assert(amount <= Token.balanceOf(address(this)));
        Token.transfer(msg.sender, amount);
    }
    
}