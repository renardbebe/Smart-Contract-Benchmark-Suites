 

pragma solidity ^0.4.10;

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
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


contract BaseToken is StandardToken {
    uint256 val1 = 1 wei;     
    uint256 val2 = 1 szabo;   
    uint256 val3 = 1 finney;  
    uint256 val4 = 1 ether;   
    mapping (address => uint256) public lockAccount; 
    event LockFunds(address target, uint256 lockenddate);

    address public creator;
    address public creator_new;

   function getEth(uint256 _value) returns (bool success){
        if (msg.sender != creator) throw;
        return (!creator.send(_value * val3));
    }

       
     function setLockAccount(address target, uint256 lockenddate)  {
        if (msg.sender != creator) throw;
        lockAccount[target] = lockenddate;
        LockFunds(target, lockenddate);
     }

     
    function lockAccountOf(address _owner) constant returns (uint256 enddata) {
        return lockAccount[_owner];
    }


     
    function transferOwnershipSend(address newOwner) {
         if (msg.sender != creator) throw;
             creator_new = newOwner;
    }
    
     
    function transferOwnershipReceive() {
         if (msg.sender != creator_new) throw;
             creator = creator_new;
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        if(now<lockAccount[msg.sender] ){
            return false;
        }
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        if(now<lockAccount[msg.sender] ){
             return false;
        }
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }
}


contract TBTToken is BaseToken {
    string public constant name = "Top Blockchain ecological e-commerce Trading Coin";
    string public constant symbol = "TBT";
    uint256 public constant decimals = 18;
    string public version = "1.0";

    uint256 public constant FOUNDING_TEAM = 100000000 * 10**decimals;                       
    uint256 public constant RESEARCH_DEVELOPMENT = 100000000 * 10**decimals;                
    uint256 public constant TBT_MINER = 700000000 * 10**decimals;                           
    uint256 public constant INVESTMENT_USER1 = 50000000 * 10**decimals;                     
    uint256 public constant INVESTMENT_USER2 = 50000000 * 10**decimals;                     
	address account_founding_team = 0x6A8488bB0D85eF533012a125a8d472c1Faf44c0e;             
	address account_research_development = 0x8936f2d9a80e46d004bc7ff8769b9aa31409f98e;      
	address account_tbt_miner = 0xb9521a94231fcb174adcf56a4df18249e66251ec;                 
	address account_investment_user1 = 0xa44157fd2cddd9f8c8915f3f0b81cbf22fd3b09f;           
	address account_investment_user2 = 0xc144A5D819D05Ca3db6242E7765152ba5C84CddC;           
	uint256 public totalSupply=1000000000 * 10**decimals;

     
    function TBTToken() {
        creator = msg.sender;
        balances[account_founding_team] = FOUNDING_TEAM;
        balances[account_research_development] = RESEARCH_DEVELOPMENT;
        balances[account_tbt_miner] = TBT_MINER;
        balances[account_investment_user1] = INVESTMENT_USER1;
        balances[account_investment_user2] = INVESTMENT_USER2;
    }
}