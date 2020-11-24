 

 

pragma solidity ^0.5.2;

 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

 

pragma solidity ^0.5.2;

 
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

 

 

pragma solidity 0.5.7;


 
interface ICore {
     
    function transferProxy()
        external
        view
        returns (address);

     
    function vault()
        external
        view
        returns (address);

     
    function exchangeIds(
        uint8 _exchangeId
    )
        external
        view
        returns (address);

     
    function validSets(address)
        external
        view
        returns (bool);

     
    function validModules(address)
        external
        view
        returns (bool);

     
    function validPriceLibraries(
        address _priceLibrary
    )
        external
        view
        returns (bool);

     
    function issue(
        address _set,
        uint256 _quantity
    )
        external;

     
    function issueTo(
        address _recipient,
        address _set,
        uint256 _quantity
    )
        external;

     
    function issueInVault(
        address _set,
        uint256 _quantity
    )
        external;

     
    function redeem(
        address _set,
        uint256 _quantity
    )
        external;

     
    function redeemTo(
        address _recipient,
        address _set,
        uint256 _quantity
    )
        external;

     
    function redeemInVault(
        address _set,
        uint256 _quantity
    )
        external;

     
    function redeemAndWithdrawTo(
        address _set,
        address _to,
        uint256 _quantity,
        uint256 _toExclude
    )
        external;

     
    function batchDeposit(
        address[] calldata _tokens,
        uint256[] calldata _quantities
    )
        external;

     
    function batchWithdraw(
        address[] calldata _tokens,
        uint256[] calldata _quantities
    )
        external;

     
    function deposit(
        address _token,
        uint256 _quantity
    )
        external;

     
    function withdraw(
        address _token,
        uint256 _quantity
    )
        external;

     
    function internalTransfer(
        address _token,
        address _to,
        uint256 _quantity
    )
        external;

     
    function createSet(
        address _factory,
        address[] calldata _components,
        uint256[] calldata _units,
        uint256 _naturalUnit,
        bytes32 _name,
        bytes32 _symbol,
        bytes calldata _callData
    )
        external
        returns (address);

     
    function depositModule(
        address _from,
        address _to,
        address _token,
        uint256 _quantity
    )
        external;

     
    function withdrawModule(
        address _from,
        address _to,
        address _token,
        uint256 _quantity
    )
        external;

     
    function batchDepositModule(
        address _from,
        address _to,
        address[] calldata _tokens,
        uint256[] calldata _quantities
    )
        external;

     
    function batchWithdrawModule(
        address _from,
        address _to,
        address[] calldata _tokens,
        uint256[] calldata _quantities
    )
        external;

     
    function issueModule(
        address _owner,
        address _recipient,
        address _set,
        uint256 _quantity
    )
        external;

     
    function redeemModule(
        address _burnAddress,
        address _incrementAddress,
        address _set,
        uint256 _quantity
    )
        external;

     
    function batchIncrementTokenOwnerModule(
        address[] calldata _tokens,
        address _owner,
        uint256[] calldata _quantities
    )
        external;

     
    function batchDecrementTokenOwnerModule(
        address[] calldata _tokens,
        address _owner,
        uint256[] calldata _quantities
    )
        external;

     
    function batchTransferBalanceModule(
        address[] calldata _tokens,
        address _from,
        address _to,
        uint256[] calldata _quantities
    )
        external;

     
    function transferModule(
        address _token,
        uint256 _quantity,
        address _from,
        address _to
    )
        external;

     
    function batchTransferModule(
        address[] calldata _tokens,
        uint256[] calldata _quantities,
        address _from,
        address _to
    )
        external;
}

 

 

pragma solidity 0.5.7;


 
library RebalancingLibrary {

     

    enum State { Default, Proposal, Rebalance, Drawdown }

     

    struct AuctionPriceParameters {
        uint256 auctionStartTime;
        uint256 auctionTimeToPivot;
        uint256 auctionStartPrice;
        uint256 auctionPivotPrice;
    }

    struct BiddingParameters {
        uint256 minimumBid;
        uint256 remainingCurrentSets;
        uint256[] combinedCurrentUnits;
        uint256[] combinedNextSetUnits;
        address[] combinedTokenArray;
    }
}

 

 

pragma solidity 0.5.7;


 

