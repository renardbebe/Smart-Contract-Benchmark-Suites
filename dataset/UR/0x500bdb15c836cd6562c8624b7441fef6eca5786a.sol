 

pragma solidity 0.4.21;

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

contract UnicornManagementInterface {

    function ownerAddress() external view returns (address);
    function managerAddress() external view returns (address);
    function communityAddress() external view returns (address);
    function dividendManagerAddress() external view returns (address);
    function walletAddress() external view returns (address);
    function blackBoxAddress() external view returns (address);
    function unicornBreedingAddress() external view returns (address);
    function geneLabAddress() external view returns (address);
    function unicornTokenAddress() external view returns (address);
    function candyToken() external view returns (address);
    function candyPowerToken() external view returns (address);

    function createDividendPercent() external view returns (uint);
    function sellDividendPercent() external view returns (uint);
    function subFreezingPrice() external view returns (uint);
    function subFreezingTime() external view returns (uint64);
    function subTourFreezingPrice() external view returns (uint);
    function subTourFreezingTime() external view returns (uint64);
    function createUnicornPrice() external view returns (uint);
    function createUnicornPriceInCandy() external view returns (uint);
    function oraclizeFee() external view returns (uint);

    function paused() external view returns (bool);
    function locked() external view returns (bool);

    function isTournament(address _tournamentAddress) external view returns (bool);

    function getCreateUnicornFullPrice() external view returns (uint);
    function getHybridizationFullPrice(uint _price) external view returns (uint);
    function getSellUnicornFullPrice(uint _price) external view returns (uint);
    function getCreateUnicornFullPriceInCandy() external view returns (uint);


     
    function registerInit(address _contract) external;

}

contract UnicornAccessControl {

    UnicornManagementInterface public unicornManagement;


    function UnicornAccessControl(address _unicornManagementAddress) public {
        unicornManagement = UnicornManagementInterface(_unicornManagementAddress);
        unicornManagement.registerInit(this);
    }

    modifier onlyOwner() {
        require(msg.sender == unicornManagement.ownerAddress());
        _;
    }

    modifier onlyManager() {
        require(msg.sender == unicornManagement.managerAddress());
        _;
    }

    modifier onlyCommunity() {
        require(msg.sender == unicornManagement.communityAddress());
        _;
    }

    modifier onlyTournament() {
        require(unicornManagement.isTournament(msg.sender));
        _;
    }

    modifier whenNotPaused() {
        require(!unicornManagement.paused());
        _;
    }

    modifier whenPaused {
        require(unicornManagement.paused());
        _;
    }

 
 
 
 

    modifier onlyManagement() {
        require(msg.sender == address(unicornManagement));
        _;
    }

    modifier onlyBreeding() {
        require(msg.sender == unicornManagement.unicornBreedingAddress());
        _;
    }

    modifier onlyUnicornContract() {
        require(msg.sender == unicornManagement.unicornBreedingAddress() || unicornManagement.isTournament(msg.sender));
        _;
    }

    modifier onlyGeneLab() {
        require(msg.sender == unicornManagement.geneLabAddress());
        _;
    }

    modifier onlyBlackBox() {
        require(msg.sender == unicornManagement.blackBoxAddress());
        _;
    }

    modifier onlyUnicornToken() {
        require(msg.sender == unicornManagement.unicornTokenAddress());
        _;
    }

    function isGamePaused() external view returns (bool) {
        return unicornManagement.paused();
    }
}

contract DividendManagerInterface {
    function payDividend() external payable;
}

