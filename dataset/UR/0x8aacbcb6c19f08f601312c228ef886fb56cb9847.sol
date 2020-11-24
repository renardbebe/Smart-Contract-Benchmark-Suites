 

pragma solidity ^0.4.24;

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
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

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string name, string symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

   
  function name() public view returns(string) {
    return _name;
  }

   
  function symbol() public view returns(string) {
    return _symbol;
  }

   
  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

   
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

   
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

   
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

   
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

   
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

   
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

   
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

   
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

     
     
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

   
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

   
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

contract PauserRole {
  using Roles for Roles.Role;

  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);

  Roles.Role private pausers;

  constructor() internal {
    _addPauser(msg.sender);
  }

  modifier onlyPauser() {
    require(isPauser(msg.sender));
    _;
  }

  function isPauser(address account) public view returns (bool) {
    return pausers.has(account);
  }

  function addPauser(address account) public onlyPauser {
    _addPauser(account);
  }

  function renouncePauser() public {
    _removePauser(msg.sender);
  }

  function _addPauser(address account) internal {
    pausers.add(account);
    emit PauserAdded(account);
  }

  function _removePauser(address account) internal {
    pausers.remove(account);
    emit PauserRemoved(account);
  }
}

 
contract Pausable is PauserRole {
  event Paused(address account);
  event Unpaused(address account);

  bool private _paused;

  constructor() internal {
    _paused = false;
  }

   
  function paused() public view returns(bool) {
    return _paused;
  }

   
  modifier whenNotPaused() {
    require(!_paused);
    _;
  }

   
  modifier whenPaused() {
    require(_paused);
    _;
  }

   
  function pause() public onlyPauser whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
  }

   
  function unpause() public onlyPauser whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
  }
}

 
contract ERC20Pausable is ERC20, Pausable {

  function transfer(
    address to,
    uint256 value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(to, value);
  }

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(from, to, value);
  }

  function approve(
    address spender,
    uint256 value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(spender, value);
  }

  function increaseAllowance(
    address spender,
    uint addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseAllowance(spender, addedValue);
  }

  function decreaseAllowance(
    address spender,
    uint subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseAllowance(spender, subtractedValue);
  }
}

contract SignkeysToken is ERC20Pausable, ERC20Detailed, Ownable {

    uint8 public constant DECIMALS = 18;

    uint256 public constant INITIAL_SUPPLY = 2E9 * (10 ** uint256(DECIMALS));

     
    constructor() public ERC20Detailed("SignkeysToken", "KEYS", DECIMALS) {
        _mint(owner(), INITIAL_SUPPLY);
    }

    function approveAndCall(address _spender, uint256 _value, bytes _data) public payable returns (bool success) {
        require(_spender != address(this));
        require(super.approve(_spender, _value));
        require(_spender.call(_data));
        return true;
    }

    function() payable external {
        revert();
    }
}

