 

pragma solidity ^0.4.18;

 

 
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

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

 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
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
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 

contract FFUELCoinToken is MintableToken {
    string public constant name = "FIFO FUEL";
    string public constant symbol = "FFUEL";
    uint8 public decimals = 18;
    bool public tradingStarted = false;

     
    string public constant version = "v2";

     
    mapping (address => bool) public transferable;

     
    modifier allowTransfer(address _spender) {

        require(tradingStarted || transferable[_spender]);
        _;
    }
     

    function modifyTransferableHash(address _spender, bool value) onlyOwner public {
        transferable[_spender] = value;
    }

     
    function startTrading() onlyOwner public {
        tradingStarted = true;
    }

     
    function transfer(address _to, uint _value) allowTransfer(msg.sender) public returns (bool){
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint _value) allowTransfer(_from) public returns (bool){
        return super.transferFrom(_from, _to, _value);
    }

     
    function approve(address _spender, uint256 _value) public allowTransfer(_spender) returns (bool) {
        return super.approve(_spender, _value);
    }

     
    function increaseApproval(address _spender, uint _addedValue) public allowTransfer(_spender) returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public allowTransfer(_spender) returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

 

 
contract Crowdsale {
  using SafeMath for uint256;

   
  MintableToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


   
  function () external payable {
    buyTokens(msg.sender);
  }

   
   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

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

 

 
contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    emit Finalized();

    isFinalized = true;
  }

   
  function finalization() internal{
  }
}

 

