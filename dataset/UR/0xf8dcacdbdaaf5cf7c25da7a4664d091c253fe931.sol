 

pragma solidity ^0.4.19;

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor() public { owner = msg.sender;  }
 
  modifier onlyOwner() {     
      address sender =  msg.sender;
      address _owner = owner;
      require(msg.sender == _owner);    
      _;  
  }
  
  function transferOwnership(address newOwner) onlyOwner public { 
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
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

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  
   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    uint256 _allowance = allowed[_from][msg.sender];
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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

contract MintableToken is StandardToken, Ownable {
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
    emit Mint(_to, _amount);
    emit Transfer(0x0, _to, _amount);
    return true;
  }
  
   
  function mintFinalize(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 
contract SwordToken is MintableToken {

    string public constant name = "Sword Coin"; 
    string public constant symbol = "SWDC";
    uint8 public constant decimals = 18;

    function getTotalSupply() view public returns (uint256) {
        return totalSupply;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        super.transfer(_to, _value);
    }
    
}

contract KycContractInterface {
    function isAddressVerified(address _address) public view returns (bool);
}

contract KycContract is Ownable {
    
    mapping (address => bool) verifiedAddresses;
    
    function isAddressVerified(address _address) public view returns (bool) {
        return verifiedAddresses[_address];
    }
    
    function addAddress(address _newAddress) public onlyOwner {
        require(!verifiedAddresses[_newAddress]);
        
        verifiedAddresses[_newAddress] = true;
    }
    
    function removeAddress(address _oldAddress) public onlyOwner {
        require(verifiedAddresses[_oldAddress]);
        
        verifiedAddresses[_oldAddress] = false;
    }
    
    function batchAddAddresses(address[] _addresses) public onlyOwner {
        for (uint cnt = 0; cnt < _addresses.length; cnt++) {
            assert(!verifiedAddresses[_addresses[cnt]]);
            verifiedAddresses[_addresses[cnt]] = true;
        }
    }
}


 
contract SwordCrowdsale is Ownable {
    using SafeMath for uint256;
    
     
    uint256 public startTime;
    uint256 public endTime;
     
    uint256 public weiRaised;
    uint256 public limitDateSale;  
   
    bool public isSoftCapHit = false;
    bool public isStarted = false;
    bool public isFinalized = false;
   
   struct ContributorData {
        uint256 contributionAmount;
        uint256 tokensIssued;
    }
   
   address[] public tokenSendFailures;
   
    mapping(address => ContributorData) public contributorList;
    mapping(uint => address) contributorIndexes;
    uint nextContributorIndex;

    constructor() public {}
    
   function init(uint256 _totalTokens, uint256 _tokensForCrowdsale, address _wallet, 
        uint256 _etherInUSD, address _tokenAddress, uint256 _softCapInEthers, uint256 _hardCapInEthers, 
        uint _saleDurationInDays, address _kycAddress, uint bonus) onlyOwner public {
        
        setTotalTokens(_totalTokens);
        setTokensForCrowdSale(_tokensForCrowdsale);
        setWallet(_wallet);
        setRate(_etherInUSD);
        setTokenAddress(_tokenAddress);
        setSoftCap(_softCapInEthers);
        setHardCap(_hardCapInEthers);
        setSaleDuration(_saleDurationInDays);
        setKycAddress(_kycAddress);
        setSaleBonus(bonus);
        kyc = KycContract(_kycAddress);
        start();  
   }
   
     
    function start() onlyOwner public {
        require(!isStarted);
        require(!hasStarted());
        require(wallet != address(0));
        require(tokenAddress != address(0));
        require(kycAddress != address(0));
        require(rate != 0);
        require(saleDuration != 0);
        require(totalTokens != 0);
        require(tokensForCrowdSale != 0);
        require(softCap != 0);
        require(hardCap != 0);
        
        starting();
        emit SwordStarted();
        
        isStarted = true;
    }
  
  
   uint256 public totalTokens = 0;
   function setTotalTokens(uint256 _totalTokens) onlyOwner public {
       totalTokens = _totalTokens * (10 ** 18);  
   }
    
   uint256 public tokensForCrowdSale = 0;
   function setTokensForCrowdSale(uint256 _tokensForCrowdsale) onlyOwner public {
       tokensForCrowdSale = _tokensForCrowdsale * (10 ** 18);  
   }
 
     
    address public wallet = 0x0;
    function setWallet(address _wallet) onlyOwner public {
        wallet = _wallet;
    } 

    uint256 public rate = 0;
    function setRate(uint256 _etherInUSD) public onlyOwner{
         rate = (5 * (10**18) / 100) / _etherInUSD;
    }
    
     
    SwordToken public token;
    address tokenAddress = 0x0; 
    function setTokenAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;  
        token = SwordToken(_tokenAddress);
    }

   uint256 public softCap = 0;
   function setSoftCap(uint256 _softCap) onlyOwner public {
       softCap = _softCap * (10 ** 18); 
    }
   
   uint256 public hardCap = 0; 
   function setHardCap(uint256 _hardCap) onlyOwner public {
       hardCap = _hardCap * (10 ** 18); 
   }
  
     
    uint public saleDuration = 0;  
    function setSaleDuration(uint _saleDurationInDays) onlyOwner public {
        saleDuration = _saleDurationInDays;
		limitDateSale = startTime + (saleDuration * 1 days);
        endTime = limitDateSale;
    }
  
    address kycAddress = 0x0;
    function setKycAddress(address _kycAddress) onlyOwner public {
        kycAddress = _kycAddress;
    }
	
    uint public saleBonus = 0;  
    function setSaleBonus(uint bonus) public onlyOwner{
        saleBonus = bonus;
    }
  
   bool public isKYCRequiredToReceiveFunds = true;  
    function setKYCRequiredToReceiveFunds(bool IS_KYCRequiredToReceiveFunds) public onlyOwner{
        isKYCRequiredToReceiveFunds = IS_KYCRequiredToReceiveFunds;
    }
    
    bool public isKYCRequiredToSendTokens = true;  
      function setKYCRequiredToSendTokens(bool IS_KYCRequiredToSendTokens) public onlyOwner{
        isKYCRequiredToSendTokens = IS_KYCRequiredToSendTokens;
    }
    
    
     
    function () public payable {
        buyTokens(msg.sender);
    }
    
   KycContract public kyc;
   function transferKycOwnerShip(address _address) onlyOwner public {
       kyc.transferOwnership(_address);
   }
   
   function transferTokenOwnership(address _address) onlyOwner public {
       token.transferOwnership(_address);
   }
   
     
    function releaseAllTokens() onlyOwner public {
        for(uint i=0; i < nextContributorIndex; i++) {
            address addressToSendTo = contributorIndexes[i];  
            releaseTokens(addressToSendTo);
        }
    }
    
     
    function releaseTokens(address _contributerAddress) onlyOwner public {
        if(isKYCRequiredToSendTokens){
             if(KycContractInterface(kycAddress).isAddressVerified(_contributerAddress)){  
                release(_contributerAddress);
             }
        } else {
            release(_contributerAddress);
        }
    }
    
    function release(address _contributerAddress) internal {
        if(contributorList[_contributerAddress].tokensIssued > 0) { 
            if(token.mint(_contributerAddress, contributorList[_contributerAddress].tokensIssued)) {  
                contributorList[_contributerAddress].tokensIssued = 0;
                contributorList[_contributerAddress].contributionAmount = 0;
            } else {  
                tokenSendFailures.push(_contributerAddress);
            }
        }
    }
    
    function tokenSendFailuresCount() public view returns (uint) {
        return tokenSendFailures.length;
    }
   
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());
        if(isKYCRequiredToReceiveFunds){
            require(KycContractInterface(kycAddress).isAddressVerified(msg.sender));
        }

        uint256 weiAmount = msg.value;

         
        uint256 tokens = computeTokens(weiAmount);

        require(isWithinTokenAllocLimit(tokens));

         
        weiRaised = weiRaised.add(weiAmount);

        if (contributorList[beneficiary].contributionAmount == 0) {  
            contributorIndexes[nextContributorIndex] = beneficiary;
            nextContributorIndex += 1;
        }
        contributorList[beneficiary].contributionAmount += weiAmount;
        contributorList[beneficiary].tokensIssued += tokens;

        emit SwordTokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
        handleFunds();
    }
  
       
    event SwordTokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  
    function investorCount() constant public returns(uint) {
        return nextContributorIndex;
    }
    
     
    function hasStarted() public constant returns (bool) {
        return (startTime != 0 && now > startTime);
    }

     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }
    
      
    function forwardAllRaisedFunds() internal {
        wallet.transfer(weiRaised);
    }

    function isWithinSaleTimeLimit() internal view returns (bool) {
        return now <= limitDateSale;
    }

    function isWithinSaleLimit(uint256 _tokens) internal view returns (bool) {
        return token.getTotalSupply().add(_tokens) <= tokensForCrowdSale;
    }

    function computeTokens(uint256 weiAmount) view internal returns (uint256) {
        uint256 appliedBonus = 0;
        if (isWithinSaleTimeLimit()) {
            appliedBonus = saleBonus;
        } 
        return (weiAmount.div(rate) + (weiAmount.div(rate).mul(appliedBonus).div(100))) * (10 ** 18);
    }
    
    function isWithinTokenAllocLimit(uint256 _tokens) view internal returns (bool) {
        return (isWithinSaleTimeLimit() && isWithinSaleLimit(_tokens));
    }

    function didSoftCapReached() internal returns (bool) {
        if(weiRaised >= softCap){
            isSoftCapHit = true;  
        } else {
            isSoftCapHit = false;
        }
        return isSoftCapHit;
    }

     
     
    function validPurchase() internal constant returns (bool) {
        bool withinCap = weiRaised.add(msg.value) <= hardCap;
        bool withinPeriod = now >= startTime && now <= endTime; 
        bool nonZeroPurchase = msg.value != 0; 
        return (withinPeriod && nonZeroPurchase) && withinCap && isWithinSaleTimeLimit();
    }

     
     
    function hasEnded() public constant returns (bool) {
        bool capReached = weiRaised >= hardCap;
        return (endTime != 0 && now > endTime) || capReached;
    }

  

  event SwordStarted();
  event SwordFinalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    

    finalization();
    emit SwordFinalized();

    isFinalized = true;
  }

    function starting() internal {
        startTime = now;
        limitDateSale = startTime + (saleDuration * 1 days);
        endTime = limitDateSale;
    }

    function finalization() internal {
        uint256 remainingTokens = totalTokens.sub(token.getTotalSupply());
        token.mintFinalize(wallet, remainingTokens);
        forwardAllRaisedFunds(); 
    }
    
     
    function handleFunds() internal {
        if(isSoftCapHit){  
            forwardFunds();  
        } else {
            if(didSoftCapReached()){    
                forwardAllRaisedFunds();            
            }
        }
    }
    
     modifier afterDeadline() { if (hasEnded() || isFinalized) _; }  
    
   
    function refundAllMoney() onlyOwner public {
        for(uint i=0; i < nextContributorIndex; i++) {
            address addressToSendTo = contributorIndexes[i];
            refundMoney(addressToSendTo); 
        }
    }
    
     
    function refundMoney(address _address) onlyOwner public {
        uint amount = contributorList[_address].contributionAmount;
        if (amount > 0 && _address.send(amount)) {  
            contributorList[_address].contributionAmount =  0;
            contributorList[_address].tokensIssued =  0;
        } 
    }
}