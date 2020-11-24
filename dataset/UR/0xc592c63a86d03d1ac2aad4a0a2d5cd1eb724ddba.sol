 

pragma solidity ^0.4.17;

 
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

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = true;


   
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

contract Token {
    uint256 public totalSupply;

    function balanceOf(address who) public constant returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    function allowance(address owner, address spender) public constant returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract StandardToken is Token, Pausable {

    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) allowed;


    mapping (address => uint256) balances;

     
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

        uint256 _allowance = allowed[_from][msg.sender];
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue)
    returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue)
    returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        }
        else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract Status {
    uint256 public endTimeTwo = 1512072000;  
    uint public weiRaised;

    function hasEnded() public constant returns (bool) {
        return now > endTimeTwo;
    }
}

contract FinalizableCrowdsale is Ownable, Status {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() onlyOwner  public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
  }
}

contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public escrow;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  function RefundVault(address _escrow) {
    require(_escrow != 0x0);
    escrow = _escrow;
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
    escrow.transfer(this.balance);
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

contract RefundableCrowdsale is FinalizableCrowdsale {
  using SafeMath for uint256;

   
  uint256 public goal = 5000 ether;

   
  RefundVault public vault;

  function RefundableCrowdsale(address _escrow) {
    vault = new RefundVault(_escrow);
  }

   
   
   
  function forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

   
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());

    vault.refund(msg.sender);
  }

   
  function finalization() internal {
    if (goalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }

    super.finalization();
  }

  function goalReached() public constant returns (bool) {
    return weiRaised >= goal;
  }

}

contract LCD is StandardToken, Status, RefundableCrowdsale {

    string public constant name = "LCD Token";
    string public constant symbol = "LCD";
    uint256 public constant decimals = 2;
    uint256 public constant tokenCreationCap = 100000000 * 10 ** decimals;
    uint256 public constant tokenCreationCapOne = 75000000 * 10 ** decimals;
    address public escrow;
     
       uint256 public startTimeOne = 1508140800;  
    uint256 public endTimeOne = 1509433200;  
    uint256 public startTimeTwo = 1509480000;  
    uint256 public oneTokenInWei = 781250000000000;
    Stage public currentStage = Stage.Two;

    event CreateLCD(address indexed _to, uint256 _value);
    event PriceChanged(string _text, uint _newPrice);

    function LCD (address _escrow) FinalizableCrowdsale() RefundableCrowdsale(_escrow)
    {
        escrow = _escrow;
        balances[escrow] = 50000000 * 10 ** decimals;
        totalSupply = balances[escrow];
    }

    enum Stage {
        One,
        Two
    }

    function () payable {
        createTokens();
    }

    function createTokens() internal {
        uint multiplier = 10 ** decimals;
        if (now >= startTimeOne && now <= endTimeOne) {
            uint256 tokens = msg.value.div(oneTokenInWei) * multiplier;
            uint256 checkedSupply = totalSupply.add(tokens);
            if(checkedSupply <= tokenCreationCapOne) {
                addTokens(tokens, 40);
                updateStage();
            }
        } else if (currentStage == Stage.Two || now >= startTimeTwo && now <= endTimeTwo) {
            tokens = msg.value.div(oneTokenInWei) * multiplier;
            checkedSupply = totalSupply.add(tokens);
            if (checkedSupply <= tokenCreationCap) {
                addTokens(tokens, 0);
            }
        } else {
            revert();
        }
    }

    function updateStage() internal {
        if (totalSupply >= tokenCreationCapOne) {
            currentStage = Stage.Two;
        }
    }

    function addTokens(uint256 tokens, uint sale) internal {
        if (sale > 0) {
            tokens += tokens / 100 * sale;
        }
        balances[msg.sender] += tokens;
        totalSupply = totalSupply.add(tokens);
        weiRaised += msg.value;
        CreateLCD(msg.sender, tokens);
        forwardFunds();
    }

    function setTokenPrice(uint256 _tokenPrice) external onlyOwner {
        oneTokenInWei = _tokenPrice;
        PriceChanged("New price is", _tokenPrice);
    }

    function changeStageTwo() external onlyOwner {
        currentStage = Stage.Two;
    }

    function destroy() onlyOwner external {
       selfdestruct(escrow);
    }
}