 

pragma solidity ^0.4.24;

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 
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

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

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


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

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

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
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

   
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 
contract Crowdsale is Ownable{
  using SafeMath for uint256;

   
  address public wallet;

   
  uint256 public weiRaised;

  bool public isFinalized = false;

  uint256 public openingTime;
  uint256 public closingTime;

  event Finalized();

   
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

   
  modifier onlyWhileOpen {
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }
  
   
  constructor(address _wallet, uint256 _openingTime, uint256 _closingTime) public {
    require(_wallet != address(0));
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;

    wallet = _wallet;
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

    _forwardFunds();
  }

   
  function finalize() public onlyOwner {
    require(!isFinalized);
    require(hasClosed());

    emit Finalized();

    isFinalized = true;
  }

   
   
   

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal view
    onlyWhileOpen
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
   function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal;

   
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function _getTokenAmount(uint256 weiAmount) internal view returns (uint256);

   
  function hasClosed() public view returns (bool) {
    return block.timestamp > closingTime;
  }

}

contract FieldCoin is MintableToken, BurnableToken{

    using SafeMath for uint256;
    
     
    string public name;
     
    string public symbol;
     
    uint8 public decimals;
     
    address public bountyWallet;
     
    address public teamWallet;
     
    bool public transferEnabled;
     
    uint256 public TOKEN_OFFERING_ALLOWANCE = 770e6 * 10 **18; 
     
    address public tokenOfferingAddr;
     
    address public landCollectorAddr;

    mapping(address => bool) public transferAgents;
     
    mapping(address => bool) private blacklist;

         
    modifier canTransfer(address sender) {
        require(transferEnabled || transferAgents[sender], "transfer is not enabled or sender is not allowed");
          _;
    }

     
    modifier onlyTokenOfferingAddrNotSet() {
        require(tokenOfferingAddr == address(0x0), "token offering address is already set");
        _;
    }

     
    modifier onlyWhenLandCollectporAddressIsSet() {
        require(landCollectorAddr != address(0x0), "land collector address is not set");
        _;
    }


     
    modifier validDestination(address to) {
        require(to != address(0x0), "receiver can't be zero address");
        require(to != address(this), "receiver can't be token address");
        require(to != owner, "receiver can't be owner");
        require(to != address(tokenOfferingAddr), "receiver can't be token offering address");
        _;
    }

     
    constructor () public {
        name    =   "Fieldcoin";
        symbol  =   "FLC";
        decimals    =   18;  
        totalSupply_ =   1000e6 * 10  **  uint256(decimals);  
        owner   =   msg.sender;
        balances[owner] = totalSupply_;
    }

     
    function setBountyWallet (address _bountyWallet) public onlyOwner returns (bool) {
        require(_bountyWallet != address(0x0), "bounty address can't be zero");
        if(bountyWallet == address(0x0)){  
            bountyWallet = _bountyWallet;
            balances[bountyWallet] = 20e6 * 10   **  uint256(decimals);  
            balances[owner] = balances[owner].sub(20e6 * 10   **  uint256(decimals));
        }else{
            address oldBountyWallet = bountyWallet;
            bountyWallet = _bountyWallet;
            balances[bountyWallet] = balances[oldBountyWallet];
        }
        return true;
    }

     
    function setTeamWallet (address _teamWallet) public onlyOwner returns (bool) {
        require(_teamWallet != address(0x0), "team address can't be zero");
        if(teamWallet == address(0x0)){  
            teamWallet = _teamWallet;
            balances[teamWallet] = 90e6 * 10   **  uint256(decimals);  
            balances[owner] = balances[owner].sub(90e6 * 10   **  uint256(decimals));
        }else{
            address oldTeamWallet = teamWallet;
            teamWallet = _teamWallet;
            balances[teamWallet] = balances[oldTeamWallet];
        }
        return true;
    }

     
    function transfer(address to, uint256 value) canTransfer(msg.sender) validDestination(to) public returns (bool) {
        return super.transfer(to, value);
    }

     
    function transferFrom(address from, address to, uint256 value) canTransfer(msg.sender) validDestination(to) public returns (bool) {
        return super.transferFrom(from, to, value);
    }

     
    function addBlacklistAddress(address addr) public onlyOwner {
        require(!isBlacklisted(addr), "address is already blacklisted");
        require(addr != address(0x0), "blacklisting address can't be zero");
         
        blacklist[addr] = true;
    }

     
    function setTokenOffering(address offeringAddr, uint256 amountForSale) external onlyOwner onlyTokenOfferingAddrNotSet {
        require (offeringAddr != address(0x0), "offering address can't be zero");
        require(!transferEnabled, "transfer should be diabled");

        uint256 amount = (amountForSale == 0) ? TOKEN_OFFERING_ALLOWANCE : amountForSale;
        require(amount <= TOKEN_OFFERING_ALLOWANCE);

        approve(offeringAddr, amount);
        tokenOfferingAddr = offeringAddr;
         
        setTransferAgent(tokenOfferingAddr, true);

    }

     
    function setLandCollector(address collectorAddr) public onlyOwner {
        require (collectorAddr != address(0x0), "land collecting address can't be set to zero");
        require(!transferEnabled,  "transfer should be diabled");
        landCollectorAddr = collectorAddr;
    }


     
    function enableTransfer() public onlyOwner {
        transferEnabled = true;
         
        approve(tokenOfferingAddr, 0);
         
        setTransferAgent(tokenOfferingAddr, false);
    }

     
    function setTransferAgent(address _addr, bool _allowTransfer) public onlyOwner {
        transferAgents[_addr] = _allowTransfer;
    }

     
    function _withdraw(address _investor, uint256 _tokens) external{
        require (msg.sender == tokenOfferingAddr, "sender must be offering address");
        require (isBlacklisted(_investor), "address is not whitelisted");
        balances[owner] = balances[owner].add(_tokens);
        balances[_investor] = balances[_investor].sub(_tokens);
        balances[_investor] = 0;
    }

     
    function _buyLand(address _investor, uint256 _tokens) external onlyWhenLandCollectporAddressIsSet{
        require (!transferEnabled, "transfer should be diabled");
        require (msg.sender == tokenOfferingAddr, "sender must be offering address");
        balances[landCollectorAddr] = balances[landCollectorAddr].add(_tokens);
        balances[_investor] = balances[_investor].sub(_tokens);
    }

    
    function burn(uint256 _value) public {
        require(transferEnabled || msg.sender == owner, "transfer is not enabled or sender is not owner");
        super.burn(_value);
    }

     
    function isBlacklisted(address _addr) public view returns(bool){
        return blacklist[_addr];
    }

}

