 

pragma solidity ^0.4.21;

 

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
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

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

 
contract PoolPartyToken is Ownable {
  using SafeMath for uint256;

  struct HOLDers {
    address HOLDersAddress;
  }

  HOLDers[] public HOLDersList;

  function _alreadyInList(address _thisHODLer) internal view returns(bool HolderinList) {

    bool result = false;
    for (uint256 r = 0; r < HOLDersList.length; r++) {
      if (HOLDersList[r].HOLDersAddress == _thisHODLer) {
        result = true;
        break;
      }
    }
    return result;
  }

   
  function AddHOLDer(address _thisHODLer) internal {

    if (_alreadyInList(_thisHODLer) == false) {
      HOLDersList.push(HOLDers(_thisHODLer));
    }
  }

  function UpdateHOLDer(address _currentHODLer, address _newHODLer) internal {

    for (uint256 r = 0; r < HOLDersList.length; r++){
       
      if (HOLDersList[r].HOLDersAddress == _currentHODLer) {
         
        HOLDersList[r].HOLDersAddress = _newHODLer;
      }
    }
  }
}

 
contract BasicToken is PoolPartyToken, ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  bool public transferEnabled;     

  modifier openBarrier() {
      require(transferEnabled || msg.sender == owner);
      _;
  }

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) openBarrier public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);

     
    UpdateHOLDer(msg.sender, _to);

    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
}

 
contract PoolPartyPayRoll is BasicToken {
  using SafeMath for uint256;

  mapping (address => uint256) PayRollCount;

   
  function _HOLDersPayRoll() onlyOwner public {

    uint256 _amountToPay = address(this).balance;
    uint256 individualPayRoll = _amountToPay.div(uint256(HOLDersList.length));

    for (uint256 r = 0; r < HOLDersList.length; r++){
       
      address HODLer = HOLDersList[r].HOLDersAddress;
      HODLer.transfer(individualPayRoll);
       
      PayRollCount[HOLDersList[r].HOLDersAddress] = PayRollCount[HOLDersList[r].HOLDersAddress].add(1);
    }
  }

  function PayRollHistory(address _thisHODLer) external view returns (uint256) {

    return uint256(PayRollCount[_thisHODLer]);
  }
}

 
contract StandardToken is PoolPartyPayRoll, ERC20 {

  mapping (address => mapping (address => uint256)) internal allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) openBarrier public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);

     
    UpdateHOLDer(msg.sender, _to);

    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}

 
contract MintableToken is StandardToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint external returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);

     
    AddHOLDer(_to);

    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint external returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function recoverERC20Token_SendbyMistake(ERC20Basic missing_token) external onlyOwner {
    uint256 balance = missing_token.balanceOf(this);
    missing_token.safeTransfer(owner, balance);
  }
}

 
contract HasEther is Ownable {

   
  function() public payable {
  }

   
  function recoverETH_SendbyMistake() external onlyOwner {
     
    assert(owner.send(address(this).balance));
  }
}

 
contract HasNoContracts is Ownable {

   
  function reclaimChildOwnership(address contractAddr) public onlyOwner {
    Ownable contractInst = Ownable(contractAddr);
    contractInst.transferOwnership(owner);
  }
}

 
contract IRONtoken is MintableToken, CanReclaimToken, HasEther, HasNoContracts {

  string public constant name = "iron Bank Network token";  
  string public constant symbol = "IRON";  
  uint8 public constant decimals = 18;  

  function IRONtoken() public {
  }

  function setBarrierAsOpen(bool enable) onlyOwner public {
       
      transferEnabled = enable;
  }
}

 
contract IRONtokenSale is PoolPartyToken, CanReclaimToken, HasNoContracts {
    using SafeMath for uint256;

    IRONtoken public token;

    struct Round {
        uint256 start;           
        uint256 end;             
        uint256 rate;            
    }

    Round[] public rounds;           
    uint256 public hardCap;          
    uint256 public tokensMinted;     
    bool public finalized;           

    function IRONtokenSale (uint256 _hardCap, uint256 _initMinted) public {

      token = new IRONtoken();
      token.setBarrierAsOpen(false);
      tokensMinted = token.totalSupply();
      require(_hardCap > 0);
      hardCap = _hardCap;
      mintTokens(msg.sender, _initMinted);
    }

    function addRound(uint256 StartTimeStamp, uint256 EndTimeStamp, uint256 Rate) onlyOwner public {
      rounds.push(Round(StartTimeStamp, EndTimeStamp, Rate));
    }

     
    function saleAirdrop(address beneficiary, uint256 amount) onlyOwner external {
        mintTokens(beneficiary, amount);
    }
    
     
    function MultiplesaleAirdrop(address[] beneficiaries, uint256[] amounts) onlyOwner external {
      for (uint256 r=0; r<beneficiaries.length; r++){
        mintTokens(address(beneficiaries[r]), uint256(amounts[r]));
      }
    }
    
      
    function ironTokensaleRunning() view public returns(bool){
        return (!finalized && (tokensMinted < hardCap));
    }

    function currentTime() view public returns(uint256) {
      return uint256(block.timestamp);
    }

      
    function RoundIndex() internal returns(uint256) {
      uint256 index = 0;
      for (uint256 r=0; r<rounds.length; r++){
        if ( (rounds[r].start < uint256(block.timestamp)) && (uint256(block.timestamp) < rounds[r].end) ) {
          index = r.add(1);
        }
      }
      return index;
    }

    function currentRound() view public returns(uint256) {
      return RoundIndex();
    }

    function currentRate() view public returns(uint256) {
        uint256 thisRound = RoundIndex();
        if (thisRound != 0) {
            return uint256(rounds[thisRound.sub(1)].rate);
        } else {
            return 0;
        }
    }
    
    function _magic(uint256 _weiAmount) internal view returns (uint256) {
      uint256 tokenRate = currentRate();
      require(tokenRate > 0);
      uint256 preTransformweiAmount = tokenRate.mul(_weiAmount);
      uint256 transform = 10**18;
      uint256 TransformedweiAmount = preTransformweiAmount.div(transform);
      return TransformedweiAmount;
    }

     
    function () external payable {
      require(msg.value > 0);
      require(ironTokensaleRunning());
      uint256 weiAmount = msg.value;
      uint256 tokens = _magic(weiAmount);
      JustForward(msg.value);
      mintTokens(msg.sender, tokens);
    }

     
    function mintTokens(address beneficiary, uint256 amount) internal {
        tokensMinted = tokensMinted.add(amount);       

        require(tokensMinted <= hardCap);
        assert(token.mint(beneficiary, amount));

         
        AddHOLDer(beneficiary);
    }

    function JustForward(uint256 weiAmount) internal {
      owner.transfer(weiAmount);
    }

    function forwardCollectedEther() onlyOwner public {
        if(address(this).balance > 0){
            owner.transfer(address(this).balance);
        }
    }

     
    function finalizeTokensale() onlyOwner public {
        finalized = true;
        assert(token.finishMinting());
        token.setBarrierAsOpen(true);
        token.transferOwnership(owner);
        forwardCollectedEther();
    }
}