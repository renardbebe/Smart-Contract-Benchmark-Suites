 

pragma solidity ^0.4.15;

contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

 
contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
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

}

contract StandardToken is ERC20, SafeMath {

   
  event Minted(address receiver, uint amount);

   
  mapping(address => uint) balances;

   
  mapping (address => mapping (address => uint)) allowed;

   
  function isToken() public constant returns (bool weAre) {
    return true;
  }

  function transfer(address _to, uint _value) returns (bool success) {
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    uint _allowance = allowed[_from][msg.sender];

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

contract QVT is StandardToken {

    string public name = "QVT";
    string public symbol = "QVT";
    uint public decimals = 18;
    uint public multiplier = 1000000000000000000;  

     
    bool public halted = false;  
    bool public freeze = true;  

    uint public roundCount = 1;  
    bool public isDayFirst = false;  
    bool public isDaySecond = false;  
    bool public isDayThird = false;  
    bool public isPreSale = false;  

     
    address public founder = 0x0;
    address public owner = 0x0;

     
    uint public totalTokens = 21600000;
    uint public team = 3420000;
    uint public bounty = 180000 * multiplier;  
    uint public preIcoSold = 0;

     
    uint public icoCap = 18000000;  

     
    uint public presaleTokenSupply = 0;  
    uint public presaleEtherRaised = 0;  

    event Buy(address indexed sender, uint eth, uint fbt);

     
    event TokensSent(address indexed to, uint256 value);
    event ContributionReceived(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    function QVT(address _founder) payable {
        owner = msg.sender;
        founder = _founder;

        team = safeMul(team, multiplier);

         
        totalSupply = safeMul(totalTokens, multiplier);
        balances[owner] = safeSub(totalSupply, team);

         
        balances[founder] = team;

        TokensSent(founder, team);
        Transfer(owner, founder, team);
    }

     
    function price() constant returns (uint){
        return 1 finney;
    }

     
    function buy() public payable returns(bool) {
        processBuy(msg.sender, msg.value);

        return true;
    }

    function processBuy(address _to, uint256 _value) internal returns(bool) {
         
        require(!halted);
         
        require(_value>0);

         
        uint tokens = _value / price();

         
        require(balances[owner]>safeMul(tokens, multiplier));

         
        if (isPreSale) {
            tokens = tokens + (tokens / 2);
        }

         
        if (isDayFirst) {
            tokens = tokens + safeMul(safeDiv(tokens, 10), 3);
        }

         
        if (isDaySecond) {
            tokens = tokens + safeDiv(tokens, 5);
        }

         
        if (isDayThird) {
            tokens = tokens + safeDiv(tokens, 10);
        }

         
        require(safeAdd(presaleTokenSupply, tokens) < icoCap);

         
        founder.transfer(_value);

         
        balances[_to] = safeAdd(balances[_to], safeMul(tokens, multiplier));
         
        balances[owner] = safeSub(balances[owner], safeMul(tokens, multiplier));

        presaleTokenSupply = safeAdd(presaleTokenSupply, tokens);
        presaleEtherRaised = safeAdd(presaleEtherRaised, _value);

         
        Buy(_to, _value, safeMul(tokens, multiplier));
        TokensSent(_to, safeMul(tokens, multiplier));
        ContributionReceived(_to, _value);
        Transfer(owner, _to, safeMul(tokens, multiplier));

        return true;
    }

     
    function sendEvents(address to, uint256 value, uint tokens) internal {
         
        Buy(to, value, safeMul(tokens, multiplier));
        TokensSent(to, safeMul(tokens, multiplier));
        ContributionReceived(to, value);
        Transfer(owner, to, safeMul(tokens, multiplier));
    }

     
    function proceedPreIcoTransactions(address[] toArray, uint[] valueArray) onlyOwner() {
        uint tokens = 0;
        address to = 0x0;
        uint value = 0;

        for (uint i = 0; i < toArray.length; i++) {
            to = toArray[i];
            value = valueArray[i];
            tokens = value / price();
            tokens = tokens + tokens;
            balances[to] = safeAdd(balances[to], safeMul(tokens, multiplier));
            balances[owner] = safeSub(balances[owner], safeMul(tokens, multiplier));
            preIcoSold = safeAdd(preIcoSold, tokens);
            sendEvents(to, value, tokens);
        }
    }

     
    function halt() onlyOwner() {
        halted = true;
    }

    function unHalt() onlyOwner() {
        halted = false;
    }

     
    function sendBounty(address _to, uint256 _value) onlyOwner() {
        require(bounty > _value);

        bounty = safeSub(bounty, _value);
        balances[_to] = safeAdd(balances[_to], safeMul(_value, multiplier));
         
        TokensSent(_to, safeMul(_value, multiplier));
        Transfer(owner, _to, safeMul(_value, multiplier));
    }

     
    function sendSupplyTokens(address _to, uint256 _value) onlyOwner() {
        balances[owner] = safeSub(balances[owner], safeMul(_value, multiplier));
        balances[_to] = safeAdd(balances[_to], safeMul(_value, multiplier));

         
        TokensSent(_to, safeMul(_value, multiplier));
        Transfer(owner, _to, safeMul(_value, multiplier));
    }

     
    function transfer(address _to, uint256 _value) isAvailable() returns (bool success) {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) isAvailable() returns (bool success) {
        return super.transferFrom(_from, _to, _value);
    }

     
    function burnRemainingTokens() isAvailable() onlyOwner() {
        Burn(owner, balances[owner]);
        balances[owner] = 0;
    }

     
    function setDayFirst() onlyOwner() {
        isDayFirst = true;
        isDaySecond = false;
        isDayThird = false;
    }

     
    function setDaySecond() onlyOwner() {
        isDayFirst = false;
        isDaySecond = true;
        isDayThird = false;
    }

     
    function setDayThird() onlyOwner() {
        isDayFirst = false;
        isDaySecond = false;
        isDayThird = true;
    }

     
    function setBonusOff() onlyOwner() {
        isDayFirst = false;
        isDaySecond = false;
        isDayThird = false;
    }

    
   function setPreSaleOn() onlyOwner() {
       isPreSale = true;
   }

    
   function setPreSaleOff() onlyOwner() {
       isPreSale = false;
   }

     
    function startNewRound() onlyOwner() {
        require(roundCount < 5);
        roundCount = roundCount + 1;

        balances[owner] = safeAdd(balances[owner], safeMul(icoCap, multiplier));
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isAvailable() {
        require(!halted && !freeze);
        _;
    }

     
    function() payable {
        buy();
    }

     
    function freeze() onlyOwner() {
         freeze = true;
    }

     function unFreeze() onlyOwner() {
         freeze = false;
     }

     
    function changeOwner(address _to) onlyOwner() {
        balances[_to] = balances[owner];
        balances[owner] = 0;
        owner = _to;
    }

     
    function changeFounder(address _to) onlyOwner() {
        balances[_to] = balances[founder];
        balances[founder] = 0;
        founder = _to;
    }
}