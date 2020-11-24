 

pragma solidity ^0.4.18;

 

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Token {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

  bool public endITO = false;

  uint public endDate = 1530360000;   

   
  modifier whenNotPaused() {
    require(now >= endDate || endITO);
    _;
  }

  function unPause() public onlyOwner returns (bool) {
      endITO = true;
      return endITO;
  }

}

contract StandardToken is Token, Pausable {
    using SafeMath for uint256;
    mapping (address => mapping (address => uint256)) internal allowed;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    require(_to != address(0));
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }


   
  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    require(_to != address(0));
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
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

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}

contract KeeppetToken is BurnableToken {

    string public constant name = "KeepPet Token";
    string public constant symbol = "PET";
    uint8 public constant decimals = 0;

    uint256 public constant INITIAL_SUPPLY = 3500000;

     
    function KeeppetToken() public {
        totalSupply = INITIAL_SUPPLY;
        balances[owner] = INITIAL_SUPPLY;
    }

    function sendTokens(address _to, uint _amount) external onlyOwner {
        require(_amount <= balances[msg.sender]);
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        Transfer(msg.sender, _to, _amount);
    }
}

 
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}

contract SalesManager is Ownable {
    using SafeMath for uint256;

     
     
    uint public constant etherCost = 750;
    uint public constant startDate = 1514721600;
    uint public constant endDate = 1516017600;
    uint256 public constant softCap = 250000 / etherCost * 1 ether;
    uint256 public constant hardCap = 1050000 / etherCost * 1 ether;

    struct Stat {
        uint256 currentFundraiser;
        uint256 additionalEthAmount;
        uint256 ethAmount;
        uint txCounter;
    }

    Stat public stat;

     
     
    uint256 public constant tokenPrice = uint256(15 * 1 ether).div(etherCost * 10);
    RefundVault public refundVault;
    KeeppetToken public keeppetToken;

     
    modifier isFinished() {
        require(now >= endDate);
        _;
    }

    function SalesManager(address wallet) public {
        require(wallet != address(0));
        keeppetToken = new KeeppetToken();
        refundVault = new RefundVault(wallet);
    }

    function () payable public {
       require(msg.value >= 2 * 10**15  && now >= startDate && now < endDate);
       require(stat.ethAmount + stat.additionalEthAmount < hardCap);
       buyTokens();
    }

    uint bonusX2Stage1 = softCap;
    uint bonusX2Stage2 = 525000 / etherCost * 1 ether;
    uint bonusX2Stage3 = 787500 / etherCost * 1 ether;
    uint bonusX2Stage4 = hardCap;

    function checkBonus(uint256 amount) public constant returns(bool) {
        uint256 current = stat.ethAmount + stat.additionalEthAmount;
        uint256 withAmount = current.add(amount);

        return ((current < bonusX2Stage1 && bonusX2Stage1 <= withAmount)
        || (current < bonusX2Stage2 && bonusX2Stage2 <= withAmount)
        || (current < bonusX2Stage3 && bonusX2Stage3 <= withAmount)
        || (current < bonusX2Stage4 && bonusX2Stage4 <= withAmount));
    }

    uint private bonusPeriod = 1 days;

    function countMultiplyBonus(uint256 amount) internal returns (uint) {
        if (now >= startDate && now <= startDate + bonusPeriod) {  
            return 5;
        }
        if (now > startDate + bonusPeriod && now <= startDate + 2 * bonusPeriod) {  
            return 4;
        }
        if (now > startDate + 2 * bonusPeriod && now <= startDate + 3 * bonusPeriod) {  
            return 3;
        }
        if (now > startDate + 3 * bonusPeriod && now <= startDate + 4 * bonusPeriod) {  
            return 2;
        }
        if (checkBonus(amount)) {
            return 2;
        }
        return 1;
    }

    function buyTokens() internal {
        uint256 tokens = msg.value.div(tokenPrice);
        uint256 balance = keeppetToken.balanceOf(this);
        tokens = tokens.mul(countMultiplyBonus(msg.value));

        if (balance < tokens) {
            uint256 tempTokenPrice = msg.value.div(tokens);  
            uint256 toReturn = tempTokenPrice.mul(tokens.sub(balance));  
            sendTokens(balance, msg.value - toReturn);
            msg.sender.transfer(toReturn);
            return;
        }
        sendTokens(tokens, msg.value);
    }

    function sendTokens(uint256 _amount, uint256 _ethers) internal {
        keeppetToken.sendTokens(msg.sender, _amount);
        RefundVault refundVaultContract = RefundVault(refundVault);
        stat.currentFundraiser += _amount;
        stat.ethAmount += _ethers;
        stat.txCounter += 1;
        refundVaultContract.deposit.value(_ethers)(msg.sender);
    }

    function sendTokensManually(address _to, uint256 ethAmount, uint multiplier) public onlyOwner {
        require(multiplier < 6);  
        require(_to != address(0) && now <= endDate + 3 days);  
        uint256 tokens = ethAmount.div(tokenPrice).mul(multiplier);
        keeppetToken.sendTokens(_to, tokens);
        stat.currentFundraiser += tokens;
        stat.additionalEthAmount += ethAmount;
        stat.txCounter += 1;
    }

    function checkFunds() public isFinished onlyOwner {
        RefundVault refundVaultContract = RefundVault(refundVault);
        uint256 leftValue = keeppetToken.balanceOf(this);
        keeppetToken.burn(leftValue);
        uint256 fullAmount = stat.additionalEthAmount.add(stat.ethAmount);
        if (fullAmount < softCap) {
             
            refundVaultContract.enableRefunds();
        } else {
             
            refundVaultContract.close();
        }
    }

    function unPauseToken() public onlyOwner {
        require(keeppetToken.unPause());
    }
}