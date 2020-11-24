 

pragma solidity ^0.4.13;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
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

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract FollowCoin is Ownable, ERC20 {
    using SafeMath for uint256;

     
    string public name;
    string public symbol;
    uint8 public decimals;
    
     
    mapping (address => uint256) public balances;
    mapping (address => bool) public allowedAccount;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public isHolder;
    address [] public holders;

     
    event Burn(address indexed from, uint256 value);

    bool public contributorsLockdown = true;

    function disableLockDown() onlyOwner {
      contributorsLockdown = false;
    }

    modifier coinsLocked() {
      require(!contributorsLockdown || msg.sender == owner || allowedAccount[msg.sender]);
      _;
    }

     
    function FollowCoin(
        
        address multiSigWallet,
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        
    ) {

        owner = multiSigWallet;
        totalSupply = initialSupply;                         
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        decimals = decimalUnits;                             
        balances[owner] = totalSupply;                    

        if (isHolder[owner] != true) {
            holders[holders.length++] = owner;
            isHolder[owner] = true;
        }
    }

     
    function _transfer(address _from, address _to, uint _value) internal coinsLocked {
        require(_to != 0x0);                                

        require(balanceOf(_from) >= _value);                 
        require(balanceOf(_to).add(_value) > balanceOf(_to));  
        balances[_from] = balanceOf(_from).sub(_value);                          
        balances[_to] = balanceOf(_to).add(_value);                            

        if (isHolder[_to] != true) {
            holders[holders.length++] = _to;
            isHolder[_to] = true;
        }
        Transfer(_from, _to, _value);
    }
    
     

    function transfer(address _to, uint256 _value) public returns (bool)  {
        require(_to != address(this));
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }


    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
         return allowance[_owner][_spender];
    }


    function allowAccount(address _target, bool allow) onlyOwner returns (bool success) {

         allowedAccount[_target] = allow;
         return true;
    }

    function mint(uint256 mintedAmount) onlyOwner {
        balances[msg.sender] = balanceOf(msg.sender).add(mintedAmount);
        totalSupply  = totalSupply.add(mintedAmount);
        Transfer(0, owner, mintedAmount);
    }

     
    function burn(uint256 _value) onlyOwner returns (bool success) {
        require(balanceOf(msg.sender) >= _value);    
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);             
        totalSupply = totalSupply.sub(_value);                       
        Burn(msg.sender, _value);
        return true;
    }
}


 
 contract Haltable is Ownable {
   bool public halted;

   modifier inNormalState {
     assert(!halted);
     _;
   }

   modifier inEmergencyState {
     assert(halted);
     _;
   }

    
   function halt() external onlyOwner inNormalState {
     halted = true;
   }

    
   function unhalt() external onlyOwner inEmergencyState {
     halted = false;
   }

 }

contract FollowCoinTokenSale is Haltable {
    using SafeMath for uint256;

    address public beneficiary;
    address public multisig;
    uint public tokenLimitPerWallet;
    uint public hardCap;
    uint public amountRaised;
    uint public totalTokens;
    uint public tokensSold = 0;
    uint public investorCount = 0;
    uint public startTimestamp;
    uint public deadline;
    uint public tokensPerEther;
    FollowCoin public tokenReward;
    mapping(address => uint256) public balances;

    event FundTransfer(address backer, uint amount, bool isContribution);

     
    function FollowCoinTokenSale(
        address multiSigWallet,
        uint icoTokensLimitPerWallet,
        uint icoHardCap,
        uint icoStartTimestamp,
        uint durationInDays,
        uint icoTotalTokens,
        uint icoTokensPerEther,
        address addressOfTokenUsedAsReward
        
    ) {
        multisig = multiSigWallet;
        owner = multiSigWallet;
        hardCap = icoHardCap;
        deadline = icoStartTimestamp + durationInDays * 1 days;
        startTimestamp = icoStartTimestamp;
        totalTokens = icoTotalTokens;
        tokenLimitPerWallet = icoTokensLimitPerWallet;
        tokensPerEther = icoTokensPerEther;
        tokenReward = FollowCoin(addressOfTokenUsedAsReward);
        beneficiary = multisig;
    }

    function changeMultisigWallet(address _multisig) onlyOwner {
        require(_multisig != address(0));
        multisig = _multisig;
    }

    function changeTokenReward(address _token) onlyOwner {
        require(_token != address(0));
        tokenReward = FollowCoin(_token);
        beneficiary = tokenReward.owner();
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
    function () payable preSaleActive inNormalState {
        buyTokens();
    }

    function buyTokens() payable preSaleActive inNormalState {
        require(msg.value > 0);
       
        uint amount = msg.value;
        require(balanceOf(msg.sender).add(amount) <= tokenLimitPerWallet);

        uint tokens =  calculateTokenAmount(amount);
        require(totalTokens >= tokens);
        require(tokensSold.add(tokens) <= hardCap);  
        
        balances[msg.sender] = balances[msg.sender].add(amount);
        amountRaised = amountRaised.add(amount);

        tokensSold = tokensSold.add(tokens);
        totalTokens = totalTokens.sub(tokens);

        if (tokenReward.balanceOf(msg.sender) == 0) investorCount++;

        tokenReward.transfer(msg.sender, tokens);
        multisig.transfer(amount);
        FundTransfer(msg.sender, amount, true);
    }

    modifier preSaleActive() {
      require(now >= startTimestamp);
      require(now < deadline);
      _;
    }

    function setSold(uint tokens) onlyOwner {
      tokensSold = tokensSold.add(tokens);
    }


    function sendTokensBackToWallet() onlyOwner {
      totalTokens = 0;
      tokenReward.transfer(multisig, tokenReward.balanceOf(address(this)));
    }

    function getTokenBalance(address _from) constant returns(uint) {
      return tokenReward.balanceOf(_from);
    }

    function calculateTokenAmount(uint256 amount) constant returns(uint256) {
        return amount.mul(tokensPerEther);
    }
}