contract SignkeysBonusProgram is Ownable {
    using SafeMath for uint256;

     
    SignkeysToken public token;

     
    SignkeysCrowdsale public crowdsale;

     
    SignkeysBonusProgramRewards public bonusProgramRewards;

     
    uint256[] public referralBonusTokensAmountRanges = [199, 1000, 10000, 100000, 1000000, 10000000];

     
    uint256[] public referrerRewards = [5, 50, 500, 5000, 50000];

     
    uint256[] public buyerRewards = [5, 50, 500, 5000, 50000];

     
    uint256[] public purchaseAmountRangesInCents = [2000, 1000000, 10000000];

     
    uint256[] public purchaseRewardsPercents = [10, 15, 20];

    event BonusSent(
        address indexed referrerAddress,
        uint256 referrerBonus,
        address indexed buyerAddress,
        uint256 buyerBonus,
        uint256 purchaseBonus,
        uint256 couponBonus
    );

    constructor(address _token, address _bonusProgramRewards) public {
        token = SignkeysToken(_token);
        bonusProgramRewards = SignkeysBonusProgramRewards(_bonusProgramRewards);
    }

    function setCrowdsaleContract(address _crowdsale) public onlyOwner {
        crowdsale = SignkeysCrowdsale(_crowdsale);
    }

    function setBonusProgramRewardsContract(address _bonusProgramRewards) public onlyOwner {
        bonusProgramRewards = SignkeysBonusProgramRewards(_bonusProgramRewards);
    }

     
    function calcBonus(uint256 tokensAmount, uint256[] rewards) private view returns (uint256) {
        uint256 multiplier = 10 ** uint256(token.decimals());
        if (tokensAmount <= multiplier.mul(referralBonusTokensAmountRanges[0])) {
            return 0;
        }
        for (uint i = 1; i < referralBonusTokensAmountRanges.length; i++) {
            uint min = referralBonusTokensAmountRanges[i - 1];
            uint max = referralBonusTokensAmountRanges[i];
            if (tokensAmount > min.mul(multiplier) && tokensAmount <= max.mul(multiplier)) {
                return multiplier.mul(rewards[i - 1]);
            }
        }
        if (tokensAmount >= referralBonusTokensAmountRanges[referralBonusTokensAmountRanges.length - 1].mul(multiplier)) {
            return multiplier.mul(rewards[rewards.length - 1]);
        }
    }

    function calcPurchaseBonus(uint256 amountCents, uint256 tokensAmount) private view returns (uint256) {
        if (amountCents < purchaseAmountRangesInCents[0]) {
            return 0;
        }
        for (uint i = 1; i < purchaseAmountRangesInCents.length; i++) {
            if (amountCents >= purchaseAmountRangesInCents[i - 1] && amountCents < purchaseAmountRangesInCents[i]) {
                return tokensAmount.mul(purchaseRewardsPercents[i - 1]).div(100);
            }
        }
        if (amountCents >= purchaseAmountRangesInCents[purchaseAmountRangesInCents.length - 1]) {
            return tokensAmount.mul(purchaseRewardsPercents[purchaseAmountRangesInCents.length - 1]).div(100);
        }
    }

     
    function sendBonus(address referrer, address buyer, uint256 _tokensAmount, uint256 _valueCents, uint256 _couponCampaignId) external returns (uint256)  {
        require(msg.sender == address(crowdsale), "Bonus may be sent only by crowdsale contract");

        uint256 referrerBonus = 0;
        uint256 buyerBonus = 0;
        uint256 purchaseBonus = 0;
        uint256 couponBonus = 0;

        uint256 referrerBonusAmount = calcBonus(_tokensAmount, referrerRewards);
        uint256 buyerBonusAmount = calcBonus(_tokensAmount, buyerRewards);
        uint256 purchaseBonusAmount = calcPurchaseBonus(_valueCents, _tokensAmount);

        if (referrer != 0x0 && !bonusProgramRewards.areReferralBonusesSent(buyer)) {
            if (referrerBonusAmount > 0 && token.balanceOf(this) > referrerBonusAmount) {
                token.transfer(referrer, referrerBonusAmount);
                bonusProgramRewards.setReferralBonusesSent(buyer, true);
                referrerBonus = referrerBonusAmount;
            }

            if (buyerBonusAmount > 0 && token.balanceOf(this) > buyerBonusAmount) {
                bonusProgramRewards.setReferralBonusesSent(buyer, true);
                buyerBonus = buyerBonusAmount;
            }
        }

        if (token.balanceOf(this) > purchaseBonusAmount.add(buyerBonus)) {
            purchaseBonus = purchaseBonusAmount;
        }

        if (_couponCampaignId > 0 && !bonusProgramRewards.isCouponUsed(buyer, _couponCampaignId)) {
            if (
                token.balanceOf(this) > purchaseBonusAmount
                .add(buyerBonus)
                .add(bonusProgramRewards.getCouponCampaignBonusTokensAmount(_couponCampaignId))
            ) {
                bonusProgramRewards.setCouponUsed(buyer, _couponCampaignId, true);
                couponBonus = bonusProgramRewards.getCouponCampaignBonusTokensAmount(_couponCampaignId);
            }
        }

        if (buyerBonus > 0 || purchaseBonus > 0 || couponBonus > 0) {
            token.transfer(buyer, buyerBonus.add(purchaseBonus).add(couponBonus));
        }

        emit BonusSent(referrer, referrerBonus, buyer, buyerBonus, purchaseBonus, couponBonus);
    }

    function getReferralBonusTokensAmountRanges() public view returns (uint256[]) {
        return referralBonusTokensAmountRanges;
    }

    function getReferrerRewards() public view returns (uint256[]) {
        return referrerRewards;
    }

    function getBuyerRewards() public view returns (uint256[]) {
        return buyerRewards;
    }

    function getPurchaseRewardsPercents() public view returns (uint256[]) {
        return purchaseRewardsPercents;
    }

    function getPurchaseAmountRangesInCents() public view returns (uint256[]) {
        return purchaseAmountRangesInCents;
    }

    function setReferralBonusTokensAmountRanges(uint[] ranges) public onlyOwner {
        referralBonusTokensAmountRanges = ranges;
    }

    function setReferrerRewards(uint[] rewards) public onlyOwner {
        require(rewards.length == referralBonusTokensAmountRanges.length - 1);
        referrerRewards = rewards;
    }

    function setBuyerRewards(uint[] rewards) public onlyOwner {
        require(rewards.length == referralBonusTokensAmountRanges.length - 1);
        buyerRewards = rewards;
    }

    function setPurchaseAmountRangesInCents(uint[] ranges) public onlyOwner {
        purchaseAmountRangesInCents = ranges;
    }

    function setPurchaseRewardsPercents(uint[] rewards) public onlyOwner {
        require(rewards.length == purchaseAmountRangesInCents.length);
        purchaseRewardsPercents = rewards;
    }

     
    function withdrawTokens() external onlyOwner {
        uint256 amount = token.balanceOf(this);
        address tokenOwner = token.owner();
        token.transfer(tokenOwner, amount);
    }
}

