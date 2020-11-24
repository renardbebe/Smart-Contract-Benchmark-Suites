 

pragma solidity ^0.4.24;
 
 
 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract ERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value)
    public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function burn(uint256 _value)
    public returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );

  event Burn(
    address indexed burner,
    uint256 value
  );

}

library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0);  
    uint256 c = _a / _b;
     

    return c;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract LoligoToken is ERC20, Ownable {
  using SafeMath for uint256;

  string public constant name = "Loligo Token";
  string public constant symbol = "LLG";
  uint8 public constant decimals = 18;
  uint256 private totalSupply_ = 16000000 * (10 ** uint256(decimals));
  bool public locked = true;
  mapping (address => uint256) private balances;

  mapping (address => mapping (address => uint256)) private allowed;

  modifier onlyWhenUnlocked() {
    require(!locked || msg.sender == owner);
    _;
  }

  constructor() public {
      balances[msg.sender] = totalSupply_;
  }
   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function transfer(address _to, uint256 _value) public onlyWhenUnlocked returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    onlyWhenUnlocked
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function burn(uint256 _value) public returns (bool success){
    require(_value > 0);
    require(_value <= balances[msg.sender]);
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(burner, _value);
    return true;
  }

  function unlock() public onlyOwner {
    locked = false;
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

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

contract Whitelist is Ownable{

   
  mapping(address => bool) public whitelist;
   
  event LogAddedBeneficiary(address indexed _beneficiary);
  event LogRemovedBeneficiary(address indexed _beneficiary);

   
  function addManyToWhitelist(address[] _beneficiaries) public onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
      emit LogAddedBeneficiary(_beneficiaries[i]);
    }
  }

   
  function removeFromWhitelist(address _beneficiary) public onlyOwner {
    whitelist[_beneficiary] = false;
    emit LogRemovedBeneficiary(_beneficiary);
  }

  function isWhitelisted(address _beneficiary) public view returns (bool) {
    return (whitelist[_beneficiary]);
  }

}

contract TokenBonus is Ownable {
    using SafeMath for uint256;

    address public owner;
    mapping (address => uint256) public bonusBalances;    
    address[] public bonusList;
    uint256 public savedBonusToken;

    constructor() public {
        owner = msg.sender;
    }

    function distributeBonusToken(address _token, uint256 _percent) public onlyOwner {
        for (uint256 i = 0; i < bonusList.length; i++) {
            require(LoligoToken(_token).balanceOf(address(this)) >= savedBonusToken);

            uint256 amountToTransfer = bonusBalances[bonusList[i]].mul(_percent).div(100);
            bonusBalances[bonusList[i]] = bonusBalances[bonusList[i]].sub(amountToTransfer);
            savedBonusToken = savedBonusToken.sub(amountToTransfer);
            LoligoToken(_token).transfer(bonusList[i], amountToTransfer);
        }
    }
}

contract Presale is Pausable, Whitelist, TokenBonus {
    using SafeMath for uint256;

     
    address private wallet = 0xE2a5B96B6C1280cfd93b57bcd3fDeAf73691D3f3;      

     
    LoligoToken public token;

     
    uint256 public presaleRate;                                           
    uint256 public totalTokensForPresale;                                 
    bool public presale1;                                                 
    bool public presale2;                                                 

     
    uint256 public savedBalance;                                         
    uint256 public savedPresaleTokenBalance;                             
    mapping (address => uint256) balances;                               

     
    event Contribution(address indexed _contributor, uint256 indexed _value, uint256 indexed _tokens);      
    event PayEther(address indexed _receiver, uint256 indexed _value, uint256 indexed _timestamp);          
    event BurnTokens(uint256 indexed _value, uint256 indexed _timestamp);                                   


     
    constructor(address _token) public {
         
        token = LoligoToken(_token);
    }


     
    function () external payable whenNotPaused {
        _buyPresaleTokens(msg.sender);
    }
    
     
    function _buyPresaleTokens(address _beneficiary) public payable  {
        require(presale1 || presale2);
        require(msg.value >= 0.25 ether);
        require(isWhitelisted(_beneficiary));
        require(savedPresaleTokenBalance.add(_getTokensAmount(msg.value)) <= totalTokensForPresale);

        if (msg.value >= 10 ether) {
          _deliverBlockedTokens(_beneficiary);
        }else {
          _deliverTokens(_beneficiary);
        }
    }

     

     
    function startPresale(uint256 _rate, uint256 _totalTokensForPresale) public onlyOwner {
        require(_rate != 0 && _totalTokensForPresale != 0);
        presaleRate = _rate;
        totalTokensForPresale = _totalTokensForPresale;
        presale1 = true;
        presale2 = false;
    }

     
    function updatePresale() public onlyOwner {
        require(presale1);
        presale1 = false;
        presale2 = true;
    }

     
    function closePresale() public onlyOwner {
        require(presale2 || presale1);
        presale1 = false;
        presale2 = false;
    }

     
    function transferTokenOwnership(address _newOwner) public onlyOwner {
        token.transferOwnership(_newOwner);
    }

     
    function transferToken(address _crowdsale) public onlyOwner {
        require(!presale1 && !presale2);
        require(token.balanceOf(address(this)) > savedBonusToken);
        uint256 tokensToTransfer =  token.balanceOf(address(this)).sub(savedBonusToken);
        token.transfer(_crowdsale, tokensToTransfer);
    }
     

    function _deliverBlockedTokens(address _beneficiary) internal {
        uint256 tokensAmount = msg.value.mul(presaleRate);
        uint256 bonus = tokensAmount.mul(_checkPresaleBonus(msg.value)).div(100);

        savedPresaleTokenBalance = savedPresaleTokenBalance.add(tokensAmount.add(bonus));
        token.transfer(_beneficiary, tokensAmount);
        savedBonusToken = savedBonusToken.add(bonus);
        bonusBalances[_beneficiary] = bonusBalances[_beneficiary].add(bonus);
        bonusList.push(_beneficiary);
        wallet.transfer(msg.value);
        emit PayEther(wallet, msg.value, now);
    }

    function _deliverTokens(address _beneficiary) internal {
      uint256 tokensAmount = msg.value.mul(presaleRate);
      uint256 tokensToTransfer = tokensAmount.add((tokensAmount.mul(_checkPresaleBonus(msg.value))).div(100));

      savedPresaleTokenBalance = savedPresaleTokenBalance.add(tokensToTransfer);
      token.transfer(_beneficiary, tokensToTransfer);
      wallet.transfer(msg.value);
      emit PayEther(wallet, msg.value, now);
    }

    function _checkPresaleBonus(uint256 _value) internal view returns (uint256){
        if(presale1 && _value >= 0.25 ether){
          return 40;
        }else if(presale2 && _value >= 0.25 ether){
          return 30;
        }else{
          return 0;
        }
    }

    function _getTokensAmount(uint256 _value) internal view returns (uint256){
       uint256 tokensAmount = _value.mul(presaleRate);
       uint256 tokensToTransfer = tokensAmount.add((tokensAmount.mul(_checkPresaleBonus(_value))).div(100));
       return tokensToTransfer;
    }
}