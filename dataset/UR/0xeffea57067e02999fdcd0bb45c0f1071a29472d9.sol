 

pragma solidity ^0.4.18;

 
 
 
 
 

 
 
 
 
 

contract Owned {

  address public owner;
  address public newOwner;

   

  event OwnershipTransferProposed(address indexed _from, address indexed _to);
  event OwnershipTransferred(address indexed _from, address indexed _to);

   

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

   

  function Owned() public {
    owner = msg.sender;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != owner);
    require(_newOwner != address(0x0));
    OwnershipTransferProposed(owner, _newOwner);
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    require(msg.sender == newOwner);
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

 
 
 
 
 
 

contract ERC20Interface {

   

  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);

   

  function totalSupply() public constant returns (uint);
  function balanceOf(address _owner) public constant returns (uint balance);
  function transfer(address _to, uint _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint _value) public returns (bool success);
  function approve(address _spender, uint _value) public returns (bool success);
  function allowance(address _owner, address _spender) public constant returns (uint remaining);

}

 
 
 
 
 

contract ERC20Coin is ERC20Interface, Owned {
  
  using SafeMath for uint;

  uint public coinsIssuedTotal = 0;
  mapping(address => uint) public balances;
  mapping(address => mapping (address => uint)) public allowed;

   

   

  function totalSupply() public constant returns (uint) {
    return coinsIssuedTotal;
  }

   

  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }

   

  function transfer(address _to, uint _amount) public returns (bool success) {
     
    require(balances[msg.sender] >= _amount);

     
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);

     
    Transfer(msg.sender, _to, _amount);
    return true;
  }

   

  function approve(address _spender, uint _amount) public returns (bool success) {
     
    require (balances[msg.sender] >= _amount);
      
     
    allowed[msg.sender][_spender] = _amount;
    
     
    Approval(msg.sender, _spender, _amount);
    return true;
  }

   
   

  function transferFrom(address _from, address _to, uint _amount) public returns (bool success) {
     
    require(balances[_from] >= _amount);
    require(allowed[_from][msg.sender] >= _amount);

     
    balances[_from] = balances[_from].sub(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);

     
    Transfer(_from, _to, _amount);
    return true;
  }

   
   

  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

contract ZanteCoin is ERC20Coin {

     

    string public constant name = "Zpay";
    string public constant symbol = "ZPAY";
    uint8  public constant decimals = 18;

     

    uint public constant DATE_ICO_START = 1521072000;  
    uint public constant DATE_ICO_END   = 1531612800;  

       

    uint public constant COIN_SUPPLY_ICO_PHASE_0 = 30000000 * 10**18;   
    uint public constant COIN_SUPPLY_ICO_PHASE_1 = 70000000 * 10**18;   
    uint public constant COIN_SUPPLY_ICO_PHASE_2 = 200000000 * 10**18;  
    uint public constant COIN_SUPPLY_ICO_PHASE_3 = 300000000 * 10**18;  
    uint public constant COIN_SUPPLY_ICO_TOTAL   = 
        COIN_SUPPLY_ICO_PHASE_0
        + COIN_SUPPLY_ICO_PHASE_1
        + COIN_SUPPLY_ICO_PHASE_2
        + COIN_SUPPLY_ICO_PHASE_3;

    uint public constant COIN_SUPPLY_MKT_TOTAL = 600000000 * 10**18;

    uint public constant COIN_SUPPLY_COMPANY_TOTAL = 800000000 * 10**18;

    uint public constant COIN_SUPPLY_TOTAL = 
        COIN_SUPPLY_ICO_TOTAL
        + COIN_SUPPLY_MKT_TOTAL
        + COIN_SUPPLY_COMPANY_TOTAL;

       

    uint public constant MIN_CONTRIBUTION = 1 ether / 100;  
    uint public constant MAX_CONTRIBUTION = 15610 ether;

     

    uint public coinsIssuedIco = 0;
    uint public coinsIssuedMkt = 0;
    uint public coinsIssuedCmp = 0;  

     

    event IcoCoinsIssued(address indexed _owner, uint _coins);
    event MarketingCoinsGranted(address indexed _participant, uint _coins, uint _balance);
    event CompanyCoinsGranted(address indexed _participant, uint _coins, uint _balance);

     

     

    function ZanteCoin() public {  }

     

    function () public {
         
    }

    function issueIcoCoins(address _participant, uint _coins) public onlyOwner {
         
        require(_coins <= COIN_SUPPLY_ICO_TOTAL.sub(coinsIssuedIco));

         
        balances[_participant] = balances[_participant].add(_coins);
        coinsIssuedIco = coinsIssuedIco.add(_coins);
        coinsIssuedTotal = coinsIssuedTotal.add(_coins);

         
        Transfer(0x0, _participant, _coins);
        IcoCoinsIssued(_participant, _coins);
    }

     
    function grantMarketingCoins(address _participant, uint _coins) public onlyOwner {
         
        require(_coins <= COIN_SUPPLY_MKT_TOTAL.sub(coinsIssuedMkt));

         
        balances[_participant] = balances[_participant].add(_coins);
        coinsIssuedMkt = coinsIssuedMkt.add(_coins);
        coinsIssuedTotal = coinsIssuedTotal.add(_coins);

         
        Transfer(0x0, _participant, _coins);
        MarketingCoinsGranted(_participant, _coins, balances[_participant]);
    }

     
    function grantCompanyCoins(address _participant, uint _coins) public onlyOwner {
         
        require(_coins <= COIN_SUPPLY_COMPANY_TOTAL.sub(coinsIssuedCmp));

         
        balances[_participant] = balances[_participant].add(_coins);
        coinsIssuedCmp = coinsIssuedCmp.add(_coins);
        coinsIssuedTotal = coinsIssuedTotal.add(_coins);

         
        Transfer(0x0, _participant, _coins);
        CompanyCoinsGranted(_participant, _coins, balances[_participant]);
    }
}