contract SignkeysBonusProgramRewards is Ownable {
    using SafeMath for uint256;

     
    SignkeysBonusProgram public bonusProgram;

     
    mapping(uint256 => uint256) private _couponCampaignBonusTokensAmount;

     
    mapping(address => bool) private _areReferralBonusesSent;

     
    mapping(address => mapping(uint256 => bool)) private _isCouponUsed;

    function setBonusProgram(address _bonusProgram) public onlyOwner {
        bonusProgram = SignkeysBonusProgram(_bonusProgram);
    }

    modifier onlyBonusProgramContract() {
        require(msg.sender == address(bonusProgram), "Bonus program rewards state may be changed only by bonus program contract");
        _;
    }

    function addCouponCampaignBonusTokensAmount(uint256 _couponCampaignId, uint256 amountOfBonuses) public onlyOwner {
        _couponCampaignBonusTokensAmount[_couponCampaignId] = amountOfBonuses;
    }

    function getCouponCampaignBonusTokensAmount(uint256 _couponCampaignId) public view returns (uint256)  {
        return _couponCampaignBonusTokensAmount[_couponCampaignId];
    }

    function isCouponUsed(address buyer, uint256 couponCampaignId) public view returns (bool)  {
        return _isCouponUsed[buyer][couponCampaignId];
    }

    function setCouponUsed(address buyer, uint256 couponCampaignId, bool isUsed) public onlyBonusProgramContract {
        _isCouponUsed[buyer][couponCampaignId] = isUsed;
    }

    function areReferralBonusesSent(address buyer) public view returns (bool)  {
        return _areReferralBonusesSent[buyer];
    }

    function setReferralBonusesSent(address buyer, bool areBonusesSent) public onlyBonusProgramContract {
        _areReferralBonusesSent[buyer] = areBonusesSent;
    }
}

 
contract ReentrancyGuard {

   
  uint256 private _guardCounter;

  constructor() internal {
     
     
    _guardCounter = 1;
  }

   
  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }

}

