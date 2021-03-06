 

pragma solidity 0.4.24;

 

 
contract Ownable {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused, "must not be paused");
        _;
    }

     
    modifier whenPaused() {
        require(_paused, "must be paused");
        _;
    }

     
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        _paused = false;
        emit Unpause();
    }
}

 

 
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

 

 
contract Crowdsale {
     
    uint256 public startTime;
    uint256 public endTime;

     
    address public wallet;

     
    uint256 public rate;

     
    uint256 public weiRaised;


     
     
     
     
     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function initCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
        require(
            startTime == 0 && endTime == 0 && rate == 0 && wallet == address(0),
            "Global variables must be empty when initializing crowdsale!"
        );
        require(_startTime >= now, "_startTime must be more than current time!");
        require(_endTime >= _startTime, "_endTime must be more than _startTime!");
        require(_wallet != address(0), "_wallet parameter must not be empty!");

        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        wallet = _wallet;
    }

     
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }

     
     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
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

   
  function finalization() internal {
  }
}

 

 
contract ERC20Plus {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    function mint(address _to, uint256 _amount) public returns (bool);
    function owner() public view returns (address);
    function transferOwnership(address newOwner) public;
    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint8);
    function paused() public view returns (bool);

}

 

 
contract Whitelist is Ownable {
    mapping(address => bool) public allowedAddresses;

    event WhitelistUpdated(uint256 timestamp, string operation, address indexed member);

     
    function addToWhitelist(address _address) external onlyOwner {
        allowedAddresses[_address] = true;
        emit WhitelistUpdated(now, "Added", _address);
    }

     
    function addManyToWhitelist(address[] _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            allowedAddresses[_addresses[i]] = true;
            emit WhitelistUpdated(now, "Added", _addresses[i]);
        }
    }

     
    function removeManyFromWhitelist(address[] _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            allowedAddresses[_addresses[i]] = false;
            emit WhitelistUpdated(now, "Removed", _addresses[i]);
        }
    }
}

 

 
interface TokenSaleInterface {
    function init
    (
        uint256 _startTime,
        uint256 _endTime,
        address _whitelist,
        address _starToken,
        address _companyToken,
        uint256 _rate,
        uint256 _starRate,
        address _wallet,
        uint256 _crowdsaleCap,
        bool    _isWeiAccepted
    )
    external;
}

 

 
contract TokenSale is FinalizableCrowdsale, Pausable {
    uint256 public crowdsaleCap;
    uint256 public tokensSold;
     
    uint256 public starRaised;
    uint256 public starRate;
    address public initialTokenOwner;
    bool public isWeiAccepted;

     
    Whitelist public whitelist;
    ERC20Plus public starToken;
     
    ERC20Plus public tokenOnSale;

    event TokenRateChanged(uint256 previousRate, uint256 newRate);
    event TokenStarRateChanged(uint256 previousStarRate, uint256 newStarRate);
    event TokenPurchaseWithStar(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    function init(
        uint256 _startTime,
        uint256 _endTime,
        address _whitelist,
        address _starToken,
        address _companyToken,
        uint256 _rate,
        uint256 _starRate,
        address _wallet,
        uint256 _crowdsaleCap,
        bool    _isWeiAccepted
    )
        external
    {
        require(
            whitelist == address(0) &&
            starToken == address(0) &&
            rate == 0 &&
            starRate == 0 &&
            tokenOnSale == address(0) &&
            crowdsaleCap == 0,
            "Global variables should not have been set before!"
        );

        require(
            _whitelist != address(0) &&
            _starToken != address(0) &&
            !(_rate == 0 && _starRate == 0) &&
            _companyToken != address(0) &&
            _crowdsaleCap != 0,
            "Parameter variables cannot be empty!"
        );

        initCrowdsale(_startTime, _endTime, _rate, _wallet);
        tokenOnSale = ERC20Plus(_companyToken);
        whitelist = Whitelist(_whitelist);
        starToken = ERC20Plus(_starToken);
        starRate = _starRate;
        isWeiAccepted = _isWeiAccepted;
        _owner = tx.origin;

        initialTokenOwner = ERC20Plus(tokenOnSale).owner();
        uint256 tokenDecimals = ERC20Plus(tokenOnSale).decimals();
        crowdsaleCap = _crowdsaleCap.mul(10 ** tokenDecimals);

        require(ERC20Plus(tokenOnSale).paused(), "Company token must be paused upon initialization!");
    }

    modifier isWhitelisted(address beneficiary) {
        require(whitelist.allowedAddresses(beneficiary), "Beneficiary not whitelisted!");
        _;
    }

    modifier crowdsaleIsTokenOwner() {
        require(tokenOnSale.owner() == address(this), "The token owner must be contract address!");
        _;
    }

     
    function () external payable {
        revert("No fallback function defined!");
    }

     
    function setRate(uint256 newRate) external onlyOwner {
        require(newRate != 0, "ETH rate must be more than 0");

        emit TokenRateChanged(rate, newRate);
        rate = newRate;
    }

     
    function setStarRate(uint256 newStarRate) external onlyOwner {
        require(newStarRate != 0, "Star rate must be more than 0!");

        emit TokenStarRateChanged(starRate, newStarRate);
        starRate = newStarRate;
    }

     
    function setIsWeiAccepted(bool _isWeiAccepted) external onlyOwner {
        require(rate != 0, "When accepting Wei you need to set a conversion rate!");
        isWeiAccepted = _isWeiAccepted;
    }

     
    function buyTokens(address beneficiary)
        public
        payable
        whenNotPaused
        isWhitelisted(beneficiary)
        crowdsaleIsTokenOwner
    {
        require(beneficiary != address(0));
        require(validPurchase() && tokensSold < crowdsaleCap);

        if (!isWeiAccepted) {
            require(msg.value == 0);
        } else if (msg.value > 0) {
            buyTokensWithWei(beneficiary);
        }

         
        uint256 starAllocationToTokenSale = starToken.allowance(beneficiary, this);
        if (starAllocationToTokenSale > 0) {
             
            uint256 tokens = starAllocationToTokenSale.mul(starRate);

             
            if (tokensSold.add(tokens) > crowdsaleCap) {
                tokens = crowdsaleCap.sub(tokensSold);

                starAllocationToTokenSale = tokens.div(starRate);
            }

             
            starRaised = starRaised.add(starAllocationToTokenSale);

            tokensSold = tokensSold.add(tokens);
            tokenOnSale.mint(beneficiary, tokens);
            emit TokenPurchaseWithStar(msg.sender, beneficiary, starAllocationToTokenSale, tokens);

             
            starToken.transferFrom(beneficiary, wallet, starAllocationToTokenSale);
        }
    }

     
    function buyTokensWithWei(address beneficiary)
        internal
    {
        uint256 weiAmount = msg.value;
        uint256 weiRefund = 0;

         
        uint256 tokens = weiAmount.mul(rate);

         
        if (tokensSold.add(tokens) > crowdsaleCap) {
            tokens = crowdsaleCap.sub(tokensSold);
            weiAmount = tokens.div(rate);

            weiRefund = msg.value.sub(weiAmount);
        }

         
        weiRaised = weiRaised.add(weiAmount);

        tokensSold = tokensSold.add(tokens);
        tokenOnSale.mint(beneficiary, tokens);
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        wallet.transfer(weiAmount);
        if (weiRefund > 0) {
            msg.sender.transfer(weiRefund);
        }
    }

     
     
    function hasEnded() public view returns (bool) {
        if (tokensSold >= crowdsaleCap) {
            return true;
        }

        return super.hasEnded();
    }

     
    function validPurchase() internal view returns (bool) {
        return now >= startTime && now <= endTime;
    }

     
    function finalization() internal {
        if (crowdsaleCap > tokensSold) {
            uint256 remainingTokens = crowdsaleCap.sub(tokensSold);

            tokenOnSale.mint(wallet, remainingTokens);
        }

        tokenOnSale.transferOwnership(initialTokenOwner);
        super.finalization();
    }
}