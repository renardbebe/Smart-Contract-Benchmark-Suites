 

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

 
contract Bank is Ownable {
    
    address public investmentAddr;       
    address public coinToken;            
    address public cashToken;            

     
    constructor(address _coinToken, address _cashToken)
      public
    {
        coinToken = _coinToken;
        cashToken = _cashToken;
    }

 
    
     
    function transfer(address _to, uint256 _value, bool _isCoin)
      external
    returns (bool success)
    {
        require(msg.sender == investmentAddr);

        ERC20Interface token;
        if (_isCoin) token = ERC20Interface(coinToken);
        else token = ERC20Interface(cashToken);

        require(token.transfer(_to, _value));
        return true;
    }
    
 
    
     
    function changeInvestment(address _newInvestment)
      external
      onlyOwner
    {
        require(_newInvestment != address(0));
        investmentAddr = _newInvestment;
    }
    
 

     
    function tokenEscape(address _tokenContract)
      external
      coinvestOrOwner
    {
        require(_tokenContract != coinToken && _tokenContract != cashToken);
        if (_tokenContract == address(0)) coinvest.transfer(address(this).balance);
        else {
            ERC20Interface lostToken = ERC20Interface(_tokenContract);
        
            uint256 stuckTokens = lostToken.balanceOf(address(this));
            lostToken.transfer(coinvest, stuckTokens);
        }    
    }

}