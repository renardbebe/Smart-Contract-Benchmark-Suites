 

pragma solidity ^0.4.18;


 
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




 
contract Claimable is Ownable {
    address public pendingOwner;

     
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
        pendingOwner = newOwner;
    }

     
    function claimOwnership() onlyPendingOwner public {
        OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
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


 

contract LimitedTransferToken is ERC20 {

   
  modifier canTransfer(address _sender, uint256 _value) {
   require(_value <= transferableTokens(_sender, uint64(now)));
   _;
  }

   
  function transfer(address _to, uint256 _value) canTransfer(msg.sender, _value) public returns (bool) {
    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) canTransfer(_from, _value) public returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

   
  function transferableTokens(address holder, uint64 time) public view returns (uint256) {
    return balanceOf(holder);
  }
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

   
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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




 

contract MintableToken is StandardToken, Claimable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 
contract ISmartToken {

     
     
     

    bool public transfersEnabled = false;

     
     
     

     
    event NewSmartToken(address _token);
     
    event Issuance(uint256 _amount);
     
    event Destruction(uint256 _amount);

     
     
     

    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}


 
contract LimitedTransferBancorSmartToken is MintableToken, ISmartToken, LimitedTransferToken {

     
     
     

     
    modifier canDestroy() {
        require(destroyEnabled);
        _;
    }

     
     
     

     
     
     
    bool public destroyEnabled = false;

     
     
     

    function setDestroyEnabled(bool _enable) onlyOwner public {
        destroyEnabled = _enable;
    }

     
     
     

     
    function disableTransfers(bool _disable) onlyOwner public {
        transfersEnabled = !_disable;
    }

     
    function issue(address _to, uint256 _amount) onlyOwner public {
        require(super.mint(_to, _amount));
        Issuance(_amount);
    }

     
    function destroy(address _from, uint256 _amount) canDestroy public {

        require(msg.sender == _from || msg.sender == owner);  

        balances[_from] = balances[_from].sub(_amount);
        totalSupply = totalSupply.sub(_amount);

        Destruction(_amount);
        Transfer(_from, 0x0, _amount);
    }

     
     
     


     
     
     
     
     
     
    function transferableTokens(address holder, uint64 time) public constant returns (uint256) {
        require(transfersEnabled);
        return super.transferableTokens(holder, time);
    }
}

 
contract TokenHolder is Ownable {
     
    function TokenHolder() {
    }

     
    function withdrawTokens(StandardToken _token, address _to, uint256 _amount) public onlyOwner {
        require(_token != address(0));
        require(_to != address(0));
        require(_to != address(this));
        assert(_token.transfer(_to, _amount));
    }
}




 
contract LeadcoinSmartToken is TokenHolder, LimitedTransferBancorSmartToken {

     
     
     

    string public name = "LEADCOIN";

    string public symbol = "LDC";

    uint8 public decimals = 18;

     
     
     

    function LeadcoinSmartToken() public {
         
        NewSmartToken(address(this));
    }
}



 
contract Crowdsale {
    using SafeMath for uint256;

     
    LeadcoinSmartToken public token;

     
    uint256 public startTime;

    uint256 public endTime;

     
    address public wallet;

     
    uint256 public rate;

     
    uint256 public weiRaised;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, LeadcoinSmartToken _token) public {
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_rate > 0);
        require(_wallet != address(0));
        require(_token != address(0));

        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        wallet = _wallet;
        token = _token;
    }

     
    function() external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

         
        uint256 tokens = weiAmount.mul(rate);

         
        weiRaised = weiRaised.add(weiAmount);

        token.issue(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

     
     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

     
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

     
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }

}


 
contract FinalizableCrowdsale is Crowdsale, Claimable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
  }
}




