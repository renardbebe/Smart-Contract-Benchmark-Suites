 

pragma solidity ^0.4.11;

 
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

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract Ownable {
  address public owner;


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract SYNVault {
     
    bool public isSYNVault = false;

    SynchroCoin synchroCoin;
    address businessAddress;
    uint256 unlockedAtBlockNumber;
     
     
    uint256 public constant numBlocksLocked = 2129143;

     
     
    function SYNVault(address _businessAddress) public {
        require(_businessAddress != 0x0);
        synchroCoin = SynchroCoin(msg.sender);
        businessAddress = _businessAddress;
        isSYNVault = true;
        unlockedAtBlockNumber = SafeMath.add(block.number, numBlocksLocked);  
    }

     
    function unlock() external {
         
        require(block.number > unlockedAtBlockNumber);
         
        if (!synchroCoin.transfer(businessAddress, synchroCoin.balanceOf(this))) revert();
    }

     
    function () public { revert(); }
}

contract SynchroCoin is Ownable, StandardToken {

    string public constant symbol = "SYC";
    string public constant name = "SynchroCoin";
    uint8 public constant decimals = 18;
    uint256 public constant initialSupply = 100000000e18;     
    
    uint256 public constant startDate = 1506092400;
    uint256 public constant endDate = 1508511599;
    uint256 public constant firstPresaleStart = 1502884800;
    uint256 public constant firstPresaleEnd = 1503835140;
    uint256 public constant secondPresaleStart = 1504526400;
    uint256 public constant secondPresaleEnd = 1504785540;

     
    uint256 public constant crowdSalePercentage = 5500;
     
    uint256 public constant rewardPoolPercentage = 2000;
     
    uint256 public constant businessPercentage = 1450;
     
    uint256 public constant vaultPercentage = 950;
     
    uint256 public constant bountyPercentage = 100;
    
     
    uint256 public constant hundredPercent = 10000; 
    
     
     
     
    uint256 public constant totalFundedEther = 755427897026000000400;
    
     
     
     
    uint256 public constant totalConsideredFundedEther = 904571225465900000400;
    
    SYNVault public vault;
    address public businessAddress;
    address public rewardPoolAddress;
    
    uint256 public crowdSaleTokens;
    uint256 public bountyTokens;
    uint256 public rewardPoolTokens;

    function SynchroCoin(address _businessAddress, address _rewardPoolAddress) public {
        totalSupply = initialSupply;
        businessAddress = _businessAddress;
        rewardPoolAddress = _rewardPoolAddress;
        
        vault = new SYNVault(businessAddress);
        require(vault.isSYNVault());
        
        uint256 remainingSupply = initialSupply;
        
         
        crowdSaleTokens = SafeMath.div(SafeMath.mul(totalSupply, crowdSalePercentage), hundredPercent);
        remainingSupply = SafeMath.sub(remainingSupply, crowdSaleTokens);
        
         
        rewardPoolTokens = SafeMath.div(SafeMath.mul(totalSupply, rewardPoolPercentage), hundredPercent);
        balances[rewardPoolAddress] = SafeMath.add(balances[rewardPoolAddress], rewardPoolTokens);
        Transfer(0, rewardPoolAddress, rewardPoolTokens);
        remainingSupply = SafeMath.sub(remainingSupply, rewardPoolTokens);
        
         
        uint256 vaultTokens = SafeMath.div(SafeMath.mul(totalSupply, vaultPercentage), hundredPercent);
        balances[vault] = SafeMath.add(balances[vault], vaultTokens);
        Transfer(0, vault, vaultTokens);
        remainingSupply = SafeMath.sub(remainingSupply, vaultTokens);
        
         
        bountyTokens = SafeMath.div(SafeMath.mul(totalSupply, bountyPercentage), hundredPercent);
        remainingSupply = SafeMath.sub(remainingSupply, bountyTokens);
        
        balances[businessAddress] = SafeMath.add(balances[businessAddress], remainingSupply);
        Transfer(0, businessAddress, remainingSupply);
    }

     
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        return super.transfer(_to, _amount);
    }

     
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        return super.transferFrom(_from, _to, _amount);
    }
    
    function getBonusMultiplierAt(uint256 _timestamp) public constant returns (uint256) {
        if (_timestamp >= firstPresaleStart && _timestamp < firstPresaleEnd) {
            return 140;
        }
        else if (_timestamp >= secondPresaleStart && _timestamp < secondPresaleEnd) {
            return 130;
        }
        else if (_timestamp < (startDate + 1 days)) {
            return 120;
        }
        else if (_timestamp < (startDate + 7 days)) {
            return 115;
        }
        else if (_timestamp < (startDate + 14 days)) {
            return 110;
        }
        else if (_timestamp < (startDate + 21 days)) {
            return 105;
        }
        else if (_timestamp <= endDate) {
            return 100;
        }
        else {
            return 0;
        }
    }

    function distributeCrowdsaleTokens(address _to, uint256 _ether, uint256 _timestamp) public onlyOwner returns (uint256) {
        require(_to != 0x0);
        require(_ether >= 100 finney);
        require(_timestamp >= firstPresaleStart);
        require(_timestamp <= endDate);
        
         
        uint256 consideredFundedEther = SafeMath.div(SafeMath.mul(_ether, getBonusMultiplierAt(_timestamp)), 100);
         
        uint256 share = SafeMath.div(SafeMath.mul(consideredFundedEther, crowdSaleTokens), totalConsideredFundedEther);
        balances[_to] = SafeMath.add(balances[_to], share);
        Transfer(0, _to, share);
        return share;
    }
    
    function distributeBountyTokens(address[] _to, uint256[] _values) public onlyOwner {
        require(_to.length == _values.length);
        
        uint256 i = 0;
        while (i < _to.length) {
            bountyTokens = SafeMath.sub(bountyTokens, _values[i]);
            balances[_to[i]] = SafeMath.add(balances[_to[i]], _values[i]);
            Transfer(0, _to[i], _values[i]);
            i += 1;
        }
    }
    
    function completeBountyDistribution() public onlyOwner {
         
        balances[businessAddress] = SafeMath.add(balances[businessAddress], bountyTokens);
        Transfer(0, businessAddress, bountyTokens);
        bountyTokens = 0;
    }
}