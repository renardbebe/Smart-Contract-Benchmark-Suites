 

pragma solidity 0.4.25;


 
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
         
         
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
    }
}


 
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string name, string symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

     
    function name() public view returns (string) {
        return _name;
    }

     
    function symbol() public view returns (string) {
        return _symbol;
    }

     
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

 
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

     
    modifier whenPaused() {
        require(_paused);
        _;
    }

     
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

 
contract ERC20Pausable is ERC20, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from,address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool success) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}


contract Airtoto is ERC20Pausable, ERC20Detailed, Ownable {
    using SafeMath for uint256;
	uint256 public constant initialSupply = 300000000 * (10 ** uint256(decimals()));
    uint256 public constant sum_bounties_wallet = initialSupply.mul(10).div(100);
    address public constant address_bounties_wallet = 0x5E4C4043A5C96FEFc61F6548FcF14Abc5a92654B;
    uint256 public constant sum_team_wallet = initialSupply.mul(20).div(100);
    address public constant address_team_wallet = 0xDeFb454cB3771C98144CbfC1359Eb7FE2bDd054B;	
    uint256 public constant sum_crowdsale = initialSupply.mul(70).div(100);
	
    constructor () public ERC20Detailed("Airtoto", "Att", 18) {
		_mint(address_bounties_wallet, sum_bounties_wallet);
		_mint(address_team_wallet, sum_team_wallet);
		_mint(msg.sender, sum_crowdsale);		
    }
	
    function transferForICO (address _to, uint256 _value) public onlyOwner{
        _transfer(msg.sender, _to, _value);
    }	
	  
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }
}

 
contract ReentrancyGuard {

   
  uint256 private _guardCounter;

  constructor() internal {
     
     
    _guardCounter = 1;
  }

   
  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }
}

