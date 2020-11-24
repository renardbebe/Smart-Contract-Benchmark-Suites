 

pragma solidity ^0.4.11;


 
contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

 
contract SafeMath {

     
     
     
     
     
contract StandardToken is Token {

  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }


    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) returns (bool success) {
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

contract splitterContract is Ownable{

    event ev(string msg, address whom, uint256 val);

    struct xRec {
        bool inList;
        address next;
        address prev;
        uint256 val;
    }

    struct l8r {
        address whom;
        uint256 val;
    }
    address public myAddress = this;
    address public first;
    address public last;
    address public ddf;
    bool    public thinkMode;
    uint256 public pos;

    mapping (address => xRec) public theList;

    l8r[]  afterParty;

    modifier onlyMeOrDDF() {
        if (msg.sender == ddf || msg.sender == myAddress || msg.sender == owner) {
            _;
            return;
        }
    }

    function setDDF(address ddf_) onlyOwner {
        ddf = ddf_;
    }

    function splitterContract(address seed, uint256 seedVal) {
        first = seed;
        last = seed;
        theList[seed] = xRec(true,0x0,0x0,seedVal);
    }

    function startThinking() onlyOwner {
        thinkMode = true;
        pos = 0;
    }

    function stopThinking(uint256 num) onlyOwner {
        thinkMode = false;
        for (uint256 i = 0; i < num; i++) {
            if (pos >= afterParty.length) {
                delete afterParty;
                return;
            }
            update(afterParty[pos].whom,afterParty[pos].val);
            pos++;
        }
        thinkMode = true;
    } 

    function thinkLength() constant returns (uint256) {
        return afterParty.length;
    }

    function addRec4L8R(address whom, uint256 val) internal {
        afterParty.push(l8r(whom,val));
    }

    function add(address whom, uint256 value) internal {
        theList[whom] = xRec(true,0x0,last,value);
        theList[last].next = whom;
        last = whom;
        ev("add",whom,value);
    }

    function remove(address whom) internal {
        if (first == whom) {
            first = theList[whom].next;
            theList[whom] = xRec(false,0x0,0x0,0);
            return;
        }
        address next = theList[whom].next;
        address prev = theList[whom].prev;
        if (prev != 0x0) {
            theList[prev].next = next;
        }
        if (next != 0x0) {
            theList[next].prev = prev;
        }
        theList[whom] = xRec(false,0x0,0x0,0);
        ev("remove",whom,0);
    }

    function update(address whom, uint256 value) onlyMeOrDDF {
        if (thinkMode) {
            addRec4L8R(whom,value);
            return;
        }
        if (value != 0) {
            if (!theList[whom].inList) {
                add(whom,value);
            } else {
                theList[whom].val = value;
                ev("update",whom,value);
            }
            return;
        }
        if (theList[whom].inList) {
                remove(whom);
        }
    }

}



contract DDFToken is StandardToken, SafeMath {

     
    string public constant name = "Digital Developers Fund Token";
    string public constant symbol = "DDF";
    uint256 public constant decimals = 18;
    string public version = "1.0";

     
    address public ethFundDeposit;       
    address public ddftFundDeposit;      
    address public splitter;           

     
    bool public isFinalized;               
    uint256 public fundingStartTime;
    uint256 public fundingEndTime;
    uint256 public constant ddftFund = 25 * (10**5) * 10**decimals;    
    uint256 public constant tokenExchangeRate = 1000;                
    uint256 public constant tokenCreationCap =  250 * (10**6) * 10**decimals;
    uint256 public constant tokenCreationMin =  1 * (10**6) * 10**decimals;


     
    event LogRefund(address indexed _to, uint256 _value);
    event CreateDDFT(address indexed _to, uint256 _value);

     
    function DDFToken(
        address _ethFundDeposit,
        address _ddftFundDeposit,
        address _splitter,  
        uint256 _fundingStartTime,
        uint256 duration)
    {
      isFinalized = false;                    
      ethFundDeposit = _ethFundDeposit;
      ddftFundDeposit = _ddftFundDeposit;
      splitter =  _splitter ;                   
      fundingStartTime = _fundingStartTime;
      fundingEndTime = fundingStartTime + duration * 1 days;
      totalSupply = ddftFund;
      balances[ddftFundDeposit] = ddftFund;     
      CreateDDFT(ddftFundDeposit, ddftFund);   
    }

    function () payable {            
      createTokens(msg.value);
    }

     
    function createTokens(uint256 _value)  internal {
      if (isFinalized) throw;
      if (now < fundingStartTime) throw;
      if (now > fundingEndTime) throw;
      if (msg.value == 0) throw;

      uint256 tokens = safeMult(_value, tokenExchangeRate);  
      uint256 checkedSupply = safeAdd(totalSupply, tokens);

       
      if (tokenCreationCap < checkedSupply) {
        if (tokenCreationCap <= totalSupply) throw;   
        uint256 tokensToAllocate = safeSubtract(tokenCreationCap,totalSupply);
        uint256 tokensToRefund   = safeSubtract(tokens,tokensToAllocate);
        totalSupply = tokenCreationCap;
        balances[msg.sender] += tokensToAllocate;   
        uint256 etherToRefund = tokensToRefund / tokenExchangeRate;
        msg.sender.transfer(etherToRefund);
        CreateDDFT(msg.sender, tokensToAllocate);   
        LogRefund(msg.sender,etherToRefund);
        splitterContract(splitter).update(msg.sender,balances[msg.sender]);
        return;
      }
       
      totalSupply = checkedSupply;
      balances[msg.sender] += tokens;   
      CreateDDFT(msg.sender, tokens);   
      splitterContract(splitter).update(msg.sender,balances[msg.sender]);
    }

     
    function finalize() external {
      if (isFinalized) throw;
      if (msg.sender != ethFundDeposit) throw;  
      if(totalSupply < tokenCreationMin + ddftFund) throw;       
      if(now <= fundingEndTime && totalSupply != tokenCreationCap) throw;
       
      isFinalized = true;
       
      ethFundDeposit.transfer(this.balance);   
    }

     
    function refund() external {
      if(isFinalized) throw;                        
      if (now <= fundingEndTime) throw;  
      if(totalSupply >= tokenCreationMin + ddftFund) throw;   
      if(msg.sender == ddftFundDeposit) throw;     
      uint256 ddftVal = balances[msg.sender];
      if (ddftVal == 0) throw;
      balances[msg.sender] = 0;
      totalSupply = safeSubtract(totalSupply, ddftVal);  
      uint256 ethVal = ddftVal / tokenExchangeRate;      
      LogRefund(msg.sender, ethVal);                
       
      msg.sender.transfer(ethVal);                  
    }

     
     
    function transfer(address _to, uint _value) returns (bool success)  {
      success = super.transfer(_to,_value);
      splitterContract sc = splitterContract(splitter);
      sc.update(msg.sender,balances[msg.sender]);
      sc.update(_to,balances[_to]);
      return;
    }

}