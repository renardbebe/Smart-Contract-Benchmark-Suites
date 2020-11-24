 

pragma solidity ^0.4.20;

contract Owned {
    address public owner;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface Token {
    function totalSupply() constant external returns (uint256);
    
    function transfer(address receiver, uint amount) external returns (bool success);
    function burn(uint256 _value) external returns (bool success);
    function startTrading() external;
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


interface TokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; 
    
}


interface AquaPriceOracle {
  function getAudCentWeiPrice() external constant returns (uint);
  function getAquaTokenAudCentsPrice() external constant returns (uint);
  event NewPrice(uint _audCentWeiPrice, uint _aquaTokenAudCentsPrice);
}


 

 
library LibCLLu {

    string constant public VERSION = "LibCLLu 0.4.0";
    uint constant NULL = 0;
    uint constant HEAD = 0;
    bool constant PREV = false;
    bool constant NEXT = true;
    
    struct CLL{
        mapping (uint => mapping (bool => uint)) cll;
    }

     

     
    function exists(CLL storage self, uint n)
        internal
        constant returns (bool)
    {
        if (self.cll[n][PREV] != HEAD || self.cll[n][NEXT] != HEAD)
            return true;
        if (n == HEAD)
            return false;
        if (self.cll[HEAD][NEXT] == n)
            return true;
        return false;
    }
    
     
    function sizeOf(CLL storage self) internal constant returns (uint r) {
        uint i = step(self, HEAD, NEXT);
        while (i != HEAD) {
            i = step(self, i, NEXT);
            r++;
        }
        return;
    }

     
    function getNode(CLL storage self, uint n)
        internal  constant returns (uint[2])
    {
        return [self.cll[n][PREV], self.cll[n][NEXT]];
    }

     
    function step(CLL storage self, uint n, bool d)
        internal  constant returns (uint)
    {
        return self.cll[n][d];
    }

     
     
     
     
    function seek(CLL storage self, uint a, uint b, bool d)
        internal  constant returns (uint r)
    {
        r = step(self, a, d);
        while  ((b!=r) && ((b < r) != d)) r = self.cll[r][d];
        return;
    }

     
    function stitch(CLL storage self, uint a, uint b, bool d) internal  {
        self.cll[b][!d] = a;
        self.cll[a][d] = b;
    }

     
    function insert (CLL storage self, uint a, uint b, bool d) internal  {
        uint c = self.cll[a][d];
        stitch (self, a, b, d);
        stitch (self, b, c, d);
    }
    
    function remove(CLL storage self, uint n) internal returns (uint) {
        if (n == NULL) return;
        stitch(self, self.cll[n][PREV], self.cll[n][NEXT], NEXT);
        delete self.cll[n][PREV];
        delete self.cll[n][NEXT];
        return n;
    }

    function push(CLL storage self, uint n, bool d) internal  {
        insert(self, HEAD, n, d);
    }
    
    function pop(CLL storage self, bool d) internal returns (uint) {
        return remove(self, step(self, HEAD, d));
    }
}

 
library LibCLLi {

    string constant public VERSION = "LibCLLi 0.4.0";
    int constant NULL = 0;
    int constant HEAD = 0;
    bool constant PREV = false;
    bool constant NEXT = true;
    
    struct CLL{
        mapping (int => mapping (bool => int)) cll;
    }

     

     
    function exists(CLL storage self, int n) internal constant returns (bool) {
        if (self.cll[n][PREV] != HEAD || self.cll[n][NEXT] != HEAD)
            return true;
        if (n == HEAD)
            return false;
        if (self.cll[HEAD][NEXT] == n)
            return true;
        return false;
    }
     
    function sizeOf(CLL storage self) internal constant returns (uint r) {
        int i = step(self, HEAD, NEXT);
        while (i != HEAD) {
            i = step(self, i, NEXT);
            r++;
        }
        return;
    }

     
    function getNode(CLL storage self, int n)
        internal  constant returns (int[2])
    {
        return [self.cll[n][PREV], self.cll[n][NEXT]];
    }

     
    function step(CLL storage self, int n, bool d)
        internal  constant returns (int)
    {
        return self.cll[n][d];
    }

     
     
     
     
    function seek(CLL storage self, int a, int b, bool d)
        internal  constant returns (int r)
    {
        r = step(self, a, d);
        while  ((b!=r) && ((b < r) != d)) r = self.cll[r][d];
        return;
    }

     
    function stitch(CLL storage self, int a, int b, bool d) internal  {
        self.cll[b][!d] = a;
        self.cll[a][d] = b;
    }

     
    function insert (CLL storage self, int a, int b, bool d) internal  {
        int c = self.cll[a][d];
        stitch (self, a, b, d);
        stitch (self, b, c, d);
    }
    
    function remove(CLL storage self, int n) internal returns (int) {
        if (n == NULL) return;
        stitch(self, self.cll[n][PREV], self.cll[n][NEXT], NEXT);
        delete self.cll[n][PREV];
        delete self.cll[n][NEXT];
        return n;
    }

    function push(CLL storage self, int n, bool d) internal  {
        insert(self, HEAD, n, d);
    }
    
    function pop(CLL storage self, bool d) internal returns (int) {
        return remove(self, step(self, HEAD, d));
    }
}

 
library LibCLLa {

    string constant public VERSION = "LibCLLa 0.4.0";
    address constant NULL = 0;
    address constant HEAD = 0;
    bool constant PREV = false;
    bool constant NEXT = true;
    
    struct CLL{
        mapping (address => mapping (bool => address)) cll;
    }

     

     
    function exists(CLL storage self, address n) internal constant returns (bool) {
        if (self.cll[n][PREV] != HEAD || self.cll[n][NEXT] != HEAD)
            return true;
        if (n == HEAD)
            return false;
        if (self.cll[HEAD][NEXT] == n)
            return true;
        return false;
    }
     
    function sizeOf(CLL storage self) internal constant returns (uint r) {
        address i = step(self, HEAD, NEXT);
        while (i != HEAD) {
            i = step(self, i, NEXT);
            r++;
        }
        return;
    }

     
    function getNode(CLL storage self, address n)
        internal  constant returns (address[2])
    {
        return [self.cll[n][PREV], self.cll[n][NEXT]];
    }

     
    function step(CLL storage self, address n, bool d)
        internal  constant returns (address)
    {
        return self.cll[n][d];
    }

     
     
     
     
    function seek(CLL storage self, address a, address b, bool d)
        internal  constant returns (address r)
    {
        r = step(self, a, d);
        while  ((b!=r) && ((b < r) != d)) r = self.cll[r][d];
        return;
    }

     
    function stitch(CLL storage self, address a, address b, bool d) internal  {
        self.cll[b][!d] = a;
        self.cll[a][d] = b;
    }

     
    function insert (CLL storage self, address a, address b, bool d) internal  {
        address c = self.cll[a][d];
        stitch (self, a, b, d);
        stitch (self, b, c, d);
    }
    
    function remove(CLL storage self, address n) internal returns (address) {
        if (n == NULL) return;
        stitch(self, self.cll[n][PREV], self.cll[n][NEXT], NEXT);
        delete self.cll[n][PREV];
        delete self.cll[n][NEXT];
        return n;
    }

    function push(CLL storage self, address n, bool d) internal  {
        insert(self, HEAD, n, d);
    }
    
    function pop(CLL storage self, bool d) internal returns (address) {
        return remove(self, step(self, HEAD, d));
    }
}


library LibHoldings {
    using LibCLLa for LibCLLa.CLL;
    bool constant PREV = false;
    bool constant NEXT = true;

    struct Holding {
        uint totalTokens;
        uint lockedTokens;
        uint weiBalance;
        uint lastRewardNumber;
    }
    
    struct HoldingsSet {
        LibCLLa.CLL keys;
        mapping (address => Holding) holdings;
    }
    
    function exists(HoldingsSet storage self, address holder) internal constant returns (bool) {
        return self.keys.exists(holder);
    }
    
    function add(HoldingsSet storage self, address holder, Holding h) internal {
        self.keys.push(holder, PREV);
        self.holdings[holder] = h;
    }
    
    function get(HoldingsSet storage self, address holder) constant internal returns (Holding storage) {
        require(self.keys.exists(holder));
        return self.holdings[holder];
    }
    
    function remove(HoldingsSet storage self, address holder) internal {
        require(self.keys.exists(holder));
        delete self.holdings[holder];
        self.keys.remove(holder);
    }
    
    function firstHolder(HoldingsSet storage self) internal constant returns (address) {
        return self.keys.step(0x0, NEXT);
    }
    function nextHolder(HoldingsSet storage self, address currentHolder) internal constant returns (address) {
        return self.keys.step(currentHolder, NEXT);
    }
}


library LibRedemptions {
    using LibCLLu for LibCLLu.CLL;
    bool constant PREV = false;
    bool constant NEXT = true;

    struct Redemption {
        uint256 Id;
        address holderAddress;
        uint256 numberOfTokens;
    }
    
    struct RedemptionsQueue {
        uint256 redemptionRequestsCounter;
        LibCLLu.CLL keys;
        mapping (uint => Redemption) queue;
    }
    
    function exists(RedemptionsQueue storage self, uint id) internal constant returns (bool) {
        return self.keys.exists(id);
    }
    
    function add(RedemptionsQueue storage self, address holder, uint _numberOfTokens) internal returns(uint) {
        Redemption memory r = Redemption({
            Id: ++self.redemptionRequestsCounter,
            holderAddress: holder, 
            numberOfTokens: _numberOfTokens
        });
        self.queue[r.Id] = r;
        self.keys.push(r.Id, PREV);
        return r.Id;
    }
    
    function get(RedemptionsQueue storage self, uint id) internal constant returns (Redemption storage) {
        require(self.keys.exists(id));
        return self.queue[id];
    }
    
    function remove(RedemptionsQueue storage self, uint id) internal {
        require(self.keys.exists(id));
        delete self.queue[id];
        self.keys.remove(id);
    }
    
    function firstRedemption(RedemptionsQueue storage self) internal constant returns (uint) {
        return self.keys.step(0x0, NEXT);
    }
    function nextRedemption(RedemptionsQueue storage self, uint currentId) internal constant returns (uint) {
        return self.keys.step(currentId, NEXT);
    }
}


contract AquaToken is Owned, Token {
    
     
    using SafeMath for uint256;
    using LibHoldings for LibHoldings.Holding;
    using LibHoldings for LibHoldings.HoldingsSet;
    using LibRedemptions for LibRedemptions.Redemption;
    using LibRedemptions for LibRedemptions.RedemptionsQueue;

     
    struct DistributionContext {
        uint distributionAmount;
        uint receivedRedemptionAmount;
        uint redemptionAmount;
        uint tokenPriceWei;
        uint currentRedemptionId;

        uint totalRewardAmount;
    }
    

    struct WindUpContext {
        uint totalWindUpAmount;
        uint tokenReward;
        uint paidReward;
        address currenHolderAddress;
    }
    
     
    bool constant PREV = false;
    bool constant NEXT = true;

     
    enum TokenStatus {
        OnSale,
        Trading,
        Distributing,
        WindingUp
    }
     
    TokenStatus public tokenStatus;
    
     
    AquaPriceOracle public priceOracle;
    LibHoldings.HoldingsSet internal holdings;
    uint256 internal totalSupplyOfTokens;
    LibRedemptions.RedemptionsQueue redemptionsQueue;
    
     
     
    uint8 public redemptionPercentageOfDistribution;
    mapping (address => mapping (address => uint256)) internal allowances;

    uint [] internal rewards;

    DistributionContext internal distCtx;
    WindUpContext internal windUpCtx;
    

     
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);    

     
    string public name;
     
    string public symbol;
     
    uint8 public decimals;
    
     
    function totalSupply() constant external returns (uint256) {
        return totalSupplyOfTokens;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        if (!holdings.exists(_owner))
            return 0;
        LibHoldings.Holding storage h = holdings.get(_owner);
        return h.totalTokens.sub(h.lockedTokens);
    }
     
    function transfer(address _to, uint256 _value) external returns (bool success) {
        return _transfer(msg.sender, _to, _value);
    }

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowances[_from][msg.sender]);      
        allowances[_from][msg.sender] = allowances[_from][msg.sender].sub( _value);
        return _transfer(_from, _to, _value);
    }
    
     
     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (tokenStatus == TokenStatus.OnSale) {
            require(msg.sender == owner);
        }
        allowances[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }
    
    
     
    
     
     
     
     
    event RequestRedemption(address holder, uint256 _numberOfTokens, uint _requestId);
    
     
     
     
     
    event CancelRedemptionRequest(address holder, uint256 _numberOfTokens, uint256 _requestId);
    
     
     
     
     
     
    event HolderRedemption(address holder, uint _requestId, uint256 _numberOfTokens, uint amount);

     
     
    event DistributionStarted(uint amount);
     
     
     
     
    event DistributionCompleted(uint redeemedAmount, uint rewardedAmount, uint remainingAmount);
     
     
     
     
    event WithdrawBalance(address holderAddress, uint amount, bool hasRemainingBalance);
    
     
     
     
    event ContinueDistribution(bool _continue);

     
     
    event WindingUpStarted(uint amount);
    
     
    event StartTrading();
    
     
     
     
    event Burn(address indexed from, uint256 numberOfTokens);

     
     
     
     
     
     
    function AquaToken(uint256 initialSupply, 
            string tokenName, 
            string tokenSymbol, 
            uint8 decimalUnits,
            uint8 _redemptionPercentageOfDistribution,
            address _priceOracle
    ) public
    {
        totalSupplyOfTokens = initialSupply;
        holdings.add(msg.sender, LibHoldings.Holding({
            totalTokens : initialSupply, 
            lockedTokens : 0,
            lastRewardNumber : 0,
            weiBalance : 0 
        }));

        name = tokenName;                          
        symbol = tokenSymbol;                      
        decimals = decimalUnits;                   
    
        redemptionPercentageOfDistribution = _redemptionPercentageOfDistribution;
    
        priceOracle = AquaPriceOracle(_priceOracle);
        owner = msg.sender;
        
        tokenStatus = TokenStatus.OnSale;
        rewards.push(0);
    }
    
     
    function startTrading() onlyOwner external {
        require(tokenStatus == TokenStatus.OnSale);
        tokenStatus = TokenStatus.Trading;
        StartTrading();
    }
    
     
     
     
     
    function requestRedemption(uint256 _numberOfTokens) public returns (uint) {
        require(tokenStatus == TokenStatus.Trading && _numberOfTokens > 0);
        LibHoldings.Holding storage h = holdings.get(msg.sender);
        require(h.totalTokens.sub( h.lockedTokens) >= _numberOfTokens);                  

        uint redemptionId = redemptionsQueue.add(msg.sender, _numberOfTokens);

        h.lockedTokens = h.lockedTokens.add(_numberOfTokens);
        RequestRedemption(msg.sender, _numberOfTokens, redemptionId);
        return redemptionId;
    }
    
     
     
     
    function cancelRedemptionRequest(uint256 _requestId) public {
        require(tokenStatus == TokenStatus.Trading && redemptionsQueue.exists(_requestId));
        LibRedemptions.Redemption storage r = redemptionsQueue.get(_requestId); 
        require(r.holderAddress == msg.sender);

        LibHoldings.Holding storage h = holdings.get(msg.sender); 
        h.lockedTokens = h.lockedTokens.sub(r.numberOfTokens);
        uint numberOfTokens = r.numberOfTokens;
        redemptionsQueue.remove(_requestId);

        CancelRedemptionRequest(msg.sender, numberOfTokens,  _requestId);
    }
    
     
     
    function firstRedemptionRequest() public constant returns (uint) {
        return redemptionsQueue.firstRedemption();
    }
    
     
     
     
     
    function nextRedemptionRequest(uint _currentRedemptionId) public constant returns (uint) {
        return redemptionsQueue.nextRedemption(_currentRedemptionId);
    }
    
     
     
     
     
    function getRedemptionRequest(uint _requestId) public constant returns 
                (address _holderAddress, uint256 _numberOfTokens) {
        LibRedemptions.Redemption storage r = redemptionsQueue.get(_requestId);
        _holderAddress = r.holderAddress;
        _numberOfTokens = r.numberOfTokens;
    }
    
     
     
     
    function firstHolder() public constant returns (address) {
        return holdings.firstHolder();
    }    
    
     
     
     
     
    function nextHolder(address _currentHolder) public constant returns (address) {
        return holdings.nextHolder(_currentHolder);
    }
    
     
     
     
     
     
    function getHolding(address _holder) public constant 
            returns (uint totalTokens, uint lockedTokens, uint weiBalance) {
        if (!holdings.exists(_holder)) {
            totalTokens = 0;
            lockedTokens = 0;
            weiBalance = 0;
            return;
        }
        LibHoldings.Holding storage h = holdings.get(_holder);
        totalTokens = h.totalTokens;
        lockedTokens = h.lockedTokens;
        uint stepsMade;
        (weiBalance, stepsMade) = calcFullWeiBalance(h, 0);
        return;
    }
    
     
    function startDistribuion() onlyOwner public payable {
        require(tokenStatus == TokenStatus.Trading);
        tokenStatus = TokenStatus.Distributing;
        startRedemption(msg.value);
        DistributionStarted(msg.value);
    } 
    
     
     
     
    function continueDistribution(uint maxNumbeOfSteps) public returns (bool) {
        require(tokenStatus == TokenStatus.Distributing);
        if (continueRedeeming(maxNumbeOfSteps)) {
            ContinueDistribution(true);
            return true;
        }
        uint tokenReward = distCtx.totalRewardAmount.div( totalSupplyOfTokens );
        rewards.push(tokenReward);
        uint paidReward = tokenReward.mul(totalSupplyOfTokens);


        uint unusedDistributionAmount = distCtx.totalRewardAmount.sub(paidReward);
        if (unusedDistributionAmount > 0) {
            if (!holdings.exists(owner)) { 
                holdings.add(owner, LibHoldings.Holding({
                    totalTokens : 0, 
                    lockedTokens : 0,
                    lastRewardNumber : rewards.length.sub(1),
                    weiBalance : unusedDistributionAmount 
                }));
            }
            else {
                LibHoldings.Holding storage ownerHolding = holdings.get(owner);
                ownerHolding.weiBalance = ownerHolding.weiBalance.add(unusedDistributionAmount);
            }
        }
        tokenStatus = TokenStatus.Trading;
        DistributionCompleted(distCtx.receivedRedemptionAmount.sub(distCtx.redemptionAmount), 
                            paidReward, unusedDistributionAmount);
        ContinueDistribution(false);
        return false;
    }

     
     
     
     
    function withdrawBalanceMaxSteps(uint maxSteps) public {
        require(holdings.exists(msg.sender));
        LibHoldings.Holding storage h = holdings.get(msg.sender); 
        uint updatedBalance;
        uint stepsMade;
        (updatedBalance, stepsMade) = calcFullWeiBalance(h, maxSteps);
        h.weiBalance = 0;
        h.lastRewardNumber = h.lastRewardNumber.add(stepsMade);
        
        bool balanceRemainig = h.lastRewardNumber < rewards.length.sub(1);
        if (h.totalTokens == 0 && h.weiBalance == 0) 
            holdings.remove(msg.sender);

        msg.sender.transfer(updatedBalance);
        
        WithdrawBalance(msg.sender, updatedBalance, balanceRemainig);
    }

     
     
    function withdrawBalance() public {
        withdrawBalanceMaxSteps(0);
    }

     
     
     
     
     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        TokenRecipient spender = TokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
     
     
     
    function burn(uint256 numberOfTokens) external returns (bool success) {
        require(holdings.exists(msg.sender));
        if (numberOfTokens == 0) {
            Burn(msg.sender, numberOfTokens);
            return true;
        }
        LibHoldings.Holding storage fromHolding = holdings.get(msg.sender);
        require(fromHolding.totalTokens.sub(fromHolding.lockedTokens) >= numberOfTokens);                  

        updateWeiBalance(fromHolding, 0);    
        fromHolding.totalTokens = fromHolding.totalTokens.sub(numberOfTokens);                          
        if (fromHolding.totalTokens == 0 && fromHolding.weiBalance == 0) 
            holdings.remove(msg.sender);
        totalSupplyOfTokens = totalSupplyOfTokens.sub(numberOfTokens);

        Burn(msg.sender, numberOfTokens);
        return true;
    }

     
    function windUp() onlyOwner public payable {
        require(tokenStatus == TokenStatus.Trading);
        tokenStatus = TokenStatus.WindingUp;
        uint totalWindUpAmount = msg.value;
    
        uint tokenReward = msg.value.div(totalSupplyOfTokens);
        rewards.push(tokenReward);
        uint paidReward = tokenReward.mul(totalSupplyOfTokens);

        uint unusedWindUpAmount = totalWindUpAmount.sub(paidReward);
        if (unusedWindUpAmount > 0) {
            if (!holdings.exists(owner)) { 
                holdings.add(owner, LibHoldings.Holding({
                    totalTokens : 0, 
                    lockedTokens : 0,
                    lastRewardNumber : rewards.length.sub(1),
                    weiBalance : unusedWindUpAmount 
                }));
            }
            else {
                LibHoldings.Holding storage ownerHolding = holdings.get(owner);
                ownerHolding.weiBalance = ownerHolding.weiBalance.add(unusedWindUpAmount);
            }
        }
        WindingUpStarted(msg.value);
    }
     
    function calcFullWeiBalance(LibHoldings.Holding storage holding, uint maxSteps) internal constant 
                    returns(uint updatedBalance, uint stepsMade) {
        uint fromRewardIdx = holding.lastRewardNumber.add(1);
        updatedBalance = holding.weiBalance;
        if (fromRewardIdx == rewards.length) {
            stepsMade = 0;
            return;
        }

        uint toRewardIdx;
        if (maxSteps == 0) {
            toRewardIdx = rewards.length.sub( 1);
        }
        else {
            toRewardIdx = fromRewardIdx.add( maxSteps ).sub(1);
            if (toRewardIdx > rewards.length.sub(1)) {
                toRewardIdx = rewards.length.sub(1);
            }
        }
        for(uint idx = fromRewardIdx; 
                    idx <= toRewardIdx; 
                    idx = idx.add(1)) {
            updatedBalance = updatedBalance.add( 
                rewards[idx].mul( holding.totalTokens ) 
                );
        }
        stepsMade = toRewardIdx.sub( fromRewardIdx ).add( 1 );
        return;
    }
    
    function updateWeiBalance(LibHoldings.Holding storage holding, uint maxSteps) internal 
                returns(uint updatedBalance, uint stepsMade) {
        (updatedBalance, stepsMade) = calcFullWeiBalance(holding, maxSteps);
        if (stepsMade == 0)
            return;
        holding.weiBalance = updatedBalance;
        holding.lastRewardNumber = holding.lastRewardNumber.add(stepsMade);
    }
    

    function startRedemption(uint distributionAmount) internal {
        distCtx.distributionAmount = distributionAmount;
        distCtx.receivedRedemptionAmount = 
            (distCtx.distributionAmount.mul(redemptionPercentageOfDistribution)).div(100);
        distCtx.redemptionAmount = distCtx.receivedRedemptionAmount;
        distCtx.tokenPriceWei = priceOracle.getAquaTokenAudCentsPrice().mul(priceOracle.getAudCentWeiPrice());

        distCtx.currentRedemptionId = redemptionsQueue.firstRedemption();
    }
    
    function continueRedeeming(uint maxNumbeOfSteps) internal returns (bool) {
        uint remainingNoSteps = maxNumbeOfSteps;
        uint currentId = distCtx.currentRedemptionId;
        uint redemptionAmount = distCtx.redemptionAmount;
        uint totalRedeemedTokens = 0;
        while(currentId != 0 && redemptionAmount > 0) {
            if (remainingNoSteps == 0) { 
                distCtx.currentRedemptionId = currentId;
                distCtx.redemptionAmount = redemptionAmount;
                if (totalRedeemedTokens > 0) {
                    totalSupplyOfTokens = totalSupplyOfTokens.sub( totalRedeemedTokens );
                }
                return true;
            }
            if (redemptionAmount.div(distCtx.tokenPriceWei) < 1)
                break;

            LibRedemptions.Redemption storage r = redemptionsQueue.get(currentId);
            LibHoldings.Holding storage holding = holdings.get(r.holderAddress);
            uint updatedBalance;
            uint stepsMade;
            (updatedBalance, stepsMade) = updateWeiBalance(holding, remainingNoSteps);
            remainingNoSteps = remainingNoSteps.sub(stepsMade);          
            if (remainingNoSteps == 0) { 
                distCtx.currentRedemptionId = currentId;
                distCtx.redemptionAmount = redemptionAmount;
                if (totalRedeemedTokens > 0) {
                    totalSupplyOfTokens = totalSupplyOfTokens.sub(totalRedeemedTokens);
                }
                return true;
            }

            uint holderTokensToRedeem = redemptionAmount.div(distCtx.tokenPriceWei);
            if (holderTokensToRedeem > r.numberOfTokens)
                holderTokensToRedeem = r.numberOfTokens;

            uint holderRedemption = holderTokensToRedeem.mul(distCtx.tokenPriceWei);
            holding.weiBalance = holding.weiBalance.add( holderRedemption );

            redemptionAmount = redemptionAmount.sub( holderRedemption );
            
            r.numberOfTokens = r.numberOfTokens.sub( holderTokensToRedeem );
            holding.totalTokens = holding.totalTokens.sub(holderTokensToRedeem);
            holding.lockedTokens = holding.lockedTokens.sub(holderTokensToRedeem);
            totalRedeemedTokens = totalRedeemedTokens.add( holderTokensToRedeem );

            uint nextId = redemptionsQueue.nextRedemption(currentId);
            HolderRedemption(r.holderAddress, currentId, holderTokensToRedeem, holderRedemption);
            if (r.numberOfTokens == 0) 
                redemptionsQueue.remove(currentId);
            currentId = nextId;
            remainingNoSteps = remainingNoSteps.sub(1);
        }
        distCtx.currentRedemptionId = currentId;
        distCtx.redemptionAmount = redemptionAmount;
        totalSupplyOfTokens = totalSupplyOfTokens.sub(totalRedeemedTokens);
        distCtx.totalRewardAmount = 
            distCtx.distributionAmount.sub(distCtx.receivedRedemptionAmount).add(distCtx.redemptionAmount);
        return false;
    }


    function _transfer(address _from, address _to, uint _value) internal returns (bool success) {
        require(_to != 0x0);                                 
        if (tokenStatus == TokenStatus.OnSale) {
            require(_from == owner);
        }
        if (_value == 0) {
            Transfer(_from, _to, _value);
            return true;
        }
        require(holdings.exists(_from));
        
        LibHoldings.Holding storage fromHolding = holdings.get(_from);
        require(fromHolding.totalTokens.sub(fromHolding.lockedTokens) >= _value);                  
        
        if (!holdings.exists(_to)) { 
            holdings.add(_to, LibHoldings.Holding({
                totalTokens : _value, 
                lockedTokens : 0,
                lastRewardNumber : rewards.length.sub(1),
                weiBalance : 0 
            }));
        }
        else {
            LibHoldings.Holding storage toHolding = holdings.get(_to);
            require(toHolding.totalTokens.add(_value) >= toHolding.totalTokens);   
            
            updateWeiBalance(toHolding, 0);    
            toHolding.totalTokens = toHolding.totalTokens.add(_value);                           
        }

        updateWeiBalance(fromHolding, 0);    
        fromHolding.totalTokens = fromHolding.totalTokens.sub(_value);                          
        if (fromHolding.totalTokens == 0 && fromHolding.weiBalance == 0) 
            holdings.remove(_from);
        Transfer(_from, _to, _value);
        return true;
    }
    
}