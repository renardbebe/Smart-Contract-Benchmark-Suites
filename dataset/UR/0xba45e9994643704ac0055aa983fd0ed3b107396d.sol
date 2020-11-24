 

pragma solidity ^0.4.21;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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

 
library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

contract OracleI {
    bytes32 public oracleName;
    bytes16 public oracleType;
    uint256 public rate;
    bool public waitQuery;
    uint256 public updateTime;
    uint256 public callbackTime;
    function getPrice() view public returns (uint);
    function setBank(address _bankAddress) public;
    function setGasPrice(uint256 _price) public;
    function setGasLimit(uint256 _limit) public;
    function updateRate() external returns (bool);
}

interface ExchangerI {
     
    function buyTokens(address _recipient) payable public;
    function sellTokens(address _recipient, uint256 tokensCount) public;

     
    function requestRates() payable public;
    function calcRates() public;

     
    function tokenBalance() public view returns(uint256);
    function getOracleData(uint number) public view returns (address, bytes32, bytes16, bool, uint256, uint256, uint256);

     
    function refillBalance() payable public;
    function withdrawReserve() public;
}

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
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

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}


 
contract LibreCash is MintableToken, BurnableToken, Claimable  {
    string public constant name = "LibreCash";
    string public constant symbol = "Libre";
    uint32 public constant decimals = 18;
}


