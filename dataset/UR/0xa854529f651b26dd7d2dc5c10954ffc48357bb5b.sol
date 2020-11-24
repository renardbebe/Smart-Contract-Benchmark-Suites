 

pragma solidity ^0.4.18;

 

interface IPricingStrategy {

    function isPricingStrategy() public view returns (bool);

     
    function calculateTokenAmount(uint weiAmount, uint tokensSold) public view returns (uint tokenAmount);

}

 

contract ERC223 {
    function transfer(address _to, uint _value, bytes _data) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

 

 
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

 

 
contract Contactable is Ownable{

    string public contactInformation;

     
    function setContactInformation(string info) onlyOwner public {
         contactInformation = info;
     }
}

 

 
contract ERC20Basic {
  uint256 public totalSupply;
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

 

contract MintableToken is ERC20, Contactable {
    using SafeMath for uint;

    mapping (address => uint) balances;
    mapping (address => uint) public holderGroup;
    bool public mintingFinished = false;
    address public minter;

    event MinterChanged(address indexed previousMinter, address indexed newMinter);
    event Mint(address indexed to, uint amount);
    event MintFinished();

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier onlyMinter() {
        require(msg.sender == minter);
        _;
    }

       
    function mint(address _to, uint _amount, uint _holderGroup) onlyMinter canMint public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        holderGroup[_to] = _holderGroup;
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

     
    function finishMinting() onlyMinter canMint public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

    function changeMinter(address _minter) external onlyOwner {
        require(_minter != 0x0);
        MinterChanged(minter, _minter);
        minter = _minter;
    }
}

 

 
 
 contract TokenReciever {
    function tokenFallback(address _from, uint _value, bytes _data) public pure {
    }
}

 

contract HeroCoin is ERC223, MintableToken {
    using SafeMath for uint;

    string constant public name = "HeroCoin";
    string constant public symbol = "HRO";
    uint constant public decimals = 18;

    mapping(address => mapping (address => uint)) internal allowed;

    mapping (uint => uint) public activationTime;

    modifier activeForHolder(address holder) {
        uint group = holderGroup[holder];
        require(activationTime[group] <= now);
        _;
    }

     
    function transfer(address _to, uint _value) public returns (bool) {
        bytes memory empty;
        return transfer(_to, _value, empty);
    }

     
    function transfer(address _to, uint _value, bytes _data) public activeForHolder(msg.sender) returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        if (isContract(_to)) {
            TokenReciever receiver = TokenReciever(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }

        Transfer(msg.sender, _to, _value);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

     
    function transferFrom(address _from, address _to, uint _value) activeForHolder(_from) public returns (bool) {
        bytes memory empty;
        return transferFrom(_from, _to, _value, empty);
    }

     
    function transferFrom(address _from, address _to, uint _value, bytes _data) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        if (isContract(_to)) {
            TokenReciever receiver = TokenReciever(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }

        Transfer(_from, _to, _value);
        Transfer(_from, _to, _value, _data);
        return true;
    }

     
    function approve(address _spender, uint _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint) {
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

    function setActivationTime(uint _holderGroup, uint _activationTime) external onlyOwner {
        activationTime[_holderGroup] = _activationTime;
    }

    function setHolderGroup(address _holder, uint _holderGroup) external onlyOwner {
        holderGroup[_holder] = _holderGroup;
    }

    function isContract(address _addr) private view returns (bool) {
        uint length;
        assembly {
               
              length := extcodesize(_addr)
        }
        return (length>0);
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

 

contract SaleBase is Pausable, Contactable {
    using SafeMath for uint;
  
     
    HeroCoin public token;
  
     
    uint public startTime;
    uint public endTime;
  
     
    address public wallet;
  
     
    IPricingStrategy public pricingStrategy;
  
     
    uint public weiRaised;

     
    uint public tokensSold;

     
    uint public weiMaximumGoal;

     
    uint public weiMinimumGoal;

     
    uint public weiMinimumAmount;

     
    uint public buyerCount;

     
    uint public loadedRefund;

     
    uint public weiRefunded;

     
    mapping (address => uint) public boughtAmountOf;

     
    function holderGroupNumber() pure returns (uint) {
        return 0;
    }

     
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint value,
        uint tokenAmount
    );

     
    event Refund(address buyer, uint weiAmount);

    function SaleBase(
        uint _startTime,
        uint _endTime,
        IPricingStrategy _pricingStrategy,
        HeroCoin _token,
        address _wallet,
        uint _weiMaximumGoal,
        uint _weiMinimumGoal,
        uint _weiMinimumAmount
    ) public
    {
        require(_pricingStrategy.isPricingStrategy());
        require(address(_token) != 0x0);
        require(_wallet != 0x0);
        require(_weiMaximumGoal > 0);

        setStartTime(_startTime);
        setEndTime(_endTime);
        pricingStrategy = _pricingStrategy;
        token = _token;
        wallet = _wallet;
        weiMaximumGoal = _weiMaximumGoal;
        weiMinimumGoal = _weiMinimumGoal;
        weiMinimumAmount = _weiMinimumAmount;
    }

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) public whenNotPaused payable returns (bool) {
        uint weiAmount = msg.value;

        require(beneficiary != 0x0);
        require(validPurchase(weiAmount));
    
         
        uint tokenAmount = pricingStrategy.calculateTokenAmount(weiAmount, tokensSold);
        
        mintTokenToBuyer(beneficiary, tokenAmount, weiAmount);
        
        wallet.transfer(msg.value);

        return true;
    }

    function mintTokenToBuyer(address beneficiary, uint tokenAmount, uint weiAmount) internal {
        if (boughtAmountOf[beneficiary] == 0) {
             
            buyerCount++;
        }

        boughtAmountOf[beneficiary] = boughtAmountOf[beneficiary].add(weiAmount);
        weiRaised = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokenAmount);
    
        token.mint(beneficiary, tokenAmount, holderGroupNumber());
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokenAmount);
    }

     
    function validPurchase(uint weiAmount) internal constant returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool withinCap = weiRaised.add(weiAmount) <= weiMaximumGoal;
        bool moreThenMinimum = weiAmount >= weiMinimumAmount;

        return withinPeriod && withinCap && moreThenMinimum;
    }

     
    function hasEnded() external constant returns (bool) {
        bool capReached = weiRaised >= weiMaximumGoal;
        bool afterEndTime = now > endTime;
        
        return capReached || afterEndTime;
    }

     
    function getWeiLeft() external constant returns (uint) {
        return weiMaximumGoal - weiRaised;
    }

     
    function isMinimumGoalReached() public constant returns (bool) {
        return weiRaised >= weiMinimumGoal;
    }
    
     
    function setPricingStrategy(IPricingStrategy _pricingStrategy) external onlyOwner returns (bool) {
        pricingStrategy = _pricingStrategy;
        return true;
    }

     
    function loadRefund() external payable {
        require(msg.value > 0);
        require(!isMinimumGoalReached());
        
        loadedRefund = loadedRefund.add(msg.value);
    }

     
    function refund() external {
        require(!isMinimumGoalReached() && loadedRefund > 0);
        uint256 weiValue = boughtAmountOf[msg.sender];
        require(weiValue > 0);
        
        boughtAmountOf[msg.sender] = 0;
        weiRefunded = weiRefunded.add(weiValue);
        Refund(msg.sender, weiValue);
        msg.sender.transfer(weiValue);
    }

    function setStartTime(uint _startTime) public onlyOwner {
        require(_startTime >= now);
        startTime = _startTime;
    }

    function setEndTime(uint _endTime) public onlyOwner {
        require(_endTime >= startTime);
        endTime = _endTime;
    }
}

 

 
contract Presale is SaleBase {
    function Presale(
        uint _startTime,
        uint _endTime,
        IPricingStrategy _pricingStrategy,
        HeroCoin _token,
        address _wallet,
        uint _weiMaximumGoal,
        uint _weiMinimumGoal,
        uint _weiMinimumAmount
    ) public SaleBase(
        _startTime,
        _endTime,
        _pricingStrategy,
        _token,
        _wallet,
        _weiMaximumGoal,
        _weiMinimumGoal,
        _weiMinimumAmount) 
    {

    }

    function holderGroupNumber() public pure returns (uint) {
        return 1;
    }
}