 

pragma solidity ^0.4.18;

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
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

 
 
 
 
 
 
contract Token is StandardToken {

    string  public constant name   = "COPYTRACK Token";
    string  public constant symbol = "CPY";

    uint8 public constant   decimals = 18;

    uint256 constant EXA       = 10 ** 18;
    uint256 public totalSupply = 100 * 10 ** 6 * EXA;

    bool public finalized = false;

    address public tokenSaleContract;

     
     
     
    event Finalized();

    event Burnt(address indexed _from, uint256 _amount);


     
    function Token(address _tokenSaleContract)
        public
    {
         
        require(_tokenSaleContract != 0);

        balances[_tokenSaleContract] = totalSupply;

        tokenSaleContract = _tokenSaleContract;
    }


     
    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        checkTransferAllowed(msg.sender);

        return super.transfer(_to, _value);
    }


     
    function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool success)
    {
        checkTransferAllowed(msg.sender);

        return super.transferFrom(_from, _to, _value);
    }


    function checkTransferAllowed(address _sender)
        private
        view
    {
        if (finalized) {
             
            return;
        }

         
        require(_sender == tokenSaleContract);
    }


     
    function finalize()
        external
        returns (bool success)
    {
        require(!finalized);
        require(msg.sender == tokenSaleContract);

        finalized = true;

        Finalized();

        return true;
    }


     
    function burn(uint256 _value)
        public
        returns (bool success)
    {
        require(finalized);
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);

        Burnt(msg.sender, _value);

        return true;
    }
}

