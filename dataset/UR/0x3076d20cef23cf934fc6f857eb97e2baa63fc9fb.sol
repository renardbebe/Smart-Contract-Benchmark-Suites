 

pragma solidity ^0.4.18;

contract ERC20Basic {
  uint256 public totalSupply;
  string public name;
  string public symbol;
  uint8 public decimals;
  function balanceOf(address who) constant public returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ExternalToken {
    function burn(uint256 _value, bytes _data) public;
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant public returns (uint256 balance) {
    return balances[_owner];
  }

}

contract TokenReceiver {
    function onTokenTransfer(address _from, uint256 _value, bytes _data) public;
}

contract Ownable {
  address public owner;


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract AbstractSale is TokenReceiver, Pausable {
    using SafeMath for uint256;

    event BonusChange(uint256 bonus);
    event RateChange(address token, uint256 rate);
    event Purchase(address indexed buyer, address token, uint256 value, uint256 amount);
    event Withdraw(address token, address to, uint256 value);
    event Burn(address token, uint256 value, bytes data);

    mapping (address => uint256) rates;
    uint256 public bonus;

    function onTokenTransfer(address _from, uint256 _value, bytes _data) whenNotPaused public {
        onReceive(msg.sender, _from, _value, _data);
    }

    function() payable whenNotPaused public {
        receiveWithData("");
    }

    function receiveWithData(bytes _data) payable whenNotPaused public {
        onReceive(address(0), msg.sender, msg.value, _data);
    }

    function onReceive(address _token, address _from, uint256 _value, bytes _data) internal {
        uint256 tokens = getAmount(_token, _value);
        require(tokens > 0);
        address buyer;
        if (_data.length == 20) {
            buyer = address(toBytes20(_data, 0));
        } else {
            require(_data.length == 0);
            buyer = _from;
        }
        Purchase(buyer, _token, _value, tokens);
        doPurchase(buyer, tokens);
    }

    function doPurchase(address buyer, uint256 amount) internal;

    function toBytes20(bytes b, uint256 _start) pure internal returns (bytes20 result) {
        require(_start + 20 <= b.length);
        assembly {
            let from := add(_start, add(b, 0x20))
            result := mload(from)
        }
    }

    function getAmount(address _token, uint256 _value) constant public returns (uint256) {
        uint256 rate = getRate(_token);
        require(rate > 0);
        uint256 beforeBonus = _value.mul(rate);
        return beforeBonus.add(beforeBonus.mul(bonus).div(100)).div(10**18);
    }

    function getRate(address _token) constant public returns (uint256) {
        return rates[_token];
    }

    function setRate(address _token, uint256 _rate) onlyOwner public {
        rates[_token] = _rate;
        RateChange(_token, _rate);
    }

    function setBonus(uint256 _bonus) onlyOwner public {
        bonus = _bonus;
        BonusChange(_bonus);
    }

    function withdraw(address _token, address _to, uint256 _amount) onlyOwner public {
        require(_to != address(0));
        verifyCanWithdraw(_token, _to, _amount);
        if (_token == address(0)) {
            _to.transfer(_amount);
        } else {
            ERC20(_token).transfer(_to, _amount);
        }
        Withdraw(_token, _to, _amount);
    }

    function burnWithData(address _token, uint256 _amount, bytes _data) onlyOwner public {
        ExternalToken(_token).burn(_amount, _data);
        Burn(_token, _amount, _data);
    }

    function verifyCanWithdraw(address _token, address _to, uint256 _amount) internal {

    }
}

contract Sale is AbstractSale {
    ERC20 public token;

    function Sale(address _token) public {
        token = ERC20(_token);
    }

    function doPurchase(address buyer, uint256 amount) internal {
        token.transfer(buyer, amount);
    }

     
    function verifyCanWithdraw(address _token, address _to, uint256 _amount) internal {
        require(_token != address(token));
    }
}

contract GoldeaSale is Sale {
    address public btcToken;
    uint256 public constant end = 1522540800;
    uint256 public constant total = 200000000000000;

    function GoldeaSale(address _token, address _btcToken) Sale(_token) public {
        btcToken = _btcToken;
    }

    function changeParameters(uint256 _ethRate, uint256 _btcRate, uint256 _bonus) onlyOwner public {
        setRate(address(0), _ethRate);
        setRate(btcToken, _btcRate);
        setBonus(_bonus);
    }

    function setBtcToken(address _btcToken) onlyOwner public {
        btcToken = _btcToken;
    }

    function doPurchase(address buyer, uint256 amount) internal {
        require(now < end);
        super.doPurchase(buyer, amount);
    }

    function burn() onlyOwner public {
        require(now >= end);
        BurnableToken(token).burn(token.balanceOf(this));
    }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant public returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
  
   
  function increaseApproval (address _spender, uint _addedValue) public
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract BurnableToken is StandardToken {

     
    function burn(uint _value)
        public
    {
        require(_value > 0);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }

    event Burn(address indexed burner, uint indexed value);
}