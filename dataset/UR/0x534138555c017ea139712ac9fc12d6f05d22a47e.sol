 

pragma solidity 0.4.25;

 
contract Ownable {
  address public owner;
  address public coinvest;
  mapping (address => bool) public admins;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  constructor() public {
    owner = msg.sender;
    coinvest = msg.sender;
    admins[owner] = true;
    admins[coinvest] = true;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier coinvestOrOwner() {
      require(msg.sender == coinvest || msg.sender == owner);
      _;
  }

  modifier onlyAdmin() {
      require(admins[msg.sender]);
      _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
  
   
  function transferCoinvest(address _newCoinvest) 
    external
    onlyOwner
  {
    require(_newCoinvest != address(0));
    coinvest = _newCoinvest;
  }

   
  function alterAdmin(address _user, bool _status)
    external
    onlyOwner
  {
    require(_user != address(0));
    require(_user != coinvest);
    admins[_user] = _status;
  }

}

contract ERC20Interface {

    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}

 
library SafeMathLib{
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

contract UserData is Ownable {
    using SafeMathLib for uint256;

     
    address public investmentAddress;
    
     
    mapping (address => mapping (uint256 => uint256)) public userHoldings;

     
    constructor(address _investmentAddress) 
      public
    {
        investmentAddress = _investmentAddress;
    }
    
     
    function modifyHoldings(address _beneficiary, uint256[] _cryptoIds, uint256[] _amounts, bool _buy)
      external
    {
        require(msg.sender == investmentAddress);
        require(_cryptoIds.length == _amounts.length);
        
        for (uint256 i = 0; i < _cryptoIds.length; i++) {
            if (_buy) {
                userHoldings[_beneficiary][_cryptoIds[i]] = userHoldings[_beneficiary][_cryptoIds[i]].add(_amounts[i]);
            } else {
                userHoldings[_beneficiary][_cryptoIds[i]] = userHoldings[_beneficiary][_cryptoIds[i]].sub(_amounts[i]);
            }
        }
    }

 
    
     
    function returnHoldings(address _beneficiary, uint256 _start, uint256 _end)
      external
      view
    returns (uint256[] memory holdings)
    {
        require(_start <= _end);
        
        holdings = new uint256[](_end.sub(_start)+1); 
        for (uint256 i = 0; i < holdings.length; i++) {
            holdings[i] = userHoldings[_beneficiary][_start+i];
        }
        return holdings;
    }
    
 
    
     
    function changeInvestment(address _newAddress)
      external
      onlyOwner
    {
        investmentAddress = _newAddress;
    }
    
 
    
     
    function tokenEscape(address _tokenContract)
      external
      coinvestOrOwner
    {
        if (_tokenContract == address(0)) coinvest.transfer(address(this).balance);
        else {
            ERC20Interface lostToken = ERC20Interface(_tokenContract);
        
            uint256 stuckTokens = lostToken.balanceOf(address(this));
            lostToken.transfer(coinvest, stuckTokens);
        }    
    }
    
}