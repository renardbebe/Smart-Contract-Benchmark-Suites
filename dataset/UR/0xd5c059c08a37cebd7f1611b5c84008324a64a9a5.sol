 

pragma solidity ^0.4.23;



 
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


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract Crowdsale {
  using SafeMath for uint256;

   
  ERC20 public token;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

   
  constructor(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

   
   
   

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
     
  }

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
     
  }

   
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}


 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

   
  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(weiRaised.add(_weiAmount) <= cap);
  }

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


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
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

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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


 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
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

   
  function mint(address _to, uint256 _amount) hasMintPermission canMint public returns (bool) {
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


 
contract MintedCrowdsale is Crowdsale {

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    require(MintableToken(token).mint(_beneficiary, _tokenAmount));
  }
}




 
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

   
  modifier onlyWhileOpen {
     
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

   
  constructor(uint256 _openingTime, uint256 _closingTime) public {
     
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

   
  function hasClosed() public view returns (bool) {
     
    return block.timestamp > closingTime;
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

 
contract ClosedPeriod is TimedCrowdsale {
    uint256 startClosePeriod;
    uint256 stopClosePeriod;
  
    modifier onlyWhileOpen {
        require(block.timestamp >= openingTime && block.timestamp <= closingTime);
        require(block.timestamp < startClosePeriod || block.timestamp > stopClosePeriod);
        _;
    }

    constructor(
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _openClosePeriod,
        uint256 _endClosePeriod
    ) public
        TimedCrowdsale(_openingTime, _closingTime)
    {
        require(_openClosePeriod > 0);
        require(_endClosePeriod > _openClosePeriod);
        startClosePeriod = _openClosePeriod;
        stopClosePeriod = _endClosePeriod;
    }
}





 
contract OptionsToken is StandardToken, Ownable {
    using SafeMath for uint256;
    bool revertable = true;
    mapping (address => uint256) public optionsOwner;
    
    modifier hasOptionPermision() {
        require(msg.sender == owner);
        _;
    }  

    function storeOptions(address recipient, uint256 amount) public hasOptionPermision() {
        optionsOwner[recipient] += amount;
    }

    function refundOptions(address discharged) public onlyOwner() returns (bool) {
        require(revertable);
        require(optionsOwner[discharged] > 0);
        require(optionsOwner[discharged] <= balances[discharged]);

        uint256 revertTokens = optionsOwner[discharged];
        optionsOwner[discharged] = 0;

        balances[discharged] = balances[discharged].sub(revertTokens);
        balances[owner] = balances[owner].add(revertTokens);
        emit Transfer(discharged, owner, revertTokens);
        return true;
    }

    function doneOptions() public onlyOwner() {
        require(revertable);
        revertable = false;
    }
}



 
contract ContractableToken is MintableToken, OptionsToken {
    address[5] public contract_addr;
    uint8 public contract_num = 0;

    function existsContract(address sender) public view returns(bool) {
        bool found = false;
        for (uint8 i = 0; i < contract_num; i++) {
            if (sender == contract_addr[i]) {
                found = true;
            }
        }
        return found;
    }

    modifier onlyContract() {
        require(existsContract(msg.sender));
        _;
    }

    modifier hasMintPermission() {
        require(existsContract(msg.sender));
        _;
    }
    
    modifier hasOptionPermision() {
        require(existsContract(msg.sender));
        _;
    }  
  
    event ContractRenounced();
    event ContractTransferred(address indexed newContract);
  
     
    function setContract(address newContract) public onlyOwner() {
        require(newContract != address(0));
        contract_num++;
        require(contract_num <= 5);
        emit ContractTransferred(newContract);
        contract_addr[contract_num-1] = newContract;
    }
  
    function renounceContract() public onlyOwner() {
        emit ContractRenounced();
        contract_num = 0;
    }
  
}



 
contract FTIToken is ContractableToken {

    string public constant name = "GlobalCarService Token";
    string public constant symbol = "FTI";
    uint8 public constant decimals = 18;

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(msg.sender == owner || mintingFinished);
        super.transferFrom(_from, _to, _value);
        return true;
    }
  
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(msg.sender == owner || mintingFinished);
        super.transfer(_to, _value);
        return true;
    }
}


 
contract FTICrowdsale is CappedCrowdsale, MintedCrowdsale, ClosedPeriod, Ownable {
    using SafeMath for uint256;
    uint256 public referralMinimum;
    uint8 public additionalTokenRate; 
    uint8 public referralPercent;
    uint8 public referralOwnerPercent;
    bool public openingManualyMining = true;
     
    modifier onlyOpeningManualyMinig() {
        require(openingManualyMining);
        _;
    }
   
    struct Pay {
        address payer;
        uint256 amount;
    }
    
    struct ReferalUser {
        uint256 fundsTotal;
        uint32 numReferrals;
        uint256 amountWEI;
        uint32 paysCount;
        mapping (uint32 => Pay) pays;
        mapping (uint32 => address) paysUniq;
        mapping (address => uint256) referral;
    }
    mapping (address => ReferalUser) public referralAddresses;

    uint8 constant maxGlobInvestor = 5;
    struct BonusPeriod {
        uint64 from;
        uint64 to;
        uint256 min_amount;
        uint256 max_amount;
        uint8 bonus;
        uint8 index_global_investor;
    }
    BonusPeriod[] public bonus_periods;

    mapping (uint8 => address[]) public globalInvestor;

    constructor(
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _openClosePeriod,
        uint256 _endClosePeriod,
        uint256 _rate,
        address _wallet,
        uint256 _cap,
        FTIToken _token,
        uint8 _additionalTokenRate,
        uint8 _referralPercent,
        uint256 _referralMinimum,
        uint8 _referralOwnerPercent,
        uint256 _startWeiAmount
    ) public
        Crowdsale(_rate, _wallet, _token)
        CappedCrowdsale(_cap)
        ClosedPeriod(_openingTime, _closingTime, _openClosePeriod, _endClosePeriod)
    {
        require(_additionalTokenRate > 0);
        require(_referralPercent > 0);
        require(_referralMinimum > 0);
        require(_referralOwnerPercent > 0);
        additionalTokenRate = _additionalTokenRate;
        referralPercent = _referralPercent;
        referralMinimum = _referralMinimum;
        referralOwnerPercent = _referralOwnerPercent;
        weiRaised = _startWeiAmount;
    }

    function manualyAddReferral(address ref, uint256 amount) public onlyOwner() {
        referralAddresses[ref] = ReferalUser(0,0,amount,0);
    }

    function manualyAddReferralPayer(address ref, address _beneficiary, uint256 _weiAmount) public onlyOwner() {
        ReferalUser storage rr = referralAddresses[ref];
        if (rr.amountWEI > 0) {
            uint mintTokens = _weiAmount.mul(rate);
            uint256 ownerToken = mintTokens.mul(referralOwnerPercent).div(100);
            rr.fundsTotal += ownerToken;
            if (rr.referral[_beneficiary] == 0){
                rr.paysUniq[rr.numReferrals] = _beneficiary;
                rr.numReferrals += 1;
            }
            rr.referral[_beneficiary] += _weiAmount;
            rr.pays[rr.paysCount] = Pay(_beneficiary, _weiAmount);
            rr.paysCount += 1;
        }
    }

    function bytesToAddress(bytes source) internal constant returns(address parsedReferer) {
        assembly {
            parsedReferer := mload(add(source,0x14))
        }
        require(parsedReferer != msg.sender);
        return parsedReferer;
    }

    function processReferral(address owner, address _beneficiary, uint256 _weiAmount) internal {
        require(owner != address(0));
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
        ReferalUser storage rr = referralAddresses[owner];
        if (rr.amountWEI > 0) {
            uint mintTokens = _weiAmount.mul(rate);
            uint256 ownerToken = mintTokens.mul(referralOwnerPercent).div(100);
            rr.fundsTotal += ownerToken;
            if (rr.referral[_beneficiary] == 0){
                rr.paysUniq[rr.numReferrals] = _beneficiary;
                rr.numReferrals += 1;
            }
            rr.referral[_beneficiary] += _weiAmount;
            rr.pays[rr.paysCount] = Pay(_beneficiary, _weiAmount);
            rr.paysCount += 1;
            FTIToken(token).mint(owner, ownerToken);
            FTIToken(token).mint(_beneficiary, mintTokens.mul(referralPercent).div(100));
        }
    }

    function addReferral(address _beneficiary, uint256 _weiAmount) internal {
        if (_weiAmount > referralMinimum) {
            ReferalUser storage r = referralAddresses[_beneficiary];
            if (r.amountWEI > 0 ) {
                r.amountWEI += _weiAmount;
            }
            else {
                referralAddresses[_beneficiary] = ReferalUser(0, 0, _weiAmount, 0);
            }
        }
    }

    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
        if (msg.data.length == 20) {
            address ref = bytesToAddress(msg.data);
            processReferral(ref, _beneficiary, _weiAmount);
        }

        addReferral(_beneficiary, _weiAmount);

        uint8 index = indexSuperInvestor(_weiAmount);
        if (index > 0 && globalInvestor[index].length < maxGlobInvestor) {
            bool found = false;
            for (uint8 iter = 0; iter < globalInvestor[index].length; iter++) {
                if (globalInvestor[index][iter] == _beneficiary) {
                    found = true;
                }
            }
            if (!found) { 
                globalInvestor[index].push(_beneficiary);
            }
        }
    }
    
    function addBonusPeriod (uint64 from, uint64 to, uint256 min_amount, uint8 bonus, uint256 max_amount, uint8 index_glob_inv) public onlyOwner {
        bonus_periods.push(BonusPeriod(from, to, min_amount, max_amount, bonus, index_glob_inv));
    }


    function referalCount (address addr) public view returns(uint64 len) {
        len = referralAddresses[addr].numReferrals;
    } 

    function referalAddrByNum (address ref_owner, uint32 num) public view returns(address addr) {
        addr = referralAddresses[ref_owner].paysUniq[num];
    } 

    function referalPayCount (address addr) public view returns(uint64 len) {
        len = referralAddresses[addr].paysCount;
    } 

    function referalPayByNum (address ref_owner, uint32 num) public view returns(address addr, uint256 amount) {
        addr = referralAddresses[ref_owner].pays[num].payer;
        amount = referralAddresses[ref_owner].pays[num].amount;
    } 

    function getBonusRate (uint256 amount) public constant returns(uint8) {
        for (uint i = 0; i < bonus_periods.length; i++) {
            BonusPeriod storage bonus_period = bonus_periods[i];
            if (bonus_period.from <= now && bonus_period.to > now && bonus_period.min_amount <= amount && bonus_period.max_amount > amount) {
                return bonus_period.bonus;
            } 
        }
        return 0;
    }
    
    function indexSuperInvestor (uint256 amount) internal view returns(uint8) {
        for (uint8 i = 0; i < bonus_periods.length; i++) {
            BonusPeriod storage bonus_period = bonus_periods[i];
            if (bonus_period.from <= now && bonus_period.to > now && bonus_period.min_amount <= amount && bonus_period.max_amount > amount) {
                return bonus_period.index_global_investor;
            } 
        }
        return 0;
    }

    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint8 bonusPercent = 100 + getBonusRate(_weiAmount);
        uint256 amountTokens = _weiAmount.mul(rate).mul(bonusPercent).div(100);
        return amountTokens;
    }

    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        super._processPurchase(_beneficiary, _tokenAmount);
        FTIToken(token).mint(wallet, _tokenAmount.mul(additionalTokenRate).div(100));
    }

    function closeManualyMining() public onlyOwner() {
        openingManualyMining = false;
    }

    function manualyMintTokens(uint256 _weiAmount, address _beneficiary, uint256 mintTokens) public onlyOwner() onlyOpeningManualyMinig() {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
        require(mintTokens != 0);
        weiRaised = weiRaised.add(_weiAmount);
        _processPurchase(_beneficiary, mintTokens);
        emit TokenPurchase(
            msg.sender,
            _beneficiary,
            _weiAmount,
            mintTokens
        );
        addReferral(_beneficiary, _weiAmount);
    }


}