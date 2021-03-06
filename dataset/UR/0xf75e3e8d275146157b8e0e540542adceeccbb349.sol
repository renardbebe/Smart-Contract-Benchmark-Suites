 

pragma solidity ^0.4.21;

 

 
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

 

 
contract Contactable is Ownable {

  string public contactInformation;

   
  function setContactInformation(string info) onlyOwner public {
    contactInformation = info;
  }
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

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

 

contract RootsSaleToken is Contactable, MintableToken {

    string constant public name = "ROOTS Sale Token";
    string constant public symbol = "ROOTSSale";
    uint constant public decimals = 18;

    bool public isTransferable = false;

    function transfer(address _to, uint _value) public returns (bool) {
        require(isTransferable);
        return false;
    }

    function transfer(address _to, uint _value, bytes _data) public returns (bool) {
        require(isTransferable);
        return false;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require(isTransferable);
        return false;
    }

    function transferFrom(address _from, address _to, uint _value, bytes _data) public returns (bool) {
        require(isTransferable);
        return false;
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

 

contract RootsSale is Pausable {
  using SafeMath for uint256;

   
  RootsSaleToken public token;

   
  uint public startTime;
  uint public endTime;

   
  address public wallet;

   
  uint public rate;

   
  uint public weiRaised;

   
  uint public tokensSold;

   
  uint public weiMaximumGoal;

   
  uint public weiMinimumAmount;

   
  uint public weiMaximumAmount;

   
  uint public buyerCount;

   
  mapping (address => uint) public boughtAmountOf;

   
  mapping (address => bool) public isBuyer;

   
  mapping (address => bool) public isExternalBuyer;

  address public admin;

   
  event TokenPurchase(
      address indexed purchaser,
      address indexed beneficiary,
      uint value,
      uint tokenAmount
  );

  function RootsSale(
      uint _startTime,
      uint _endTime,
      uint _rate,
      RootsSaleToken _token,
      address _wallet,
      uint _weiMaximumGoal,
      uint _weiMinimumAmount,
      uint _weiMaximumAmount,
      address _admin
  ) public
  {
      require(_startTime >= now);
      require(_endTime >= _startTime);
      require(_rate > 0);
      require(address(_token) != 0x0);
      require(_wallet != 0x0);
      require(_weiMaximumGoal > 0);
      require(_admin != 0x0);

      startTime = _startTime;
      endTime = _endTime;
      token = _token;
      rate = _rate;
      wallet = _wallet;
      weiMaximumGoal = _weiMaximumGoal;
      weiMinimumAmount = _weiMinimumAmount;
      weiMaximumAmount = _weiMaximumAmount;
      admin = _admin;
  }


  modifier onlyOwnerOrAdmin() {
      require(msg.sender == owner || msg.sender == admin);
      _;
  }

   
  function () external payable {
      buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public whenNotPaused payable returns (bool) {
      uint weiAmount = msg.value;

      require(beneficiary != 0x0);
      require(weiAmount >= weiMinimumAmount);
      require(weiAmount <= weiMaximumAmount);
      require(validPurchase(msg.value));

       
      uint tokenAmount = calculateTokenAmount(weiAmount, weiRaised);

      mintTokenToBuyer(beneficiary, tokenAmount, weiAmount);

      wallet.transfer(msg.value);

      return true;
  }

  function mintTokenToBuyer(address beneficiary, uint tokenAmount, uint weiAmount) internal {
      if (!isBuyer[beneficiary]) {
           
          buyerCount++;
          isBuyer[beneficiary] = true;
      }

      boughtAmountOf[beneficiary] = boughtAmountOf[beneficiary].add(weiAmount);
      weiRaised = weiRaised.add(weiAmount);
      tokensSold = tokensSold.add(tokenAmount);

      token.mint(beneficiary, tokenAmount);
      TokenPurchase(msg.sender, beneficiary, weiAmount, tokenAmount);
  }

   
  function validPurchase(uint weiAmount) internal constant returns (bool) {
      bool withinPeriod = now >= startTime && now <= endTime;
      bool withinCap = weiRaised.add(weiAmount) <= weiMaximumGoal;

      return withinPeriod && withinCap;
  }

   
  function hasEnded() public constant returns (bool) {
      bool capReached = weiRaised >= weiMaximumGoal;
      bool afterEndTime = now > endTime;

      return capReached || afterEndTime;
  }

   
  function getWeiLeft() external constant returns (uint) {
      return weiMaximumGoal - weiRaised;
  }

   
  function setPricingStrategy(
    uint _startTime,
    uint _endTime,
    uint _rate,
    uint _weiMaximumGoal,
    uint _weiMinimumAmount,
    uint _weiMaximumAmount
)  external onlyOwner returns (bool) {
    require(!hasEnded());
    require(_endTime >= _startTime);
    require(_weiMaximumGoal > 0);

    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    weiMaximumGoal = _weiMaximumGoal;
    weiMinimumAmount = _weiMinimumAmount;
    weiMaximumAmount = _weiMaximumAmount;
    return true;
  }

  function registerPayment(address beneficiary, uint tokenAmount, uint weiAmount) public onlyOwnerOrAdmin {
      require(validPurchase(weiAmount));
      isExternalBuyer[beneficiary] = true;
      mintTokenToBuyer(beneficiary, tokenAmount, weiAmount);
  }

  function registerPayments(address[] beneficiaries, uint[] tokenAmounts, uint[] weiAmounts) external onlyOwnerOrAdmin {
      require(beneficiaries.length == tokenAmounts.length);
      require(tokenAmounts.length == weiAmounts.length);

      for (uint i = 0; i < beneficiaries.length; i++) {
          registerPayment(beneficiaries[i], tokenAmounts[i], weiAmounts[i]);
      }
  }

  function setAdmin(address adminAddress) external onlyOwner {
      admin = adminAddress;
  }

   
  function calculateTokenAmount(uint weiAmount, uint weiRaised) public view returns (uint tokenAmount) {
      return weiAmount.mul(rate);
  }

  function changeTokenOwner(address newOwner) external onlyOwner {
      require(newOwner != 0x0);
      require(hasEnded());

      token.transferOwnership(newOwner);
  }

  function finishMinting() public onlyOwnerOrAdmin {
      require(hasEnded());

      token.finishMinting();
  }


}