contract UnicornTokenInterface {

     
    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _unicornId) public view returns (address _owner);
    function transfer(address _to, uint256 _unicornId) public;
    function approve(address _to, uint256 _unicornId) public;
    function takeOwnership(uint256 _unicornId) public;
    function totalSupply() public constant returns (uint);
    function owns(address _claimant, uint256 _unicornId) public view returns (bool);
    function allowance(address _claimant, uint256 _unicornId) public view returns (bool);
    function transferFrom(address _from, address _to, uint256 _unicornId) public;
    function createUnicorn(address _owner) external returns (uint);
     
    function getGen(uint _unicornId) external view returns (bytes);
    function setGene(uint _unicornId, bytes _gene) external;
    function updateGene(uint _unicornId, bytes _gene) external;
    function getUnicornGenByte(uint _unicornId, uint _byteNo) external view returns (uint8);

    function setName(uint256 _unicornId, string _name ) external returns (bool);
    function plusFreezingTime(uint _unicornId) external;
    function plusTourFreezingTime(uint _unicornId) external;
    function minusFreezingTime(uint _unicornId, uint64 _time) external;
    function minusTourFreezingTime(uint _unicornId, uint64 _time) external;
    function isUnfreezed(uint _unicornId) external view returns (bool);
    function isTourUnfreezed(uint _unicornId) external view returns (bool);

    function marketTransfer(address _from, address _to, uint256 _unicornId) external;
}


interface UnicornBalancesInterface {
     
     
    function trustedTokens(address _token) external view returns (bool);
     
    function transfer(address _token, address _from, address _to, uint _value) external returns (bool);
    function transferWithFee(address _token, address _userFrom, uint _fullPrice, address _feeTaker, address _priceTaker, uint _price) external returns (bool);
}

contract ERC20 {
     
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
}

contract TrustedTokenInterface is ERC20 {
    function transferFromSystem(address _from, address _to, uint256 _value) public returns (bool);
    function burn(address _from, uint256 _value) public returns (bool);
    function mint(address _to, uint256 _amount) public returns (bool);
}


 
 
 
 

contract BlackBoxInterface {
    function createGen0(uint _unicornId) public payable;
    function geneCore(uint _childUnicornId, uint _parent1UnicornId, uint _parent2UnicornId) public payable;
}


interface BreedingDataBaseInterface {

    function gen0Limit() external view returns (uint);
    function gen0Count() external view returns (uint);
    function gen0Step() external view returns (uint);

    function gen0PresaleLimit() external view returns (uint);
    function gen0PresaleCount() external view returns (uint);

    function incGen0Count() external;
    function incGen0PresaleCount() external;
    function incGen0Limit() external;

    function createHybridization(uint _unicornId, uint _price) external;
    function hybridizationExists(uint _unicornId) external view returns (bool);
    function hybridizationPrice(uint _unicornId) external view returns (uint);
    function deleteHybridization(uint _unicornId) external returns (bool);

    function freezeIndex(uint _unicornId) external view returns (uint);
    function freezeHybridizationsCount(uint _unicornId) external view returns (uint);
    function freezeStatsSumHours(uint _unicornId) external view returns (uint);
    function freezeEndTime(uint _unicornId) external view returns (uint);
    function freezeMustCalculate(uint _unicornId) external view returns (bool);
    function freezeExists(uint _unicornId) external view returns (bool);

    function createFreeze(uint _unicornId, uint _index) external;
    function incFreezeHybridizationsCount(uint _unicornId) external;
    function setFreezeHybridizationsCount(uint _unicornId, uint _count) external;

    function incFreezeIndex(uint _unicornId) external;
    function setFreezeEndTime(uint _unicornId, uint _time) external;
    function minusFreezeEndTime(uint _unicornId, uint _time) external;
    function setFreezeMustCalculate(uint _unicornId, bool _mustCalculate) external;
    function setStatsSumHours(uint _unicornId, uint _statsSumHours) external;


    function offerExists(uint _unicornId) external view returns (bool);
    function offerPriceEth(uint _unicornId) external view returns (uint);
    function offerPriceCandy(uint _unicornId) external view returns (uint);

    function createOffer(uint _unicornId, uint _priceEth, uint _priceCandy) external;
    function deleteOffer(uint _unicornId) external;

}

