 

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

  function toUINT112(uint256 a) internal constant returns(uint112) {
    assert(uint112(a) == a);
    return uint112(a);
  }

  function toUINT120(uint256 a) internal constant returns(uint120) {
    assert(uint120(a) == a);
    return uint120(a);
  }

  function toUINT128(uint256 a) internal constant returns(uint128) {
    assert(uint128(a) == a);
    return uint128(a);
  }
}


 
 

contract Token {
     
     
     
    function totalSupply() constant returns (uint256 supply);

     
     
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

     
    struct Supplies {
         
         
        uint128 total;
        uint128 rawTokens;
    }

    Supplies supplies;

     
    struct Account {
         
         
        uint112 balance;

         
        uint112 rawTokens;

         
        uint32 lastMintedTimestamp;
    }

     
    mapping(address => Account) accounts;

     
    mapping(address => mapping(address => uint256)) allowed;

     
    uint256 bonusOffered;

     
    function VEN() {
    }

    function totalSupply() constant returns (uint256 supply){
        return supplies.total;
    }

     
    function () {
        revert();
    }

     
    function isSealed() constant returns (bool) {
        return owner == 0;
    }

    function lastMintedTimestamp(address _owner) constant returns(uint32) {
        return accounts[_owner].lastMintedTimestamp;
    }

     
    function claimBonus(address _owner) internal{      
        require(isSealed());
        if (accounts[_owner].rawTokens != 0) {
            uint256 realBalance = balanceOf(_owner);
            uint256 bonus = realBalance
                .sub(accounts[_owner].balance)
                .sub(accounts[_owner].rawTokens);

            accounts[_owner].balance = realBalance.toUINT112();
            accounts[_owner].rawTokens = 0;
            if(bonus > 0){
                Transfer(this, _owner, bonus);
            }
        }
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        if (accounts[_owner].rawTokens == 0)
            return accounts[_owner].balance;

        if (bonusOffered > 0) {
            uint256 bonus = bonusOffered
                 .mul(accounts[_owner].rawTokens)
                 .div(supplies.rawTokens);

            return bonus.add(accounts[_owner].balance)
                    .add(accounts[_owner].rawTokens);
        }
        
        return uint256(accounts[_owner].balance)
            .add(accounts[_owner].rawTokens);
    }

     
    function transfer(address _to, uint256 _amount) returns (bool success) {
        require(isSealed());

         
        claimBonus(msg.sender);
        claimBonus(_to);

         
        if (accounts[msg.sender].balance >= _amount
            && _amount > 0) {            
            accounts[msg.sender].balance -= uint112(_amount);
            accounts[_to].balance = _amount.add(accounts[_to].balance).toUINT112();
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
            && _amount > 0) {
            accounts[_from].balance -= uint112(_amount);
            allowed[_from][msg.sender] -= _amount;
            accounts[_to].balance = _amount.add(accounts[_to].balance).toUINT112();
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

     
    function mint(address _owner, uint256 _amount, bool _isRaw, uint32 timestamp) onlyOwner{
        if (_isRaw) {
            accounts[_owner].rawTokens = _amount.add(accounts[_owner].rawTokens).toUINT112();
            supplies.rawTokens = _amount.add(supplies.rawTokens).toUINT128();
        } else {
            accounts[_owner].balance = _amount.add(accounts[_owner].balance).toUINT112();
        }

        accounts[_owner].lastMintedTimestamp = timestamp;

        supplies.total = _amount.add(supplies.total).toUINT128();
        Transfer(0, _owner, _amount);
    }
    
     
    function offerBonus(uint256 _bonus) onlyOwner { 
        bonusOffered = bonusOffered.add(_bonus);
        supplies.total = _bonus.add(supplies.total).toUINT128();
        Transfer(0, this, _bonus);
    }

     
    function seal() onlyOwner {
        setOwner(0);
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


    uint256 public constant officialLimit = 64371825 * (10 ** 18);
    uint256 public constant channelsLimit = publicSupply - officialLimit;

     
    struct SoldOut {
        uint16 placeholder;  

         
         
        uint120 official; 

        uint120 channels;  
    }

    SoldOut soldOut;
    
    uint256 constant venPerEth = 3500;   
    uint256 constant venPerEthEarlyStage = venPerEth + venPerEth * 15 / 100;   

    uint constant minBuyInterval = 30 minutes;  
    uint constant maxBuyEthAmount = 30 ether;
   
    VEN ven;  

    address ethVault;  
    address venVault;  

    uint public constant startTime = 1503057600;  
    uint public constant endTime = 1504180800;    
    uint public constant earlyStageLasts = 3 days;  

    bool initialized;
    bool finalized;

    function VENSale() {
        soldOut.placeholder = 1;
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

     
    function blockTime() constant returns (uint32) {
        return uint32(block.timestamp);
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

        if (uint256(soldOut.official).add(soldOut.channels) >= publicSupply) {
             
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

    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

     
    function () payable {        
        buy();
    }

     
    function buy() payable {
         
        require(!isContract(msg.sender));
        require(msg.value >= 0.01 ether);

        uint256 rate = exchangeRate();
         
        require(rate > 0);
         
        require(blockTime() >= ven.lastMintedTimestamp(msg.sender) + minBuyInterval);

        uint256 requested;
         
        if (msg.value > maxBuyEthAmount) {
            requested = maxBuyEthAmount.mul(rate);
        } else {
            requested = msg.value.mul(rate);
        }

        uint256 remained = officialLimit.sub(soldOut.official);
        if (requested > remained) {
             
            requested = remained;
        }

        uint256 ethCost = requested.div(rate);
        if (requested > 0) {
            ven.mint(msg.sender, requested, true, blockTime());
             
            ethVault.transfer(ethCost);

            soldOut.official = requested.add(soldOut.official).toUINT120();
            onSold(msg.sender, requested, ethCost);        
        }

        uint256 toReturn = msg.value.sub(ethCost);
        if(toReturn > 0) {
             
            msg.sender.transfer(toReturn);
        }        
    }

     
    function officialSold() constant returns (uint256) {
        return soldOut.official;
    }

     
    function channelsSold() constant returns (uint256) {
        return soldOut.channels;
    } 

     
    function offerToChannel(address _channelAccount, uint256 _venAmount) onlyOwner {
        Stage stg = stage();
         
        require(stg == Stage.Early || stg == Stage.Normal || stg == Stage.Closed);

        soldOut.channels = _venAmount.add(soldOut.channels).toUINT120();

         
        require(soldOut.channels <= channelsLimit);

        ven.mint(
            _channelAccount,
            _venAmount,
            true,   
            blockTime()
            );

        onSold(_channelAccount, _venAmount, 0);
    }

     
     
     
     
    function initialize(
        VEN _ven,
        address _ethVault,
        address _venVault) onlyOwner {
        require(stage() == Stage.Created);

         
        require(_ven.owner() == address(this));

        require(address(_ethVault) != 0);
        require(address(_venVault) != 0);      

        ven = _ven;
        
        ethVault = _ethVault;
        venVault = _venVault;    
        
        ven.mint(
            venVault,
            reservedForTeam.add(reservedForOperations),
            false,  
            blockTime()
        );

        ven.mint(
            venVault,
            privateSupply.add(commercialPlan),
            true,  
            blockTime()
        );

        initialized = true;
        onInitialized();
    }

     
    function finalize() onlyOwner {
         
        require(stage() == Stage.Closed);       

        uint256 unsold = publicSupply.sub(soldOut.official).sub(soldOut.channels);

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