contract Crowdsale is Ownable, ReentrancyGuard {

  using SafeMath for uint256;  
  
  Airtoto public token;
   
  
   
  uint256 public   startPreICOStage;
  uint256 public   endPreICOStage;
  uint256 public   startICOStage1;
  uint256 public   endICOStage1;  
  uint256 public   startICOStage2;
  uint256 public   endICOStage2; 
  uint256 public   startICOStage3;
  uint256 public   endICOStage3;  

   
  mapping(address => uint256) public balances;  
   
  uint256 public amountOfTokensSold; 
  uint256 public minimumPayment;  
   
  uint256 public valueAirDrop;
  uint8 public airdropOn;
  uint8 public referralSystemOn;
  mapping (address => uint8) public payedAddress; 
   
  uint256 public rateETHUSD;    
   
  address public wallet;

 
  event TokenProcurement(address indexed contributor, address indexed beneficiary, uint256 value, uint256 amount, address indexed referrer, uint256 amountReferrer);

  constructor() public {    
    token = createTokenContract();
	 
    rateETHUSD = 10000;  
     
     
    startPreICOStage  = 1544875200;  
    endPreICOStage    = 1546084800;  
    startICOStage1    = 1546084800;  
    endICOStage1      = 1547294400;  
    startICOStage2    = 1547294400;  
    endICOStage2      = 1550059200;  
    startICOStage3    = 1550059200;  
    endICOStage3      = 1552564800;  

     
    minimumPayment = 980000000000000000;  

     
    valueAirDrop = 1 * 1 ether;	
     
    wallet = 0xfc19e8fD7564A48b82a51d106e6D0E6098032811;
  }
  
  function setMinimumPayment(uint256 _minimumPayment) public onlyOwner{
    minimumPayment = _minimumPayment;
  } 
  function setValueAirDrop(uint256 _valueAirDrop) public onlyOwner{
    valueAirDrop = _valueAirDrop;
  } 

  function setRateIco(uint256 _rateETHUSD) public onlyOwner  {
    rateETHUSD = _rateETHUSD;
  }  
   
  function () external payable {
    buyTokens(msg.sender);
  }
  
  function createTokenContract() internal returns (Airtoto) {
    return new Airtoto();
  }
  
  function getRateTokeUSD() public view returns (uint256) {
    uint256 rate;  
    if (now >= startPreICOStage && now < endPreICOStage){
      rate = 100000;    
    }	
    if (now >= startICOStage1 && now < endICOStage1){
      rate = 100000;    
    } 
    if (now >= startICOStage2 && now < endICOStage2){
      rate = 150000;    
    }    
    if (now >= startICOStage3 && now < endICOStage3){
      rate = 200000;    
    }    	
    return rate;
  }
  
  function getRateIcoWithBonus() public view returns (uint256) {
    uint256 bonus;
    if (now >= startPreICOStage && now < endPreICOStage){
      bonus = 20;    
    }
    if (now >= startICOStage1 && now < endICOStage1){
      bonus = 15;    
    }
    if (now >= startICOStage2 && now < endICOStage2){
      bonus = 10;    
    }   
    if (now >= startICOStage3 && now < endICOStage3){
      bonus = 5;    
    }       
    return rateETHUSD + rateETHUSD.mul(bonus).div(100);
  }  
 
  function bytesToAddress(bytes source) internal pure returns(address) {
    uint result;
    uint mul = 1;
    for(uint i = 20; i > 0; i--) {
      result += uint8(source[i-1])*mul;
      mul = mul*256;
    }
    return address(result);
  }
  function setAirdropOn(uint8 _flag) public onlyOwner{
    airdropOn = _flag;
  } 
  function setReferralSystemOn(uint8 _flag) public onlyOwner{
    referralSystemOn = _flag;
  }   
  function buyTokens(address _beneficiary) public nonReentrant payable {
    uint256 tokensAmount;
    uint256 weiAmount = msg.value;
    uint256 rate;
	uint256 referrerTokens;
	uint256 restTokensAmount;
	uint256 restWeiAmount;
	address referrer; 
    address _this = this;
    uint256 rateTokenUSD;  
    require(now >= startPreICOStage);
    require(now <= endICOStage3);
	require(token.balanceOf(_this) > 0);
    require(_beneficiary != address(0));
	
	if (weiAmount == 0 && airdropOn == 1){ 
	  require(payedAddress[_beneficiary] == 0);
      payedAddress[_beneficiary] = 1;
	  token.transferForICO(_beneficiary, valueAirDrop);
	}
	else{	
	  require(weiAmount >= minimumPayment);
      rate = getRateIcoWithBonus();
	  rateTokenUSD = getRateTokeUSD();
      tokensAmount = weiAmount.mul(rate).mul(10000).div(rateTokenUSD);
	   
	  if(msg.data.length == 20 && referralSystemOn == 1) {
        referrer = bytesToAddress(bytes(msg.data));
        require(referrer != msg.sender);
	     
        referrerTokens = tokensAmount.mul(5).div(100);
	     
	    tokensAmount = tokensAmount + tokensAmount.mul(5).div(100);
      }
	   
      if (tokensAmount.add(referrerTokens) > token.balanceOf(_this)) {
	    restTokensAmount = tokensAmount.add(referrerTokens) - token.balanceOf(_this);
	    tokensAmount = token.balanceOf(_this);
	    referrerTokens = 0;
	    restWeiAmount = restTokensAmount.mul(rateTokenUSD).div(rate).div(10000);
	  }
        amountOfTokensSold = amountOfTokensSold.add(tokensAmount);
	    balances[_beneficiary] = balances[_beneficiary].add(msg.value);
	  if (referrerTokens != 0){
        token.transferForICO(referrer, referrerTokens);	  
	  }
	  if (restWeiAmount != 0){
	    _beneficiary.transfer(restWeiAmount);
		weiAmount = weiAmount.sub(restWeiAmount);
	  }
      token.transferForICO(_beneficiary, tokensAmount);
	  wallet.transfer(weiAmount);
      emit TokenProcurement(msg.sender, _beneficiary, weiAmount, tokensAmount, referrer, referrerTokens);
	}
  }
  function manualSendTokens(address _to, uint256 _value) public onlyOwner{
    address _this = this;
    require(_value > 0);
	require(_value <= token.balanceOf(_this));
    require(_to != address(0));
    amountOfTokensSold = amountOfTokensSold.add(_value);
    token.transferForICO(_to, _value);
	emit TokenProcurement(msg.sender, _to, 0, _value, address(0), 0);
  } 
  function pause() public onlyOwner{
    token.pause();
  }
  function unpause() public onlyOwner{
    token.unpause();
  }
 
}