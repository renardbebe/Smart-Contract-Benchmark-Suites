 

pragma solidity ^0.4.11;

 

 
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract Reseller {
   
  mapping (address => uint256) public snt_claimed;
   
  uint256 public total_snt_claimed;
  
   
  ERC20 public token = ERC20(0x744d70FDBE2Ba4CF95131626614a1763DF805B9E);
   
  address developer = 0x4e6A1c57CdBfd97e8efe831f8f4418b1F2A09e6e;
  
   
  function withdraw() {
     
    uint256 snt_to_withdraw = snt_claimed[msg.sender];
     
    snt_claimed[msg.sender] = 0;
     
    total_snt_claimed -= snt_to_withdraw;
     
    if(!token.transfer(msg.sender, snt_to_withdraw)) throw;
  }
  
   
  function claim() payable {
     
    if(block.number < 3915000) throw;
     
    uint256 snt_per_eth = (block.number - 3915000) * 2;
     
    uint256 snt_to_claim = snt_per_eth * msg.value;
     
    uint256 contract_snt_balance = token.balanceOf(address(this));
     
    if((contract_snt_balance - total_snt_claimed) < snt_to_claim) throw;
     
    snt_claimed[msg.sender] += snt_to_claim;
     
    total_snt_claimed += snt_to_claim;
     
    developer.transfer(msg.value);
  }
  
   
  function () payable {
     
    if(msg.value == 0) {
      withdraw();
    }
     
    else {
      claim();
    }
  }
}