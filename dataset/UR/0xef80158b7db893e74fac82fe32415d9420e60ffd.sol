 

pragma solidity ^0.4.11;

 library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}


 contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

}

contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;

  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }


  function approve(address _spender, uint _value) {
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }


  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

contract BAC is StandardToken{
    string public constant name = "BananaFundCoin";
    string public constant symbol = "BAC";
    uint public constant decimals = 18;
    string public version = "1.0";
    
     
    uint public price ;
    uint public issueIndex = 0;
     
    uint public constant bacFund =500*(10**6)*10**decimals;
    uint public constant MaxReleasedBac =1000*(10**6)*10**decimals;
     
    bool public saleOrNot;
     
    event InvalidCaller(address caller);
    event Issue(uint issueIndex, address addr, uint ethAmount, uint tokenAmount);
    event StartOK();
    event InvalidState(bytes msg);
    event ShowMsg(bytes msg);
    
     
    address public target;
    
     
    function BAC(uint _price){
        target = msg.sender;
        price =_price;
        totalSupply=bacFund;
        balances[target] = bacFund;
        saleOrNot = false;
    }
    
    modifier onlyOwner {
        if (target == msg.sender) {
          _;
        } else {
            InvalidCaller(msg.sender);
            throw;
        }
    }

    modifier inProgress {
        if (saleStarted()) {
            _;
        } else {
            InvalidState("Sale is not in progress");
            throw;
        }
    }
  
     
    function () payable{
        if(saleOrNot){
            issueToken(msg.sender);
        }else{
            throw;
        }
    }
    
    function issueToken(address recipient) payable inProgress{
        assert(msg.value >= 0.01 ether);
         
        uint  amount = computeAccount(msg.value);
        if(totalSupply < bacFund+MaxReleasedBac){
            balances[recipient] = balances[recipient].add(amount);
            totalSupply = totalSupply.add(amount);
            Issue(issueIndex++, recipient,msg.value, amount);
        }else{
            InvalidState("BAC is not enough");
            throw;
        }
         
        if (!target.send(msg.value)) {
            throw;
        }
    }
    
     
    function computeAccount(uint ehtAccount) internal constant returns (uint tokens){
        tokens=price.mul(ehtAccount);
    }
    
     
    function setPrice(uint _price) onlyOwner{
        if(_price>0){
            price= _price;
        }else{
            ShowMsg("Invalid price");
        }
    }
    
     
    function startSale() onlyOwner{
        if(!saleOrNot){
            saleOrNot = true;
            StartOK();
        }else{
            ShowMsg("sale is ing ");
        }
    }   
    
     
    function stopSale() onlyOwner{
        if(saleOrNot) {
            saleOrNot=false;
             
            if(totalSupply< 1500*(10**6)*10**decimals){
                balances[target] = balances[target].add(1500*(10**6)*10**decimals-totalSupply);
            }
        }else{
            ShowMsg("sale has been over");
        }
    }
    
    function saleStarted() constant returns (bool) {
        return saleOrNot;
    }
    
     
    function destroy() onlyOwner{
        suicide(target);
    }
}