contract UnicornBreeding is UnicornAccessControl {
    using SafeMath for uint;

    BlackBoxInterface public blackBox;
    TrustedTokenInterface public megaCandyToken;
    BreedingDataBaseInterface public breedingDB;
    UnicornTokenInterface public unicornToken;  
    UnicornBalancesInterface public balances;

    address public candyTokenAddress;

    event HybridizationAdd(uint indexed unicornId, uint price);
    event HybridizationAccept(uint indexed firstUnicornId, uint indexed secondUnicornId, uint newUnicornId, uint price);
    event SelfHybridization(uint indexed firstUnicornId, uint indexed secondUnicornId, uint newUnicornId, uint price);
    event HybridizationDelete(uint indexed unicornId);
    event CreateUnicorn(address indexed owner, uint indexed unicornId, uint parent1, uint  parent2);
    event NewGen0Limit(uint limit);
    event NewGen0Step(uint step);

    event FreeHybridization(uint256 indexed unicornId);
    event NewSelfHybridizationPrice(uint percentCandy);

    event UnicornFreezingTimeSet(uint indexed unicornId, uint time);
    event MinusFreezingTime(uint indexed unicornId, uint count);

    uint public selfHybridizationPrice = 0;

    uint32[8] internal freezing = [
    uint32(1 hours),     
    uint32(2 hours),     
    uint32(8 hours),     
    uint32(16 hours),    
    uint32(36 hours),    
    uint32(72 hours),    
    uint32(120 hours),   
    uint32(168 hours)    
    ];

     
    uint32[8] internal freezingPlusCount = [
    0, 3, 5, 9, 13, 25, 25, 0
    ];


    function makeHybridization(uint _unicornId, uint _price) whenNotPaused public {
        require(unicornToken.owns(msg.sender, _unicornId));
        require(isUnfreezed(_unicornId));
        require(!breedingDB.hybridizationExists(_unicornId));
        require(unicornToken.getUnicornGenByte(_unicornId, 10) > 0);

        checkFreeze(_unicornId);
        breedingDB.createHybridization(_unicornId, _price);
        emit HybridizationAdd(_unicornId, _price);
         
        if (_price == 0) {
            emit FreeHybridization(_unicornId);
        }
    }

    function acceptHybridization(uint _firstUnicornId, uint _secondUnicornId) whenNotPaused public payable {
        require(unicornToken.owns(msg.sender, _secondUnicornId));
        require(_secondUnicornId != _firstUnicornId);
        require(isUnfreezed(_firstUnicornId) && isUnfreezed(_secondUnicornId));
        require(breedingDB.hybridizationExists(_firstUnicornId));

        require(unicornToken.getUnicornGenByte(_firstUnicornId, 10) > 0 && unicornToken.getUnicornGenByte(_secondUnicornId, 10) > 0);
        require(msg.value == unicornManagement.oraclizeFee());

        uint price = breedingDB.hybridizationPrice(_firstUnicornId);

        if (price > 0) {
            uint fullPrice = unicornManagement.getHybridizationFullPrice(price);

            require(balances.transferWithFee(candyTokenAddress, msg.sender, fullPrice, balances, unicornToken.ownerOf(_firstUnicornId), price));

        }

        plusFreezingTime(_firstUnicornId);
        plusFreezingTime(_secondUnicornId);
        uint256 newUnicornId = unicornToken.createUnicorn(msg.sender);
        blackBox.geneCore.value(unicornManagement.oraclizeFee())(newUnicornId, _firstUnicornId, _secondUnicornId);

        emit HybridizationAccept(_firstUnicornId, _secondUnicornId, newUnicornId, price);
        emit CreateUnicorn(msg.sender, newUnicornId, _firstUnicornId, _secondUnicornId);
        _deleteHybridization(_firstUnicornId);
    }

    function selfHybridization(uint _firstUnicornId, uint _secondUnicornId) whenNotPaused public payable {
        require(unicornToken.owns(msg.sender, _firstUnicornId) && unicornToken.owns(msg.sender, _secondUnicornId));
        require(_secondUnicornId != _firstUnicornId);
        require(isUnfreezed(_firstUnicornId) && isUnfreezed(_secondUnicornId));
        require(unicornToken.getUnicornGenByte(_firstUnicornId, 10) > 0 && unicornToken.getUnicornGenByte(_secondUnicornId, 10) > 0);

        require(msg.value == unicornManagement.oraclizeFee());

        if (selfHybridizationPrice > 0) {
             
            require(balances.transfer(candyTokenAddress, msg.sender, balances, selfHybridizationPrice));
        }

        plusFreezingTime(_firstUnicornId);
        plusFreezingTime(_secondUnicornId);
        uint256 newUnicornId = unicornToken.createUnicorn(msg.sender);
        blackBox.geneCore.value(unicornManagement.oraclizeFee())(newUnicornId, _firstUnicornId, _secondUnicornId);
        emit SelfHybridization(_firstUnicornId, _secondUnicornId, newUnicornId, selfHybridizationPrice);
        emit CreateUnicorn(msg.sender, newUnicornId, _firstUnicornId, _secondUnicornId);
    }

    function cancelHybridization (uint _unicornId) whenNotPaused public {
        require(unicornToken.owns(msg.sender,_unicornId));
         
        _deleteHybridization(_unicornId);
    }

    function deleteHybridization(uint _unicornId) onlyUnicornToken external {
        _deleteHybridization(_unicornId);
    }

    function _deleteHybridization(uint _unicornId) internal {
        if (breedingDB.deleteHybridization(_unicornId)) {
            emit HybridizationDelete(_unicornId);
        }
    }

     
    function createUnicorn() public payable whenNotPaused returns(uint256)   {
        require(msg.value == getCreateUnicornPrice());
        return _createUnicorn(msg.sender);
    }

    function createUnicornForCandy() public payable whenNotPaused returns(uint256)   {
        require(msg.value == unicornManagement.oraclizeFee());
        uint price = getCreateUnicornPriceInCandy();
         
        require(balances.transfer(candyTokenAddress, msg.sender, balances, price));
        return _createUnicorn(msg.sender);
    }

    function createPresaleUnicorns(uint _count, address _owner) public payable onlyManager whenPaused returns(bool) {
        require(breedingDB.gen0PresaleCount().add(_count) <= breedingDB.gen0PresaleLimit());
        uint256 newUnicornId;
        address owner = _owner == address(0) ? msg.sender : _owner;
        for (uint i = 0; i < _count; i++){
            newUnicornId = unicornToken.createUnicorn(owner);
            blackBox.createGen0(newUnicornId);
            emit CreateUnicorn(owner, newUnicornId, 0, 0);
            breedingDB.incGen0Count();
            breedingDB.incGen0PresaleCount();
        }
        return true;
    }

    function _createUnicorn(address _owner) private returns(uint256) {
        require(breedingDB.gen0Count() < breedingDB.gen0Limit());
        uint256 newUnicornId = unicornToken.createUnicorn(_owner);
        blackBox.createGen0.value(unicornManagement.oraclizeFee())(newUnicornId);
        emit CreateUnicorn(_owner, newUnicornId, 0, 0);
        breedingDB.incGen0Count();
        return newUnicornId;
    }

    function plusFreezingTime(uint _unicornId) private {
        checkFreeze(_unicornId);
         
        if (breedingDB.freezeHybridizationsCount(_unicornId) < 3) {
            breedingDB.incFreezeHybridizationsCount(_unicornId);
        } else {
            if (breedingDB.freezeIndex(_unicornId) < freezing.length - 1) {
                breedingDB.incFreezeIndex(_unicornId);
                breedingDB.setFreezeHybridizationsCount(_unicornId,0);
            }
        }

        uint _time = _getFreezeTime(breedingDB.freezeIndex(_unicornId)) + now;
        breedingDB.setFreezeEndTime(_unicornId, _time);
        emit UnicornFreezingTimeSet(_unicornId, _time);
    }

    function checkFreeze(uint _unicornId) internal {
        if (!breedingDB.freezeExists(_unicornId)) {
            breedingDB.createFreeze(_unicornId, unicornToken.getUnicornGenByte(_unicornId, 163));
        }
        if (breedingDB.freezeMustCalculate(_unicornId)) {
            breedingDB.setFreezeMustCalculate(_unicornId, false);
            breedingDB.setStatsSumHours(_unicornId, _getStatsSumHours(_unicornId));
        }
    }

    function _getRarity(uint8 _b) internal pure returns (uint8) {
         
         
         
         
         
        return _b < 1 ? 0 : _b < 189 ? 1 : _b < 224 ? 2 : _b < 244 ? 3 : _b < 254 ? 4 : 5;
    }

    function _getStatsSumHours(uint _unicornId) internal view returns (uint) {
        uint8[5] memory physStatBytes = [
         
        112,  
        117,  
        122,  
        127,  
        132  
        ];
        uint8[10] memory rarity1Bytes = [
         
        13,  
        18,  
        23,  
        28,  
        33,  
        38,  
        43,  
        48,  
        53,  
        58  
        ];
        uint8[10] memory rarity2Bytes = [
         
        87,  
        92,  
        97,  
        102,  
        107,  
        137,  
        142,  
        147,  
        152,  
        157  
        ];

        uint sum = 0;
        uint i;
        for(i = 0; i < 5; i++) {
            sum += unicornToken.getUnicornGenByte(_unicornId, physStatBytes[i]);
        }

        for(i = 0; i < 10; i++) {
             
            uint rarity = unicornToken.getUnicornGenByte(_unicornId, rarity2Bytes[i]);
            if (rarity == 0) {
                 
                rarity = _getRarity(unicornToken.getUnicornGenByte(_unicornId, rarity1Bytes[i]));
            }
            sum += rarity;
        }
        return sum * 1 hours;
    }

    function isUnfreezed(uint _unicornId) public view returns (bool) {
        return unicornToken.isUnfreezed(_unicornId) && breedingDB.freezeEndTime(_unicornId) <= now;
    }

    function enableFreezePriceRateRecalc(uint _unicornId) onlyGeneLab external {
        breedingDB.setFreezeMustCalculate(_unicornId, true);
    }

     
    function getUnfreezingPrice(uint _unicornId) public view returns (uint) {
        uint32 freezeHours = freezing[breedingDB.freezeIndex(_unicornId)];
        return unicornManagement.subFreezingPrice()
        .mul(breedingDB.freezeStatsSumHours(_unicornId).add(freezeHours))
        .div(freezeHours);
    }

    function _getFreezeTime(uint freezingIndex) internal view returns (uint time) {
        time = freezing[freezingIndex];
        if (freezingPlusCount[freezingIndex] != 0) {
            time += (uint(block.blockhash(block.number - 1)) % freezingPlusCount[freezingIndex]) * 1 hours;
        }
    }

     
    function minusFreezingTime(uint _unicornId, uint _count) public {
        uint price = getUnfreezingPrice(_unicornId);
        require(megaCandyToken.burn(msg.sender, price.mul(_count)));
         
        require(breedingDB.freezeEndTime(_unicornId) > now);
         
        breedingDB.minusFreezeEndTime(_unicornId, uint(unicornManagement.subFreezingTime()).mul(_count));
        emit MinusFreezingTime(_unicornId,_count);
    }

    function getHybridizationPrice(uint _unicornId) public view returns (uint) {
        return unicornManagement.getHybridizationFullPrice(breedingDB.hybridizationPrice(_unicornId));
    }

    function getEtherFeeForPriceInCandy() public view returns (uint) {
        return unicornManagement.oraclizeFee();
    }

    function getCreateUnicornPriceInCandy() public view returns (uint) {
        return unicornManagement.getCreateUnicornFullPriceInCandy();
    }

    function getCreateUnicornPrice() public view returns (uint) {
        return unicornManagement.getCreateUnicornFullPrice();
    }

    function setGen0Limit() external onlyCommunity {
        require(breedingDB.gen0Count() == breedingDB.gen0Limit());
        breedingDB.incGen0Limit();
        emit NewGen0Limit(breedingDB.gen0Limit());
    }

    function setSelfHybridizationPrice(uint _percentCandy) public onlyManager {
        selfHybridizationPrice = _percentCandy;
        emit NewSelfHybridizationPrice(_percentCandy);
    }

}


