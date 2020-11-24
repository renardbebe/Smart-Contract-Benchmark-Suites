 

pragma solidity ^0.4.3;

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner, "Sender not authorised.");
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC677 is ERC20 {
    function transferAndCall(address to, uint value, bytes data) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

 
library SafeMath {
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

 
library itmap {
    struct entry {
         
        uint keyIndex;
        uint value;
    }

    struct itmap {
        mapping(uint => entry) data;
        uint[] keys;
    }
    
    function insert(itmap storage self, uint key, uint value) internal returns (bool replaced) {
        entry storage e = self.data[key];
        e.value = value;
        if (e.keyIndex > 0) {
            return true;
        } else {
            e.keyIndex = ++self.keys.length;
            self.keys[e.keyIndex - 1] = key;
            return false;
        }
    }
    
    function remove(itmap storage self, uint key) internal returns (bool success) {
        entry storage e = self.data[key];
        if (e.keyIndex == 0)
            return false;
        
        if (e.keyIndex < self.keys.length) {
             
            self.data[self.keys[self.keys.length - 1]].keyIndex = e.keyIndex;
            self.keys[e.keyIndex - 1] = self.keys[self.keys.length - 1];
            self.keys.length -= 1;
            delete self.data[key];
            return true;
        }
    }
    
    function contains(itmap storage self, uint key) internal view returns (bool exists) {
        return self.data[key].keyIndex > 0;
    }
    
    function size(itmap storage self) internal view returns (uint) {
        return self.keys.length;
    }
    
    function get(itmap storage self, uint key) internal view returns (uint) {
        return self.data[key].value;
    }
    
    function getKey(itmap storage self, uint idx) internal view returns (uint) {
        return self.keys[idx];
    }
}

 
contract PoolOwners is Ownable {

    using SafeMath for uint256;
    using itmap for itmap.itmap;

    struct Owner {
        uint256 key;
        uint256 percentage;
        uint256 shareTokens;
        mapping(address => uint256) balance;
    }
    mapping(address => Owner) public owners;

    struct Distribution {
        address token;
        uint256 amount;
        uint256 owners;
        uint256 claimed;
        mapping(address => bool) claimedAddresses;
    }
    mapping(uint256 => Distribution) public distributions;

    mapping(address => uint256) public tokenBalance;
    mapping(address => uint256) public totalReturned;

    mapping(address => bool) private whitelist;

    itmap.itmap ownerMap;
    
    uint256 public totalContributed     = 0;
    uint256 public totalOwners          = 0;
    uint256 public totalDistributions   = 0;
    bool    public distributionActive   = false;
    uint256 public distributionMinimum  = 20 ether;
    uint256 public precisionMinimum     = 0.04 ether;
    bool    public locked               = false;
    address public wallet;

    bool    private contributionStarted = false;
    uint256 private valuation           = 4000 ether;
    uint256 private hardCap             = 996.96 ether;

    event Contribution(address indexed sender, uint256 share, uint256 amount);
    event ClaimedTokens(address indexed owner, address indexed token, uint256 amount, uint256 claimedStakers, uint256 distributionId);
    event TokenDistributionActive(address indexed token, uint256 amount, uint256 distributionId, uint256 amountOfOwners);
    event TokenWithdrawal(address indexed token, address indexed owner, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner, uint256 amount);
    event TokenDistributionComplete(address indexed token, uint256 amountOfOwners);

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender]);
        _;
    }

     
    constructor(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
    }

     
    function() public payable {
        require(contributionStarted, "Contribution phase hasn't started");
        require(whitelist[msg.sender], "You are not whitelisted");
        contribute(msg.sender, msg.value); 
        wallet.transfer(msg.value);
    }

     
    function setContribution(address _sender, uint256 _amount) public onlyOwner() { contribute(_sender, _amount); }

     
    function contribute(address _sender, uint256 _amount) private {
        require(!locked, "Crowdsale period over, contribution is locked");
        require(!distributionActive, "Cannot contribute when distribution is active");
        require(_amount >= precisionMinimum, "Amount needs to be above the minimum contribution");
        require(hardCap >= _amount, "Your contribution is greater than the hard cap");
        require(_amount % precisionMinimum == 0, "Your amount isn't divisible by the minimum precision");
        require(hardCap >= totalContributed.add(_amount), "Your contribution would cause the total to exceed the hardcap");

        totalContributed = totalContributed.add(_amount);
        uint256 share = percent(_amount, valuation, 5);

        Owner storage o = owners[_sender];
        if (o.percentage != 0) {  
            o.shareTokens = o.shareTokens.add(_amount);
            o.percentage = o.percentage.add(share);
        } else {  
            require(ownerMap.insert(totalOwners, uint(_sender)) == false);
            o.key = totalOwners;
            totalOwners += 1;
            o.shareTokens = _amount;
            o.percentage = share;
        }

        if (!whitelist[msg.sender]) {
            whitelist[msg.sender] = true;
        }

        emit Contribution(_sender, share, _amount);
    }

     
    function whitelistWallet(address _owner) external onlyOwner() {
        require(!locked, "Can't whitelist when the contract is locked");
        require(_owner != address(0), "Empty address");
        whitelist[_owner] = true;
    }

     
    function startContribution() external onlyOwner() {
        require(!contributionStarted, "Contribution has started");
        contributionStarted = true;
    }

     
    function setOwnerShare(address _owner, uint256 _value) public onlyOwner() {
        require(!locked, "Can't manually set shares, it's locked");
        require(!distributionActive, "Cannot set owners share when distribution is active");

        Owner storage o = owners[_owner];
        if (o.shareTokens == 0) {
            whitelist[_owner] = true;
            require(ownerMap.insert(totalOwners, uint(_owner)) == false);
            o.key = totalOwners;
            totalOwners += 1;
        }
        o.shareTokens = _value;
        o.percentage = percent(_value, valuation, 5);
    }

     
    function sendOwnership(address _receiver, uint256 _amount) public onlyWhitelisted() {
        Owner storage o = owners[msg.sender];
        Owner storage r = owners[_receiver];

        require(o.shareTokens > 0, "You don't have any ownership");
        require(o.shareTokens >= _amount, "The amount exceeds what you have");
        require(!distributionActive, "Distribution cannot be active when sending ownership");
        require(_amount % precisionMinimum == 0, "Your amount isn't divisible by the minimum precision amount");

        o.shareTokens = o.shareTokens.sub(_amount);

        if (o.shareTokens == 0) {
            o.percentage = 0;
            require(ownerMap.remove(o.key) == true);
        } else {
            o.percentage = percent(o.shareTokens, valuation, 5);
        }
        if (r.shareTokens == 0) {
            whitelist[_receiver] = true;
            require(ownerMap.insert(totalOwners, uint(_receiver)) == false);
            totalOwners += 1;
        }
        r.shareTokens = r.shareTokens.add(_amount);
        r.percentage = r.percentage.add(percent(_amount, valuation, 5));

        emit OwnershipTransferred(msg.sender, _receiver, _amount);
    }

     
    function lockShares() public onlyOwner() {
        require(!locked, "Shares already locked");
        locked = true;
    }

     
    function distributeTokens(address _token) public onlyWhitelisted() {
        require(!distributionActive, "Distribution is already active");
        distributionActive = true;

        ERC677 erc677 = ERC677(_token);

        uint256 currentBalance = erc677.balanceOf(this) - tokenBalance[_token];
        require(currentBalance > distributionMinimum, "Amount in the contract isn't above the minimum distribution limit");

        totalDistributions++;
        Distribution storage d = distributions[totalDistributions]; 
        d.owners = ownerMap.size();
        d.amount = currentBalance;
        d.token = _token;
        d.claimed = 0;
        totalReturned[_token] += currentBalance;

        emit TokenDistributionActive(_token, currentBalance, totalDistributions, d.owners);
    }

     
    function claimTokens(address _owner) public {
        Owner storage o = owners[_owner];
        Distribution storage d = distributions[totalDistributions]; 

        require(o.shareTokens > 0, "You need to have a share to claim tokens");
        require(distributionActive, "Distribution isn't active");
        require(!d.claimedAddresses[_owner], "Tokens already claimed for this address");

        address token = d.token;
        uint256 tokenAmount = d.amount.mul(o.percentage).div(100000);
        o.balance[token] = o.balance[token].add(tokenAmount);
        tokenBalance[token] = tokenBalance[token].add(tokenAmount);

        d.claimed++;
        d.claimedAddresses[_owner] = true;

        emit ClaimedTokens(_owner, token, tokenAmount, d.claimed, totalDistributions);

        if (d.claimed == d.owners) {
            distributionActive = false;
            emit TokenDistributionComplete(token, totalOwners);
        }
    }

     
    function withdrawTokens(address _token, uint256 _amount) public {
        require(_amount > 0, "You have requested for 0 tokens to be withdrawn");

        Owner storage o = owners[msg.sender];
        Distribution storage d = distributions[totalDistributions]; 

        if (distributionActive && !d.claimedAddresses[msg.sender]) {
            claimTokens(msg.sender);
        }
        require(o.balance[_token] >= _amount, "Amount requested is higher than your balance");

        o.balance[_token] = o.balance[_token].sub(_amount);
        tokenBalance[_token] = tokenBalance[_token].sub(_amount);

        ERC677 erc677 = ERC677(_token);
        require(erc677.transfer(msg.sender, _amount) == true);

        emit TokenWithdrawal(_token, msg.sender, _amount);
    }

     
    function setDistributionMinimum(uint256 _minimum) public onlyOwner() {
        distributionMinimum = _minimum;
    }

     
    function setEthWallet(address _wallet) public onlyOwner() {
        wallet = _wallet;
    }

     
    function isWhitelisted(address _owner) public view returns (bool) {
        return whitelist[_owner];
    }

     
    function getOwnerBalance(address _token) public view returns (uint256) {
        Owner storage o = owners[msg.sender];
        return o.balance[_token];
    }

     
    function getOwner(address _owner) public view returns (uint256, uint256, uint256) {
        Owner storage o = owners[_owner];
        return (o.key, o.shareTokens, o.percentage);
    }

     
    function getCurrentOwners() public view returns (uint) {
        return ownerMap.size();
    }

     
    function getOwnerAddress(uint _key) public view returns (address) {
        return address(ownerMap.get(_key));
    }

     
    function hasClaimed(address _owner, uint256 _dId) public view returns (bool) {
        Distribution storage d = distributions[_dId]; 
        return d.claimedAddresses[_owner];
    }

     
    function percent(uint numerator, uint denominator, uint precision) private pure returns (uint quotient) {
        uint _numerator = numerator * 10 ** (precision+1);
        uint _quotient = ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
    }
}