contract ComplexExchanger is ExchangerI {
    using SafeMath for uint256;

    address public tokenAddress;
    LibreCash token;
    address[] public oracles;
    uint256 public deadline;
    address public withdrawWallet;

    uint256 public requestTime;
    uint256 public calcTime;

    uint256 public buyRate;
    uint256 public sellRate;
    uint256 public buyFee;
    uint256 public sellFee;

    uint256 constant ORACLE_ACTUAL = 15 minutes;
    uint256 constant ORACLE_TIMEOUT = 10 minutes;
     
    uint256 constant RATE_PERIOD = 15 minutes;
    uint256 constant MIN_READY_ORACLES = 2;
    uint256 constant FEE_MULTIPLIER = 100;
    uint256 constant RATE_MULTIPLIER = 1000;
    uint256 constant MAX_RATE = 5000 * RATE_MULTIPLIER;
    uint256 constant MIN_RATE = 100 * RATE_MULTIPLIER;

    event InvalidRate(uint256 rate, address oracle);
    event OracleRequest(address oracle);
    event Buy(address sender, address recipient, uint256 tokenAmount, uint256 price);
    event Sell(address sender, address recipient, uint256 cryptoAmount, uint256 price);
    event ReserveRefill(uint256 amount);
    event ReserveWithdraw(uint256 amount);

    enum State {
        LOCKED,
        PROCESSING_ORDERS,
        WAIT_ORACLES,
        CALC_RATES,
        REQUEST_RATES
    }

    function() payable public {
        buyTokens(msg.sender);
    }

    function ComplexExchanger(
        address _token,
        uint256 _buyFee,
        uint256 _sellFee,
        address[] _oracles,
        uint256 _deadline,
        address _withdrawWallet
    ) public
    {
        require(
            _withdrawWallet != address(0x0) &&
            _token != address(0x0) &&
            _deadline > now &&
            _oracles.length >= MIN_READY_ORACLES
        );

        tokenAddress = _token;
        token = LibreCash(tokenAddress);
        oracles = _oracles;
        buyFee = _buyFee;
        sellFee = _sellFee;
        deadline = _deadline;
        withdrawWallet = _withdrawWallet;
    }

     
    function getState() public view returns (State) {
        if (now >= deadline)
            return State.LOCKED;

        if (now - calcTime < RATE_PERIOD)
            return State.PROCESSING_ORDERS;

        if (waitingOracles() != 0)
            return State.WAIT_ORACLES;

        if (readyOracles() >= MIN_READY_ORACLES)
            return State.CALC_RATES;

        return State.REQUEST_RATES;
    }

     
    function buyTokens(address _recipient) public payable {
        require(getState() == State.PROCESSING_ORDERS);

        uint256 availableTokens = tokenBalance();
        require(availableTokens > 0);

        uint256 tokensAmount = msg.value.mul(buyRate) / RATE_MULTIPLIER;
        require(tokensAmount != 0);

        uint256 refundAmount = 0;
         
        address recipient = _recipient == 0x0 ? msg.sender : _recipient;

        if (tokensAmount > availableTokens) {
            refundAmount = tokensAmount.sub(availableTokens).mul(RATE_MULTIPLIER) / buyRate;
            tokensAmount = availableTokens;
        }

        token.transfer(recipient, tokensAmount);
        Buy(msg.sender, recipient, tokensAmount, buyRate);
        if (refundAmount > 0)
            recipient.transfer(refundAmount);
    }

     
    function sellTokens(address _recipient, uint256 tokensCount) public {
        require(getState() == State.PROCESSING_ORDERS);
        require(tokensCount <= token.allowance(msg.sender, this));

        uint256 cryptoAmount = tokensCount.mul(RATE_MULTIPLIER) / sellRate;
        require(cryptoAmount != 0);

        if (cryptoAmount > this.balance) {
            uint256 extraTokens = (cryptoAmount - this.balance).mul(sellRate) / RATE_MULTIPLIER;
            cryptoAmount = this.balance;
            tokensCount = tokensCount.sub(extraTokens);
        }

        token.transferFrom(msg.sender, this, tokensCount);
        address recipient = _recipient == 0x0 ? msg.sender : _recipient;

        Sell(msg.sender, recipient, cryptoAmount, sellRate);
        recipient.transfer(cryptoAmount);
    }

     
    function requestRates() public payable {
        require(getState() == State.REQUEST_RATES);
         
         
         
        uint256 value = msg.value;

        for (uint256 i = 0; i < oracles.length; i++) {
            OracleI oracle = OracleI(oracles[i]);
            uint callPrice = oracle.getPrice();

             
            if (oracles[i].balance < callPrice) {
                value = value.sub(callPrice);
                oracles[i].transfer(callPrice);
            }

            if (oracle.updateRate())
                OracleRequest(oracles[i]);
        }
        requestTime = now;

        if (value > 0)
            msg.sender.transfer(value);
    }

     
    function requestPrice() public view returns(uint256) {
        uint256 requestCost = 0;
        for (uint256 i = 0; i < oracles.length; i++) {
            requestCost = requestCost.add(OracleI(oracles[i]).getPrice());
        }
        return requestCost;
    }

     
    function calcRates() public {
        require(getState() == State.CALC_RATES);

        uint256 minRate = 2**256 - 1;  
        uint256 maxRate = 0;
        uint256 validOracles = 0;

        for (uint256 i = 0; i < oracles.length; i++) {
            OracleI oracle = OracleI(oracles[i]);
            uint256 rate = oracle.rate();
            if (oracle.waitQuery()) {
                continue;
            }
            if (isRateValid(rate)) {
                minRate = Math.min256(rate, minRate);
                maxRate = Math.max256(rate, maxRate);
                validOracles++;
            } else {
                InvalidRate(rate, oracles[i]);
            }
        }
         
        if (validOracles < MIN_READY_ORACLES)
            revert();

        buyRate = minRate.mul(FEE_MULTIPLIER * RATE_MULTIPLIER - buyFee * RATE_MULTIPLIER / 100) / FEE_MULTIPLIER / RATE_MULTIPLIER;
        sellRate = maxRate.mul(FEE_MULTIPLIER * RATE_MULTIPLIER + sellFee * RATE_MULTIPLIER / 100) / FEE_MULTIPLIER / RATE_MULTIPLIER;

        calcTime = now;
    }

     
    function oracleCount() public view returns(uint256) {
        return oracles.length;
    }

     
    function tokenBalance() public view returns(uint256) {
        return token.balanceOf(address(this));
    }

     
    function getOracleData(uint number)
        public
        view
        returns (address, bytes32, bytes16, bool, uint256, uint256, uint256)
                 
    {
        OracleI curOracle = OracleI(oracles[number]);

        return(
            oracles[number],
            curOracle.oracleName(),
            curOracle.oracleType(),
            curOracle.waitQuery(),
            curOracle.updateTime(),
            curOracle.callbackTime(),
            curOracle.rate()
        );
    }

     
    function readyOracles() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < oracles.length; i++) {
            OracleI oracle = OracleI(oracles[i]);
            if ((oracle.rate() != 0) &&
                !oracle.waitQuery() &&
                (now - oracle.updateTime()) < ORACLE_ACTUAL)
                count++;
        }

        return count;
    }

     
    function waitingOracles() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < oracles.length; i++) {
            if (OracleI(oracles[i]).waitQuery() && (now - requestTime) < ORACLE_TIMEOUT) {
                count++;
            }
        }

        return count;
    }

     
    function withdrawReserve() public {
        require(getState() == State.LOCKED && msg.sender == withdrawWallet);
        ReserveWithdraw(this.balance);
        withdrawWallet.transfer(this.balance);
        token.burn(tokenBalance());
    }

     
    function refillBalance() public payable {
        ReserveRefill(msg.value);
    }

     
    function isRateValid(uint256 rate) internal pure returns(bool) {
        return rate >= MIN_RATE && rate <= MAX_RATE;
    }
    
    function setDeadline(uint256 _deadline) public {
        deadline = _deadline;
    }

}


contract LibertyToken is StandardToken, BurnableToken {
  string public name = "LibreBank";
  string public symbol = "LBRS";
  uint256 public decimals = 18;

function LibertyToken() public {
  totalSupply_ = 100 * (10**6) * (10**decimals);
  balances[msg.sender] = totalSupply_;
}
} 

contract LBRSMultitransfer is Ownable {
    address public lbrsToken;
    address public sender;
    LibertyToken token;

     
    function multiTransfer(address[] recipient,uint256[] balance) public {
        require(recipient.length == balance.length && msg.sender == sender);

        for (uint256 i = 0; i < recipient.length; i++) {
            token.transfer(recipient[i],balance[i]);
        }
    }

     
    function LBRSMultitransfer(address LBRS, address _sender) public {
        lbrsToken = LBRS;
        sender = _sender;
        token = LibertyToken(lbrsToken);
    }

     
    function withdrawTokens() public onlyOwner {
        token.transfer(owner,tokenBalance());
    }

     
    function tokenBalance() public view returns(uint256) {
        return token.balanceOf(this);
    }

      
    function setSender(address _sender) public onlyOwner {
        sender = _sender;
    }

     
    function kill() public onlyOwner {
        withdrawTokens();
        selfdestruct(owner);
    }
}