contract UnicornMarket is UnicornBreeding {
    uint public sellDividendPercentCandy = 375;  
    uint public sellDividendPercentEth = 375;  

    event NewSellDividendPercent(uint percentCandy, uint percentCandyEth);
    event OfferAdd(uint256 indexed unicornId, uint priceEth, uint priceCandy);
    event OfferDelete(uint256 indexed unicornId);
    event UnicornSold(uint256 indexed unicornId, uint priceEth, uint priceCandy);
    event FreeOffer(uint256 indexed unicornId);


    function sellUnicorn(uint _unicornId, uint _priceEth, uint _priceCandy) whenNotPaused public {
        require(unicornToken.owns(msg.sender, _unicornId));
        require(!breedingDB.offerExists(_unicornId));

        breedingDB.createOffer(_unicornId, _priceEth, _priceCandy);

        emit OfferAdd(_unicornId, _priceEth, _priceCandy);
         
        if (_priceEth == 0 && _priceCandy == 0) {
            emit FreeOffer(_unicornId);
        }
    }

    function buyUnicornWithEth(uint _unicornId) whenNotPaused public payable {
        require(breedingDB.offerExists(_unicornId));
        uint price = breedingDB.offerPriceEth(_unicornId);
         
        if (price == 0) {
            require(breedingDB.offerPriceCandy(_unicornId) == 0);
        }
        require(msg.value == getOfferPriceEth(_unicornId));

        address owner = unicornToken.ownerOf(_unicornId);

        emit UnicornSold(_unicornId, price, 0);
         
        unicornToken.marketTransfer(owner, msg.sender, _unicornId);
        owner.transfer(price);
    }

    function buyUnicornWithCandy(uint _unicornId) whenNotPaused public {
        require(breedingDB.offerExists(_unicornId));
        uint price = breedingDB.offerPriceCandy(_unicornId);
         
        if (price == 0) {
            require(breedingDB.offerPriceEth(_unicornId) == 0);
        }

        address owner = unicornToken.ownerOf(_unicornId);

        if (price > 0) {
            uint fullPrice = getOfferPriceCandy(_unicornId);
            require(balances.transferWithFee(candyTokenAddress, msg.sender, fullPrice, balances, owner, price));
        }

        emit UnicornSold(_unicornId, 0, price);
         
        unicornToken.marketTransfer(owner, msg.sender, _unicornId);
    }


    function revokeUnicorn(uint _unicornId) whenNotPaused public {
        require(unicornToken.owns(msg.sender, _unicornId));
         
        _deleteOffer(_unicornId);
    }


    function deleteOffer(uint _unicornId) onlyUnicornToken external {
        _deleteOffer(_unicornId);
    }


    function _deleteOffer(uint _unicornId) internal {
        if (breedingDB.offerExists(_unicornId)) {
            breedingDB.deleteOffer(_unicornId);
            emit OfferDelete(_unicornId);
        }
    }


    function getOfferPriceEth(uint _unicornId) public view returns (uint) {
        uint priceEth = breedingDB.offerPriceEth(_unicornId);
        return priceEth.add(valueFromPercent(priceEth, sellDividendPercentEth));
    }


    function getOfferPriceCandy(uint _unicornId) public view returns (uint) {
        uint priceCandy = breedingDB.offerPriceCandy(_unicornId);
        return priceCandy.add(valueFromPercent(priceCandy, sellDividendPercentCandy));
    }


    function setSellDividendPercent(uint _percentCandy, uint _percentEth) public onlyManager {
         
        require(_percentCandy < 2500 && _percentEth < 2500);

        sellDividendPercentCandy = _percentCandy;
        sellDividendPercentEth = _percentEth;
        emit NewSellDividendPercent(_percentCandy, _percentEth);
    }


     
    function valueFromPercent(uint _value, uint _percent) internal pure returns (uint amount)    {
        uint _amount = _value.mul(_percent).div(10000);
        return (_amount);
    }
}


