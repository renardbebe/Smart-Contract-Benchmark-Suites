 

pragma solidity ^0.4.18;  



 
 
 
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

 
 
 
 
 
 

contract AutomatedExchange is ApproveAndCallFallBack{

    uint256 PSN=100000000000000;
    uint256 PSNH=50000000000000;
    address tokenAddress=0x841D34aF2018D9487199678eDd47Dd46B140690B;
    ERC20Interface tokenContract=ERC20Interface(tokenAddress);
    function AutomatedExchange() public{
    }
     
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public{
         
        require(msg.sender==tokenAddress);
        uint256 tokenValue=calculateTokenSell(tokens);
        tokenContract.transferFrom(from,this,tokens);
        from.transfer(tokenValue);
    }
    function buyTokens() public payable{
        uint256 tokensBought=calculateTokenBuy(msg.value,SafeMath.sub(this.balance,msg.value));
        tokenContract.transfer(msg.sender,tokensBought);
    }
     
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
         
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateTokenSell(uint256 tokens) public view returns(uint256){
        return calculateTrade(tokens,tokenContract.balanceOf(this),this.balance);
    }
    function calculateTokenBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,tokenContract.balanceOf(this));
    }
    function calculateTokenBuySimple(uint256 eth) public view returns(uint256){
        return calculateTokenBuy(eth,this.balance);
    }

     
    function () public payable {}

    function getBalance() public view returns(uint256){
        return this.balance;
    }
    function getTokenBalance() public view returns(uint256){
        return tokenContract.balanceOf(this);
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}