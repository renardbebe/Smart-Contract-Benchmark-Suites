 

 
pragma solidity ^0.4.2;

contract SafeMath {
   

  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function assert(bool assertion) internal {
    if (!assertion) throw;
  }
}

 
contract Token {

     
    function totalSupply() constant returns (uint256 supply) {}

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {}

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

 
contract StandardToken is Token {

     
    function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
         
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
         
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping(address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;

}


 
contract ARCToken is StandardToken, SafeMath {

    string public name = "Arcade Token";
    string public symbol = "ARC";
    uint public decimals = 18;
    uint public startBlock;  
    uint public endBlock;  

     
     
     
    address public multisig = 0x0;

    address public founder = 0x0;
    address public developer = 0x0;
    address public rewards = 0x0;
    bool public rewardAddressesSet = false;

    address public owner = 0x0;
    bool public marketactive = false;

    uint public etherCap = 672000 * 10**18;  
    uint public rewardsAllocation = 2;  
    uint public developerAllocation = 6 ;  
    uint public founderAllocation = 8;  
    bool public allocated = false;  
    uint public presaleTokenSupply = 0;  
    uint public presaleEtherRaised = 0;  
    bool public halted = false;  
    event Buy(address indexed sender, uint eth, uint fbt);

    function ARCToken(address multisigInput, uint startBlockInput, uint endBlockInput) {
        owner = msg.sender;
        multisig = multisigInput;

        startBlock = startBlockInput;
        endBlock = endBlockInput;
    }

    function setRewardAddresses(address founderInput, address developerInput, address rewardsInput){
        if (msg.sender != owner) throw;
        if (rewardAddressesSet) throw;
        founder = founderInput;
        developer = developerInput;
        rewards = rewardsInput;
        rewardAddressesSet = true;
    }

    function price() constant returns(uint) {
        return testPrice(block.number);        
    }

     
    function testPrice(uint blockNumber) constant returns(uint) {
        if (blockNumber>=startBlock && blockNumber<startBlock+250) return 125;  
        if (blockNumber<startBlock || blockNumber>endBlock) return 75;  
        return 75 + 4*(endBlock - blockNumber)/(endBlock - startBlock + 1)*34/4;  
    }

     
    function buyRecipient(address recipient) {
        if (block.number<startBlock || block.number>endBlock || safeAdd(presaleEtherRaised,msg.value)>etherCap || halted) throw;
        uint tokens = safeMul(msg.value, price());
        balances[recipient] = safeAdd(balances[recipient], tokens);
        totalSupply = safeAdd(totalSupply, tokens);
        presaleEtherRaised = safeAdd(presaleEtherRaised, msg.value);

        if (!multisig.send(msg.value)) throw;  

         
        if (presaleEtherRaised == etherCap && !marketactive){
            marketactive = true;
        }

        Buy(recipient, msg.value, tokens);

    }

     
    function allocateTokens() {
         
        if(founder == 0x0 || developer == 0x0 || rewards == 0x0) throw;
         
        if (msg.sender != owner && msg.sender != founder && msg.sender != developer && msg.sender != rewards ) throw;
         
        if (block.number <= endBlock && presaleEtherRaised < etherCap) throw;
        if (allocated) throw;
        presaleTokenSupply = totalSupply;
         
        balances[founder] = safeAdd(balances[founder], presaleTokenSupply * founderAllocation / 84 );
        totalSupply = safeAdd(totalSupply, presaleTokenSupply * founderAllocation / 84);
        
        balances[developer] = safeAdd(balances[developer], presaleTokenSupply * developerAllocation / 84);
        totalSupply = safeAdd(totalSupply, presaleTokenSupply * developerAllocation / 84);
        
        balances[rewards] = safeAdd(balances[rewards], presaleTokenSupply * rewardsAllocation / 84);
        totalSupply = safeAdd(totalSupply, presaleTokenSupply * rewardsAllocation / 84);

        allocated = true;

    }

     
    function halt() {
        if (msg.sender!=founder && msg.sender != developer) throw;
        halted = true;
    }

    function unhalt() {
        if (msg.sender!=founder && msg.sender != developer) throw;
        halted = false;
    }

     
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (block.number <= endBlock && marketactive == false) throw;
        return super.transfer(_to, _value);
    }
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (block.number <= endBlock && marketactive == false) throw;
        return super.transferFrom(_from, _to, _value);
    }

     
    function() payable {
        buyRecipient(msg.sender);
    }

}