contract UnicornCoinMarket is UnicornMarket {
    uint public feeTake = 5000000000000000;  
    mapping (address => mapping (bytes32 => uint)) public orderFills;  
    mapping (address => bool) public tokensWithoutFee;

     
    event Trade(bytes32 indexed hash, address tokenGet, uint amountGet, address tokenGive, uint amountGive, address get, address give);


     
    function changeFeeTake(uint feeTake_) external onlyOwner {
        feeTake = feeTake_;
    }


    function setTokenWithoutFee(address _token, bool _takeFee) external onlyOwner {
        tokensWithoutFee[_token] = _takeFee;
    }


     
     
     

     
    function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount) external {
        bytes32 hash = sha256(balances, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
        require(
            ecrecover(keccak256(keccak256("bytes32 Order hash"), keccak256(hash)), v, r, s) == user &&
            block.number <= expires &&
            orderFills[user][hash].add(amount) <= amountGet
        );
        uint amount2 =  tradeBalances(tokenGet, amountGet, tokenGive, amountGive, user, amount);
        orderFills[user][hash] = orderFills[user][hash].add(amount);
        emit Trade(hash, tokenGet, amount, tokenGive, amount2, user, msg.sender);
    }

     
    function tradeBalances(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address user, uint amount) private returns(uint amount2){

        uint _fee = 0;

        if (!tokensWithoutFee[tokenGet]) {
            _fee = amount.mul(feeTake).div(1 ether);
        }


        if (balances.trustedTokens(tokenGet)) {
            TrustedTokenInterface t = TrustedTokenInterface(tokenGet);
            require(t.transferFromSystem(msg.sender, user, amount));
            require(t.transferFromSystem(msg.sender, this, _fee));
        } else {
            require(
                balances.transferWithFee(tokenGet, msg.sender, amount, balances, user, amount.sub(_fee))
            );
             
             
             
        }

        amount2 = amountGive.mul(amount).div(amountGet);
        if (balances.trustedTokens(tokenGive)) {
            require(TrustedTokenInterface(tokenGive).transferFromSystem(user, msg.sender, amount2));
        } else {
            require(balances.transfer(tokenGive, user, msg.sender, amount2));
        }
    }
}


