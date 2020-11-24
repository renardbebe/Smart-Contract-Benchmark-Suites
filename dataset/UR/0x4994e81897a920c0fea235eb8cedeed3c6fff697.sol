 

pragma solidity ^0.4.10;

 
 
 
 
 
 
 
 
 
 


 
 
 
 
 
contract Owned {
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }
 
    function acceptOwnership() {
        if (msg.sender != newOwner) throw;
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


 
 
 
 
 
 
contract ERC20Interface {
    function totalSupply() constant returns (uint256 totalSupply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) 
        returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant 
        returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, 
        uint256 _value);
}


 
 
 
 
 
contract ERC20Token is Owned, ERC20Interface {
    uint256 _totalSupply = 0;

     
     
     
    mapping(address => uint256) balances;

     
     
     
    mapping(address => mapping (address => uint256)) allowed;

     
     
     
    function totalSupply() constant returns (uint256 totalSupply) {
        totalSupply = _totalSupply;
    }

     
     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
     
     
    function transfer(
        address _to,
        uint256 _amount
    ) returns (bool success) {
        if (balances[msg.sender] >= _amount              
            && _amount > 0                               
            && balances[_to] + _amount > balances[_to]   
        ) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
     
     
     
    function approve(
        address _spender,
        uint256 _amount
    ) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) returns (bool success) {
        if (balances[_from] >= _amount                   
            && allowed[_from][msg.sender] >= _amount     
            && _amount > 0                               
            && balances[_to] + _amount > balances[_to]   
        ) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
     
     
    function allowance(
        address _owner, 
        address _spender
    ) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}


 
 
 
 
 
contract SikobaContinuousSale is ERC20Token {

     
     
     
    string public constant symbol = "SKO1";
    string public constant name = "Sikoba Continuous Sale";
    uint8 public constant decimals = 18;

     
    uint256 public constant START_DATE = 1496275200;

     
    uint256 public constant END_DATE = 1509494399;

     
    uint256 public constant START_SKO1_UNITS = 1650;
    uint256 public constant END_SKO1_UNITS = 1200;

     
    uint256 public constant MIN_CONTRIBUTION = 10**16;

     
    uint256 public constant ONE_DAY = 24*60*60;

     
    uint256 public constant MAX_USD_FUNDING = 400000;
    uint256 public totalUsdFunding;
    bool public maxUsdFundingReached = false;
    uint256 public usdPerHundredEth;
    uint256 public softEndDate = END_DATE;

     
    uint256 public ethersContributed = 0;

     
    bool public mintingCompleted = false;
    bool public fundingPaused = false;

     
    uint256 public constant MULT_FACTOR = 10**18;

     
     
     
    event UsdRateSet(uint256 _usdPerHundredEth);
    event TokensBought(address indexed buyer, uint256 ethers, uint256 tokens, 
          uint256 newTotalSupply, uint256 unitsPerEth);

     
     
     
    function SikobaContinuousSale(uint256 _usdPerHundredEth) {
        setUsdPerHundredEth(_usdPerHundredEth);
    }

     
     
     
     
    function setUsdPerHundredEth(uint256 _usdPerHundredEth) onlyOwner {
        usdPerHundredEth = _usdPerHundredEth;
        UsdRateSet(_usdPerHundredEth);
    }

     
     
     
     
    function unitsPerEth() constant returns (uint256) {
        return unitsPerEthAt(now);
    }

    function unitsPerEthAt(uint256 at) constant returns (uint256) {
        if (at < START_DATE) {
            return START_SKO1_UNITS * MULT_FACTOR;
        } else if (at > END_DATE) {
            return END_SKO1_UNITS * MULT_FACTOR;
        } else {
            return START_SKO1_UNITS * MULT_FACTOR
                - ((START_SKO1_UNITS - END_SKO1_UNITS) * MULT_FACTOR 
                   * (at - START_DATE)) / (END_DATE - START_DATE);
        }
    }

     
     
     
    function () payable {
        buyTokens();
    }

    function buyTokens() payable {
         
        if (fundingPaused) throw;
        if (now < START_DATE) throw;
        if (now > END_DATE) throw;
        if (now > softEndDate) throw;
        if (msg.value < MIN_CONTRIBUTION) throw;

         
        uint256 _unitsPerEth = unitsPerEth();
        uint256 tokens = msg.value * _unitsPerEth / MULT_FACTOR;
        _totalSupply += tokens;
        balances[msg.sender] += tokens;
        Transfer(0x0, msg.sender, tokens);

         
        totalUsdFunding += msg.value * usdPerHundredEth / 10**20;
        if (!maxUsdFundingReached && totalUsdFunding > MAX_USD_FUNDING) {
            softEndDate = now + ONE_DAY;
            maxUsdFundingReached = true;
        }

        ethersContributed += msg.value;
        TokensBought(msg.sender, msg.value, tokens, _totalSupply, _unitsPerEth);

         
        if (!owner.send(this.balance)) throw;
    }

     
     
     
    function pause() external onlyOwner {
        fundingPaused = true;
    }

    function restart() external onlyOwner {
        fundingPaused = false;
    }


     
     
     
     
     
    function mint(address participant, uint256 tokens) onlyOwner {
        if (mintingCompleted) throw;
        balances[participant] += tokens;
        _totalSupply += tokens;
        Transfer(0x0, participant, tokens);
    }

    function setMintingCompleted() onlyOwner {
        mintingCompleted = true;
    }

     
     
     
    function transferAnyERC20Token(
        address tokenAddress, 
        uint256 amount
    ) onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, amount);
    }
}