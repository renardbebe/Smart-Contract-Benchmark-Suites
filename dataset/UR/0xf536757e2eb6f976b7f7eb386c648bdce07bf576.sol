 

pragma solidity ^0.4.13;

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

     
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        else {return false;}
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        }
        else {return false;}
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

     
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
}

contract LGBiT is StandardToken {

    string public name = "LGBiT";
    string public symbol = "LGBiT";

    uint public decimals = 8;
    uint public multiplier = 100000000;  

     
    bool public halted = false;  
    bool public preIco = true;  

     
    address public founder = 0x0;
    address public owner = 0x0;

     
    uint public totalTokens = 50750000;

    uint public bounty = 200000;  

     
    uint public preIcoCap = 550000 * multiplier;  
    uint public icoCap = 50000000 * multiplier;  

     
    uint public presaleTokenSupply = 0;  
    uint public presaleEtherRaised = 0;  
    uint public preIcoTokenSupply = 0;  

    event Buy(address indexed sender, uint eth, uint fbt);

     
    event TokensSent(address indexed to, uint256 value);
    event ContributionReceived(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    function LGBiT() payable {
        owner = msg.sender;
        founder = 0x00A691299526E4DC3754F8e2A0d6788F27c0dc7e;

         
        totalTokens = safeSub(totalTokens, bounty);
        totalSupply = safeMul(totalTokens, multiplier);
        balances[owner] = safeMul(totalSupply, multiplier);
    }

     
    function price() constant returns (uint256){
        if (preIco) {
            return safeDiv(1 ether, 800);
        } else {
            if (presaleEtherRaised < 4999 ether) {
                return safeDiv(1 ether, 700);
            } else if (presaleEtherRaised >= 5000 ether && presaleEtherRaised < 9999 ether) {
                return safeDiv(1 ether, 685);
            } else if (presaleEtherRaised >= 10000 ether && presaleEtherRaised < 19999 ether) {
                return safeDiv(1 ether, 660);
            } else {
                return safeDiv(1 ether, 600);
            }
        }
    }

     
    function buy() public payable returns(bool) {
        processBuy(msg.sender, msg.value);

        return true;
    }

    function processBuy(address _to, uint256 _value) internal returns(bool) {
         
        require(!halted);
         
        require(_value>0);

         
        uint tokens = _value / price();

        if (_value > 99 ether && _value < 1000 ether) {
             
            tokens = tokens + (tokens / 10);
        } else if (_value > 999 ether) {
             
            tokens = tokens + (tokens / 4);
        }

         
        require(balances[owner]>safeMul(tokens, multiplier));

         
        if (preIco) {
             
            require(safeAdd(presaleTokenSupply, tokens) < preIcoCap);
        } else {
             
            require(safeAdd(presaleTokenSupply, tokens) < safeSub(icoCap, preIcoTokenSupply));
        }

         
        founder.transfer(_value);

         
        balances[_to] = safeAdd(balances[_to], safeMul(tokens, multiplier));
         
        balances[owner] = safeSub(balances[owner], safeMul(tokens, multiplier));

         
        if (preIco) {
            preIcoTokenSupply  = safeAdd(preIcoTokenSupply, tokens);
        }

        presaleTokenSupply = safeAdd(presaleTokenSupply, tokens);
        presaleEtherRaised = safeAdd(presaleEtherRaised, _value);

         
        Buy(_to, _value, safeMul(tokens, multiplier));

         
        TokensSent(_to, safeMul(tokens, multiplier));
        ContributionReceived(_to, _value);
        Transfer(owner, _to, safeMul(tokens, multiplier));

        return true;
    }

     
    function setPreIco() onlyOwner() {
        preIco = true;
    }

    function unPreIco() onlyOwner() {
        preIco = false;
    }

     
    function halt() onlyOwner() {
        halted = true;
    }

    function unHalt() onlyOwner() {
        halted = false;
    }

     
    function sendBounty(address _to, uint256 _value) onlyOwner() {
        require(bounty>_value);

        bounty = safeSub(bounty, _value);
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

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isAvailable() {
        require(!halted);
        _;
    }

     
    function() payable {
        buy();
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