contract SignkeysCrowdsale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public INITIAL_TOKEN_PRICE_CENTS = 10;

     
    SignkeysToken public signkeysToken;

     
    SignkeysBonusProgram public signkeysBonusProgram;

     
    address public signer;

     
    address public wallet;

     
    uint256 public tokenPriceCents;

     
    event BuyTokens(
        address indexed buyer,
        address indexed tokenReceiver,
        uint256 tokenPrice,
        uint256 amount
    );

     
    event WalletChanged(address newWallet);

     
    event CrowdsaleSignerChanged(address newSigner);

     
    event TokenPriceChanged(uint256 oldPrice, uint256 newPrice);

    constructor(
        address _token,
        address _bonusProgram,
        address _wallet,
        address _signer
    ) public {
        require(_token != 0x0, "Token contract for crowdsale must be set");
        require(_bonusProgram != 0x0, "Referrer smart contract for crowdsale must be set");

        require(_wallet != 0x0, "Wallet for fund transferring must be set");
        require(_signer != 0x0, "Signer must be set");

        signkeysToken = SignkeysToken(_token);
        signkeysBonusProgram = SignkeysBonusProgram(_bonusProgram);

        signer = _signer;
        wallet = _wallet;

        tokenPriceCents = INITIAL_TOKEN_PRICE_CENTS;
    }

    function setSignerAddress(address _signer) external onlyOwner {
        signer = _signer;
        emit CrowdsaleSignerChanged(_signer);
    }

    function setWalletAddress(address _wallet) external onlyOwner {
        wallet = _wallet;
        emit WalletChanged(_wallet);
    }

    function setBonusProgram(address _bonusProgram) external onlyOwner {
        signkeysBonusProgram = SignkeysBonusProgram(_bonusProgram);
    }

    function setTokenPriceCents(uint256 _tokenPriceCents) external onlyOwner {
        emit TokenPriceChanged(tokenPriceCents, _tokenPriceCents);
        tokenPriceCents = _tokenPriceCents;
    }

     
    function buyTokens(
        address _tokenReceiver,
        address _referrer,
        uint256 _couponCampaignId,  
        uint256 _tokenPrice,
        uint256 _minWei,
        uint256 _expiration,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) payable external nonReentrant {
        require(_expiration >= now, "Signature expired");
        require(_tokenReceiver != 0x0, "Token receiver must be provided");
        require(_minWei > 0, "Minimal amount to purchase must be greater than 0");

        require(wallet != 0x0, "Wallet must be set");
        require(msg.value >= _minWei, "Purchased amount is less than min amount to invest");

        address receivedSigner = ecrecover(
            keccak256(
                abi.encodePacked(
                    _tokenPrice, _minWei, _tokenReceiver, _referrer, _couponCampaignId, _expiration
                )
            ), _v, _r, _s);

        require(receivedSigner == signer, "Something wrong with signature");

        uint256 tokensAmount = msg.value.mul(10 ** uint256(signkeysToken.decimals())).div(_tokenPrice);
        require(signkeysToken.balanceOf(this) >= tokensAmount, "Not enough tokens in sale contract");

        signkeysToken.transfer(_tokenReceiver, tokensAmount);

         
        signkeysBonusProgram.sendBonus(
            _referrer,
            _tokenReceiver,
            tokensAmount,
            (tokensAmount.mul(tokenPriceCents).div(10 ** uint256(signkeysToken.decimals()))),
            _couponCampaignId);

         
        wallet.transfer(msg.value);

        emit BuyTokens(msg.sender, _tokenReceiver, _tokenPrice, tokensAmount);
    }

     
    function() payable external {
        revert();
    }

     
    function withdrawTokens() external onlyOwner {
        uint256 amount = signkeysToken.balanceOf(this);
        address tokenOwner = signkeysToken.owner();
        signkeysToken.transfer(tokenOwner, amount);
    }
}