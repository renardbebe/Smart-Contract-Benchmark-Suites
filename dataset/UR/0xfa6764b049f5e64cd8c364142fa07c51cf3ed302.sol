 

 
pragma solidity ^0.4.18;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
pragma solidity ^0.4.18;




 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
pragma solidity ^0.4.18;





 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

 
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
pragma solidity ^0.4.18;


 
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

 
pragma solidity ^0.4.18;







 
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

   
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

   
  function TokenVesting(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) public {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

   
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    Released(unreleased);
  }

   
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    Revoked();
  }

   
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

   
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (now < cliff) {
      return 0;
    } else if (now >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(start)).div(duration);
    }
  }
}

 
pragma solidity ^0.4.18;





 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

 
pragma solidity ^0.4.18;






 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}

 
pragma solidity ^0.4.19;




 
contract KYCBase {
    using SafeMath for uint256;

    mapping (address => bool) public isKycSigner;
    mapping (uint64 => uint256) public alreadyPayed;

    event KycVerified(address indexed signer, address buyerAddress, uint64 buyerId, uint maxAmount);

    function KYCBase(address [] kycSigners) internal {
        for (uint i = 0; i < kycSigners.length; i++) {
            isKycSigner[kycSigners[i]] = true;
        }
    }

     
    function releaseTokensTo(address buyer) internal returns(bool);

     
    function senderAllowedFor(address buyer)
        internal view returns(bool)
    {
        return buyer == msg.sender;
    }

    function buyTokensFor(address buyerAddress, uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
        public payable returns (bool)
    {
        require(senderAllowedFor(buyerAddress));
        return buyImplementation(buyerAddress, buyerId, maxAmount, v, r, s);
    }

    function buyTokens(uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
        public payable returns (bool)
    {
        return buyImplementation(msg.sender, buyerId, maxAmount, v, r, s);
    }

    function buyImplementation(address buyerAddress, uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
        private returns (bool)
    {
         
        bytes32 hash = sha256("Eidoo icoengine authorization", this, buyerAddress, buyerId, maxAmount);
        address signer = ecrecover(hash, v, r, s);
        if (!isKycSigner[signer]) {
            revert();
        } else {
            uint256 totalPayed = alreadyPayed[buyerId].add(msg.value);
            require(totalPayed <= maxAmount);
            alreadyPayed[buyerId] = totalPayed;
            KycVerified(signer, buyerAddress, buyerId, maxAmount);
            return releaseTokensTo(buyerAddress);
        }
        return true;
    }

     
    function () public {
        revert();
    }
}
 
pragma solidity ^0.4.19;


contract ICOEngineInterface {

     
    function started() public view returns(bool);

     
    function ended() public view returns(bool);

     
    function startTime() public view returns(uint);

     
    function endTime() public view returns(uint);

     
     
     

     
     
     

     
    function totalTokens() public view returns(uint);

     
     
    function remainingTokens() public view returns(uint);

     
    function price() public view returns(uint);
}
 
 
pragma solidity ^0.4.19;







contract CrowdsaleBase is Pausable, CanReclaimToken, ICOEngineInterface, KYCBase {

     
    uint256 public constant USD_PER_TOKEN = 2;                         
    uint256 public constant USD_PER_ETHER = 1000;                       

    uint256 public start;                                              
    uint256 public end;                                                
    uint256 public cap;                                                
    address public wallet;
    uint256 public tokenPerEth;
    uint256 public availableTokens;                                    
    address[] public kycSigners;                                       
    bool public capReached;
    uint256 public weiRaised;
    uint256 public tokensSold;

     
    function CrowdsaleBase(
        uint256 _start,
        uint256 _end,
        uint256 _cap,
        address _wallet,
        address[] _kycSigners
    )
        public
        KYCBase(_kycSigners)
    {
        require(_end >= _start);
        require(_cap > 0);

        start = _start;
        end = _end;
        cap = _cap;
        wallet = _wallet;
        tokenPerEth = USD_PER_ETHER.div(USD_PER_TOKEN);
        availableTokens = _cap;
        kycSigners = _kycSigners;
    }

     
    function started() public view returns(bool) {
        if (block.timestamp >= start) {
            return true;
        } else {
            return false;
        }
    }

     
    function ended() public view returns(bool) {
        if (block.timestamp >= end) {
            return true;
        } else {
            return false;
        }
    }

     
    function startTime() public view returns(uint) {
        return start;
    }

     
    function endTime() public view returns(uint) {
        return end;
    }

     
    function totalTokens() public view returns(uint) {
        return cap;
    }

     
    function remainingTokens() public view returns(uint) {
        return availableTokens;
    }

     
    function senderAllowedFor(address buyer) internal view returns(bool) {
        require(buyer != address(0));

        return true;
    }

     
    function releaseTokensTo(address buyer) internal returns(bool) {
        require(validPurchase());

        uint256 overflowTokens;
        uint256 refundWeiAmount;

        uint256 weiAmount = msg.value;
        uint256 tokenAmount = weiAmount.mul(price());

        if (tokenAmount >= availableTokens) {
            capReached = true;
            overflowTokens = tokenAmount.sub(availableTokens);
            tokenAmount = tokenAmount.sub(overflowTokens);
            refundWeiAmount = overflowTokens.div(price());
            weiAmount = weiAmount.sub(refundWeiAmount);
            buyer.transfer(refundWeiAmount);
        }

        weiRaised = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokenAmount);
        availableTokens = availableTokens.sub(tokenAmount);
        mintTokens(buyer, tokenAmount);
        forwardFunds(weiAmount);

        return true;
    }

     
    function forwardFunds(uint256 _weiAmount) internal {
        wallet.transfer(_weiAmount);
    }

     
    function validPurchase() internal view returns (bool) {
        require(!paused && !capReached);
        require(block.timestamp >= start && block.timestamp <= end);

        return true;
    }

     
    function mintTokens(address to, uint256 amount) private;
}





 
 
pragma solidity ^0.4.19;




contract Reservation is CrowdsaleBase {

     
    uint256 public constant START_TIME = 1525683600;                      
    uint256 public constant END_TIME = 1525856400;                        
    uint256 public constant RESERVATION_CAP = 7.5e6 * 1e18;
    uint256 public constant BONUS = 110;                                  

    UacCrowdsale public crowdsale;

     
    function Reservation(
        address _wallet,
        address[] _kycSigners
    )
        public
        CrowdsaleBase(START_TIME, END_TIME, RESERVATION_CAP, _wallet, _kycSigners)
    {
    }

    function setCrowdsale(address _crowdsale) public {
        require(crowdsale == address(0));
        crowdsale = UacCrowdsale(_crowdsale);
    }

     
    function price() public view returns (uint256) {
        return tokenPerEth.mul(BONUS).div(1e2);
    }

     
    function mintTokens(address to, uint256 amount) private {
        crowdsale.mintReservationTokens(to, amount);
    }
}
 
pragma solidity ^0.4.18;






 
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
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 
pragma solidity ^0.4.18;





 
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

 
pragma solidity ^0.4.18;





 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 
pragma solidity ^0.4.18;





 
contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

 
 
pragma solidity ^0.4.19;





contract UacToken is CanReclaimToken, MintableToken, PausableToken {
    string public constant name = "Ubiatar Coin";
    string public constant symbol = "UAC";
    uint8 public constant decimals = 18;

     
    function UacToken() public {
         
        paused = true;
    }
}

 
 

pragma solidity ^0.4.19;







contract UbiatarPlayVault {
    using SafeMath for uint256;
    using SafeERC20 for UacToken;

    uint256[6] public vesting_offsets = [
        90 days,
        180 days,
        270 days,
        360 days,
        540 days,
        720 days
    ];

    uint256[6] public vesting_amounts = [
        2e6 * 1e18,
        4e6 * 1e18,
        6e6 * 1e18,
        8e6 * 1e18,
        10e6 * 1e18,
        20.5e6 * 1e18
    ];

    address public ubiatarPlayWallet;
    UacToken public token;
    uint256 public start;
    uint256 public released;

     
    function UbiatarPlayVault(
        address _ubiatarPlayWallet,
        address _token,
        uint256 _start
    )
        public
    {
        ubiatarPlayWallet = _ubiatarPlayWallet;
        token = UacToken(_token);
        start = _start;
    }

     
    function release() public {
        uint256 unreleased = releasableAmount();
        require(unreleased > 0);

        released = released.add(unreleased);

        token.safeTransfer(ubiatarPlayWallet, unreleased);
    }

     
    function releasableAmount() public view returns (uint256) {
        return vestedAmount().sub(released);
    }

     
    function vestedAmount() public view returns (uint256) {
        uint256 vested = 0;

        for (uint256 i = 0; i < vesting_offsets.length; i = i.add(1)) {
            if (block.timestamp > start.add(vesting_offsets[i])) {
                vested = vested.add(vesting_amounts[i]);
            }
        }

        return vested;
    }
}



 
 
pragma solidity ^0.4.17;







contract PresaleTokenVault {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Basic;

     
    uint256 public constant VESTING_OFFSET = 90 days;                    
    uint256 public constant VESTING_DURATION = 180 days;                 

    uint256 public start;
    uint256 public cliff;
    uint256 public end;

    ERC20Basic public token;

    struct Investment {
        address beneficiary;
        uint256 totalBalance;
        uint256 released;
    }

    Investment[] public investments;

     
    mapping(address => uint256) public investorLUT;

    function init(address[] beneficiaries, uint256[] balances, uint256 startTime, address _token) public {
         
        require(token == address(0));
        require(beneficiaries.length == balances.length);

        start = startTime;
        cliff = start.add(VESTING_OFFSET);
        end = cliff.add(VESTING_DURATION);

        token = ERC20Basic(_token);

        for (uint256 i = 0; i < beneficiaries.length; i = i.add(1)) {
            investorLUT[beneficiaries[i]] = investments.length;
            investments.push(Investment(beneficiaries[i], balances[i], 0));
        }
    }

     
    function release(address beneficiary) public {
        uint256 unreleased = releasableAmount(beneficiary);
        require(unreleased > 0);

        uint256 investmentIndex = investorLUT[beneficiary];
        investments[investmentIndex].released = investments[investmentIndex].released.add(unreleased);
        token.safeTransfer(beneficiary, unreleased);
    }

     
    function release() public {
        release(msg.sender);
    }

     
    function releasableAmount(address beneficiary) public view returns (uint256) {
        uint256 investmentIndex = investorLUT[beneficiary];

        return vestedAmount(beneficiary).sub(investments[investmentIndex].released);
    }

     
    function vestedAmount(address beneficiary) public view returns (uint256) {

        uint256 investmentIndex = investorLUT[beneficiary];

        uint256 vested = 0;

        if (block.timestamp >= start) {
             
            vested = investments[investmentIndex].totalBalance.div(3);
        }
        if (block.timestamp >= cliff && block.timestamp < end) {
             
            uint256 p1 = investments[investmentIndex].totalBalance.div(3);
            uint256 p2 = investments[investmentIndex].totalBalance;

             
            uint256 d_token = p2.sub(p1);
            uint256 time = block.timestamp.sub(cliff);
            uint256 d_time = end.sub(cliff);

            vested = vested.add(d_token.mul(time).div(d_time));
        }
        if (block.timestamp >= end) {
             
            vested = investments[investmentIndex].totalBalance;
        }
        return vested;
    }
}

 
 
pragma solidity ^0.4.19;









contract UacCrowdsale is CrowdsaleBase {

     
    uint256 public constant START_TIME = 1525856400;                      
    uint256 public constant END_TIME = 1528448400;                        
    uint256 public constant PRESALE_VAULT_START = END_TIME + 7 days;
    uint256 public constant PRESALE_CAP = 17584778551358900100698693;
    uint256 public constant TOTAL_MAX_CAP = 15e6 * 1e18;                 
    uint256 public constant CROWDSALE_CAP = 7.5e6 * 1e18;
    uint256 public constant FOUNDERS_CAP = 12e6 * 1e18;
    uint256 public constant UBIATARPLAY_CAP = 50.5e6 * 1e18;
    uint256 public constant ADVISORS_CAP = 4915221448641099899301307;

     
    uint256 public constant BONUS_TIER1 = 108;                            
    uint256 public constant BONUS_TIER2 = 106;                            
    uint256 public constant BONUS_TIER3 = 104;                            
    uint256 public constant BONUS_DURATION_1 = 3 hours;
    uint256 public constant BONUS_DURATION_2 = 12 hours;
    uint256 public constant BONUS_DURATION_3 = 42 hours;

    uint256 public constant FOUNDERS_VESTING_CLIFF = 1 years;
    uint256 public constant FOUNDERS_VESTING_DURATION = 2 years;

    Reservation public reservation;

     
    PresaleTokenVault public presaleTokenVault;
    TokenVesting public foundersVault;
    UbiatarPlayVault public ubiatarPlayVault;

     
    address public foundersWallet;
    address public advisorsWallet;
    address public ubiatarPlayWallet;

    address public wallet;

    UacToken public token;

     
    bool public didOwnerEndCrowdsale;

     
    function UacCrowdsale(
        address _token,
        address _reservation,
        address _presaleTokenVault,
        address _foundersWallet,
        address _advisorsWallet,
        address _ubiatarPlayWallet,
        address _wallet,
        address[] _kycSigners
    )
        public
        CrowdsaleBase(START_TIME, END_TIME, TOTAL_MAX_CAP, _wallet, _kycSigners)
    {
        token = UacToken(_token);
        reservation = Reservation(_reservation);
        presaleTokenVault = PresaleTokenVault(_presaleTokenVault);
        foundersWallet = _foundersWallet;
        advisorsWallet = _advisorsWallet;
        ubiatarPlayWallet = _ubiatarPlayWallet;
        wallet = _wallet;
         
        foundersVault = new TokenVesting(foundersWallet, END_TIME, FOUNDERS_VESTING_CLIFF, FOUNDERS_VESTING_DURATION, false);

         
        ubiatarPlayVault = new UbiatarPlayVault(ubiatarPlayWallet, address(token), END_TIME);
    }

    function mintPreAllocatedTokens() public onlyOwner {
        mintTokens(address(foundersVault), FOUNDERS_CAP);
        mintTokens(advisorsWallet, ADVISORS_CAP);
        mintTokens(address(ubiatarPlayVault), UBIATARPLAY_CAP);
    }

     
    function initPresaleTokenVault(address[] beneficiaries, uint256[] balances) public onlyOwner {
        require(beneficiaries.length == balances.length);

        presaleTokenVault.init(beneficiaries, balances, PRESALE_VAULT_START, token);

        uint256 totalPresaleBalance = 0;
        uint256 balancesLength = balances.length;
        for(uint256 i = 0; i < balancesLength; i++) {
            totalPresaleBalance = totalPresaleBalance.add(balances[i]);
        }

        mintTokens(presaleTokenVault, totalPresaleBalance);
    }

     
    function price() public view returns (uint256 _price) {
        if (block.timestamp <= start.add(BONUS_DURATION_1)) {
            return tokenPerEth.mul(BONUS_TIER1).div(1e2);
        } else if (block.timestamp <= start.add(BONUS_DURATION_2)) {
            return tokenPerEth.mul(BONUS_TIER2).div(1e2);
        } else if (block.timestamp <= start.add(BONUS_DURATION_3)) {
            return tokenPerEth.mul(BONUS_TIER3).div(1e2);
        }
        return tokenPerEth;
    }

     
    function mintReservationTokens(address to, uint256 amount) public {
        require(msg.sender == address(reservation));
        tokensSold = tokensSold.add(amount);
        availableTokens = availableTokens.sub(amount);
        mintTokens(to, amount);
    }

     
    function mintTokens(address to, uint256 amount) private {
        token.mint(to, amount);
    }

     
    function closeCrowdsale() public onlyOwner {
        require(block.timestamp >= START_TIME && block.timestamp < END_TIME);
        didOwnerEndCrowdsale = true;
    }

     
    function finalise() public onlyOwner {
        require(didOwnerEndCrowdsale || block.timestamp > end || capReached);
        token.finishMinting();
        token.unpause();

         
         
         
        token.transferOwnership(owner);
    }
}