 

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


 
contract Ownable {
    address public owner;
    address public newOwner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    function Ownable() public {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        OwnershipTransferred(owner, _newOwner);
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


 
contract ApisToken is StandardToken, Ownable {
     
    string public constant name = "APIS";
    
     
    string public constant symbol = "APIS";
    
     
    uint8 public constant decimals = 18;
    
     
    mapping (address => LockedInfo) public lockedWalletInfo;
    
     
    mapping (address => bool) public manoContracts;
    
    
     
    struct LockedInfo {
        uint timeLockUpEnd;
        bool sendLock;
        bool receiveLock;
    } 
    
    
     
    event Transfer (address indexed from, address indexed to, uint256 value);
    
     
    event Locked (address indexed target, uint timeLockUpEnd, bool sendLock, bool receiveLock);
    
     
    event Unlocked (address indexed target);
    
     
    event RejectedPaymentToLockedUpWallet (address indexed from, address indexed to, uint256 value);
    
     
    event RejectedPaymentFromLockedUpWallet (address indexed from, address indexed to, uint256 value);
    
     
    event Burn (address indexed burner, uint256 value);
    
     
    event ManoContractRegistered (address manoContract, bool registered);
    
     
    function ApisToken() public {
         
        uint256 supplyApis = 9520000000;
        
         
        totalSupply = supplyApis * 10 ** uint256(decimals);
        
        balances[msg.sender] = totalSupply;
        
        Transfer(0x0, msg.sender, totalSupply);
    }
    
    
     
    function walletLock(address _targetWallet, uint _timeLockEnd, bool _sendLock, bool _receiveLock) onlyOwner public {
        require(_targetWallet != 0x0);
        
         
        if(_sendLock == false && _receiveLock == false) {
            _timeLockEnd = 0;
        }
        
        lockedWalletInfo[_targetWallet].timeLockUpEnd = _timeLockEnd;
        lockedWalletInfo[_targetWallet].sendLock = _sendLock;
        lockedWalletInfo[_targetWallet].receiveLock = _receiveLock;
        
        if(_timeLockEnd > 0) {
            Locked(_targetWallet, _timeLockEnd, _sendLock, _receiveLock);
        } else {
            Unlocked(_targetWallet);
        }
    }
    
     
    function walletLockBoth(address _targetWallet, uint _timeLockUpEnd) onlyOwner public {
        walletLock(_targetWallet, _timeLockUpEnd, true, true);
    }
    
     
    function walletLockBothForever(address _targetWallet) onlyOwner public {
        walletLock(_targetWallet, 999999999999, true, true);
    }
    
    
     
    function walletUnlock(address _targetWallet) onlyOwner public {
        walletLock(_targetWallet, 0, false, false);
    }
    
     
    function isWalletLocked_Send(address _addr) public constant returns (bool isSendLocked, uint until) {
        require(_addr != 0x0);
        
        isSendLocked = (lockedWalletInfo[_addr].timeLockUpEnd > now && lockedWalletInfo[_addr].sendLock == true);
        
        if(isSendLocked) {
            until = lockedWalletInfo[_addr].timeLockUpEnd;
        } else {
            until = 0;
        }
    }
    
     
    function isWalletLocked_Receive(address _addr) public constant returns (bool isReceiveLocked, uint until) {
        require(_addr != 0x0);
        
        isReceiveLocked = (lockedWalletInfo[_addr].timeLockUpEnd > now && lockedWalletInfo[_addr].receiveLock == true);
        
        if(isReceiveLocked) {
            until = lockedWalletInfo[_addr].timeLockUpEnd;
        } else {
            until = 0;
        }
    }
    
     
    function isMyWalletLocked_Send() public constant returns (bool isSendLocked, uint until) {
        return isWalletLocked_Send(msg.sender);
    }
    
     
    function isMyWalletLocked_Receive() public constant returns (bool isReceiveLocked, uint until) {
        return isWalletLocked_Receive(msg.sender);
    }
    
    
     
    function registerManoContract(address manoAddr, bool registered) onlyOwner public {
        manoContracts[manoAddr] = registered;
        
        ManoContractRegistered(manoAddr, registered);
    }
    
    
     
    function transfer(address _to, uint256 _apisWei) public returns (bool) {
         
        require(_to != address(this));
        
         
        if(manoContracts[msg.sender] || manoContracts[_to]) {
            return super.transfer(_to, _apisWei);
        }
        
         
        if(lockedWalletInfo[msg.sender].timeLockUpEnd > now && lockedWalletInfo[msg.sender].sendLock == true) {
            RejectedPaymentFromLockedUpWallet(msg.sender, _to, _apisWei);
            return false;
        } 
         
        else if(lockedWalletInfo[_to].timeLockUpEnd > now && lockedWalletInfo[_to].receiveLock == true) {
            RejectedPaymentToLockedUpWallet(msg.sender, _to, _apisWei);
            return false;
        } 
         
        else {
            return super.transfer(_to, _apisWei);
        }
    }
    
     
    function transferAndLockUntil(address _to, uint256 _apisWei, uint _timeLockUpEnd) onlyOwner public {
        require(transfer(_to, _apisWei));
        
        walletLockBoth(_to, _timeLockUpEnd);
    }
    
     
    function transferAndLockForever(address _to, uint256 _apisWei) onlyOwner public {
        require(transfer(_to, _apisWei));
        
        walletLockBothForever(_to);
    }
    
    
     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
        require(_value <= totalSupply);
        
        address burner = msg.sender;
        balances[burner] -= _value;
        totalSupply -= _value;
        
        Burn(burner, _value);
    }
    
    
     
    function () public payable {
        revert();
    }
}








 
contract WhiteList is Ownable {
    
    mapping (address => uint8) internal list;
    
     
    event WhiteBacker(address indexed backer, bool allowed);
    
    
     
    function setWhiteBacker(address _target, bool _allowed) onlyOwner public {
        require(_target != 0x0);
        
        if(_allowed == true) {
            list[_target] = 1;
        } else {
            list[_target] = 0;
        }
        
        WhiteBacker(_target, _allowed);
    }
    
     
    function addWhiteBacker(address _target) onlyOwner public {
        setWhiteBacker(_target, true);
    }
    
     
    function setWhiteBackersByList(address[] _backers, bool[] _allows) onlyOwner public {
        require(_backers.length > 0);
        require(_backers.length == _allows.length);
        
        for(uint backerIndex = 0; backerIndex < _backers.length; backerIndex++) {
            setWhiteBacker(_backers[backerIndex], _allows[backerIndex]);
        }
    }
    
     
    function addWhiteBackersByList(address[] _backers) onlyOwner public {
        for(uint backerIndex = 0; backerIndex < _backers.length; backerIndex++) {
            setWhiteBacker(_backers[backerIndex], true);
        }
    }
    
    
     
    function isInWhiteList(address _addr) public constant returns (bool) {
        require(_addr != 0x0);
        return list[_addr] > 0;
    }
    
     
    function isMeInWhiteList() public constant returns (bool isWhiteBacker) {
        return list[msg.sender] > 0;
    }
}



 
contract ApisCrowdSale is Ownable {
    
     
    uint8 public constant decimals = 18;
    
    
     
    uint256 public fundingGoal;
    
     
     
    uint256 public fundingGoalCurrent;
    
     
    uint256 public priceOfApisPerFund;
    

     
     
    
     
     
    
     
     
    
    
     
     
    
     
     
    
     
     

    
     
    uint public startTime;
    
     
    uint public endTime;

     
    bool closed = false;
    
	SaleStatus public saleStatus;
    
     
    ApisToken internal tokenReward;
    
     
    WhiteList internal whiteList;

    
    
    mapping (address => Property) public fundersProperty;
    
     
    struct Property {
        uint256 reservedFunds;    
        uint256 paidFunds;    	 
        uint256 reservedApis;    
        uint256 withdrawedApis;  
        uint purchaseTime;       
    }
	
	
	 
	struct SaleStatus {
		uint256 totalReservedFunds;
		uint256 totalPaidFunds;
		uint256 totalReceivedFunds;
		
		uint256 totalReservedApis;
		uint256 totalWithdrawedApis;
		uint256 totalSoldApis;
	}
    
    
    
     
    event ReservedApis(address beneficiary, uint256 amountOfFunds, uint256 amountOfApis);
    
     
    event WithdrawalFunds(address addr, uint256 amount);
    
     
    event WithdrawalApis(address funder, uint256 amountOfFunds, uint256 amountOfApis);
    
    
     
    event Refund(address _backer, uint256 _amountFunds, uint256 _amountApis);
    
    
     
    modifier onSale() {
        require(now >= startTime);
        require(now < endTime);
        require(closed == false);
        require(priceOfApisPerFund > 0);
        require(fundingGoalCurrent > 0);
        _;
    }
    
     
    modifier onFinished() {
        require(now >= endTime || closed == true);
        _;
    }
    
     
    modifier claimable() {
        require(whiteList.isInWhiteList(msg.sender) == true);
        require(fundersProperty[msg.sender].reservedFunds > 0);
        _;
    }
    
    
     
    function ApisCrowdSale (
        uint256 _fundingGoalApis,
        uint _startTime,
        uint _endTime,
        address _addressOfApisTokenUsedAsReward,
        address _addressOfWhiteList
    ) public {
        require (_fundingGoalApis > 0);
        require (_startTime > now);
        require (_endTime > _startTime);
        require (_addressOfApisTokenUsedAsReward != 0x0);
        require (_addressOfWhiteList != 0x0);
        
        fundingGoal = _fundingGoalApis * 10 ** uint256(decimals);
        
        startTime = _startTime;
        endTime = _endTime;
        
         
        tokenReward = ApisToken(_addressOfApisTokenUsedAsReward);
        
         
        whiteList = WhiteList(_addressOfWhiteList);
    }
    
     
    function closeSale(bool _closed) onlyOwner public {
        require (closed == false);
        
        closed = _closed;
    }
    
     
    function setPriceOfApis(uint256 price) onlyOwner public {
        require(priceOfApisPerFund == 0);
        
        priceOfApisPerFund = price;
    }
    
     
    function setCurrentFundingGoal(uint256 _currentFundingGoalAPIS) onlyOwner public {
        uint256 fundingGoalCurrentWei = _currentFundingGoalAPIS * 10 ** uint256(decimals);
        require(fundingGoalCurrentWei >= saleStatus.totalSoldApis);
        
        fundingGoalCurrent = fundingGoalCurrentWei;
    }
    
    
     
    function balanceOf(address _addr) public view returns (uint256 balance) {
        return tokenReward.balanceOf(_addr);
    }
    
     
    function whiteListOf(address _addr) public view returns (string message) {
        if(whiteList.isInWhiteList(_addr) == true) {
            return "The address is in whitelist.";
        } else {
            return "The address is *NOT* in whitelist.";
        }
    }
    
    
     
    function isClaimable(address _addr) public view returns (string message) {
        if(fundersProperty[_addr].reservedFunds == 0) {
            return "The address has no claimable balance.";
        }
        
        if(whiteList.isInWhiteList(_addr) == false) {
            return "The address must be registered with KYC and Whitelist";
        }
        
        else {
            return "The address can claim APIS!";
        }
    }
    
    
     
    function () onSale public payable {
        buyToken(msg.sender);
    }
    
     
    function buyToken(address _beneficiary) onSale public payable {
         
        require(_beneficiary != 0x0);
        
         
        bool isLocked = false;
        uint timeLock = 0;
        (isLocked, timeLock) = tokenReward.isWalletLocked_Send(this);
        
        require(isLocked == false);
        
        
        uint256 amountFunds = msg.value;
        uint256 reservedApis = amountFunds * priceOfApisPerFund;
        
        
         
        require(saleStatus.totalSoldApis + reservedApis <= fundingGoalCurrent);
        require(saleStatus.totalSoldApis + reservedApis <= fundingGoal);
        
         
        fundersProperty[_beneficiary].reservedFunds += amountFunds;
        fundersProperty[_beneficiary].reservedApis += reservedApis;
        fundersProperty[_beneficiary].purchaseTime = now;
        
         
        saleStatus.totalReceivedFunds += amountFunds;
        saleStatus.totalReservedFunds += amountFunds;
        
        saleStatus.totalSoldApis += reservedApis;
        saleStatus.totalReservedApis += reservedApis;
        
        
         
        if(whiteList.isInWhiteList(_beneficiary) == true) {
            withdrawal(_beneficiary);
        }
        else {
             
            ReservedApis(_beneficiary, amountFunds, reservedApis);
        }
    }
    
    
    
     
    function claimApis(address _target) public {
         
        require(whiteList.isInWhiteList(_target) == true);
         
        require(fundersProperty[_target].reservedFunds > 0);
        
        withdrawal(_target);
    }
    
     
    function claimMyApis() claimable public {
        withdrawal(msg.sender);
    }
    
    
     
    function withdrawal(address funder) internal {
         
        assert(tokenReward.transferFrom(owner, funder, fundersProperty[funder].reservedApis));
        
        fundersProperty[funder].withdrawedApis += fundersProperty[funder].reservedApis;
        fundersProperty[funder].paidFunds += fundersProperty[funder].reservedFunds;
        
         
        saleStatus.totalReservedFunds -= fundersProperty[funder].reservedFunds;
        saleStatus.totalPaidFunds += fundersProperty[funder].reservedFunds;
        
        saleStatus.totalReservedApis -= fundersProperty[funder].reservedApis;
        saleStatus.totalWithdrawedApis += fundersProperty[funder].reservedApis;
        
         
        WithdrawalApis(funder, fundersProperty[funder].reservedFunds, fundersProperty[funder].reservedApis);
        
         
        fundersProperty[funder].reservedFunds = 0;
        fundersProperty[funder].reservedApis = 0;
    }
    
    
     
    function refundByOwner(address _funder) onlyOwner public {
        require(fundersProperty[_funder].reservedFunds > 0);
        
        uint256 amountFunds = fundersProperty[_funder].reservedFunds;
        uint256 amountApis = fundersProperty[_funder].reservedApis;
        
         
        _funder.transfer(amountFunds);
        
        saleStatus.totalReceivedFunds -= amountFunds;
        saleStatus.totalReservedFunds -= amountFunds;
        
        saleStatus.totalSoldApis -= amountApis;
        saleStatus.totalReservedApis -= amountApis;
        
        fundersProperty[_funder].reservedFunds = 0;
        fundersProperty[_funder].reservedApis = 0;
        
        Refund(_funder, amountFunds, amountApis);
    }
    
    
     
    function withdrawalFunds(bool remainRefundable) onlyOwner public {
        require(now > endTime || closed == true);
        
        uint256 amount = 0;
        if(remainRefundable) {
            amount = this.balance - saleStatus.totalReservedFunds;
        } else {
            amount = this.balance;
        }
        
        if(amount > 0) {
            msg.sender.transfer(amount);
            
            WithdrawalFunds(msg.sender, amount);
        }
    }
    
     
    function isOpened() public view returns (bool isOpend) {
        if(now < startTime) return false;
        if(now >= endTime) return false;
        if(closed == true) return false;
        
        return true;
    }
}