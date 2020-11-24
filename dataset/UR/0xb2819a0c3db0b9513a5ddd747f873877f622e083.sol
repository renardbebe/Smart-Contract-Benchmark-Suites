 

pragma solidity 0.4.20;

 
contract Ownable {
  address public owner;
  uint public totalSupply = 0;

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require (msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


 
contract Authorizable {
 
  address[] authorizers;
  mapping(address => uint256) authorizerIndex;
 
   
  modifier onlyAuthorized {
    require(isAuthorized(msg.sender));
    _;
  }
 
   
  function Authorizable() public {
    authorizers.length = 2;
    authorizers[1] = msg.sender;
    authorizerIndex[msg.sender] = 1;
  }
 
   
  function getAuthorizer(uint256 authIndex) external constant returns(address) {
    return address(authorizers[authIndex + 1]);
  }
 
   
  function isAuthorized(address _addr) public constant returns(bool) {
    return authorizerIndex[_addr] > 0;
  }
 
   
  function addAuthorized(address _addr) external onlyAuthorized {
    authorizerIndex[_addr] = authorizers.length;
    authorizers.length++;
    authorizers[authorizers.length - 1] = _addr;
  }
}


 
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

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


 
contract ERC20Basic {
  function balanceOf(address who) public constant returns (uint);
  function transfer(address to, uint value) public;
  event Transfer(address indexed from, address indexed to, uint value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint);
  function transferFrom(address from, address to, uint value) public;
  function approve(address spender, uint value) public;
  event Approval(address indexed owner, address indexed spender, uint value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint;
  mapping(address => uint) public balances;

   
  modifier onlyPayloadSize(uint size) {
     require(msg.data.length >= size + 4);
     _;
  }

   
  function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

   
  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }

}


 
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;

   
  function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) {
    uint _allowance = allowed[_from][msg.sender];
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint _value) public {

     
     
     
     
     
    require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint value);
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

   
  function finishMinting() public onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


 
contract RecToken is MintableToken {
  string public standard = "Renta.City";
  string public name = "Renta.City";
  string public symbol = "REC";
  uint public decimals = 18;
  address public saleAgent;

  bool public tradingStarted = false;

   
  modifier hasStartedTrading() {
    require(tradingStarted);
    _;
  }

   
  function startTrading() public onlyOwner {
    tradingStarted = true;
  }

   
  function transfer(address _to, uint _value) public hasStartedTrading {
    super.transfer(_to, _value);
  }

    
  function transferFrom(address _from, address _to, uint _value) public hasStartedTrading {
    super.transferFrom(_from, _to, _value);
  }
  
  function set_saleAgent(address _value) public onlyOwner {
    saleAgent = _value;
  }
}


 
contract MainSale is Ownable, Authorizable {
  using SafeMath for uint;
  event TokenSold(address recipient, uint ether_amount, uint pay_amount, uint exchangerate);
  event AuthorizedCreate(address recipient, uint pay_amount);
  event MainSaleClosed();

  RecToken public token = new RecToken();

  address public multisigVault;
  mapping(address => uint) public balances;

  uint public hardcap = 100000 ether;
  uint public altDeposits = 0;
  uint public start = 1519862400; 
  uint public rate = 1000000000000000000000;
  bool public isRefund = false;

  uint public stage_Days = 30 days;
  uint public stage_Discount = 0;

  uint public commandPercent = 10;
  uint public refererPercent = 2;
  uint public bountyPercent = 2;

  uint public maxBountyTokens = 0;
  uint public maxTokensForCommand = 0;
  uint public issuedBounty = 0;			 
  uint public issuedTokensForCommand = 0;        

   
  modifier saleIsOn() {
    require(now > start && now < start + stage_Days);
    _;
  }

   
  modifier isUnderHardCap() {
    require(multisigVault.balance + altDeposits <= hardcap);
    _;
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

   
  function set_stage_Days(uint _value) public onlyOwner {
    stage_Days = _value * 1 days;
  }

  function set_stage_Discount(uint _value) public onlyOwner {
    stage_Discount = _value;
  }

  function set_commandPercent(uint _value) public onlyOwner {
    commandPercent = _value;
  }

  function set_refererPercent(uint _value) public onlyOwner {
    refererPercent = _value;
  }

  function set_bountyPercent(uint _value) public onlyOwner {
    bountyPercent = _value;
  }

  function set_Rate(uint _value) public onlyOwner {
    rate = _value * 1 ether;
  }
  
   
  function createTokens(address recipient) public isUnderHardCap saleIsOn payable {
    require(msg.value >= 0.01 ether);
    
     
    uint CurrentDiscount = 0;
    if (now > start && now < (start + stage_Days)) {CurrentDiscount = stage_Discount;}
    
     
    uint tokens = rate.mul(msg.value).div(1 ether);
    tokens = tokens + tokens.mul(CurrentDiscount).div(100);
    token.mint(recipient, tokens);
    balances[msg.sender] = balances[msg.sender].add(msg.value);
    maxBountyTokens = token.totalSupply().mul(bountyPercent).div(100-bountyPercent).div(1 ether);
    maxTokensForCommand = token.totalSupply().mul(commandPercent).div(100-commandPercent).div(1 ether);
    
    require(multisigVault.send(msg.value));
    TokenSold(recipient, msg.value, tokens, rate);

     
    address referer = 0x0;
    if(msg.data.length == 20) {
        referer = bytesToAddress(bytes(msg.data));
        require(referer != msg.sender);
        uint refererTokens = tokens.mul(refererPercent).div(100);
        if (referer != 0x0 && refererTokens > 0) {
    	    token.mint(referer, refererTokens);
    	    maxBountyTokens = token.totalSupply().mul(bountyPercent).div(100-bountyPercent).div(1 ether);
    	    maxTokensForCommand = token.totalSupply().mul(commandPercent).div(100-commandPercent).div(1 ether);
    	    TokenSold(referer, 0, refererTokens, rate);
        }
    }
  }

   
  function mintTokensForCommand(address recipient, uint tokens) public onlyOwner returns (bool){
    maxTokensForCommand = token.totalSupply().mul(commandPercent).div(100-commandPercent).div(1 ether);
    if (tokens <= (maxTokensForCommand - issuedTokensForCommand)) {
        token.mint(recipient, tokens * 1 ether);
	issuedTokensForCommand = issuedTokensForCommand + tokens;
        maxTokensForCommand = token.totalSupply().mul(commandPercent).div(100-commandPercent).div(1 ether);
        TokenSold(recipient, 0, tokens * 1 ether, rate);
        return(true);
    }
    else {return(false);}
  }

   
  function mintBounty(address recipient, uint tokens) public onlyOwner returns (bool){
    maxBountyTokens = token.totalSupply().mul(bountyPercent).div(100-bountyPercent).div(1 ether);
    if (tokens <= (maxBountyTokens - issuedBounty)) {
        token.mint(recipient, tokens * 1 ether);
	issuedBounty = issuedBounty + tokens;
        maxBountyTokens = token.totalSupply().mul(bountyPercent).div(100-bountyPercent).div(1 ether);
        TokenSold(recipient, 0, tokens * 1 ether, rate);
        return(true);
    }
    else {return(false);}
  }

  function refund() public {
      require(isRefund);
      uint value = balances[msg.sender]; 
      balances[msg.sender] = 0; 
      msg.sender.transfer(value); 
    }

  function startRefund() public onlyOwner {
      isRefund = true;
    }

  function stopRefund() public onlyOwner {
      isRefund = false;
    }

   
  function setAltDeposit(uint totalAltDeposits) public onlyOwner {
    altDeposits = totalAltDeposits;
  }

   
  function setHardCap(uint _hardcap) public onlyOwner {
    hardcap = _hardcap;
  }

   
  function setStart(uint _start) public onlyOwner {
    start = _start;
  }

   
  function setMultisigVault(address _multisigVault) public onlyOwner {
    if (_multisigVault != address(0)) {
      multisigVault = _multisigVault;
    }
  }

   
  function finishMinting() public onlyOwner {
    uint issuedTokenSupply = token.totalSupply();
    uint restrictedTokens = issuedTokenSupply.mul(commandPercent).div(100-commandPercent);
    token.mint(multisigVault, restrictedTokens);
    token.finishMinting();
    token.transferOwnership(owner);
    MainSaleClosed();
  }

   
  function retrieveTokens(address _token) public payable {
    require(msg.sender == owner);
    ERC20 erctoken = ERC20(_token);
    erctoken.transfer(multisigVault, erctoken.balanceOf(this));
  }

   
  function() external payable {
    createTokens(msg.sender);
  }

}