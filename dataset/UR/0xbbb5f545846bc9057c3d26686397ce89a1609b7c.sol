 

pragma solidity ^0.4.11;

contract Owned {

    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address _newOwner) onlyOwner {
        owner = _newOwner;
    }
}


 
library Prealloc {
    struct UINT256 {
        uint256 value_;
    }

    function set(UINT256 storage i, uint256 value) internal {
        i.value_ = ~value;
    }

    function get(UINT256 storage i) internal constant returns (uint256) {
        return ~i.value_;
    }
}


 
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



 
 

contract Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}



 
contract VEN is Token, Owned {
    using SafeMath for uint256;

    string public constant name    = "VeChain Token";   
    uint8 public constant decimals = 18;                
    string public constant symbol  = "VEN";             

    struct Account {
        uint256 balance;
         
        uint256 rawTokens;
    }

     
    mapping(address => Account) accounts;

     
    mapping(address => mapping(address => uint256)) allowed;

     
     
    using Prealloc for Prealloc.UINT256;
    Prealloc.UINT256 rawTokensSupplied;

     
    uint256 bonusOffered;

     
    function VEN() {
        rawTokensSupplied.set(0);
    }

     
    function () {
        revert();
    }

     
    function isSealed() constant returns (bool) {
        return owner == 0;
    }

     
    function claimBonus(address _owner) internal{      
        require(isSealed());
        if (accounts[_owner].rawTokens != 0) {
            accounts[_owner].balance = balanceOf(_owner);
            accounts[_owner].rawTokens = 0;
        }
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        if (accounts[_owner].rawTokens == 0)
            return accounts[_owner].balance;

        if (isSealed()) {
            uint256 bonus = 
                 accounts[_owner].rawTokens
                .mul(bonusOffered)
                .div(rawTokensSupplied.get());

            return accounts[_owner].balance
                    .add(accounts[_owner].rawTokens)
                    .add(bonus);
        }
        
        return accounts[_owner].balance.add(accounts[_owner].rawTokens);
    }

     
    function transfer(address _to, uint256 _amount) returns (bool success) {
        require(isSealed());

         
        claimBonus(msg.sender);
        claimBonus(_to);

        if (accounts[msg.sender].balance >= _amount
            && _amount > 0
            && accounts[_to].balance + _amount > accounts[_to].balance) {
            accounts[msg.sender].balance -= _amount;
            accounts[_to].balance += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) returns (bool success) {
        require(isSealed());

         
        claimBonus(_from);
        claimBonus(_to);

        if (accounts[_from].balance >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && accounts[_to].balance + _amount > accounts[_to].balance) {
            accounts[_from].balance -= _amount;
            allowed[_from][msg.sender] -= _amount;
            accounts[_to].balance += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
         
        ApprovalReceiver(_spender).receiveApproval(msg.sender, _value, this, _extraData);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function mint(address _owner, uint256 _amount, bool _isRaw) onlyOwner{
        if (_isRaw) {
            accounts[_owner].rawTokens = accounts[_owner].rawTokens.add(_amount);
            rawTokensSupplied.set(rawTokensSupplied.get().add(_amount));
        } else {
            accounts[_owner].balance = accounts[_owner].balance.add(_amount);
        }

        totalSupply = totalSupply.add(_amount);
        Transfer(0, _owner, _amount);
    }
    
     
    function offerBonus(uint256 _bonus) onlyOwner {
        bonusOffered = bonusOffered.add(_bonus);
    }

     
    function seal() onlyOwner {
        setOwner(0);

        totalSupply = totalSupply.add(bonusOffered);
        Transfer(0, address(-1), bonusOffered);
    }
}

contract ApprovalReceiver {
    function receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData);
}


 
contract VENSale is Owned{

     
     
     
     
     
     
    enum Stage {
        NotCreated,
        Created,
        Initialized,
        Early,
        Normal,
        Closed,
        Finalized
    }

    using SafeMath for uint256;
    
    uint256 public constant totalSupply         = (10 ** 9) * (10 ** 18);  

    uint256 constant privateSupply              = totalSupply * 9 / 100;   
    uint256 constant commercialPlan             = totalSupply * 23 / 100;  
    uint256 constant reservedForTeam            = totalSupply * 5 / 100;   
    uint256 constant reservedForOperations      = totalSupply * 22 / 100;  

     
    uint256 public constant nonPublicSupply     = privateSupply + commercialPlan + reservedForTeam + reservedForOperations;
     
    uint256 public constant publicSupply = totalSupply - nonPublicSupply;

    uint256 public officialLimit;
    uint256 public channelsLimit;

    using Prealloc for Prealloc.UINT256;
    Prealloc.UINT256 officialSold_;  

    uint256 public channelsSold;     
    
    uint256 constant venPerEth = 3500;   
    uint256 constant venPerEthEarlyStage = venPerEth + venPerEth * 15 / 100;   
   
    VEN ven;  

    address ethVault;  
    address venVault;  

    uint public startTime;  
    uint public endTime;    
    uint public earlyStageLasts;  

    bool initialized;
    bool finalized;

    function VENSale() {
        officialSold_.set(0);
    }    

     
     
    function exchangeRate() constant returns (uint256){
        if (stage() == Stage.Early) {
            return venPerEthEarlyStage;
        }
        if (stage() == Stage.Normal) {
            return venPerEth;
        }
        return 0;
    }

     
    function blockTime() constant returns (uint) {
        return block.timestamp;
    }

     
     
    function stage() constant returns (Stage) { 
        if (finalized) {
            return Stage.Finalized;
        }

        if (!initialized) {
             
            return Stage.Created;
        }

        if (blockTime() < startTime) {
             
            return Stage.Initialized;
        }

        if (officialSold_.get().add(channelsSold) >= publicSupply) {
             
            return Stage.Closed;
        }

        if (blockTime() < endTime) {
             
            if (blockTime() < startTime.add(earlyStageLasts)) {
                 
                return Stage.Early;
            }
             
            return Stage.Normal;
        }

         
        return Stage.Closed;
    }

     
    function () payable {        
        buy();
    }

     
    function buy() payable {
        require(msg.value >= 0.01 ether);

        uint256 rate = exchangeRate();
         
        require(rate > 0);

        uint256 remained = officialLimit.sub(officialSold_.get());
        uint256 requested = msg.value.mul(rate);
        if (requested > remained) {
             
            requested = remained;
        }

        uint256 ethCost = requested.div(rate);
        if (requested > 0) {
            ven.mint(msg.sender, requested, true);
             
            ethVault.transfer(ethCost);

            officialSold_.set(officialSold_.get().add(requested));
            onSold(msg.sender, requested, ethCost);        
        }

        uint256 toReturn = msg.value.sub(ethCost);
        if(toReturn > 0) {
             
            msg.sender.transfer(toReturn);
        }        
    }

     
    function officialSold() constant returns (uint256) {
        return officialSold_.get();
    }

     
    function offerToChannels(uint256 _venAmount) onlyOwner {
        Stage stg = stage();
         
        require(stg == Stage.Early || stg == Stage.Normal || stg == Stage.Closed);

        channelsSold = channelsSold.add(_venAmount);

         
        require(channelsSold <= channelsLimit);

        ven.mint(
            venVault,
            _venAmount,
            true   
            );

        onSold(venVault, _venAmount, 0);
    }

     
     
     
     
     
     
     
     
    function initialize(
        VEN _ven,
        address _ethVault,
        address _venVault,
        uint256 _channelsLimit,
        uint _startTime,
        uint _endTime,
        uint _earlyStageLasts) onlyOwner {
        require(stage() == Stage.Created);

         
        require(_ven.owner() == address(this));

        require(address(_ethVault) != 0);
        require(address(_venVault) != 0);

        require(_startTime > blockTime());
        require(_startTime.add(_earlyStageLasts) < _endTime);        

        ven = _ven;
        
        ethVault = _ethVault;
        venVault = _venVault;

        channelsLimit = _channelsLimit;
        officialLimit = publicSupply.sub(_channelsLimit);

        startTime = _startTime;
        endTime = _endTime;
        earlyStageLasts = _earlyStageLasts;        
        
        ven.mint(
            venVault,
            reservedForTeam.add(reservedForOperations),
            false  
        );

        ven.mint(
            venVault,
            privateSupply.add(commercialPlan),
            true  
        );

        initialized = true;
        onInitialized();
    }

     
    function finalize() onlyOwner {
         
        require(stage() == Stage.Closed);       

        uint256 unsold = publicSupply.sub(officialSold_.get()).sub(channelsSold);

        if (unsold > 0) {
             
            ven.offerBonus(unsold);        
        }
        ven.seal();

        finalized = true;
        onFinalized();
    }

    event onInitialized();
    event onFinalized();

    event onSold(address indexed buyer, uint256 venAmount, uint256 ethCost);
}