contract TokenSaleConfig  {
    uint public constant EXA = 10 ** 18;

    uint256 public constant PUBLIC_START_TIME         = 1515542400;  
    uint256 public constant END_TIME                  = 1518220800;  
    uint256 public constant CONTRIBUTION_MIN          = 0.1 ether;
    uint256 public constant CONTRIBUTION_MAX          = 2500.0 ether;

    uint256 public constant COMPANY_ALLOCATION        = 40 * 10 ** 6 * EXA;  

    Tranche[4] public tranches;

    struct Tranche {
         
        uint untilToken;

         
        uint tokensPerEther;
    }

    function TokenSaleConfig()
        public
    {
        tranches[0] = Tranche({untilToken : 5000000 * EXA, tokensPerEther : 1554});
        tranches[1] = Tranche({untilToken : 10000000 * EXA, tokensPerEther : 1178});
        tranches[2] = Tranche({untilToken : 20000000 * EXA, tokensPerEther : 1000});
        tranches[3] = Tranche({untilToken : 60000000, tokensPerEther : 740});
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

contract TokenSale is TokenSaleConfig, Ownable {
    using SafeMath for uint;

    Token  public  tokenContract;

     
     
    bool public finalized = false;

     
    mapping (address => uint256) public contributors;

     
    uint256 public totalWeiRaised = 0;

     
    uint256 public totalTokenSold = 0;

     
    address public fundingWalletAddress;

     
    mapping (address => bool) public whitelistOperators;

     
    mapping (address => bool) public whitelist;


     
    address[] public earlyBirds;

    mapping (address => uint256) public earlyBirdInvestments;


     
     
     

     
     
     
    modifier withinContributionLimits(address _contributorAddress, uint256 _weiAmount) {
        uint256 totalContributionAmount = contributors[_contributorAddress].add(_weiAmount);
        require(_weiAmount >= CONTRIBUTION_MIN);
        require(totalContributionAmount <= CONTRIBUTION_MAX);
        _;
    }

     
     
    modifier onlyWhitelisted(address _address) {
        require(whitelist[_address] == true);
        _;
    }

     
    modifier onlyWhitelistOperator()
    {
        require(whitelistOperators[msg.sender] == true);
        _;
    }

     
    modifier onlyDuringSale() {
        require(finalized == false);
        require(currentTime() <= END_TIME);
        _;
    }

     
    modifier onlyAfterFinalized() {
        require(finalized);
        _;
    }



     
     
     
    event LogWhitelistUpdated(address indexed _account);

    event LogTokensPurchased(address indexed _account, uint256 _cost, uint256 _tokens, uint256 _totalTokenSold);

    event UnsoldTokensBurnt(uint256 _amount);

    event Finalized();

     
     
    function TokenSale(address _fundingWalletAddress)
        public
    {
         
        require(_fundingWalletAddress != 0);

        fundingWalletAddress = _fundingWalletAddress;
    }

     
     
    function connectToken(Token _tokenContract)
        external
        onlyOwner
    {
        require(totalTokenSold == 0);
        require(tokenContract == address(0));

         
        require(_tokenContract.balanceOf(address(this)) == _tokenContract.totalSupply());

        tokenContract = _tokenContract;

         
        tokenContract.transfer(fundingWalletAddress, COMPANY_ALLOCATION);
        processEarlyBirds();
    }

    function()
        external
        payable
    {
        uint256 cost = buyTokens(msg.sender, msg.value);

         
        fundingWalletAddress.transfer(cost);
    }

     
    function buyTokens(address contributorAddress, uint256 weiAmount)
        onlyDuringSale
        onlyWhitelisted(contributorAddress)
        withinContributionLimits(contributorAddress, weiAmount)
        private
    returns (uint256 costs)
    {
        assert(tokenContract != address(0));

        uint256 tokensLeft = getTokensLeft();

         
        require(tokensLeft > 0);

        uint256 tokenAmount = calculateTokenAmount(weiAmount);
        uint256 cost = weiAmount;
        uint256 refund = 0;

         
        if (tokenAmount > tokensLeft) {
            tokenAmount = tokensLeft;

             
            cost = tokenAmount / getCurrentTokensPerEther();

             
            refund = weiAmount.sub(cost);
        }

         
        tokenContract.transfer(contributorAddress, tokenAmount);

         
        contributors[contributorAddress] = contributors[contributorAddress].add(cost);


         
        if (refund > 0) {
             
            contributorAddress.transfer(refund);
        }

         
        totalWeiRaised += cost;
        totalTokenSold += tokenAmount;

        LogTokensPurchased(contributorAddress, cost, tokenAmount, totalTokenSold);

         
        if (tokensLeft.sub(tokenAmount) == 0) {
            finalizeInternal();
        }


         
        return cost;
    }

     
    function getTokensLeft()
        public
        view
    returns (uint256 tokensLeft)
    {
        return tokenContract.balanceOf(this);
    }

     
    function getCurrentTokensPerEther()
        public
        view
    returns (uint256 tokensPerEther)
    {
        uint i;
        uint defaultTokensPerEther = tranches[tranches.length - 1].tokensPerEther;

        if (currentTime() >= PUBLIC_START_TIME) {
            return defaultTokensPerEther;
        }

        for (i = 0; i < tranches.length; i++) {
            if (totalTokenSold >= tranches[i].untilToken) {
                continue;
            }

             
            return tranches[i].tokensPerEther;
        }

        return defaultTokensPerEther;
    }

     
    function calculateTokenAmount(uint256 weiAmount)
        public
        view
    returns (uint256 tokens)
    {
        return weiAmount * getCurrentTokensPerEther();
    }

     
     
     

     
    function addWhitelistOperator(address _address)
        public
        onlyOwner
    {
        whitelistOperators[_address] = true;
    }

     
    function removeWhitelistOperator(address _address)
        public
        onlyOwner
    {
        require(whitelistOperators[_address]);

        delete whitelistOperators[_address];
    }


     
     
    function addToWhitelist(address _address)
        public
        onlyWhitelistOperator
    {
        require(_address != address(0));

        whitelist[_address] = true;
        LogWhitelistUpdated(_address);
    }

     
    function removeFromWhitelist(address _address)
        public
        onlyWhitelistOperator
    {
        require(_address != address(0));

        delete whitelist[_address];
    }

     
    function currentTime()
        public
        view
        returns (uint256 _currentTime)
    {
        return now;
    }


     
    function finalize()
        external
        onlyOwner
        returns (bool)
    {
         
        require(currentTime() > END_TIME);

        return finalizeInternal();
    }


     
     
     
    function finalizeInternal() private returns (bool) {
        require(!finalized);

        finalized = true;

        Finalized();

         
        tokenContract.finalize();

        return true;
    }

     
    function addEarlyBird(address _address, uint256 weiAmount)
        onlyOwner
        withinContributionLimits(_address, weiAmount)
        external
    {
         
        require(tokenContract == address(0));

        earlyBirds.push(_address);
        earlyBirdInvestments[_address] = weiAmount;

         
        whitelist[_address] = true;
    }

     
    function processEarlyBirds()
        private
    {
        for (uint256 i = 0; i < earlyBirds.length; i++)
        {
            address earlyBirdAddress = earlyBirds[i];
            uint256 weiAmount = earlyBirdInvestments[earlyBirdAddress];

            buyTokens(earlyBirdAddress, weiAmount);
        }
    }


     
    function burnUnsoldTokens()
        external
        onlyAfterFinalized
        returns (bool)
    {
        uint256 leftTokens = getTokensLeft();

        require(leftTokens > 0);

         
        require(tokenContract.burn(leftTokens));

        UnsoldTokensBurnt(leftTokens);

        return true;
    }
}