contract FieldCoinSale is Crowdsale, Pausable{

    using SafeMath for uint256;

     
    uint256 public totalSaleSupply = 600000000 *10 **18;  
     
    uint256 public tokenCost = 5;  
     
    uint256 public ETH_USD;
     
    uint256 public minContribution = 10000;  
     
    uint256 public maxContribution = 100000000;  
     
    uint256 public milestoneCount;
     
    bool public initialized = false;
     
    uint256 public bonusTokens = 170e6 * 10 ** 18;  
     
    uint256 public tokensSold = 0;
     
    FieldCoin private objFieldCoin;

    struct Milestone {
        uint256 bonus;
        uint256 total;
    }

    Milestone[6] public milestones;
    
     
    struct Investor {
        uint256 weiReceived;
        uint256 tokenSent;
        uint256 bonusSent;
    }

     
    mapping(address => Investor) public investors;

     
    event Withdrawn();

     
    constructor (uint256 _openingTime, uint256 _closingTime, address _wallet, address _token, uint256 _ETH_USD, uint256 _minContribution, uint256 _maxContribution) public
    Crowdsale(_wallet, _openingTime, _closingTime) {
        require(_ETH_USD > 0, "ETH USD rate should be greater than 0");
        minContribution = (_minContribution == 0) ? minContribution : _minContribution;
        maxContribution = (_maxContribution == 0) ? maxContribution : _maxContribution;
        ETH_USD = _ETH_USD;
        objFieldCoin = FieldCoin(_token);
    }

     
    function setETH_USDRate(uint256 _ETH_USD) public onlyOwner{
        require(_ETH_USD > 0, "ETH USD rate should be greater than 0");
        ETH_USD = _ETH_USD;
    }

     
    function setNewWallet(address _newWallet) onlyOwner public {
        wallet = _newWallet;
    }

     
    function changeMinContribution(uint256 _minContribution) public onlyOwner {
        require(_minContribution > 0, "min contribution should be greater than 0");
        minContribution = _minContribution;
    }

     
    function changeMaxContribution(uint256 _maxContribution) public onlyOwner {
        require(_maxContribution > 0, "max contribution should be greater than 0");
        maxContribution = _maxContribution;
    }

     
    function changeTokenCost(uint256 _tokenCost) public onlyOwner {
        require(_tokenCost > 0, "token cost can not be zero");
        tokenCost = _tokenCost;
    }

     
    function changeOpeningTIme(uint256 _openingTime) public onlyOwner {
        require(_openingTime >= block.timestamp, "opening time is less than current time");
        openingTime = _openingTime;
    }

     
    function changeClosingTime(uint256 _closingTime) public onlyOwner {
        require(_closingTime >= openingTime, "closing time is less than opening time");
        closingTime = _closingTime;
    }

     
    function initializeMilestones(uint256[] _bonus, uint256[] _total) public onlyOwner {
        require(_bonus.length > 0 && _bonus.length == _total.length);
        for(uint256 i = 0; i < _bonus.length; i++) {
            milestones[i] = Milestone({ total: _total[i], bonus: _bonus[i] });
        }
        milestoneCount = _bonus.length;
        initialized = true;
    }

     
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        require(tokensRemaining() >= _tokenAmount, "token need to be transferred is more than the available token");
        uint256 _bonusTokens = _processBonus(_tokenAmount);
        bonusTokens = bonusTokens.sub(_bonusTokens);
        tokensSold = tokensSold.add(_tokenAmount);
         
        uint256 totalNumberOfTokenTransferred = _tokenAmount.add(_bonusTokens);
         
        Investor storage _investor = investors[_beneficiary];
         
        _investor.tokenSent = _investor.tokenSent.add(totalNumberOfTokenTransferred);
        _investor.weiReceived = _investor.weiReceived.add(msg.value);
        _investor.bonusSent = _investor.bonusSent.add(_bonusTokens);
        super._processPurchase(_beneficiary, totalNumberOfTokenTransferred);
    }

      
    function createTokenManually(address _beneficiary, uint256 weiAmount) external onlyOwner {
         
        uint256 tokens = _getTokenAmount(weiAmount);
        
         
        weiRaised = weiRaised.add(weiAmount);
    
        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(
          msg.sender,
          _beneficiary,
          weiAmount,
          tokens
        );
    }

     
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        if(!objFieldCoin.transferFrom(objFieldCoin.owner(), _beneficiary, _tokenAmount)){
            revert("token delivery failed");
        }
    }

     
    function withdraw() external{
        Investor storage _investor = investors[msg.sender];
         
        objFieldCoin._withdraw(msg.sender, _investor.tokenSent);
         
        msg.sender.transfer(_investor.weiReceived);
         
        _investor.weiReceived = 0;
        _investor.tokenSent = 0;
        _investor.bonusSent = 0;
        emit Withdrawn();
    }

     
    function buyLand(uint256 _tokens) external{
        Investor memory _investor = investors[msg.sender];
        require (_tokens <= objFieldCoin.balanceOf(msg.sender).sub(_investor.bonusSent), "token to buy land is more than the available number of tokens");
         
        objFieldCoin._buyLand(msg.sender, _tokens);
    }

     
    function fundContractForWithdraw()external payable{
    }

     
    function increaseBonusAllowance(uint256 _value) public onlyOwner {
        bonusTokens = bonusTokens.add(_value);
    }
    
     
     
     

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) whenNotPaused internal view{
        require (!hasClosed(), "Sale has been ended");
        require(initialized, "Bonus is not initialized");
        require(_weiAmount >= getMinContributionInWei(), "amount is less than min contribution");
        require(_weiAmount <= getMaxContributionInWei(), "amount is more than max contribution");
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }

    function _processBonus(uint256 _tokenAmount) internal view returns(uint256){
        uint256 currentMilestoneIndex = getCurrentMilestoneIndex();
        uint256 _bonusTokens = 0;
         
        Milestone memory _currentMilestone = milestones[currentMilestoneIndex];
        if(bonusTokens > 0 && _currentMilestone.bonus > 0) {
          _bonusTokens = _tokenAmount.mul(_currentMilestone.bonus).div(100);
          _bonusTokens = bonusTokens < _bonusTokens ? bonusTokens : _bonusTokens;
        }
        return _bonusTokens;
    }

     
    function tokensRemaining() public view returns(uint256) {
        return totalSaleSupply.sub(tokensSold);
    }

     
    function getCurrentMilestoneIndex() public view returns (uint256) {
        for(uint256 i = 0; i < milestoneCount; i++) {
            if(tokensSold < milestones[i].total) {
                return i;
            }
        }
    }

     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.mul(ETH_USD).div(tokenCost);
    }

     
    function hasClosed() public view returns (bool) {
        uint256 tokensLeft = tokensRemaining();
        return tokensLeft <= 1e18 || super.hasClosed();
    }

     
    function getMinContributionInWei() public view returns(uint256){
        return (minContribution.mul(1e18)).div(ETH_USD);
    }

     
    function getMaxContributionInWei() public view returns(uint256){
        return (maxContribution.mul(1e18)).div(ETH_USD);
    }

     
    function usdRaised() public view returns (uint256) {
        return weiRaised.mul(ETH_USD).div(1e18);
    }
    
}