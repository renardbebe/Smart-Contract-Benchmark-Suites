 

pragma solidity ^0.4.19; 
 

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


contract _ERC20Pool {
  address constant public bitcoinContract = 0xB6eD7644C69416d67B522e20bC294A9a9B405B31;
    
  ERC20Interface public tokenContract = ERC20Interface(bitcoinContract);

  address public owner = msg.sender;
  uint32 public totalTokenSupply;
  mapping (address => uint32) public minerTokens;
  mapping (address => uint32) public minerTokenPayouts;

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  modifier hasTokens(address sentFrom) {
    require(minerTokens[sentFrom] > 0);
    _;
  }

   
  function addMinerTokens(uint32 totalTokensInBatch, address[] minerAddress, uint32[] minerRewardTokens) public onlyOwner {
    totalTokenSupply += totalTokensInBatch;
    for (uint i = 0; i < minerAddress.length; i ++) {
      minerTokens[minerAddress[i]] += minerRewardTokens[i];
    }
  }
  
   
  function withdraw() public
    hasTokens(msg.sender) 
  {
    uint32 amount = minerTokens[msg.sender];
    minerTokens[msg.sender] = 0;
    totalTokenSupply -= amount;
    minerTokenPayouts[msg.sender] += amount;
    tokenContract.transfer(msg.sender, amount);
  }

   
  function getBalance(address acc) public returns (uint32) {
      return minerTokens[acc];
    }
  
  
   
  function getPayouts(address acc) public returns (uint32) {
      return minerTokenPayouts[acc];
  }
  
   
   
  function () public payable {
    revert();
  }
  
   
  function withdrawEther(uint32 amount) onlyOwner {
    owner.transfer(amount);
  }
  
   
  function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
    if(tokenAddress == bitcoinContract ){ 
        revert(); 
    }
    return ERC20Interface(tokenAddress).transfer(owner, tokens);
  }

}