contract UnicornContract is UnicornCoinMarket {
    event FundsTransferred(address dividendManager, uint value);

    function() public payable {

    }

    function UnicornContract(address _breedingDB, address _balances, address _unicornManagementAddress) UnicornAccessControl(_unicornManagementAddress) public {
        candyTokenAddress = unicornManagement.candyToken();
        breedingDB = BreedingDataBaseInterface(_breedingDB);
        balances = UnicornBalancesInterface(_balances);
    }

    function init() onlyManagement whenPaused external {
        unicornToken = UnicornTokenInterface(unicornManagement.unicornTokenAddress());
        blackBox = BlackBoxInterface(unicornManagement.blackBoxAddress());
        megaCandyToken = TrustedTokenInterface(unicornManagement.candyPowerToken());
    }


    function transferTokensToDividendManager(address _token) onlyManager public {
        require(ERC20(_token).balanceOf(this) > 0);
        ERC20(_token).transfer(unicornManagement.walletAddress(), ERC20(_token).balanceOf(this));
    }


    function transferEthersToDividendManager(uint _value) onlyManager public {
        require(address(this).balance >= _value);
        DividendManagerInterface dividendManager = DividendManagerInterface(unicornManagement.dividendManagerAddress());
        dividendManager.payDividend.value(_value)();
        emit FundsTransferred(unicornManagement.dividendManagerAddress(), _value);
    }
}