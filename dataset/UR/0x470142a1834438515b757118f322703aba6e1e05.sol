 

pragma solidity ^0.4.13;

contract PolicyPalNetworkAirdrop {
    struct BountyType {
      bool twitter;
      bool signature;
    }

     
    address                         public admin;
    PolicyPalNetworkToken           public token;
    mapping(address => bool)        public airdrops;
    mapping(address => bool)        public twitterdrops;
    mapping(address => bool)        public signaturedrops;
    uint256                         public numDrops;
    uint256                         public dropAmount;

    using SafeMath for uint256;

     
    modifier onlyAdmin() {
      require(msg.sender == admin);
      _;
    }

     
    modifier validAddress(address _addr) {
        require(_addr != address(0x0));
        require(_addr != address(this));
        _;
    }

     
    modifier validBalance(address[] _recipients, uint256 _amount) {
         
        uint256 balance = token.balanceOf(this);
        require(balance > 0);
        require(balance >= _recipients.length.mul(_amount));
        _;
    }

     
    modifier validBalanceMultiple(address[] _recipients, uint256[] _amounts) {
         
        uint256 balance = token.balanceOf(this);
        require(balance > 0);

        uint256 totalAmount;
        for (uint256 i = 0 ; i < _recipients.length ; i++) {
            totalAmount = totalAmount.add(_amounts[i]);
        }
        require(balance >= totalAmount);
        _;
    }

     
    function PolicyPalNetworkAirdrop(
        PolicyPalNetworkToken _token, 
        address _adminAddr
    )
        public
        validAddress(_adminAddr)
        validAddress(_token)
    {
         
        admin = _adminAddr;
        token = _token;
    }
    
     
    event TokenDrop(address _receiver, uint _amount, string _type);

     
    function airDropSingleAmount(address[] _recipients, uint256 _amount) external
        onlyAdmin
        validBalance(_recipients, _amount)
    {
         
        for (uint256 i = 0 ; i < _recipients.length ; i++) {
            address recipient = _recipients[i];
             
            if (!airdrops[recipient]) {
                 
                assert(token.transfer(recipient, _amount));
                 
                airdrops[recipient] = true;
                 
                numDrops = numDrops.add(1);
                dropAmount = dropAmount.add(_amount);
                 
                TokenDrop(recipient, _amount, "AIRDROP");
            }
        }
    }

     
    function airDropMultipleAmount(address[] _recipients, uint256[] _amounts) external
        onlyAdmin
        validBalanceMultiple(_recipients, _amounts)
    {
         
        for (uint256 i = 0 ; i < _recipients.length ; i++) {
            address recipient = _recipients[i];
            uint256 amount = _amounts[i];
             
            if (!airdrops[recipient]) {
                 
                assert(token.transfer(recipient, amount));
                 
                airdrops[recipient] = true;
                 
                numDrops = numDrops.add(1);
                dropAmount = dropAmount.add(amount);
                 
                TokenDrop(recipient, amount, "AIRDROP");
            }
        }
    }

     
    function twitterDropSingleAmount(address[] _recipients, uint256 _amount) external
        onlyAdmin
        validBalance(_recipients, _amount)
    {
         
        for (uint256 i = 0 ; i < _recipients.length ; i++) {
            address recipient = _recipients[i];
             
            if (!twitterdrops[recipient]) {
               
              assert(token.transfer(recipient, _amount));
               
              twitterdrops[recipient] = true;
               
              numDrops = numDrops.add(1);
              dropAmount = dropAmount.add(_amount);
               
              TokenDrop(recipient, _amount, "TWITTER");
            }
        }
    }

     
    function twitterDropMultipleAmount(address[] _recipients, uint256[] _amounts) external
        onlyAdmin
        validBalanceMultiple(_recipients, _amounts)
    {
         
        for (uint256 i = 0 ; i < _recipients.length ; i++) {
            address recipient = _recipients[i];
            uint256 amount = _amounts[i];
             
            if (!twitterdrops[recipient]) {
               
              assert(token.transfer(recipient, amount));
               
              twitterdrops[recipient] = true;
               
              numDrops = numDrops.add(1);
              dropAmount = dropAmount.add(amount);
               
              TokenDrop(recipient, amount, "TWITTER");
            }
        }
    }

     
    function signatureDropSingleAmount(address[] _recipients, uint256 _amount) external
        onlyAdmin
        validBalance(_recipients, _amount)
    {
         
        for (uint256 i = 0 ; i < _recipients.length ; i++) {
            address recipient = _recipients[i];
             
            if (!signaturedrops[recipient]) {
               
              assert(token.transfer(recipient, _amount));
               
              signaturedrops[recipient] = true;
               
              numDrops = numDrops.add(1);
              dropAmount = dropAmount.add(_amount);
               
              TokenDrop(recipient, _amount, "SIGNATURE");
            }
        }
    }

     
    function signatureDropMultipleAmount(address[] _recipients, uint256[] _amounts) external
        onlyAdmin
        validBalanceMultiple(_recipients, _amounts)
    {
         
        for (uint256 i = 0 ; i < _recipients.length ; i++) {
            address recipient = _recipients[i];
            uint256 amount = _amounts[i];
             
            if (!signaturedrops[recipient]) {
               
              assert(token.transfer(recipient, amount));
               
              signaturedrops[recipient] = true;
               
              numDrops = numDrops.add(1);
              dropAmount = dropAmount.add(amount);
               
              TokenDrop(recipient, amount, "SIGNATURE");
            }
        }
    }

     
    function emergencyDrain(address _recipient, uint256 _amount) external
      onlyAdmin
    {
        assert(token.transfer(_recipient, _amount));
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

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
  }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract PolicyPalNetworkToken is StandardToken, BurnableToken, Ownable {
     
    string    public constant name     = "PolicyPal Network Token";
    string    public constant symbol   = "PAL";
    uint8     public constant decimals = 18;

     
    address public  tokenSaleContract;
    bool    public  isTokenTransferable = false;


     
    modifier onlyWhenTransferAllowed() {
        require(isTokenTransferable || msg.sender == owner || msg.sender == tokenSaleContract);
        _;
    }

     
    modifier isValidDestination(address _to) {
        require(_to != address(0x0));
        require(_to != address(this));
        _;
    }

     
    function toggleTransferable(bool _toggle) external
        onlyOwner
    {
        isTokenTransferable = _toggle;
    }
    

     
    function PolicyPalNetworkToken(
        uint _tokenTotalAmount,
        address _adminAddr
    ) 
        public
        isValidDestination(_adminAddr)
    {
        require(_tokenTotalAmount > 0);

        totalSupply_ = _tokenTotalAmount;

         
        balances[msg.sender] = _tokenTotalAmount;
        Transfer(address(0x0), msg.sender, _tokenTotalAmount);

         
        tokenSaleContract = msg.sender;

         
        transferOwnership(_adminAddr);
    }

     
    function transfer(address _to, uint256 _value) public
        onlyWhenTransferAllowed
        isValidDestination(_to)
        returns (bool)
    {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public
        onlyWhenTransferAllowed
        isValidDestination(_to)
        returns (bool)
    {
        return super.transferFrom(_from, _to, _value);
    }

     
    function burn(uint256 _value)
        public
    {
        super.burn(_value);
        Transfer(msg.sender, address(0x0), _value);
    }

     
    function emergencyERC20Drain(ERC20 _token, uint256 _amount) public
        onlyOwner
    {
        _token.transfer(owner, _amount);
    }
}