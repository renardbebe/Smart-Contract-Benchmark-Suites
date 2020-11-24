 

 

 

pragma solidity 0.5.4;

contract Pool {

    address public owner;

     
    function balanceOf(address _who) external view returns (uint256);
    function totalSupply() external view returns (uint256 totaSupply);
    function getEventful() external view returns (address);
    function getData() external view returns (string memory name, string memory symbol, uint256 sellPrice, uint256 buyPrice);
    function calcSharePrice() external view returns (uint256);
    function getAdminData() external view returns (address, address feeCollector, address dragodAO, uint256 ratio, uint256 transactionFee, uint32 minPeriod);
}

contract ReentrancyGuard {

     
    bool private locked = false;

     
     
    modifier nonReentrant() {
         
        require(
            !locked,
            "REENTRANCY_ILLEGAL"
        );

         
        locked = true;

         
        _;

         
        locked = false;
    }
}

contract SafeMath {

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface ProofOfPerformanceFace {

     
     
     
    function claimPop(uint256 _ofPool) external;
    
     
     
    function setRegistry(address _dragoRegistry) external;
    
     
     
    function setRigoblockDao(address _rigoblockDao) external;
    
     
     
     
     
    function setRatio(address _ofGroup, uint256 _ratio) external;

     
     
     
     
     
     
     
     
     
     
     
     
    function getPoolData(uint256 _ofPool)
        external
        view
        returns (
            bool active,
            address thePoolAddress,
            address thePoolGroup,
            uint256 thePoolPrice,
            uint256 thePoolSupply,
            uint256 poolValue,
            uint256 epochReward,
            uint256 ratio,
            uint256 pop
        );

     
     
     
    function getHwm(uint256 _ofPool) external view returns (uint256);

     
     
     
    function getEpochReward(uint256 _ofPool)
        external
        view
        returns (uint256);

     
     
     
    function getRatio(uint256 _ofPool)
        external
        view
        returns (uint256);

     
     
     
     
     
     
     
     
    function proofOfPerformance(uint256 _ofPool)
        external
        view
        returns (uint256 popReward, uint256 performanceReward);

     
     
     
    function isActive(uint256 _ofPool)
        external
        view
        returns (bool);

     
     
     
     
    function addressFromId(uint256 _ofPool)
        external
        view
        returns (
            address pool,
            address group
        );

     
     
     
     
    function getPoolPrice(uint256 _ofPool)
        external
        view
        returns (
            uint256 thePoolPrice,
            uint256 totalTokens
        );

     
     
     
     
    function calcPoolValue(uint256 _ofPool)
        external
        view
        returns (
            uint256 aum
        );
}

interface DragoRegistry {

     

    event Registered(string name, string symbol, uint256 id, address indexed drago, address indexed owner, address indexed group);
    event Unregistered(string indexed name, string indexed symbol, uint256 indexed id);
    event MetaChanged(uint256 indexed id, bytes32 indexed key, bytes32 value);

     
    function register(address _drago, string calldata _name, string calldata _symbol, uint256 _dragoId, address _owner) external payable returns (bool);
    function unregister(uint256 _id) external;
    function setMeta(uint256 _id, bytes32 _key, bytes32 _value) external;
    function addGroup(address _group) external;
    function setFee(uint256 _fee) external;
    function updateOwner(uint256 _id) external;
    function updateOwners(uint256[] calldata _id) external;
    function upgrade(address _newAddress) external payable;  
    function setUpgraded(uint256 _version) external;
    function drain() external;

     
    function dragoCount() external view returns (uint256);
    function fromId(uint256 _id) external view returns (address drago, string memory name, string memory symbol, uint256 dragoId, address owner, address group);
    function fromAddress(address _drago) external view returns (uint256 id, string memory name, string memory symbol, uint256 dragoId, address owner, address group);
    function fromName(string calldata _name) external view returns (uint256 id, address drago, string memory symbol, uint256 dragoId, address owner, address group);
    function getNameFromAddress(address _pool) external view returns (string memory);
    function getSymbolFromAddress(address _pool) external view returns (string memory);
    function meta(uint256 _id, bytes32 _key) external view returns (bytes32);
    function getGroups() external view returns (address[] memory);
    function getFee() external view returns (uint256);
}

contract Inflation {
    
    uint256 public period;

     
    function mintInflation(address _thePool, uint256 _reward) external returns (bool);
    function setInflationFactor(address _group, uint256 _inflationFactor) external;
    function setMinimumRigo(uint256 _minimum) external;
    function setRigoblock(address _newRigoblock) external;
    function setAuthority(address _authority) external;
    function setProofOfPerformance(address _pop) external;
    function setPeriod(uint256 _newPeriod) external;

     
    function canWithdraw(address _thePool) external view returns (bool);
    function timeUntilClaim(address _thePool) external view returns (uint256);
    function getInflationFactor(address _group) external view returns (uint256);
}

contract RigoToken {
    address public minter;
    uint256 public totalSupply;

    function balanceOf(address _who) external view returns (uint256);
}

 
 
 
contract ProofOfPerformance is
    SafeMath,
    ReentrancyGuard,
    ProofOfPerformanceFace
{
    address public RIGOTOKENADDRESS;

    address public dragoRegistry;
    address public rigoblockDao;

    mapping (uint256 => PoolPrice) poolPrice;
    mapping (address => Group) groups;

    struct PoolPrice {
        uint256 highwatermark;
    }

    struct Group {
        uint256 rewardRatio;
    }

    modifier onlyRigoblockDao() {
        require(
            msg.sender == rigoblockDao,
            "ONLY_RIGOBLOCK_DAO"
        );
        _;
    }

    constructor(
        address _rigoTokenAddress,
        address _rigoblockDao,
        address _dragoRegistry)
        public
    {
        RIGOTOKENADDRESS = _rigoTokenAddress;
        rigoblockDao = _rigoblockDao;
        dragoRegistry = _dragoRegistry;
    }

     
     
     
    function claimPop(uint256 _ofPool)
        external
        nonReentrant
    {
        DragoRegistry registry = DragoRegistry(dragoRegistry);
        address poolAddress;
        (poolAddress, , , , , ) = registry.fromId(_ofPool);
        (uint256 pop, ) = proofOfPerformanceInternal(_ofPool);
        require(
            pop > 0,
            "POP_REWARD_IS_NULL"
        );
        uint256 price = Pool(poolAddress).calcSharePrice();
        poolPrice[_ofPool].highwatermark = price;
        require(
            Inflation(getMinter()).mintInflation(poolAddress, pop),
            "MINT_INFLATION_ERROR"
        );
    }

     
     
    function setRegistry(address _dragoRegistry)
        external
        onlyRigoblockDao
    {
        dragoRegistry = _dragoRegistry;
    }

     
     
    function setRigoblockDao(address _rigoblockDao)
        external
        onlyRigoblockDao
    {
        rigoblockDao = _rigoblockDao;
    }

     
     
     
     
    function setRatio(
        address _ofGroup,
        uint256 _ratio)
        external
        onlyRigoblockDao
    {
        require(
            _ratio <= 10000,
            "RATIO_BIGGER_THAN_10000"
        );  
        groups[_ofGroup].rewardRatio = _ratio;
    }

     
     
     
     
     
     
     
     
     
     
     
     
    function getPoolData(uint256 _ofPool)
        external
        view
        returns (
            bool active,
            address thePoolAddress,
            address thePoolGroup,
            uint256 thePoolPrice,
            uint256 thePoolSupply,
            uint256 poolValue,
            uint256 epochReward,
            uint256 ratio,
            uint256 pop
        )
    {
        active = isActiveInternal(_ofPool);
        (thePoolAddress, thePoolGroup) = addressFromIdInternal(_ofPool);
        (thePoolPrice, thePoolSupply, poolValue) = getPoolPriceAndValueInternal(_ofPool);
        (epochReward, , ratio) = getInflationParameters(_ofPool);
        (pop, ) = proofOfPerformanceInternal(_ofPool);
        return(
            active,
            thePoolAddress,
            thePoolGroup,
            thePoolPrice,
            thePoolSupply,
            poolValue,
            epochReward,
            ratio,
            pop
        );
    }

     
     
     
    function getHwm(uint256 _ofPool)
        external
        view
        returns (uint256)
    {
        return (getHwmInternal(_ofPool));
    }

     
     
     
    function getEpochReward(uint256 _ofPool)
        external
        view
        returns (uint256)
    {
        (uint256 epochReward, , ) = getInflationParameters(_ofPool);
        return epochReward;
    }

     
     
     
    function getRatio(uint256 _ofPool)
        external
        view
        returns (uint256)
    {
        ( , , uint256 ratio) = getInflationParameters(_ofPool);
        return ratio;
    }

     
     
     
     
     
     
     
     
    function proofOfPerformance(uint256 _ofPool)
        external
        view
        returns (uint256 popReward, uint256 performanceReward)
    {
        return proofOfPerformanceInternal(_ofPool);
    }

     
     
     
    function isActive(uint256 _ofPool)
        external
        view
        returns (bool)
    {
        return isActiveInternal(_ofPool);
    }

     
     
     
     
    function addressFromId(uint256 _ofPool)
        external
        view
        returns (
            address pool,
            address group
        )
    {
        return (addressFromIdInternal(_ofPool));
    }

     
     
     
     
    function getPoolPrice(uint256 _ofPool)
        external
        view
        returns (
            uint256 thePoolPrice,
            uint256 totalTokens
        )
    {
        (thePoolPrice, totalTokens, ) = getPoolPriceAndValueInternal(_ofPool);
    }

     
     
     
     
    function calcPoolValue(uint256 _ofPool)
        external
        view
        returns (
            uint256 aum
        )
    {
        ( , , aum) = getPoolPriceAndValueInternal(_ofPool);
    }

     
     
     
     
     
     
    function getInflationParameters(uint256 _ofPool)
        internal
        view
        returns (
            uint256 epochReward,
            uint256 epochTime,
            uint256 ratio
        )
    {
        ( , address group) = addressFromIdInternal(_ofPool);
        epochReward = Inflation(getMinter()).getInflationFactor(group);
        epochTime = Inflation(getMinter()).period();
        ratio = groups[group].rewardRatio;
    }

     
     
    function getMinter()
        internal
        view
        returns (address)
    {
        RigoToken token = RigoToken(RIGOTOKENADDRESS);
        return token.minter();
    }

     
     
     
     
     
     
    function proofOfPerformanceInternal(uint256 _ofPool)
        internal
        view
        returns (uint256 popReward, uint256 performanceReward)
    {
        uint256 highwatermark= getHwmInternal(_ofPool);
        (uint256 newPrice, uint256 tokenSupply, uint256 poolValue) = getPoolPriceAndValueInternal(_ofPool);
        require (
            newPrice >= highwatermark,
            "PRICE_LOWER_THAN_HWM_ERROR"
        );
        (address thePoolAddress, ) = addressFromIdInternal(_ofPool);
        (uint256 epochReward, uint256 epochTime, uint256 rewardRatio) = getInflationParameters(_ofPool);

        uint256 assetsComponent = safeMul(
            poolValue,
            epochReward
        ) * epochTime / 1 days;  

        uint256 performanceComponent = safeMul(
            safeMul(
                (newPrice - highwatermark),
                tokenSupply
            ) / 1000000,  
            epochReward
        ) * 365 days / 1 days;

        uint256 assetsReward = (
            safeMul(
                assetsComponent,
                safeSub(10000, rewardRatio)  
            ) / 10000 ether
        ) * ethBalanceAdjustmentInternal(thePoolAddress, poolValue) / 1 ether;  

        performanceReward = safeDiv(
            safeMul(performanceComponent, rewardRatio),
            10000 ether
        ) * ethBalanceAdjustmentInternal(thePoolAddress, poolValue) / 1 ether;

        popReward = grgBalanceRewardSlashInternal(thePoolAddress, safeAdd(performanceReward, assetsReward));

        if (popReward > 10 ** 25 / 10000) {
            popReward = 10 ** 25 / 10000;  
        }
    }

     
     
     
    function getHwmInternal(uint256 _ofPool) 
        internal
        view
        returns (uint256)
    {
        if (poolPrice[_ofPool].highwatermark == 0) {
            return (1 ether);

        } else {
            return poolPrice[_ofPool].highwatermark;
        }
    }

     
     
     
     
    function ethBalanceAdjustmentInternal(
        address thePoolAddress,
        uint256 poolValue)
        internal
        view
        returns (uint256)
    {
        uint256 poolEthBalance = address(Pool(thePoolAddress)).balance;
        require(
            poolEthBalance <= poolValue && poolEthBalance >= 1 finney,  
            "ETH_BALANCE_HIGHER_THAN_AUM_OR_TOO_SMALL_ERROR"
        );

         
         
        if (1 ether * poolEthBalance / poolValue >= 800 finney) {
            return (1 ether * poolEthBalance / poolValue);

        } else if (1 ether * poolEthBalance / poolValue >= 600 finney) {
            return (1 ether * poolEthBalance / poolValue * 820 / 1000);

        } else if (1 ether * poolEthBalance / poolValue >= 400 finney) {
            return (1 ether * poolEthBalance / poolValue * 201 / 1000);

        } else if (1 ether * poolEthBalance / poolValue >= 200 finney) {
            return (1 ether * poolEthBalance / poolValue * 29 / 1000);

        } else if (1 ether * poolEthBalance / poolValue >= 100 finney) {
            return (1 ether * poolEthBalance / poolValue * 5 / 1000);

        } else {  
            revert('ETH_BELOW_10_PERCENT_AUM_ERROR');
        }
    }

     
     
     
     
    function grgBalanceRewardSlashInternal(
        address thePoolAddress,
        uint256 pop)
        internal
        view
        returns (uint256)
    {
        uint256 operatorGrgBalance = RigoToken(RIGOTOKENADDRESS).balanceOf(Pool(thePoolAddress).owner());
        uint256 grgTotalSupply = RigoToken(RIGOTOKENADDRESS).totalSupply();

         
         
        if (10 ether * operatorGrgBalance / grgTotalSupply >= 5 finney) {
            return (pop);

        } else if (10 ether * operatorGrgBalance / grgTotalSupply >= 4 finney) {
            return (pop * 820 / 1000);

        } else if (10 ether * operatorGrgBalance / grgTotalSupply >= 3 finney) {
            return (pop * 201 / 1000);

        } else if (10 ether * operatorGrgBalance / grgTotalSupply >= 2 finney) {
            return (pop * 29 / 1000);

        } else if (10 ether * operatorGrgBalance / grgTotalSupply >= 1 finney) {
            return (pop * 5 / 1000);

        } else {
            return (pop * 2 / 1000);
        }
    }

     
     
     
    function isActiveInternal(uint256 _ofPool)
        internal view
        returns (bool)
    {
        DragoRegistry registry = DragoRegistry(dragoRegistry);
        (address thePool, , , , , ) = registry.fromId(_ofPool);
        if (thePool != address(0)) {
            return true;
        }
    }

     
     
     
     
    function addressFromIdInternal(uint256 _ofPool)
        internal
        view
        returns (
            address pool,
            address group
        )
    {
        DragoRegistry registry = DragoRegistry(dragoRegistry);
        (pool, , , , , group) = registry.fromId(_ofPool);
        return (pool, group);
    }

     
     
     
     
     
     
    function getPoolPriceAndValueInternal(uint256 _ofPool)
        internal
        view
        returns (
            uint256 thePoolPrice,
            uint256 totalTokens,
            uint256 aum
        )
    {
        (address poolAddress, ) = addressFromIdInternal(_ofPool);
        Pool pool = Pool(poolAddress);
        thePoolPrice = pool.calcSharePrice();
        totalTokens = pool.totalSupply();
        require(
            thePoolPrice != uint256(0) && totalTokens != uint256(0),
            "POOL_PRICE_OR_TOTAL_SUPPLY_NULL_ERROR"
        );
        aum = safeMul(thePoolPrice, totalTokens) / 1000000;  
    }
}