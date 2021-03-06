 

pragma solidity ^0.4.23;

 

contract JSECoinCrowdsaleConfig {
    
    uint8 public constant   TOKEN_DECIMALS = 18;
    uint256 public constant DECIMALSFACTOR = 10**uint256(TOKEN_DECIMALS);

    uint256 public constant DURATION                                = 12 weeks; 
    uint256 public constant CONTRIBUTION_MIN                        = 0.1 ether;  
    uint256 public constant CONTRIBUTION_MAX_NO_WHITELIST           = 20 ether;  
    uint256 public constant CONTRIBUTION_MAX                        = 10000.0 ether;  
    
    uint256 public constant TOKENS_MAX                              = 10000000000 * (10 ** uint256(TOKEN_DECIMALS));  
    uint256 public constant TOKENS_SALE                             = 5000000000 * DECIMALSFACTOR;  
    uint256 public constant TOKENS_DISTRIBUTED                      = 5000000000 * DECIMALSFACTOR;  


     
     
                                                                     
    uint256 public constant TOKENS_PER_KETHER                       = 75000000;

     
     
    uint256 public constant PURCHASE_DIVIDER                        = 10**(uint256(18) - TOKEN_DECIMALS + 3);

}

 

 
interface ERC223 {
    function transfer(address _to, uint _value, bytes _data) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

 

 
 
contract ERC223ReceivingContract { 

     
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

 

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

 
contract OperatorManaged is Ownable {

    address public operatorAddress;
    address public adminAddress;

    event AdminAddressChanged(address indexed _newAddress);
    event OperatorAddressChanged(address indexed _newAddress);


    constructor() public
        Ownable()
    {
        adminAddress = msg.sender;
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }


    modifier onlyAdminOrOperator() {
        require(isAdmin(msg.sender) || isOperator(msg.sender));
        _;
    }


    modifier onlyOwnerOrAdmin() {
        require(isOwner(msg.sender) || isAdmin(msg.sender));
        _;
    }


    modifier onlyOperator() {
        require(isOperator(msg.sender));
        _;
    }


    function isAdmin(address _address) internal view returns (bool) {
        return (adminAddress != address(0) && _address == adminAddress);
    }


    function isOperator(address _address) internal view returns (bool) {
        return (operatorAddress != address(0) && _address == operatorAddress);
    }

    function isOwner(address _address) internal view returns (bool) {
        return (owner != address(0) && _address == owner);
    }


    function isOwnerOrOperator(address _address) internal view returns (bool) {
        return (isOwner(_address) || isOperator(_address));
    }


     
    function setAdminAddress(address _adminAddress) external onlyOwnerOrAdmin returns (bool) {
        require(_adminAddress != owner);
        require(_adminAddress != address(this));
        require(!isOperator(_adminAddress));

        adminAddress = _adminAddress;

        emit AdminAddressChanged(_adminAddress);

        return true;
    }


     
    function setOperatorAddress(address _operatorAddress) external onlyOwnerOrAdmin returns (bool) {
        require(_operatorAddress != owner);
        require(_operatorAddress != address(this));
        require(!isAdmin(_operatorAddress));

        operatorAddress = _operatorAddress;

        emit OperatorAddressChanged(_operatorAddress);

        return true;
    }
}

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
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
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

 

 
contract JSEToken is ERC223, BurnableToken, Ownable, MintableToken, OperatorManaged {
    
    event Finalized();

    string public name = "JSE Token";
    string public symbol = "JSE";
    uint public decimals = 18;
    uint public initialSupply = 10000000000 * (10 ** decimals);  

    bool public finalized;

    constructor() OperatorManaged() public {
        totalSupply_ = initialSupply;
        balances[msg.sender] = initialSupply; 

        emit Transfer(0x0, msg.sender, initialSupply);
    }


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        checkTransferAllowed(msg.sender, _to);

        return super.transferFrom(_from, _to, _value);
    }

    function checkTransferAllowed(address _sender, address _to) private view {
        if (finalized) {
             
            return;
        }

         
         
         
         
        require(isOwnerOrOperator(_sender) || _to == owner);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        checkTransferAllowed(msg.sender, _to);

        return super.transfer(_to, _value);
    }

     
    function transfer(address _to, uint _value, bytes _data) external returns (bool) {
        checkTransferAllowed(msg.sender, _to);

        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(isContract(_to));


        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        ERC223ReceivingContract erc223Contract = ERC223ReceivingContract(_to);
        erc223Contract.tokenFallback(msg.sender, _value, _data);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }

    function isContract(address _addr) private view returns (bool) {
        uint codeSize;
         
        assembly {
            codeSize := extcodesize(_addr)
        }
        return codeSize > 0;
    }

     
    function finalize() external onlyAdmin returns (bool success) {
        require(!finalized);

        finalized = true;

        emit Finalized();

        return true;
    }
}

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 


contract JSETokenSale is OperatorManaged, Pausable, JSECoinCrowdsaleConfig {  

    using SafeMath for uint256;


     
     
    bool public finalized;

     
    bool public publicSaleStarted;

     
    uint256 public tokensPerKEther;

     
    uint256 public bonusIncreasePercentage = 10;  

     
    address public wallet;

     
    JSEToken public tokenContract;

     
     
     
     
     
     

     
    uint256 public totalTokensSold;

     
    uint256 public totalPresaleBase;
    uint256 public totalPresaleBonus;

     
    mapping(address => bool) public whitelist;

     
    uint256 public weiRaised;

     
     
     
    event Initialized();
    event PresaleAdded(address indexed _account, uint256 _baseTokens, uint256 _bonusTokens);
    event WhitelistUpdated(address indexed _account);
    event TokensPurchased(address indexed _beneficiary, uint256 _cost, uint256 _tokens, uint256 _totalSold);
    event TokensPerKEtherUpdated(uint256 _amount);
    event WalletChanged(address _newWallet);
    event TokensReclaimed(uint256 _amount);
    event UnsoldTokensBurnt(uint256 _amount);
    event BonusIncreasePercentageChanged(uint256 _oldPercentage, uint256 _newPercentage);
    event Finalized();


    constructor(JSEToken _tokenContract, address _wallet) public
        OperatorManaged()
    {
        require(address(_tokenContract) != address(0));
         
        require(_wallet != address(0));

        require(TOKENS_PER_KETHER > 0);


        wallet                  = _wallet;
        finalized               = false;
        publicSaleStarted       = false;
        tokensPerKEther         = TOKENS_PER_KETHER;
        tokenContract           = _tokenContract;
         
    }


     
     
    function initialize() external onlyOwner returns (bool) {
        require(totalTokensSold == 0);
        require(totalPresaleBase == 0);
        require(totalPresaleBonus == 0);

        uint256 ownBalance = tokenContract.balanceOf(address(this));
        require(ownBalance == TOKENS_SALE);

        emit Initialized();

        return true;
    }


     
    function changeWallet(address _wallet) external onlyAdmin returns (bool) {
        require(_wallet != address(0));
        require(_wallet != address(this));
         
        require(_wallet != address(tokenContract));

        wallet = _wallet;

        emit WalletChanged(wallet);

        return true;
    }



     
     
     

    function currentTime() public view returns (uint256 _currentTime) {
        return now;
    }


    modifier onlyBeforeSale() {
        require(hasSaleEnded() == false && publicSaleStarted == false);
        _;
    }


    modifier onlyDuringSale() {
        require(hasSaleEnded() == false && publicSaleStarted == true);
        _;
    }

    modifier onlyAfterSale() {
         
        require(finalized);
        _;
    }


    function hasSaleEnded() private view returns (bool) {
         
        if (finalized) {
            return true;
        } else {
            return false;
        }
    }



     
     
     

     
     
    function updateWhitelist(address _account) external onlyAdminOrOperator returns (bool) {
        require(_account != address(0));
        require(!hasSaleEnded());

        whitelist[_account] = true;

        emit WhitelistUpdated(_account);

        return true;
    }

     
     
     

     
    function setTokensPerKEther(uint256 _tokensPerKEther) external onlyAdmin onlyBeforeSale returns (bool) {
        require(_tokensPerKEther > 0);

        tokensPerKEther = _tokensPerKEther;

        emit TokensPerKEtherUpdated(_tokensPerKEther);

        return true;
    }


    function () external payable whenNotPaused onlyDuringSale {
        buyTokens();
    }


     
    function buyTokens() public payable whenNotPaused onlyDuringSale returns (bool) {
        require(msg.value >= CONTRIBUTION_MIN);
        require(msg.value <= CONTRIBUTION_MAX);
        require(totalTokensSold < TOKENS_SALE);

         
        bool whitelisted = whitelist[msg.sender];
        if(msg.value >= CONTRIBUTION_MAX_NO_WHITELIST){
            require(whitelisted);
        }

        uint256 tokensMax = TOKENS_SALE.sub(totalTokensSold);

        require(tokensMax > 0);
        
        uint256 actualAmount = msg.value.mul(tokensPerKEther).div(PURCHASE_DIVIDER);

        uint256 bonusAmount = actualAmount.mul(bonusIncreasePercentage).div(100);

        uint256 tokensBought = actualAmount.add(bonusAmount);

        require(tokensBought > 0);

        uint256 cost = msg.value;
        uint256 refund = 0;

        if (tokensBought > tokensMax) {
             
            tokensBought = tokensMax;

             
            cost = tokensBought.mul(PURCHASE_DIVIDER).div(tokensPerKEther);

             
            refund = msg.value.sub(cost);
        }

        totalTokensSold = totalTokensSold.add(tokensBought);

         
        require(tokenContract.transfer(msg.sender, tokensBought));

         
        if (refund > 0) {
            msg.sender.transfer(refund);
        }

         
        weiRaised = weiRaised.add(msg.value.sub(refund));

         
        wallet.transfer(msg.value.sub(refund));

        emit TokensPurchased(msg.sender, cost, tokensBought, totalTokensSold);

         
        if (totalTokensSold == TOKENS_SALE) {
            finalizeInternal();
        }

        return true;
    }



     
     
     
     
    function reclaimTokens(uint256 _amount) external onlyAfterSale onlyAdmin returns (bool) {
        uint256 ownBalance = tokenContract.balanceOf(address(this));
        require(_amount <= ownBalance);
        
        address tokenOwner = tokenContract.owner();
        require(tokenOwner != address(0));

        require(tokenContract.transfer(tokenOwner, _amount));

        emit TokensReclaimed(_amount);

        return true;
    }

    function changeBonusIncreasePercentage(uint256 _newPercentage) external onlyDuringSale onlyAdmin returns (bool) {
        uint oldPercentage = bonusIncreasePercentage;
        bonusIncreasePercentage = _newPercentage;
        emit BonusIncreasePercentageChanged(oldPercentage, _newPercentage);
        return true;
    }

     
     
     
    function finalize() external onlyAdmin returns (bool) {
        return finalizeInternal();
    }

    function startPublicSale() external onlyAdmin onlyBeforeSale returns (bool) {
        publicSaleStarted = true;
        return true;
    }


     
     
     
    function finalizeInternal() private returns (bool) {
        require(!finalized);

        finalized = true;

        emit Finalized();

        return true;
    }
}