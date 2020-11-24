 

pragma solidity ^0.4.23;

 

contract ERC20 {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract PlayerToken is ERC20 {

     
    address public owner;
    bool public paused = false;

     
    event PlayerTokenBuy(address indexed buyer, address indexed referrer, uint tokens, uint cost, string symbol);
    event PlayerTokenSell(address indexed seller, uint tokens, uint value, string symbol);

     
    using SafeMath for uint256;

     
    uint256 public initialTokenPrice_;   
    uint256 public incrementalTokenPrice_;  

     
    string public name;
    string public symbol;
    uint8 public constant decimals = 0;

     
     
    address public exchangeContract_;
    
     
    BCFMain bcfContract_ = BCFMain(0x6abF810730a342ADD1374e11F3e97500EE774D1F);
    uint256 public playerId_;
    address public originalOwner_;

     
    uint8 constant internal processingFee_ = 5;  
    uint8 constant internal originalOwnerFee_ = 2;  
    uint8 internal dividendBuyPoolFee_ = 15;  
    uint8 internal dividendSellPoolFee_ = 20;
    uint8 constant internal referrerFee_ = 1;  

     
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) internal allowed;

     
    address[] public tokenHolders;
    mapping(address => uint256) public addressToTokenHolderIndex;  
    mapping(address => int256) public totalCost;  

     
    uint256 totalSupply_;

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyOwnerOrExchange() {
        require(msg.sender == owner || msg.sender == exchangeContract_);
        _;
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

     
    constructor(
        string _name, 
        string _symbol, 
        uint _startPrice, 
        uint _incrementalPrice, 
        address _owner, 
        address _exchangeContract, 
        uint256 _playerId,
        uint8 _promoSharesQuantity
    ) 
        public
        payable
    {
        require(_exchangeContract != address(0));
        require(_owner != address(0));

        exchangeContract_ = _exchangeContract;
        playerId_ = _playerId;

         
        initialTokenPrice_ = _startPrice;
        incrementalTokenPrice_ = _incrementalPrice;  

         
        paused = true;
        owner = _owner;
        name = _name;
        symbol = _symbol;

         
        if (_promoSharesQuantity > 0) {
            _buyTokens(msg.value, _promoSharesQuantity, _owner, address(0));
        }
    }

     
    function buyTokens(uint8 _amount, address _referredBy) payable external whenNotPaused {
        require(_amount > 0 && _amount <= 100, "Valid token amount required between 1 and 100");
        require(msg.value > 0, "Provide a valid fee"); 
         
        require(msg.sender == tx.origin, "Only valid users are allowed to buy tokens"); 
        _buyTokens(msg.value, _amount, msg.sender, _referredBy);
    }

    function sellTokens(uint8 _amount) external {
        require(_amount > 0, "Valid sell amount required");
        require(_amount <= balances[msg.sender]);
        _sellTokens(_amount, msg.sender);
    }

     
    function _buyTokens(uint _ethSent, uint8 _amount, address _buyer, address _referredBy) internal {
        
        uint _totalCost;
        uint _processingFee;
        uint _originalOwnerFee;
        uint _dividendPoolFee;
        uint _referrerFee;

        (_totalCost, _processingFee, _originalOwnerFee, _dividendPoolFee, _referrerFee) = calculateTokenBuyPrice(_amount);

        require(_ethSent >= _totalCost, "Invalid fee to buy tokens");

         
         
        if (originalOwner_ != address(0)) {
            originalOwner_.transfer(_originalOwnerFee);
        } else {
            _dividendPoolFee = _dividendPoolFee.add(_originalOwnerFee);
        }

         
        if (_referredBy != address(0)) {
            _referredBy.transfer(_referrerFee);
        } else {
            _dividendPoolFee = _dividendPoolFee.add(_referrerFee);
        }

         
        owner.transfer(_processingFee);
        exchangeContract_.transfer(_dividendPoolFee);

         
        uint excess = _ethSent.sub(_totalCost);
        _buyer.transfer(excess);

         
        if (balanceOf(_buyer) == 0) {
            tokenHolders.push(_buyer);
            addressToTokenHolderIndex[_buyer] = tokenHolders.length - 1;
        }
        
         
        _allocatePlayerTokensTo(_buyer, _amount);

         
        totalCost[_buyer] = totalCost[_buyer] + int256(_totalCost);  

         
        emit PlayerTokenBuy(_buyer, _referredBy, _amount, _totalCost, symbol);
    }

    function _sellTokens(uint8 _amount, address _seller) internal {
        
        uint _totalSellerProceeds;
        uint _processingFee;
        uint _dividendPoolFee;

        (_totalSellerProceeds, _processingFee, _dividendPoolFee) = calculateTokenSellPrice(_amount);

         
        _burnPlayerTokensFrom(_seller, _amount);

         
         
        if (balanceOf(_seller) == 0) {
            removeFromTokenHolders(_seller);
        }

         
        owner.transfer(_processingFee);
        _seller.transfer(_totalSellerProceeds);
        exchangeContract_.transfer(_dividendPoolFee);

         
        totalCost[_seller] = totalCost[_seller] - int256(_totalSellerProceeds);  

         
        emit PlayerTokenSell(_seller, _amount, _totalSellerProceeds, symbol);
    }

     
    function calculateTokenBuyPrice(uint _amount) 
        public 
        view 
        returns (
        uint _totalCost, 
        uint _processingFee, 
        uint _originalOwnerFee, 
        uint _dividendPoolFee, 
        uint _referrerFee
    ) {    
        uint tokenCost = calculateTokenOnlyBuyPrice(_amount);

         
         
         
        _processingFee = SafeMath.div(SafeMath.mul(tokenCost, processingFee_), 100);
        _originalOwnerFee = SafeMath.div(SafeMath.mul(tokenCost, originalOwnerFee_), 100);
        _dividendPoolFee = SafeMath.div(SafeMath.mul(tokenCost, dividendBuyPoolFee_), 100);
        _referrerFee = SafeMath.div(SafeMath.mul(tokenCost, referrerFee_), 100);

        _totalCost = tokenCost.add(_processingFee).add(_originalOwnerFee).add(_dividendPoolFee).add(_referrerFee);
    }

    function calculateTokenSellPrice(uint _amount) 
        public 
        view 
        returns (
        uint _totalSellerProceeds,
        uint _processingFee,
        uint _dividendPoolFee
    ) {
        uint tokenSellCost = calculateTokenOnlySellPrice(_amount);

         
         
        _processingFee = SafeMath.div(SafeMath.mul(tokenSellCost, processingFee_), 100);
        _dividendPoolFee = SafeMath.div(SafeMath.mul(tokenSellCost, dividendSellPoolFee_), 100);

        _totalSellerProceeds = tokenSellCost.sub(_processingFee).sub(_dividendPoolFee);
    }

     
    function calculateTokenOnlyBuyPrice(uint _amount) public view returns(uint) {
        
         
	     
	     

         
        uint8 multiplier = 10;
        uint amountMultiplied = _amount * multiplier; 
        uint startingPrice = initialTokenPrice_ + (totalSupply_ * incrementalTokenPrice_);
        uint totalBuyPrice = (amountMultiplied / 2) * (2 * startingPrice + (_amount - 1) * incrementalTokenPrice_) / multiplier;

         
        assert(totalBuyPrice >= startingPrice); 
        return totalBuyPrice;
    }

    function calculateTokenOnlySellPrice(uint _amount) public view returns(uint) {
         
        uint8 multiplier = 10;
        uint amountMultiplied = _amount * multiplier; 
        uint startingPrice = initialTokenPrice_ + ((totalSupply_-1) * incrementalTokenPrice_);
        int absIncrementalTokenPrice = int(incrementalTokenPrice_) * -1;
        uint totalSellPrice = uint((int(amountMultiplied) / 2) * (2 * int(startingPrice) + (int(_amount) - 1) * absIncrementalTokenPrice) / multiplier);
        return totalSellPrice;
    }

     
    function buySellPrices() public view returns(uint _buyPrice, uint _sellPrice) {
        (_buyPrice,,,,) = calculateTokenBuyPrice(1);
        (_sellPrice,,) = calculateTokenSellPrice(1);
    }

    function portfolioSummary(address _address) public view returns(uint _tokenBalance, int _cost, uint _value) {
        _tokenBalance = balanceOf(_address);
        _cost = totalCost[_address];
        (_value,,) = calculateTokenSellPrice(_tokenBalance);       
    }

    function totalTokenHolders() public view returns(uint) {
        return tokenHolders.length;
    }

    function tokenHoldersByIndex() public view returns(address[] _addresses, uint[] _shares) {
        
         
        uint tokenHolderCount = tokenHolders.length;
        address[] memory addresses = new address[](tokenHolderCount);
        uint[] memory shares = new uint[](tokenHolderCount);

        for (uint i = 0; i < tokenHolderCount; i++) {
            addresses[i] = tokenHolders[i];
            shares[i] = balanceOf(tokenHolders[i]);
        }

        return (addresses, shares);
    }

     
    function setExchangeContractAddress(address _exchangeContract) external onlyOwner {
        exchangeContract_ = _exchangeContract;
    }

     
    function setBCFContractAddress(address _address) external onlyOwner {
        BCFMain candidateContract = BCFMain(_address);
        require(candidateContract.implementsERC721());
        bcfContract_ = candidateContract;
    }

    function setPlayerId(uint256 _playerId) external onlyOwner {
        playerId_ = _playerId;
    }

    function setSellDividendPercentageFee(uint8 _dividendPoolFee) external onlyOwnerOrExchange {
         
         
        require(_dividendPoolFee <= 50, "Max of 50% is assignable to the pool");
        dividendSellPoolFee_ = _dividendPoolFee;
    }

    function setBuyDividendPercentageFee(uint8 _dividendPoolFee) external onlyOwnerOrExchange {
        require(_dividendPoolFee <= 50, "Max of 50% is assignable to the pool");
        dividendBuyPoolFee_ = _dividendPoolFee;
    }

     
    function setOriginalOwner(uint256 _playerCardId, address _address) external {
        require(playerId_ > 0, "Player ID must be set on the contract");
        
         
         
         
         
        require(msg.sender == tx.origin, "Only valid users are able to set original ownership"); 
       
        address _cardOwner;
        uint256 _playerId;
        bool _isFirstGeneration;

        (_playerId,_cardOwner,,_isFirstGeneration) = bcfContract_.playerCards(_playerCardId);

        require(_isFirstGeneration, "Card must be an original");
        require(_playerId == playerId_, "Card must tbe the same player this contract relates to");
        require(_cardOwner == _address, "Card must be owned by the address provided");
        
         
        originalOwner_ = _address;
    }

     
    function _allocatePlayerTokensTo(address _to, uint256 _amount) internal {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(address(0), _to, _amount);
    }

    function _burnPlayerTokensFrom(address _from, uint256 _amount) internal {
        balances[_from] = balances[_from].sub(_amount);
        totalSupply_ = totalSupply_.sub(_amount);
        emit Transfer(_from, address(0), _amount);
    }

    function removeFromTokenHolders(address _seller) internal {
        
        uint256 tokenIndex = addressToTokenHolderIndex[_seller];
        uint256 lastAddressIndex = tokenHolders.length.sub(1);
        address lastAddress = tokenHolders[lastAddressIndex];
        
        tokenHolders[tokenIndex] = lastAddress;
        tokenHolders[lastAddressIndex] = address(0);
        tokenHolders.length--;

        addressToTokenHolderIndex[lastAddress] = tokenIndex;
    }

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(_to != address(0));
        require(_value > 0);
        require(_value <= balances[msg.sender]);

         
        if (balanceOf(_to) == 0) {
            tokenHolders.push(_to);
            addressToTokenHolderIndex[_to] = tokenHolders.length - 1;
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

         
         
        if (balanceOf(msg.sender) == 0) {
            removeFromTokenHolders(msg.sender);
        }

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(_to != address(0));
        require(_value > 0);
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

         
        if (balanceOf(_to) == 0) {
            tokenHolders.push(_to);
            addressToTokenHolderIndex[_to] = tokenHolders.length - 1;
        }

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

         
         
        if (balanceOf(_from) == 0) {
            removeFromTokenHolders(_from);
        }

        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256){
        return allowed[_owner][_spender];
    }

     
    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

    function pause() onlyOwnerOrExchange whenNotPaused public {
        paused = true;
    }

    function unpause() onlyOwnerOrExchange whenPaused public {
        paused = false;
    }
}

contract BCFMain {
    function playerCards(uint256 playerCardId) public view returns (uint256 playerId, address owner, address approvedForTransfer, bool isFirstGeneration);
    function implementsERC721() public pure returns (bool);
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

contract PlayerExchangeCore {

     
    event InitialPlayerOffering(address indexed contractAddress, string name, string symbol);
    event DividendWithdrawal(address indexed user, uint amount);

     
    using SafeMath for uint256;

     
    address public owner;
    address public referee;  

     
    struct DividendWinner {
        uint playerTokenContractId;
        uint perTokenEthValue;
        uint totalTokens;
        uint tokensProcessed;  
    }

     
    uint internal balancePendingWithdrawal_;  

     
    PlayerToken[] public playerTokenContracts_;  
    DividendWinner[] public dividendWinners_;  
    mapping(address => uint256) public addressToDividendBalance;

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyReferee() {
        require(msg.sender == referee);
        _;
    }

    modifier onlyOwnerOrReferee() {
        require(msg.sender == owner || msg.sender == referee);
        _;
    }

    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

    function setReferee(address newReferee) public onlyOwner {
        require(newReferee != address(0));
        referee = newReferee;
    }

    constructor(address _owner, address _referee) public {
        owner = _owner;
        referee = _referee;
    }

     
    function newInitialPlayerOffering(
        string _name, 
        string _symbol, 
        uint _startPrice, 
        uint _incrementalPrice, 
        address _owner,
        uint256 _playerId,
        uint8 _promoSharesQuantity
    ) 
        external 
        onlyOwnerOrReferee
        payable
    {
        PlayerToken playerTokenContract = (new PlayerToken).value(msg.value)(
            _name, 
            _symbol, 
            _startPrice, 
            _incrementalPrice, 
            _owner, 
            address(this), 
            _playerId, 
            _promoSharesQuantity
        );

         
        playerTokenContracts_.push(playerTokenContract);

         
        emit InitialPlayerOffering(address(playerTokenContract), _name, _symbol);
    }

     
     
     
    function() payable public { }

    function getTotalDividendPool() public view returns (uint) {
        return address(this).balance.sub(balancePendingWithdrawal_);
    }

    function totalPlayerTokenContracts() public view returns (uint) {
        return playerTokenContracts_.length;
    }

    function totalDividendWinners() public view returns (uint) {
        return dividendWinners_.length;
    }

     
    function allPlayerTokenContracts() external view returns (address[]) {
        uint playerContractCount = totalPlayerTokenContracts();
        address[] memory addresses = new address[](playerContractCount);

        for (uint i = 0; i < playerContractCount; i++) {
            addresses[i] = address(playerTokenContracts_[i]);
        }

        return addresses;
    }

     
    function pausePlayerContracts(uint startIndex, uint endIndex) onlyOwnerOrReferee external {
        for (uint i = startIndex; i < endIndex; i++) {
            PlayerToken playerTokenContract = playerTokenContracts_[i];
            if (!playerTokenContract.paused()) {
                playerTokenContract.pause();
            }
        }
    }

    function unpausePlayerContracts(uint startIndex, uint endIndex) onlyOwnerOrReferee external {
        for (uint i = startIndex; i < endIndex; i++) {
            PlayerToken playerTokenContract = playerTokenContracts_[i];
            if (playerTokenContract.paused()) {
                playerTokenContract.unpause();
            }
        }
    }

    function setSellDividendPercentageFee(uint8 _fee, uint startIndex, uint endIndex) onlyOwner external {
        for (uint i = startIndex; i < endIndex; i++) {
            PlayerToken playerTokenContract = playerTokenContracts_[i];
            playerTokenContract.setSellDividendPercentageFee(_fee);
        }
    }

    function setBuyDividendPercentageFee(uint8 _fee, uint startIndex, uint endIndex) onlyOwner external {
        for (uint i = startIndex; i < endIndex; i++) {
            PlayerToken playerTokenContract = playerTokenContracts_[i];
            playerTokenContract.setBuyDividendPercentageFee(_fee);
        }
    }

     
     
    function portfolioSummary(address _address) 
        external 
        view 
    returns (
        uint[] _playerTokenContractId, 
        uint[] _totalTokens, 
        int[] _totalCost, 
        uint[] _totalValue) 
    {
        uint playerContractCount = totalPlayerTokenContracts();

        uint[] memory playerTokenContractIds = new uint[](playerContractCount);
        uint[] memory totalTokens = new uint[](playerContractCount);
        int[] memory totalCost = new int[](playerContractCount);
        uint[] memory totalValue = new uint[](playerContractCount);

        PlayerToken playerTokenContract;

        for (uint i = 0; i < playerContractCount; i++) {
            playerTokenContract = playerTokenContracts_[i];
            playerTokenContractIds[i] = i;
            (totalTokens[i], totalCost[i], totalValue[i]) = playerTokenContract.portfolioSummary(_address);
        }

        return (playerTokenContractIds, totalTokens, totalCost, totalValue);
    }

     
     
     
    function setDividendWinners(
        uint[] _playerContractIds, 
        uint[] _totalPlayerTokens, 
        uint8[] _individualPlayerAllocationPcs, 
        uint _totalPrizePoolAllocationPc
    ) 
        external 
        onlyOwnerOrReferee 
    {
        require(_playerContractIds.length > 0, "Must have valid player contracts to award divs to");
        require(_playerContractIds.length == _totalPlayerTokens.length);
        require(_totalPlayerTokens.length == _individualPlayerAllocationPcs.length);
        require(_totalPrizePoolAllocationPc > 0);
        require(_totalPrizePoolAllocationPc <= 100);
        
         
        uint dailyDivPrizePool = SafeMath.div(SafeMath.mul(getTotalDividendPool(), _totalPrizePoolAllocationPc), 100);

         
        uint8 totalPlayerAllocationPc = 0;
        for (uint8 i = 0; i < _playerContractIds.length; i++) {
            totalPlayerAllocationPc += _individualPlayerAllocationPcs[i];

             
             
             
             
             
             
             
            uint playerPrizePool = SafeMath.div(SafeMath.mul(dailyDivPrizePool, _individualPlayerAllocationPcs[i]), 100);

             
            uint totalPlayerTokens = _totalPlayerTokens[i];
            uint perTokenEthValue = playerPrizePool.div(totalPlayerTokens);

             
            DividendWinner memory divWinner = DividendWinner({
                playerTokenContractId: _playerContractIds[i],
                perTokenEthValue: perTokenEthValue,
                totalTokens: totalPlayerTokens,
                tokensProcessed: 0
            });

            dividendWinners_.push(divWinner);
        }

         
         
        require(totalPlayerAllocationPc == 100);
    }

    function allocateDividendsToWinners(uint _dividendWinnerId, address[] _winners, uint[] _tokenAllocation) external onlyOwnerOrReferee {
        DividendWinner storage divWinner = dividendWinners_[_dividendWinnerId];
        require(divWinner.totalTokens > 0);  
        require(divWinner.tokensProcessed < divWinner.totalTokens);
        require(_winners.length == _tokenAllocation.length);

        uint totalEthAssigned;
        uint totalTokensAllocatedEth;
        uint ethAllocation;
        address winner;

        for (uint i = 0; i < _winners.length; i++) {
            winner = _winners[i];
            ethAllocation = _tokenAllocation[i].mul(divWinner.perTokenEthValue);
            addressToDividendBalance[winner] = addressToDividendBalance[winner].add(ethAllocation);
            totalTokensAllocatedEth = totalTokensAllocatedEth.add(_tokenAllocation[i]);
            totalEthAssigned = totalEthAssigned.add(ethAllocation);
        }

         
        balancePendingWithdrawal_ = balancePendingWithdrawal_.add(totalEthAssigned);

         
        divWinner.tokensProcessed = divWinner.tokensProcessed.add(totalTokensAllocatedEth);

         
        require(divWinner.tokensProcessed <= divWinner.totalTokens);
    }

    function withdrawDividends() external {
        require(addressToDividendBalance[msg.sender] > 0, "Must have a valid dividend balance");
        uint senderBalance = addressToDividendBalance[msg.sender];
        addressToDividendBalance[msg.sender] = 0;
        balancePendingWithdrawal_ = balancePendingWithdrawal_.sub(senderBalance);
        msg.sender.transfer(senderBalance);
        emit DividendWithdrawal(msg.sender, senderBalance);
    }
}