contract FFUELCoinTokenCrowdSale is FinalizableCrowdsale {
    using SafeMath for uint256;


    uint256 public numberOfPurchasers = 0;

     
    uint256 public maxTokenSupply = 0;

     
    uint256 public initialTokenAmount = 0;

     
    string public constant version = "v2";

     
    address public pendingOwner;

     
    uint256 public minimumAmount = 0;

     
    FFUELCoinToken public token;

     
    address public whiteListingAdmin;
    address public rateAdmin;


    bool public preSaleMode = true;
    uint256 public tokenRateGwei;
    address vested;
    uint256 vestedAmount;

    function FFUELCoinTokenCrowdSale(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        uint256 _minimumAmount,
        uint256 _maxTokenSupply,
        address _wallet,
        address _pendingOwner,
        address _whiteListingAdmin,
        address _rateAdmin,
        address _vested,
        uint256 _vestedAmount,
        FFUELCoinToken _token
    )
    FinalizableCrowdsale()
    Crowdsale(_startTime, _endTime, _rate, _wallet) public
    {
        require(_pendingOwner != address(0));
        require(_minimumAmount >= 0);
        require(_maxTokenSupply > 0);

        pendingOwner = _pendingOwner;
        minimumAmount = _minimumAmount;
        maxTokenSupply = _maxTokenSupply;

         
        setAdmin(_whiteListingAdmin, true);
        setAdmin(_rateAdmin, false);

        vested = _vested;
        vestedAmount = _vestedAmount;

        token=_token;
    }


     
    function computeTokenWithBonus(uint256 weiAmount) public view returns (uint256) {
        uint256 tokens_ = 0;

        if (weiAmount >= 100000 ether) {

            tokens_ = weiAmount.mul(50).div(100);

        } else if (weiAmount < 100000 ether && weiAmount >= 50000 ether) {

            tokens_ = weiAmount.mul(35).div(100);

        } else if (weiAmount < 50000 ether && weiAmount >= 10000 ether) {

            tokens_ = weiAmount.mul(25).div(100);

        } else if (weiAmount < 10000 ether && weiAmount >= 2500 ether) {

            tokens_ = weiAmount.mul(15).div(100);
        }


        return tokens_;
    }

     
    function createTokenContract() internal returns (MintableToken) {
        return token;
    }

     
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0), "not for 0x0");
         
        require(validPurchase(), "Crowd sale not started or ended, or min amount too low");
         
        require(owner == pendingOwner, "ownership transfer not done");

        require(tokenRateGwei != 0, "rate invalid");

         
         
        bool cleared;
        uint16 contributor_get;
        address ref;
        uint16 affiliate_get;

        (cleared, contributor_get, ref, affiliate_get) = getContributor(beneficiary);

         
        require(cleared, "not whitelisted");

        uint256 weiAmount = msg.value;

         
        require(weiAmount > 0);

         
        uint256 tokens = weiAmount.div(1000000000).mul(tokenRateGwei);

         
        uint256 bonus = computeTokenWithBonus(tokens);

         
        uint256 contributorGet = tokens.mul(contributor_get).div(10000);

         
        tokens = tokens.add(bonus);
        tokens = tokens.add(contributorGet);

        token.mint(beneficiary, tokens);
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

         
        weiRaised = weiRaised.add(weiAmount);
        numberOfPurchasers = numberOfPurchasers + 1;

        forwardFunds();

         
         
         
         
        bool refCleared;
        (refCleared) = getClearance(ref);
        if (refCleared && ref != beneficiary)
        {
             
            tokens = weiAmount.div(1000000000).mul(tokenRateGwei);

             
            uint256 affiliateGet = tokens.mul(affiliate_get).div(10000);

             
             
             
            if (token.totalSupply() + affiliateGet <= maxTokenSupply)
            {
                 
                token.mint(ref, affiliateGet);
                emit TokenPurchase(ref, ref, 0, affiliateGet);
            }
        }
    }

     
     
    function validPurchase() internal view returns (bool) {

         
        bool minAmount = (msg.value >= minimumAmount);

         
         
        bool lessThanMaxSupply = (token.totalSupply() + msg.value.div(1000000000).mul(tokenRateGwei)) <= maxTokenSupply;

         
        return super.validPurchase() && minAmount && lessThanMaxSupply;
    }

     
     
    function hasEnded() public view returns (bool) {
        bool capReached = token.totalSupply() >= maxTokenSupply;
        return super.hasEnded() || capReached;
    }


     
    function finalization() internal {
         
         
         
         
        uint256 remainingTokens = maxTokenSupply - token.totalSupply();

         
        token.mint(owner, remainingTokens);
        emit TokenPurchase(owner, owner, 0, remainingTokens);

         
        super.finalization();

         
        token.finishMinting();

         
        token.transferOwnership(owner);
    }


     
    function changeDates(uint256 _startTime, uint256 _endTime) public onlyOwner {
        require(_endTime >= _startTime, "End time need to be in the > _startTime");
        startTime = _startTime;
        endTime = _endTime;
    }

     
    function transferOwnerShipToPendingOwner() public {

         
        require(msg.sender == pendingOwner, "only the pending owner can change the ownership");

         
        require(owner != pendingOwner, "Only one time allowed");

         
        emit OwnershipTransferred(owner, pendingOwner);

         
        owner = pendingOwner;

         
        preMint(vested, vestedAmount);
    }

     
    function minted() public view returns (uint256)
    {
        return token.totalSupply().sub(initialTokenAmount);
    }

     
    function preMint(address vestedAddress, uint256 _amount) public onlyOwner {
        runPreMint(vestedAddress, _amount);
         
        runPreMint(0x6B36b48Cb69472193444658b0b181C8049d371e1, 50000000000000000000000000);
         
        runPreMint(0xa484Ebcb519a6E50e4540d48F40f5ee466dEB7A7, 5000000000000000000000000);
         
        runPreMint(0x999f7f15Cf00E4495872D55221256Da7BCec2214, 5000000000000000000000000);
         
        runPreMint(0xB2233A3c93937E02a579422b6Ffc12DA5fc917E7, 5000000000000000000000000);
         

         
        preSaleMode = false;
    }

     
     
    function runPreMint(address _target, uint256 _amount) public onlyOwner {
        if (preSaleMode)
        {
            token.mint(_target, _amount);
            emit TokenPurchase(owner, _target, 0, _amount);

            initialTokenAmount = token.totalSupply();
        }
    }

     

    function modifyTransferableHash(address _spender, bool value) public onlyOwner
    {
        token.modifyTransferableHash(_spender, value);
    }

     
    function setAdmin(address _adminAddress, bool whiteListAdmin) public onlyOwner
    {
        if (whiteListAdmin)
        {
            whiteListingAdmin = _adminAddress;
        } else {
            rateAdmin = _adminAddress;
        }
    }
     
    function setTokenRateInGwei(uint256 _tokenRateGwei) public {
        require(msg.sender == rateAdmin, "invalid admin");
        tokenRateGwei = _tokenRateGwei;
         
        rate = _tokenRateGwei.div(1000000000);
    }

     
     
     
    struct Contributor {

        bool cleared;

         
        uint16 contributor_get;

         
        address ref;

         
        uint16 affiliate_get;
    }


    mapping(address => Contributor) public whitelist;
    address[] public whitelistArray;

     

    function setContributor(address _address, bool cleared, uint16 contributor_get, uint16 affiliate_get, address ref) public {

         
        require(contributor_get < 10000, "c too high");
        require(affiliate_get < 10000, "a too high");
        require(msg.sender == whiteListingAdmin, "invalid admin");

        Contributor storage contributor = whitelist[_address];

        contributor.cleared = cleared;
        contributor.contributor_get = contributor_get;

        contributor.ref = ref;
        contributor.affiliate_get = affiliate_get;
    }

    function getContributor(address _address) public view returns (bool, uint16, address, uint16) {
        return (whitelist[_address].cleared, whitelist[_address].contributor_get, whitelist[_address].ref, whitelist[_address].affiliate_get);
    }

    function getClearance(address _address) public view returns (bool) {
        return whitelist[_address].cleared;
    }


}