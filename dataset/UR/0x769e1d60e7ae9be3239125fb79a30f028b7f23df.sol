 

pragma solidity ^0.4.11;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}


 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract XxxToken is MintableToken {
     
    string public constant name = "XXX Token";
    string public constant symbol = "XXX";
    uint8 public constant decimals = 18;
}

contract XxxTokenSale is Ownable {
    using SafeMath for uint256;

     
    uint256 public startDate;
    uint256 public endDate;

     
    uint256 public cap;

     
    address public wallet;

     
    uint256 public weiRaised;

     
    XxxToken public token;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary,
                        uint256 value, uint256 amount);
    event TokenReserveMinted(uint256 amount);

     
    modifier initialized() {
        require(address(token) != 0x0);
        _;
    }

    function XxxTokenSale() {
    }

    function initialize(XxxToken _token, address _wallet,
                        uint256 _start, uint256 _end,
                        uint256 _cap) onlyOwner {
        require(address(token) == address(0));
        require(_token.owner() == address(this));
        require(_start >= getCurrentTimestamp());
        require(_start < _end);
        require(_wallet != 0x0);

        token = _token;
        wallet = _wallet;
        startDate = _start;
        endDate = _end;
        cap = _cap;
    }

    function getCurrentTimestamp() internal returns (uint256) {
        return now;
    }

     
    function () payable {
        buyTokens(msg.sender);
    }

    function getRateAt(uint256 at) constant returns (uint256) {
        if (at < startDate) {
            return 0;
        } else if (at < (startDate + 7 days)) {
            return 2000;
        } else if (at < (startDate + 14 days)) {
            return 1800;
        } else if (at < (startDate + 21 days)) {
            return 1700;
        } else if (at < (startDate + 28 days)) {
            return 1600;
        } else if (at < (startDate + 35 days)) {
            return 1500;
        } else if (at < (startDate + 49 days)) {
            return 1400;
        } else if (at < (startDate + 63 days)) {
            return 1300;
        } else if (at < (startDate + 77 days)) {
            return 1200;
        } else if (at <= endDate) {
            return 1100;
        } else {
            return 0;
        }
    }

    function buyTokens(address beneficiary) payable {
        require(beneficiary != 0x0);
        require(msg.value != 0);
        require(saleActive());

        uint256 weiAmount = msg.value;
        uint256 updatedWeiRaised = weiRaised.add(weiAmount);

         
        require(updatedWeiRaised <= cap);

         
        uint256 actualRate = getRateAt(getCurrentTimestamp());
        uint256 tokens = weiAmount.mul(actualRate);

         
        weiRaised = updatedWeiRaised;

         
        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

         
        wallet.transfer(msg.value);
    }

    function finalize() onlyOwner {
        require(!saleActive());

         
        uint256 xxxToReserve = SafeMath.div(token.totalSupply(), 5);
        token.mint(wallet, xxxToReserve);
        TokenReserveMinted(xxxToReserve);

         
         
        token.finishMinting();
    }

    function saleActive() public constant returns (bool) {
        return (getCurrentTimestamp() >= startDate &&
                getCurrentTimestamp() <= endDate && weiRaised < cap);
    }
}