 

pragma solidity ^0.4.17;

 
contract SafeMath {

     
     
     
     
     
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
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

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract MOERToken is StandardToken, SafeMath {

     
    string public constant name = "Moer Digital Assets Platform";
    string public constant symbol = "MOER";
    uint256 public constant decimals = 18;
    string public version = "1.0";

     
    address public owner;                                              

     
    uint256 public currentSupply = 0;                                  
    uint256 public constant totalFund = 2 * (10**9) * 10**decimals;    
    
     
    bool    public isFunding;                 
    uint256 public fundingStartBlock;
    uint256 public fundingStopBlock;
    uint256 public tokenExchangeRate = 12000;              
    uint256 public totalFundingAmount = (10**8) * 10**decimals;  
    uint256 public currentFundingAmount = 0;

     
    function MOERToken(
        address _owner)
    {
        owner = _owner;
        
        isFunding = false;
        fundingStartBlock = 0;
        fundingStopBlock = 0;
        
        totalSupply = totalFund;
    }

     
    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }

     
    function increaseSupply (uint256 _value, address _to) onlyOwner external {
        if (_value + currentSupply > totalSupply) throw;
        currentSupply = safeAdd(currentSupply, _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(address(0x0), _to, _value);
    }

     
    function changeOwner(address _newOwner) onlyOwner external {
        if (_newOwner == address(0x0)) throw;
        owner = _newOwner;
    }
    
     
    function setTokenExchangeRate(uint256 _tokenExchangeRate) onlyOwner external {
        if (_tokenExchangeRate == 0) throw;
        if (_tokenExchangeRate == tokenExchangeRate) throw;

        tokenExchangeRate = _tokenExchangeRate;
    }    
    
     
    function setFundingAmount(uint256 _totalFundingAmount) onlyOwner external {
        if (_totalFundingAmount == 0) throw;
        if (_totalFundingAmount == totalFundingAmount) throw;
        if (_totalFundingAmount - currentFundingAmount + currentSupply > totalSupply) throw;

        totalFundingAmount = _totalFundingAmount;
    }    
    
     
    function transferETH() onlyOwner external {
        if (this.balance == 0) throw;
        if (!owner.send(this.balance)) throw;
    }    
    
     
    function startFunding (uint256 _fundingStartBlock, uint256 _fundingStopBlock) onlyOwner external {
        if (isFunding) throw;
        if (_fundingStartBlock >= _fundingStopBlock) throw;
        if (block.number >= _fundingStartBlock) throw;

        fundingStartBlock = _fundingStartBlock;
        fundingStopBlock = _fundingStopBlock;
        isFunding = true;
    }

     
    function stopFunding() onlyOwner external {
        if (!isFunding) throw;
        isFunding = false;
    }    
    
     
    function () payable {
        if (!isFunding) throw;
        if (msg.value == 0) throw;

        if (block.number < fundingStartBlock) throw;
        if (block.number > fundingStopBlock) throw;

        uint256 tokens = safeMult(msg.value, tokenExchangeRate);
        if (tokens + currentFundingAmount > totalFundingAmount) throw;

        currentFundingAmount = safeAdd(currentFundingAmount, tokens);
        currentSupply = safeAdd(currentSupply, tokens);
        balances[msg.sender] += tokens;

        Transfer(address(0x0), msg.sender, tokens);
    }    
}