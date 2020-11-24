 

pragma solidity 0.4.23;

 
 
 
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
    assert(b > 0);  
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

 
 
 
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    function mint(address _to, uint256 _amount) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

 
 
 
contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        require(owner == msg.sender);
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

 

contract AllstocksCrowdsale is Owned {
  using SafeMath for uint256;

   
   
  address public token;

   
  address public ethFundDeposit; 

   
  uint256 public tokenExchangeRate = 625;                         
  
   
  uint256 public tokenCreationCap =  25 * (10**6) * 10**18;  

   
  uint256 public tokenCreationMin =  25 * (10**5) * 10**18;  

   
  uint256 public _raised = 0;
  
   
  bool public isActive = false;                 
 
   
  uint256 public fundingStartTime = 0;
   
   
  uint256 public fundingEndTime = 0;

   
  bool public isFinalized = false; 
  
   
  mapping(address => uint256) public refunds;

   
  event TokenAllocated(address indexed allocator, address indexed beneficiary, uint256 amount);

  event LogRefund(address indexed _to, uint256 _value);

  constructor() public {
      tokenExchangeRate = 625;
  }

  function setup (uint256 _fundingStartTime, uint256 _fundingEndTime, address _token) onlyOwner external {
    require (isActive == false); 
    require (isFinalized == false); 			        	   
    require (msg.sender == owner);                 
    require(_fundingStartTime > 0);
    require(_fundingEndTime > 0 && _fundingEndTime > _fundingStartTime);
    require(_token != address(0));

    isFinalized = false;                           
    isActive = true;                               
    ethFundDeposit = owner;                        
    fundingStartTime = _fundingStartTime;
    fundingEndTime = _fundingEndTime;
     
    token = _token;
  }

   
  function vaultFunds() public onlyOwner {
    require(msg.sender == owner);                     
    require(_raised >= tokenCreationMin);             
    ethFundDeposit.transfer(address(this).balance);   
  }  

   
   
   

   
  function () external payable {
    buyTokens(msg.sender, msg.value);
  }

   
  function buyTokens(address _beneficiary, uint256 _value) internal {
    _preValidatePurchase(_beneficiary, _value);
     
    uint256 tokens = _getTokenAmount(_value);
     
    uint256 checkedSupply = _raised.add(tokens);
     
    require(checkedSupply <= tokenCreationCap);
    _raised = checkedSupply;
    bool mined = ERC20Interface(token).mint(_beneficiary, tokens);
    require(mined);
     
    refunds[_beneficiary] = _value.add(refunds[_beneficiary]);   
    emit TokenAllocated(this, _beneficiary, tokens);  
     
    if(_raised >= tokenCreationMin) {
      _forwardFunds();
    }
  }

   
	function setRate(uint256 _value) external onlyOwner {
    require (isActive == true);
    require(msg.sender == owner);  
     
     
    require (_value >= 500 && _value <= 1500); 
    tokenExchangeRate = _value;
  }

   
  function allocate(address _beneficiary, uint256 _value) public onlyOwner returns (bool success) {
    require (isActive == true);           
    require (_value > 0);                 
    require (msg.sender == owner);        
    require(_beneficiary != address(0));  
    uint256 checkedSupply = _raised.add(_value); 
    require(checkedSupply <= tokenCreationCap);  
    _raised = checkedSupply;
    bool sent = ERC20Interface(token).mint(_beneficiary, _value);  
    require(sent); 
    emit TokenAllocated(this, _beneficiary, _value);  
    return true;
  }

   
  function transferTokenOwnership(address _newTokenOwner) public onlyOwner {
    require(_newTokenOwner != address(0));
    require(owner == msg.sender);
    Owned(token).transferOwnership(_newTokenOwner);
  }

   
  function refund() external {
    require (isFinalized == false);   
    require (isActive == true);       
    require (now > fundingEndTime);   
    require(_raised < tokenCreationMin);   
    require(msg.sender != owner);          
     
    uint256 ethValRefund = refunds[msg.sender];
     
    require(ethValRefund > 0);
     
    refunds[msg.sender] = 0;
     
    uint256 allstocksVal = ERC20Interface(token).balanceOf(msg.sender);
     
    _raised = _raised.sub(allstocksVal);                
     
    msg.sender.transfer(ethValRefund);                  
    emit LogRefund(msg.sender, ethValRefund);           
  }

    
  function finalize() external onlyOwner {
    require (isFinalized == false);
    require(msg.sender == owner);  
    require(_raised >= tokenCreationMin);   
    require(_raised > 0);

    if (now < fundingEndTime) {     
      require(_raised >= tokenCreationCap);
    }
    else 
      require(now >= fundingEndTime);  
    
     
    transferTokenOwnership(owner);
     
    isFinalized = true;
    vaultFunds();   
  }

   
   
   

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) view internal {
    require(now >= fundingStartTime);
    require(now < fundingEndTime); 
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(tokenExchangeRate);
  }

   
  function _forwardFunds() internal {
    ethFundDeposit.transfer(msg.value);
  }
}