contract LeadcoinCrowdsale is TokenHolder,FinalizableCrowdsale {

     
     
     
     
     
     
     
     
     
     
     
    uint8 public constant MAX_TOKEN_GRANTEES = 10;

     
    uint256 public constant MAX_GRANTEE_TOKENS_ALLOWED = 250000000 * 10 ** 18;    

     
    uint256 public constant EXCHANGE_RATE = 15000;

     
     
     

     
    modifier beforeFinzalized() {
        require(!isFinalized);
        _;
    }
     
    modifier notBeforeSaleStarts() {
        require(now >= startTime);
        _;
    }
    
    modifier onlyWhileSale() {
        require(now >= startTime && now < endTime);
        _;
    }

     
     
     

     
    address public walletTeam;    
    address public walletWebydo;        
    address public walletReserve;    


     
    uint256 public fiatRaisedConvertedToWei;

     
    address[] public presaleGranteesMapKeys;
    mapping (address => uint256) public presaleGranteesMap;   

     
    uint256 public hardCap;


     
     
     
    event GrantAdded(address indexed _grantee, uint256 _amount);

    event GrantUpdated(address indexed _grantee, uint256 _oldAmount, uint256 _newAmount);

    event GrantDeleted(address indexed _grantee, uint256 _hadAmount);

    event FiatRaisedUpdated(address indexed _address, uint256 _fiatRaised);

     
     
     

    function LeadcoinCrowdsale(uint256 _startTime,
    uint256 _endTime,
    address _wallet,
    address _walletTeam,
    address _walletWebydo,
    address _walletReserve,
    uint256 _cap,
    LeadcoinSmartToken _leadcoinSmartToken)
    public
    Crowdsale(_startTime, _endTime, EXCHANGE_RATE, _wallet, _leadcoinSmartToken) {
        require(_walletTeam != address(0));
        require(_walletWebydo != address(0));
        require(_walletReserve != address(0));
        require(_leadcoinSmartToken != address(0));
        require(_cap > 0);

        walletTeam = _walletTeam;
        walletWebydo = _walletWebydo;
        walletReserve = _walletReserve;

        token = _leadcoinSmartToken;

        hardCap = _cap;

    }


     
     
     

     
    function finalization() internal onlyOwner {
        super.finalization();

         
        for (uint256 i = 0; i < presaleGranteesMapKeys.length; i++) {
            token.issue(presaleGranteesMapKeys[i], presaleGranteesMap[presaleGranteesMapKeys[i]]);
        }

         
         
        uint256 newTotalSupply = token.totalSupply().mul(200).div(100);

         
        token.issue(walletTeam, newTotalSupply.mul(10).div(100));

         
        token.issue(walletWebydo, newTotalSupply.mul(10).div(100));

         
        token.issue(walletReserve, newTotalSupply.mul(30).div(100));

         
        token.disableTransfers(false);

         
        token.setDestroyEnabled(true);

         
        token.transferOwnership(owner);

    }

     
     
     
     
    function getTotalFundsRaised() public view returns (uint256) {
        return fiatRaisedConvertedToWei.add(weiRaised);
    }

      
     
    function hasEnded() public view returns (bool) {
        bool capReached = getTotalFundsRaised() >= hardCap;
        return capReached || super.hasEnded();
    }

     
     
    function validPurchase() internal view returns (bool) {
        bool withinCap = getTotalFundsRaised() < hardCap;
        return withinCap && super.validPurchase();
    }

     
     
     
     
     
     
     
    function addUpdateGrantee(address _grantee, uint256 _value) external onlyOwner notBeforeSaleStarts beforeFinzalized {
        require(_grantee != address(0));
        require(_value > 0 && _value <= MAX_GRANTEE_TOKENS_ALLOWED);
        
         
        if (presaleGranteesMap[_grantee] == 0) {
            require(presaleGranteesMapKeys.length < MAX_TOKEN_GRANTEES);
            presaleGranteesMapKeys.push(_grantee);
            GrantAdded(_grantee, _value);
        } else {
            GrantUpdated(_grantee, presaleGranteesMap[_grantee], _value);
        }

        presaleGranteesMap[_grantee] = _value;
    }

     
     
    function deleteGrantee(address _grantee) external onlyOwner notBeforeSaleStarts beforeFinzalized {
        require(_grantee != address(0));
        require(presaleGranteesMap[_grantee] != 0);

         
        delete presaleGranteesMap[_grantee];

         
        uint256 index;
        for (uint256 i = 0; i < presaleGranteesMapKeys.length; i++) {
            if (presaleGranteesMapKeys[i] == _grantee) {
                index = i;
                break;
            }
        }
        presaleGranteesMapKeys[index] = presaleGranteesMapKeys[presaleGranteesMapKeys.length - 1];
        delete presaleGranteesMapKeys[presaleGranteesMapKeys.length - 1];
        presaleGranteesMapKeys.length--;

        GrantDeleted(_grantee, presaleGranteesMap[_grantee]);
    }

     
     
     
     
    function setFiatRaisedConvertedToWei(uint256 _fiatRaisedConvertedToWei) external onlyOwner onlyWhileSale {
        fiatRaisedConvertedToWei = _fiatRaisedConvertedToWei;
        FiatRaisedUpdated(msg.sender, fiatRaisedConvertedToWei);
    }


     
     
    function claimTokenOwnership() external onlyOwner {
        token.claimOwnership();
    }

}