interface IRebalancingSetToken {

     
    function totalSupply()
        external
        view
        returns (uint256);

     
    function lastRebalanceTimestamp()
        external
        view
        returns (uint256);

     
    function rebalanceInterval()
        external
        view
        returns (uint256);

     
    function rebalanceState()
        external
        view
        returns (RebalancingLibrary.State);

     
    function balanceOf(
        address owner
    )
        external
        view
        returns (uint256);

     
    function propose(
        address _nextSet,
        address _auctionLibrary,
        uint256 _auctionTimeToPivot,
        uint256 _auctionStartPrice,
        uint256 _auctionPivotPrice
    )
        external;

     
    function naturalUnit()
        external
        view
        returns (uint256);

     
    function currentSet()
        external
        view
        returns (address);

     
    function unitShares()
        external
        view
        returns (uint256);

     
    function burn(
        address _from,
        uint256 _quantity
    )
        external;

     
    function placeBid(
        uint256 _quantity
    )
        external
        returns (address[] memory, uint256[] memory, uint256[] memory);

     
    function getCombinedTokenArrayLength()
        external
        view
        returns (uint256);

     
    function getCombinedTokenArray()
        external
        view
        returns (address[] memory);

     
    function getFailedAuctionWithdrawComponents()
        external
        view
        returns (address[] memory);

     
    function getBiddingParameters()
        external
        view
        returns (uint256[] memory);

}

 

 

pragma solidity 0.5.7;

 
interface ISetToken {

     

     
    function naturalUnit()
        external
        view
        returns (uint256);

     
    function getComponents()
        external
        view
        returns (address[] memory);

     
    function getUnits()
        external
        view
        returns (uint256[] memory);

     
    function tokenIsComponent(
        address _tokenAddress
    )
        external
        view
        returns (bool);

     
    function mint(
        address _issuer,
        uint256 _quantity
    )
        external;

     
    function burn(
        address _from,
        uint256 _quantity
    )
        external;

     
    function transfer(
        address to,
        uint256 value
    )
        external;
}

 

 

pragma solidity 0.5.7;

 
interface IVault {

     
    function withdrawTo(
        address _token,
        address _to,
        uint256 _quantity
    )
        external;

     
    function incrementTokenOwner(
        address _token,
        address _owner,
        uint256 _quantity
    )
        external;

     
    function decrementTokenOwner(
        address _token,
        address _owner,
        uint256 _quantity
    )
        external;

     

    function transferBalance(
        address _token,
        address _from,
        address _to,
        uint256 _quantity
    )
        external;


     
    function batchWithdrawTo(
        address[] calldata _tokens,
        address _to,
        uint256[] calldata _quantities
    )
        external;

     
    function batchIncrementTokenOwner(
        address[] calldata _tokens,
        address _owner,
        uint256[] calldata _quantities
    )
        external;

     
    function batchDecrementTokenOwner(
        address[] calldata _tokens,
        address _owner,
        uint256[] calldata _quantities
    )
        external;

    
    function batchTransferBalance(
        address[] calldata _tokens,
        address _from,
        address _to,
        uint256[] calldata _quantities
    )
        external;

     
    function getOwnerBalance(
        address _token,
        address _owner
    )
        external
        view
        returns (uint256);
}

 

 

pragma solidity 0.5.7;

 
interface ITransferProxy {

     

     
    function transfer(
        address _token,
        uint256 _quantity,
        address _from,
        address _to
    )
        external;

     
    function batchTransfer(
        address[] calldata _tokens,
        uint256[] calldata _quantities,
        address _from,
        address _to
    )
        external;
}

 

 

pragma solidity 0.5.7;





 
contract ModuleCoreState {

     

     
    address public core;

     
    address public vault;

     
    ICore public coreInstance;

     
    IVault public vaultInstance;

     

     
    constructor(
        address _core,
        address _vault
    )
        public
    {
         
        core = _core;

         
        coreInstance = ICore(_core);

         
        vault = _vault;

         
        vaultInstance = IVault(_vault);
    }
}

 

 

