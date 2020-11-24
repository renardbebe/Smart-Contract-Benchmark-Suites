 

pragma solidity ^0.4.10;

 
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

 
contract SafeMath {

    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }

}

contract StandardToken is ERC20, SafeMath {

   
  modifier onlyPayloadSize(uint size) {
     require(msg.data.length >= size + 4) ;
     _;
  }


  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;

  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32)  returns (bool success){
    balances[msg.sender] = safeSubtract(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) returns (bool success) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSubtract(balances[_from], _value);
    allowed[_from][msg.sender] = safeSubtract(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require (!paused);
    _;
  }

   
  modifier whenPaused {
    require (paused) ;
    _;
  }

   
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

contract IndorseToken is SafeMath, StandardToken, Pausable {
     
    string public constant name = "Indorse Token";
    string public constant symbol = "IND";
    uint256 public constant decimals = 18;
    string public version = "1.0";

     
    address public indSaleDeposit = 0x0053B91E38B207C97CBff06f48a0f7Ab2Dd81449;
    address public indSeedDeposit = 0x0083fdFB328fC8D07E2a7933e3013e181F9798Ad;
    address public indPresaleDeposit = 0x007AB99FBf023Cb41b50AE7D24621729295EdBFA;
    address public indVestingDeposit = 0x0011349f715cf59F75F0A00185e7B1c36f55C3ab;
    address public indCommunityDeposit = 0x0097ec8840E682d058b24E6e19E68358d97A6E5C;
    address public indFutureDeposit = 0x00d1bCbCDE9Ca431f6dd92077dFaE98f94e446e4; 
    address public indInflationDeposit = 0x00D31206E625F1f30039d1Fa472303E71317870A;
    
    uint256 public constant indSale = 31603785 * 10**decimals; 
    uint256 public constant indSeed = 3566341 * 10**decimals; 
    uint256 public constant indPreSale = 22995270 * 10**decimals; 
    uint256 public constant indVesting  = 28079514 * 10**decimals; 
    uint256 public constant indCommunity  = 10919811 * 10**decimals;
    uint256 public constant indFuture  = 58832579 * 10**decimals;  
    uint256 public constant indInflation  = 14624747 * 10**decimals;
   
     
    function IndorseToken()
    {
      balances[indSaleDeposit]    = indSale; 
      balances[indSeedDeposit]  = indSeed;  
      balances[indPresaleDeposit] = indPreSale;
      balances[indVestingDeposit] = indVesting;
      balances[indCommunityDeposit] = indCommunity;
      balances[indFutureDeposit] = indFuture;    
      balances[indInflationDeposit] = indInflation;

      totalSupply = indSale + indSeed + indPreSale + indVesting + indCommunity + indFuture + indInflation;

      Transfer(0x0,indSaleDeposit,indSale);
      Transfer(0x0,indSeedDeposit,indSeed);
      Transfer(0x0,indPresaleDeposit,indPreSale);
      Transfer(0x0,indVestingDeposit,indVesting);
      Transfer(0x0,indCommunityDeposit,indCommunity);
      Transfer(0x0,indFutureDeposit,indFuture);
      Transfer(0x0,indInflationDeposit,indInflation);
   }

  function transfer(address _to, uint _value) whenNotPaused returns (bool success)  {
    return super.transfer(_to,_value);
  }

  function approve(address _spender, uint _value) whenNotPaused returns (bool success)  {
    return super.approve(_spender,_value);
  }
}

contract INDvesting {
  mapping (address => uint256) public allocations;
  uint256 public unlockDate;
  address public IND = 0xf8e386EDa857484f5a12e4B5DAa9984E06E73705;
  uint256 public constant exponent = 10**18;

  function INDvesting() {
    unlockDate = now + 240 days;

     
    allocations[0xe8C67375D802c9Ae9583df38492Ff3be49e8Ca89] = 100000;
    allocations[0x3DFb8A970e8d11B4002b2bc98d5a09b09Da3482c] = 100000;
    allocations[0xC865a2220960585A0D365E8D0d7897d4E3547ae6] = 10000;
    allocations[0x0DC77D48f290aCaC0e831c835714Ae45e65Ac3d8] = 150000;
    allocations[0x9628dB0f162665C34BFC0655D55c6B637552B9ec] = 50000;
    allocations[0x89B7c9c2D529284F9E942389D0894EEadF34f037] = 150000;
    allocations[0xee4918fbd8Cd49a46B66488C523c3C24d9426270] = 100000;
    allocations[0xc8A1DAb586DEe8a30Cb88C87b8A3614E0a391fC5] = 100000;
    allocations[0x0ed1374A831744aF48174a890BbA5ac333e76717] = 50000;
    allocations[0x293a0369D58aF2433C3A435A6B5343C5455C4eD4] = 100000;
    allocations[0xf190f0193b694d9d2bb865a66f0c17cbd8280c71] = 50000;
    allocations[0xB0D9693eEC83452BD54FA5E0318850cc1B1a4a19] = 150000;
    allocations[0x6f43006776e2df2bbcbc24055275c638dcde5b64] = 100000;

     
    allocations[0x00e21B56A62ff177331C38A359AE0b316fa432Cc] = 6239891;
    allocations[0xa6565606564282E2E23a86689d43448F6fc3236E] = 6239891;
    allocations[0xFaa2480cbCe8FAa7fb706f0f16C9AB33873A1E38] = 3119945;
    allocations[0xEaE13552b4C19B1Dcb645D40dC578fFabFD2e32C] = 3119945;
    allocations[0xba74315f5f65dE811C46840901fEDF3D6dcDc748] = 50000;

     
    allocations[0x0011349f715cf59F75F0A00185e7B1c36f55C3ab] = 8099842;
  }

  function unlock() external {
    require (now > unlockDate);
    uint256 entitled = allocations[msg.sender];
    allocations[msg.sender] = 0;
    require(IndorseToken(IND).transfer(msg.sender, entitled * exponent));
  }
}