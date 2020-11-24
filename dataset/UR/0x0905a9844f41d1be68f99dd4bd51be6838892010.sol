 

 

pragma solidity 0.4.18;


 
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

 






 
contract TaylorToken is Ownable{

    using SafeMath for uint256;

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed _owner, uint256 _amount);
     
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

     
    mapping (address => bool) public whitelistedTransfer;
    mapping (address => bool) public whitelistedBurn;

    string public name = "Taylor";
    string public symbol = "TAY";
    uint8 public decimals = 18;
    uint256 constant internal DECIMAL_CASES = 10**18;
    uint256 public totalSupply = 10**7 * DECIMAL_CASES;
    bool public transferable = false;

     
    modifier onlyWhenTransferable(){
      if(!whitelistedTransfer[msg.sender]){
        require(transferable);
      }
      _;
    }

     

     
    function TaylorToken()
      Ownable()
      public
    {
      balances[owner] = balances[owner].add(totalSupply);
      whitelistedTransfer[msg.sender] = true;
      whitelistedBurn[msg.sender] = true;
      Transfer(address(0),owner, totalSupply);
    }

     

     
    function activateTransfers()
      public
      onlyOwner
    {
      transferable = true;
    }

     
    function addWhitelistedTransfer(address _address)
      public
      onlyOwner
    {
      whitelistedTransfer[_address] = true;
    }

     
    function distribute(address _tgeAddress)
      public
      onlyOwner
    {
      whitelistedTransfer[_tgeAddress] = true;
      transfer(_tgeAddress, balances[owner]);
    }


     
    function addWhitelistedBurn(address _address)
      public
      onlyOwner
    {
      whitelistedBurn[_address] = true;
    }

     

     
    function transfer(address _to, uint256 _value)
      public
      onlyWhenTransferable
      returns (bool success)
    {
      require(_to != address(0));
      require(_value <= balances[msg.sender]);

      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);
      Transfer(msg.sender, _to, _value);
      return true;
    }

     
    function transferFrom
      (address _from,
        address _to,
        uint256 _value)
        public
        onlyWhenTransferable
        returns (bool success) {
      require(_to != address(0));
      require(_value <= balances[_from]);
      require(_value <= allowed[_from][msg.sender]);

      balances[_from] = balances[_from].sub(_value);
      balances[_to] = balances[_to].add(_value);
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
      Transfer(_from, _to, _value);
      return true;
    }

     
    function approve(address _spender, uint256 _value)
      public
      onlyWhenTransferable
      returns (bool success)
    {
      allowed[msg.sender][_spender] = _value;
      Approval(msg.sender, _spender, _value);
      return true;
    }

       
    function increaseApproval(address _spender, uint _addedValue)
      public
      returns (bool)
    {
      allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
      Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue)
      public
      returns (bool)
    {
      uint oldValue = allowed[msg.sender][_spender];
      if (_subtractedValue > oldValue) {
        allowed[msg.sender][_spender] = 0;
      } else {
        allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
      }
      Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
    }

     
    function burn(uint256 _amount)
      public
      returns (bool success)
    {
      require(whitelistedBurn[msg.sender]);
      require(_amount <= balances[msg.sender]);
      balances[msg.sender] = balances[msg.sender].sub(_amount);
      totalSupply =  totalSupply.sub(_amount);
      Burn(msg.sender, _amount);
      return true;
    }


     

     
    function balanceOf(address _owner) view public returns (uint256 balance) {
        return balances[_owner];
    }

     
    function allowance(address _owner, address _spender)
      view
      public
      returns (uint256 remaining)
    {
      return allowed[_owner][_spender];
    }

}

 




contract TaylorTokenTGE is Ownable {
  using SafeMath for uint256;

  uint256 constant internal DECIMAL_CASES = 10**18;
  TaylorToken public token;

  uint256 constant public FOUNDERS = 10**6 * DECIMAL_CASES;
  uint256 constant public ADVISORS = 4 * 10**5 * DECIMAL_CASES;
  uint256 constant public TEAM = 3 * 10**5 * DECIMAL_CASES;
  uint256 constant public REFERRAL_PROGRAMS = 7 * 10**5 * DECIMAL_CASES;
  uint256 constant public PRESALE = 1190476 * DECIMAL_CASES;
  uint256 constant public PUBLICSALE = 6409524 * DECIMAL_CASES;

  address public founders_address;
  address public advisors_address;
  address public team_address;
  address public referral_address;
  address public presale_address;
  address public publicsale_address;

   
  function setUp(address _token, address _founders, address _advisors, address _team, address _referral, address _presale, address _publicSale) public onlyOwner{
    token = TaylorToken(_token);
    founders_address = _founders;
    advisors_address = _advisors;
    team_address = _team;
    referral_address = _referral;
    presale_address = _presale;
    publicsale_address = _publicSale;
  }

   
  function distribute() public onlyOwner {
    uint256 total = FOUNDERS.add(ADVISORS).add(TEAM).add(REFERRAL_PROGRAMS).add(PRESALE).add(PUBLICSALE);
    require(total >= token.balanceOf(this));
    token.transfer(founders_address, FOUNDERS);
    token.transfer(advisors_address, ADVISORS);
    token.transfer(team_address, TEAM);
    token.transfer(referral_address, REFERRAL_PROGRAMS);
    token.transfer(presale_address, PRESALE);
    token.transfer(publicsale_address, PUBLICSALE);
  }

}