pragma solidity 0.5.7;









 
contract RebalanceAuctionModule is
    ModuleCoreState,
    ReentrancyGuard
{
    using SafeMath for uint256;

     

    event BidPlaced(
        address indexed rebalancingSetToken,
        address indexed bidder,
        uint256 executionQuantity,
        address[] combinedTokenAddresses,
        uint256[] inflowTokenUnits,
        uint256[] outflowTokenUnits
    );

     

     
    constructor(
        address _core,
        address _vault
    )
        public
        ModuleCoreState(
            _core,
            _vault
        )
    {}

     

     
    function bid(
        address _rebalancingSetToken,
        uint256 _quantity,
        bool _allowPartialFill
    )
        external
        nonReentrant
    {
         
        uint256 executionQuantity = calculateExecutionQuantity(
            _rebalancingSetToken,
            _quantity,
            _allowPartialFill
        );

         
        address[] memory tokenArray;
        uint256[] memory inflowUnitArray;
        uint256[] memory outflowUnitArray;
        (
            tokenArray,
            inflowUnitArray,
            outflowUnitArray
        ) = IRebalancingSetToken(_rebalancingSetToken).placeBid(executionQuantity);

         
        coreInstance.batchDepositModule(
            msg.sender,
            _rebalancingSetToken,
            tokenArray,
            inflowUnitArray
        );

         
        coreInstance.batchTransferBalanceModule(
            tokenArray,
            _rebalancingSetToken,
            msg.sender,
            outflowUnitArray
        );

         
        emit BidPlaced(
            _rebalancingSetToken,
            msg.sender,
            executionQuantity,
            tokenArray,
            inflowUnitArray,
            outflowUnitArray
        );
    }

     
    function bidAndWithdraw(
        address _rebalancingSetToken,
        uint256 _quantity,
        bool _allowPartialFill
    )
        external
        nonReentrant
    {
         
        uint256 executionQuantity = calculateExecutionQuantity(
            _rebalancingSetToken,
            _quantity,
            _allowPartialFill
        );

         
        address[] memory tokenArray;
        uint256[] memory inflowUnitArray;
        uint256[] memory outflowUnitArray;
        (
            tokenArray,
            inflowUnitArray,
            outflowUnitArray
        ) = IRebalancingSetToken(_rebalancingSetToken).placeBid(executionQuantity);

         
        coreInstance.batchDepositModule(
            msg.sender,
            _rebalancingSetToken,
            tokenArray,
            inflowUnitArray
        );

         
        coreInstance.batchWithdrawModule(
            _rebalancingSetToken,
            msg.sender,
            tokenArray,
            outflowUnitArray
        );

         
        emit BidPlaced(
            _rebalancingSetToken,
            msg.sender,
            executionQuantity,
            tokenArray,
            inflowUnitArray,
            outflowUnitArray
        );
    }

     
    function redeemFromFailedRebalance(
        address _rebalancingSetToken
    )
        external
        nonReentrant
    {
         
        IRebalancingSetToken rebalancingSetToken = IRebalancingSetToken(_rebalancingSetToken);

         
        require(
            coreInstance.validSets(_rebalancingSetToken),
            "RebalanceAuctionModule.redeemFromFailedRebalance: Invalid or disabled SetToken address"
        );

         
        address[] memory withdrawComponents = rebalancingSetToken.getFailedAuctionWithdrawComponents();

         
        uint256 setTotalSupply = rebalancingSetToken.totalSupply();

         
        uint256 callerBalance = rebalancingSetToken.balanceOf(msg.sender);

         
        uint256 transferArrayLength = withdrawComponents.length;
        uint256[] memory componentTransferAmount = new uint256[](transferArrayLength);
        for (uint256 i = 0; i < transferArrayLength; i++) {
            uint256 tokenCollateralAmount = vaultInstance.getOwnerBalance(
                withdrawComponents[i],
                _rebalancingSetToken
            );
            componentTransferAmount[i] = tokenCollateralAmount.mul(callerBalance).div(setTotalSupply);
        }

         
        rebalancingSetToken.burn(
            msg.sender,
            callerBalance
        );

         
        coreInstance.batchTransferBalanceModule(
            withdrawComponents,
            _rebalancingSetToken,
            msg.sender,
            componentTransferAmount
        );
    }

     

     
    function calculateExecutionQuantity(
        address _rebalancingSetToken,
        uint256 _quantity,
        bool _allowPartialFill
    )
        internal
        view
        returns (uint256)
    {
         
        require(
            coreInstance.validSets(_rebalancingSetToken),
            "RebalanceAuctionModule.bid: Invalid or disabled SetToken address"
        );

         
        uint256[] memory biddingParameters = IRebalancingSetToken(_rebalancingSetToken).getBiddingParameters();
        uint256 minimumBid = biddingParameters[0];
        uint256 remainingCurrentSets = biddingParameters[1];

        if (_allowPartialFill && _quantity > remainingCurrentSets) {
             
             
            uint256 executionQuantity = remainingCurrentSets.div(minimumBid).mul(minimumBid);
            return executionQuantity;
        } else {
            return _quantity;
        }
    }
}