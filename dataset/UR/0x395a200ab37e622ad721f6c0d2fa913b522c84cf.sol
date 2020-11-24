 

pragma solidity 0.4.24;
 
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
}
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract ERC20Interface {
     function totalSupply() public constant returns (uint);
     function balanceOf(address tokenOwner) public constant returns (uint balance);
     function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
     function transfer(address to, uint tokens) public returns (bool success);
     function approve(address spender, uint tokens) public returns (bool success);
     function transferFrom(address from, address to, uint tokens) public returns (bool success);
     function mint(address from, address to, uint tokens) public;
     event Transfer(address indexed from, address indexed to, uint tokens);
     event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 
contract RADION is ERC20Interface,Ownable {

   using SafeMath for uint256;
   
   string public name;
   string public symbol;
   uint256 public decimals;

   uint256 public _totalSupply;
   mapping(address => uint256) tokenBalances;
   address musicContract;
   address advertisementContract;
   address sale;
   address wallet;

    
   mapping (address => mapping (address => uint256)) allowed;
   
     
    mapping(address=>bool) whiteListedAddresses;
   
    
    constructor(address _wallet) public {
        owner = msg.sender;
        wallet = _wallet;
        name  = "RADION";
        symbol = "RADIO";
        decimals = 18;
        _totalSupply = 55000000 * 10 ** uint(decimals);
        tokenBalances[wallet] = _totalSupply;    
    }
    
      
     function balanceOf(address tokenOwner) public constant returns (uint balance) {
         return tokenBalances[tokenOwner];
     }
  
      
     function transfer(address to, uint tokens) public returns (bool success) {
         require(to != address(0));
         require(tokens <= tokenBalances[msg.sender]);
         tokenBalances[msg.sender] = tokenBalances[msg.sender].sub(tokens);
         tokenBalances[to] = tokenBalances[to].add(tokens);
         emit Transfer(msg.sender, to, tokens);
         return true;
     }
  
      
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= tokenBalances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    tokenBalances[_from] = tokenBalances[_from].sub(_value);
    tokenBalances[_to] = tokenBalances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
  
      
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

      
      
      
     function totalSupply() public constant returns (uint) {
         return _totalSupply  - tokenBalances[address(0)];
     }
     
    
     
      
      
      
      
     function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
         return allowed[tokenOwner][spender];
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

      
     
    function mint(address sender, address receiver, uint256 tokenAmount) public {
      require(msg.sender == musicContract || msg.sender == advertisementContract);
      require(tokenBalances[sender] >= tokenAmount);                
      tokenBalances[receiver] = tokenBalances[receiver].add(tokenAmount);                   
      tokenBalances[sender] = tokenBalances[sender].sub(tokenAmount);                         
      emit Transfer(sender, receiver, tokenAmount); 
    }
    
    function setAddresses(address music, address advertisement,address _sale) public onlyOwner
    {
       musicContract = music;
       advertisementContract = advertisement;
       sale = _sale;
    }

     function () public payable {
        revert();
     }
 
    function buy(address beneficiary, uint ethAmountSent, uint rate) public onlyOwner
    {
        require(beneficiary != 0x0 && whiteListedAddresses[beneficiary] == true);
        require(ethAmountSent>0);
        uint weiAmount = ethAmountSent;
        uint tokens = weiAmount.mul(rate);
        
        require(tokenBalances[wallet] >= tokens);                
        tokenBalances[beneficiary] = tokenBalances[beneficiary].add(tokens);                   
        tokenBalances[wallet] = tokenBalances[wallet].sub(tokens);                         
        emit Transfer(wallet, beneficiary, tokens); 
    }
 
      
      
      
     function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
         return ERC20Interface(tokenAddress).transfer(owner, tokens);
     }

    function addAddressToWhiteList(address whitelistaddress) public onlyOwner
    {
        whiteListedAddresses[whitelistaddress] = true;
    }
    
    function checkIfAddressIsWhitelisted(address whitelistaddress) public onlyOwner constant returns (bool)
    {
        if (whiteListedAddresses[whitelistaddress] == true)
            return true;
        return false; 
    }
}