 

 

pragma solidity ^0.5.2;
pragma experimental "ABIEncoderV2";

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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

 

pragma solidity ^0.5.2;



 
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

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}

 

pragma solidity ^0.5.2;


 
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

     
    function name() public view returns (string memory) {
        return _name;
    }

     
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

 

 

pragma solidity 0.5.7;



library CommonMath {
    using SafeMath for uint256;

     
    function maxUInt256()
        internal
        pure
        returns (uint256)
    {
        return 2 ** 256 - 1;
    }

     
    function safePower(
        uint256 a,
        uint256 pow
    )
        internal
        pure
        returns (uint256)
    {
        require(a > 0);

        uint256 result = 1;
        for (uint256 i = 0; i < pow; i++){
            uint256 previousResult = result;

             
            result = previousResult.mul(a);
        }

        return result;
    }

     
    function getPartialAmount(
        uint256 _principal,
        uint256 _numerator,
        uint256 _denominator
    )
        internal
        pure
        returns (uint256)
    {
         
        uint256 remainder = mulmod(_principal, _numerator, _denominator);

         
        if (remainder == 0) {
            return _principal.mul(_numerator).div(_denominator);
        }

         
        uint256 errPercentageTimes1000000 = remainder.mul(1000000).div(_numerator.mul(_principal));

         
        require(
            errPercentageTimes1000000 < 1000,
            "CommonMath.getPartialAmount: Rounding error exceeds bounds"
        );

        return _principal.mul(_numerator).div(_denominator);
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


 
interface ISetFactory {

     

     
    function core()
        external
        returns (address);

     
    function createSet(
        address[] calldata _components,
        uint[] calldata _units,
        uint256 _naturalUnit,
        bytes32 _name,
        bytes32 _symbol,
        bytes calldata _callData
    )
        external
        returns (address);
}

 

 

pragma solidity 0.5.7;

 
interface IWhiteList {

     

     
    function whiteList(
        address _address
    )
        external
        view
        returns (bool);

     
    function areValidAddresses(
        address[] calldata _addresses
    )
        external
        view
        returns (bool);
}

 

 

pragma solidity 0.5.7;




 
contract IRebalancingSetFactory is
    ISetFactory
{
     
    function minimumRebalanceInterval()
        external
        returns (uint256);

     
    function minimumProposalPeriod()
        external
        returns (uint256);

     
    function minimumTimeToPivot()
        external
        returns (uint256);

     
    function maximumTimeToPivot()
        external
        returns (uint256);

     
    function minimumNaturalUnit()
        external
        returns (uint256);

     
    function maximumNaturalUnit()
        external
        returns (uint256);

     
    function rebalanceAuctionModule()
        external
        returns (address);
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

 

pragma solidity ^0.5.2;

 
library Math {
     
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

     
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

     
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
         
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

 

 

pragma solidity 0.5.7;









 
library FailAuctionLibrary {
    using SafeMath for uint256;

     
    function endFailedAuction(
        uint256 _startingCurrentSetAmount,
        uint256 _calculatedUnitShares,
        address _currentSet,
        address _coreAddress,
        RebalancingLibrary.AuctionPriceParameters memory _auctionPriceParameters,
        RebalancingLibrary.BiddingParameters memory _biddingParameters,
        uint8 _rebalanceState
    )
        public
        returns (uint8)
    {
         
        require(
            _rebalanceState ==  uint8(RebalancingLibrary.State.Rebalance),
            "RebalanceAuctionModule.endFailedAuction: Rebalancing Set Token must be in Rebalance State"
        );

         
        uint256 revertAuctionTime = _auctionPriceParameters.auctionStartTime.add(
            _auctionPriceParameters.auctionTimeToPivot
        );

         
        require(
            block.timestamp >= revertAuctionTime,
            "RebalanceAuctionModule.endFailedAuction: Can only be called after auction reaches pivot"
        );

        uint8 newRebalanceState;
         
        if (_biddingParameters.remainingCurrentSets >= _biddingParameters.minimumBid) {
             
            if (_startingCurrentSetAmount == _biddingParameters.remainingCurrentSets) {
                 
                ICore(_coreAddress).issueInVault(
                    _currentSet,
                    _startingCurrentSetAmount
                );

                 
                newRebalanceState = uint8(RebalancingLibrary.State.Default);
            } else {
                 
                newRebalanceState = uint8(RebalancingLibrary.State.Drawdown);
            }
        } else {
             
             
            require(
                _calculatedUnitShares == 0,
                "RebalancingSetToken.endFailedAuction: Cannot be called if rebalance is viably completed"
            );

             
            newRebalanceState = uint8(RebalancingLibrary.State.Drawdown);
        }

        return newRebalanceState;
    }
}

 

 

pragma solidity 0.5.7;



 
interface IAuctionPriceCurve {

     
    function priceDivisor()
        external
        view
        returns (uint256);

     
    function validateAuctionPriceParameters(
        RebalancingLibrary.AuctionPriceParameters calldata _auctionPriceParameters
    )
        external
        view;

     
    function getCurrentPrice(
        RebalancingLibrary.AuctionPriceParameters calldata _auctionPriceParameters
    )
        external
        view
        returns (uint256, uint256);
}

 

 

pragma solidity 0.5.7;







 
library PlaceBidLibrary {
    using SafeMath for uint256;

     

     
    function validatePlaceBid(
        uint256 _quantity,
        address _coreAddress,
        RebalancingLibrary.BiddingParameters memory _biddingParameters
    )
        public
        view
        returns (uint256)
    {
         
        require(
            ICore(_coreAddress).validModules(msg.sender),
            "RebalancingSetToken.placeBid: Sender must be approved module"
        );

         
        require(
            _quantity > 0,
            "RebalancingSetToken.placeBid: Bid must be > 0"
        );

         
        require(
            _quantity.mod(_biddingParameters.minimumBid) == 0,
            "RebalancingSetToken.placeBid: Must bid multiple of minimum bid"
        );

         
        require(
            _quantity <= _biddingParameters.remainingCurrentSets,
            "RebalancingSetToken.placeBid: Bid exceeds remaining current sets"
        );
    }

     
    function getBidPrice(
        uint256 _quantity,
        address _auctionLibrary,
        RebalancingLibrary.BiddingParameters memory _biddingParameters,
        RebalancingLibrary.AuctionPriceParameters memory _auctionPriceParameters,
        uint8 _rebalanceState
    )
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
         
        require(
            _rebalanceState == uint8(RebalancingLibrary.State.Rebalance),
            "RebalancingSetToken.getBidPrice: State must be Rebalance"
        );

         
        uint256 priceNumerator;
        uint256 priceDivisor;
        (priceNumerator, priceDivisor) = IAuctionPriceCurve(_auctionLibrary).getCurrentPrice(
            _auctionPriceParameters
        );

         
        uint256 unitsMultiplier = _quantity.div(_biddingParameters.minimumBid).mul(priceDivisor);

         
        return createTokenFlowArrays(
            unitsMultiplier,
            priceNumerator,
            priceDivisor,
            _biddingParameters
        );
    }

     
    function createTokenFlowArrays(
        uint256 _unitsMultiplier,
        uint256 _priceNumerator,
        uint256 _priceDivisor,
        RebalancingLibrary.BiddingParameters memory _biddingParameters
    )
        public
        pure
        returns (uint256[] memory, uint256[] memory)
    {
         
        uint256 combinedTokenCount = _biddingParameters.combinedTokenArray.length;
        uint256[] memory inflowUnitArray = new uint256[](combinedTokenCount);
        uint256[] memory outflowUnitArray = new uint256[](combinedTokenCount);

         
         
        for (uint256 i = 0; i < combinedTokenCount; i++) {
            (
                inflowUnitArray[i],
                outflowUnitArray[i]
            ) = calculateTokenFlows(
                _biddingParameters.combinedCurrentUnits[i],
                _biddingParameters.combinedNextSetUnits[i],
                _unitsMultiplier,
                _priceNumerator,
                _priceDivisor
            );
        }

        return (inflowUnitArray, outflowUnitArray);
    }

     
    function calculateTokenFlows(
        uint256 _currentUnit,
        uint256 _nextSetUnit,
        uint256 _unitsMultiplier,
        uint256 _priceNumerator,
        uint256 _priceDivisor
    )
        public
        pure
        returns (uint256, uint256)
    {
         
        uint256 inflowUnit;
        uint256 outflowUnit;

         
        if (_nextSetUnit.mul(_priceDivisor) > _currentUnit.mul(_priceNumerator)) {
             
            inflowUnit = _unitsMultiplier.mul(
                _nextSetUnit.mul(_priceDivisor).sub(_currentUnit.mul(_priceNumerator))
            ).div(_priceNumerator);

             
            outflowUnit = 0;
        } else {
             
            outflowUnit = _unitsMultiplier.mul(
                _currentUnit.mul(_priceNumerator).sub(_nextSetUnit.mul(_priceDivisor))
            ).div(_priceNumerator);

             
            inflowUnit = 0;
        }

        return (inflowUnit, outflowUnit);
    }
}

 

 

pragma solidity 0.5.7;










 
library ProposeLibrary {
    using SafeMath for uint256;

     

    struct ProposalContext {
        address manager;
        address currentSet;
        address coreAddress;
        address componentWhitelist;
        address factoryAddress;
        uint256 lastRebalanceTimestamp;
        uint256 rebalanceInterval;
        uint8 rebalanceState;
    }

     

     
    function validateProposal(
        address _nextSet,
        address _auctionLibrary,
        ProposalContext memory _proposalContext,
        RebalancingLibrary.AuctionPriceParameters memory _auctionPriceParameters
    )
        public
    {
        ICore coreInstance = ICore(_proposalContext.coreAddress);
        IRebalancingSetFactory factoryInstance = IRebalancingSetFactory(_proposalContext.factoryAddress);

         
        require(
            msg.sender == _proposalContext.manager,
            "ProposeLibrary.validateProposal: Sender must be manager"
        );

         
        require(
            _proposalContext.rebalanceState == uint8(RebalancingLibrary.State.Default) ||
            _proposalContext.rebalanceState == uint8(RebalancingLibrary.State.Proposal),
            "ProposeLibrary.validateProposal: State must be in Propose or Default"
        );

         
        require(
            block.timestamp >= _proposalContext.lastRebalanceTimestamp.add(
                _proposalContext.rebalanceInterval
            ),
            "ProposeLibrary.validateProposal: Rebalance interval not elapsed"
        );

         
        require(
            coreInstance.validSets(_nextSet),
            "ProposeLibrary.validateProposal: Invalid or disabled proposed SetToken address"
        );

         
         
        require(
            IWhiteList(
                _proposalContext.componentWhitelist
            ).areValidAddresses(ISetToken(_nextSet).getComponents()),
            "ProposeLibrary.validateProposal: Proposed set contains invalid component token"
        );

         
        require(
            coreInstance.validPriceLibraries(_auctionLibrary),
            "ProposeLibrary.validateProposal: Invalid or disabled PriceLibrary address"
        );

         
        require(
            _auctionPriceParameters.auctionTimeToPivot >= factoryInstance.minimumTimeToPivot(),
            "ProposeLibrary.validateProposal: Time to pivot must be greater than minimum"
        );

         
        require(
            _auctionPriceParameters.auctionTimeToPivot <= factoryInstance.maximumTimeToPivot(),
            "ProposeLibrary.validateProposal: Time to pivot must be greater than maximum"
        );

         
         
        uint256 currentNaturalUnit = ISetToken(_proposalContext.currentSet).naturalUnit();
        uint256 nextSetNaturalUnit = ISetToken(_nextSet).naturalUnit();
        require(
            Math.max(currentNaturalUnit, nextSetNaturalUnit).mod(
                Math.min(currentNaturalUnit, nextSetNaturalUnit)
            ) == 0,
            "ProposeLibrary.validateProposal: Invalid proposed Set natural unit"
        );

         
        IAuctionPriceCurve(_auctionLibrary).validateAuctionPriceParameters(
            _auctionPriceParameters
        );
    }
}

 

 

pragma solidity 0.5.7;




library SetTokenLibrary {
    using SafeMath for uint256;

    struct SetDetails {
        uint256 naturalUnit;
        address[] components;
        uint256[] units;
    }

     
    function validateTokensAreComponents(
        address _set,
        address[] calldata _tokens
    )
        external
        view
    {
        for (uint256 i = 0; i < _tokens.length; i++) {
             
            require(
                ISetToken(_set).tokenIsComponent(_tokens[i]),
                "SetTokenLibrary.validateTokensAreComponents: Component must be a member of Set"
            );

        }
    }

     
    function isMultipleOfSetNaturalUnit(
        address _set,
        uint256 _quantity
    )
        external
        view
    {
        require(
            _quantity.mod(ISetToken(_set).naturalUnit()) == 0,
            "SetTokenLibrary.isMultipleOfSetNaturalUnit: Quantity is not a multiple of nat unit"
        );
    }

     
    function getSetDetails(
        address _set
    )
        internal
        view
        returns (SetDetails memory)
    {
         
        ISetToken setToken = ISetToken(_set);

         
        uint256 naturalUnit = setToken.naturalUnit();
        address[] memory components = setToken.getComponents();
        uint256[] memory units = setToken.getUnits();

        return SetDetails({
            naturalUnit: naturalUnit,
            components: components,
            units: units
        });
    }
}

 

 

pragma solidity 0.5.7;










 
library SettleRebalanceLibrary {
    using SafeMath for uint256;
     

     
    function settleRebalance(
        uint256 _totalSupply,
        uint256 _remainingCurrentSets,
        uint256 _minimumBid,
        uint256 _naturalUnit,
        address _nextSet,
        address _coreAddress,
        address _vaultAddress,
        uint8 _rebalanceState
    )
        public
        returns (uint256)
    {
         
        require(
            _rebalanceState == uint8(RebalancingLibrary.State.Rebalance),
            "RebalancingSetToken.settleRebalance: State must be Rebalance"
        );

         
        require(
            _remainingCurrentSets < _minimumBid,
            "RebalancingSetToken.settleRebalance: Rebalance not completed"
        );

         
        uint256 issueAmount;
        uint256 nextUnitShares;
        (
            issueAmount,
            nextUnitShares
        ) = calculateNextSetIssueQuantity(
            _totalSupply,
            _naturalUnit,
            _nextSet,
            _vaultAddress
        );

        require(
            nextUnitShares > 0,
            "RebalancingSetToken.settleRebalance: Failed rebalance, unitshares equals 0. Call endFailedAuction."
        );

         
        ICore(_coreAddress).issueInVault(
            _nextSet,
            issueAmount
        );

        return nextUnitShares;
    }

     
    function calculateNextSetIssueQuantity(
        uint256 _totalSupply,
        uint256 _naturalUnit,
        address _nextSet,
        address _vaultAddress
    )
        public
        view
        returns (uint256, uint256)
    {
         
        SetTokenLibrary.SetDetails memory nextSetToken = SetTokenLibrary.getSetDetails(_nextSet);
        uint256 maxIssueAmount = calculateMaxIssueAmount(
            _vaultAddress,
            nextSetToken
        );

         
        uint256 naturalUnitsOutstanding = _totalSupply.div(_naturalUnit);

         
         
         
        uint256 issueAmount = maxIssueAmount.div(nextSetToken.naturalUnit).mul(nextSetToken.naturalUnit);

         
        uint256 newUnitShares = issueAmount.div(naturalUnitsOutstanding);
        return (issueAmount, newUnitShares);
    }

     
    function calculateMaxIssueAmount(
        address _vaultAddress,
        SetTokenLibrary.SetDetails memory _setToken
    )
        public
        view
        returns (uint256)
    {
        uint256 maxIssueAmount = CommonMath.maxUInt256();
        IVault vaultInstance = IVault(_vaultAddress);

        for (uint256 i = 0; i < _setToken.components.length; i++) {
             
            uint256 componentAmount = vaultInstance.getOwnerBalance(
                _setToken.components[i],
                address(this)
            );

             
             
            uint256 componentIssueAmount = componentAmount.div(_setToken.units[i]).mul(_setToken.naturalUnit);
            if (componentIssueAmount < maxIssueAmount) {
                maxIssueAmount = componentIssueAmount;
            }
        }

        return maxIssueAmount;
    }
}

 

 
 

pragma solidity 0.5.7;


library AddressArrayUtils {

     
    function indexOf(address[] memory A, address a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (A[i] == a) {
                return (i, true);
            }
        }
        return (0, false);
    }

     
    function contains(address[] memory A, address a) internal pure returns (bool) {
        bool isIn;
        (, isIn) = indexOf(A, a);
        return isIn;
    }

     
     
    function indexOfFromEnd(address[] memory A, address a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = length; i > 0; i--) {
            if (A[i - 1] == a) {
                return (i, true);
            }
        }
        return (0, false);
    }

     
    function extend(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 aLength = A.length;
        uint256 bLength = B.length;
        address[] memory newAddresses = new address[](aLength + bLength);
        for (uint256 i = 0; i < aLength; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = 0; j < bLength; j++) {
            newAddresses[aLength + j] = B[j];
        }
        return newAddresses;
    }

     
    function append(address[] memory A, address a) internal pure returns (address[] memory) {
        address[] memory newAddresses = new address[](A.length + 1);
        for (uint256 i = 0; i < A.length; i++) {
            newAddresses[i] = A[i];
        }
        newAddresses[A.length] = a;
        return newAddresses;
    }

     
    function sExtend(address[] storage A, address[] storage B) internal {
        uint256 length = B.length;
        for (uint256 i = 0; i < length; i++) {
            A.push(B[i]);
        }
    }

     
    function intersect(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 length = A.length;
        bool[] memory includeMap = new bool[](length);
        uint256 newLength = 0;
        for (uint256 i = 0; i < length; i++) {
            if (contains(B, A[i])) {
                includeMap[i] = true;
                newLength++;
            }
        }
        address[] memory newAddresses = new address[](newLength);
        uint256 j = 0;
        for (uint256 k = 0; k < length; k++) {
            if (includeMap[k]) {
                newAddresses[j] = A[k];
                j++;
            }
        }
        return newAddresses;
    }

     
    function union(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        address[] memory leftDifference = difference(A, B);
        address[] memory rightDifference = difference(B, A);
        address[] memory intersection = intersect(A, B);
        return extend(leftDifference, extend(intersection, rightDifference));
    }

     
    function unionB(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        bool[] memory includeMap = new bool[](A.length + B.length);
        uint256 count = 0;
        for (uint256 i = 0; i < A.length; i++) {
            includeMap[i] = true;
            count++;
        }
        for (uint256 j = 0; j < B.length; j++) {
            if (!contains(A, B[j])) {
                includeMap[A.length + j] = true;
                count++;
            }
        }
        address[] memory newAddresses = new address[](count);
        uint256 k = 0;
        for (uint256 m = 0; m < A.length; m++) {
            if (includeMap[m]) {
                newAddresses[k] = A[m];
                k++;
            }
        }
        for (uint256 n = 0; n < B.length; n++) {
            if (includeMap[A.length + n]) {
                newAddresses[k] = B[n];
                k++;
            }
        }
        return newAddresses;
    }

     
    function difference(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 length = A.length;
        bool[] memory includeMap = new bool[](length);
        uint256 count = 0;
         
        for (uint256 i = 0; i < length; i++) {
            address e = A[i];
            if (!contains(B, e)) {
                includeMap[i] = true;
                count++;
            }
        }
        address[] memory newAddresses = new address[](count);
        uint256 j = 0;
        for (uint256 k = 0; k < length; k++) {
            if (includeMap[k]) {
                newAddresses[j] = A[k];
                j++;
            }
        }
        return newAddresses;
    }

     
    function sReverse(address[] storage A) internal {
        address t;
        uint256 length = A.length;
        for (uint256 i = 0; i < length / 2; i++) {
            t = A[i];
            A[i] = A[A.length - i - 1];
            A[A.length - i - 1] = t;
        }
    }

     
    function pop(address[] memory A, uint256 index)
        internal
        pure
        returns (address[] memory, address)
    {
        uint256 length = A.length;
        address[] memory newAddresses = new address[](length - 1);
        for (uint256 i = 0; i < index; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = index + 1; j < length; j++) {
            newAddresses[j - 1] = A[j];
        }
        return (newAddresses, A[index]);
    }

     
    function remove(address[] memory A, address a)
        internal
        pure
        returns (address[] memory)
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert();
        } else {
            (address[] memory _A,) = pop(A, index);
            return _A;
        }
    }

    function sPop(address[] storage A, uint256 index) internal returns (address) {
        uint256 length = A.length;
        if (index >= length) {
            revert("Error: index out of bounds");
        }
        address entry = A[index];
        for (uint256 i = index; i < length - 1; i++) {
            A[i] = A[i + 1];
        }
        A.length--;
        return entry;
    }

     
    function sPopCheap(address[] storage A, uint256 index) internal returns (address) {
        uint256 length = A.length;
        if (index >= length) {
            revert("Error: index out of bounds");
        }
        address entry = A[index];
        if (index != length - 1) {
            A[index] = A[length - 1];
            delete A[length - 1];
        }
        A.length--;
        return entry;
    }

     
    function sRemoveCheap(address[] storage A, address a) internal {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("Error: entry not found");
        } else {
            sPopCheap(A, index);
            return;
        }
    }

     
    function hasDuplicate(address[] memory A) internal pure returns (bool) {
        if (A.length == 0) {
            return false;
        }
        for (uint256 i = 0; i < A.length - 1; i++) {
            for (uint256 j = i + 1; j < A.length; j++) {
                if (A[i] == A[j]) {
                    return true;
                }
            }
        }
        return false;
    }

     
    function isEqual(address[] memory A, address[] memory B) internal pure returns (bool) {
        if (A.length != B.length) {
            return false;
        }
        for (uint256 i = 0; i < A.length; i++) {
            if (A[i] != B[i]) {
                return false;
            }
        }
        return true;
    }

     
    function argGet(address[] memory A, uint256[] memory indexArray)
        internal
        pure
        returns (address[] memory)
    {
        address[] memory array = new address[](indexArray.length);
        for (uint256 i = 0; i < indexArray.length; i++) {
            array[i] = A[indexArray[i]];
        }
        return array;
    }

}

 

 

pragma solidity 0.5.7;










 


library StartRebalanceLibrary {
    using SafeMath for uint256;
    using AddressArrayUtils for address[];

     

     
    function validateStartRebalance(
        uint256 _proposalStartTime,
        uint256 _proposalPeriod,
        uint8 _rebalanceState
    )
        external
    {
         
        require(
            _rebalanceState == uint8(RebalancingLibrary.State.Proposal),
            "RebalancingSetToken.validateStartRebalance: State must be Proposal"
        );

         
        require(
            block.timestamp >= _proposalStartTime.add(_proposalPeriod),
            "RebalancingSetToken.validateStartRebalance: Proposal period not elapsed"
        );
    }

     
    function redeemCurrentSetAndGetBiddingParameters(
        address _currentSet,
        address _nextSet,
        address _auctionLibrary,
        address _coreAddress,
        address _vaultAddress
    )
        public
        returns (RebalancingLibrary.BiddingParameters memory)
    {
         
        uint256 remainingCurrentSets = redeemCurrentSet(
            _currentSet,
            _coreAddress,
            _vaultAddress
        );

         
        RebalancingLibrary.BiddingParameters memory biddingParameters = setUpBiddingParameters(
            _currentSet,
            _nextSet,
            _auctionLibrary,
            remainingCurrentSets
        );

        return biddingParameters;
    }

     
    function setUpBiddingParameters(
        address _currentSet,
        address _nextSet,
        address _auctionLibrary,
        uint256 _remainingCurrentSets
    )
        public
        returns (RebalancingLibrary.BiddingParameters memory)
    {
         
        SetTokenLibrary.SetDetails memory currentSet = SetTokenLibrary.getSetDetails(_currentSet);
        SetTokenLibrary.SetDetails memory nextSet = SetTokenLibrary.getSetDetails(_nextSet);

         
        address[] memory combinedTokenArray = currentSet.components.union(
            nextSet.components
        );

         
        uint256 minimumBid = calculateMinimumBid(
            currentSet.naturalUnit,
            nextSet.naturalUnit,
            _auctionLibrary
        );

         
         
        require(
            _remainingCurrentSets >= minimumBid,
            "RebalancingSetToken.setUpBiddingParameters: Not enough collateral to rebalance"
        );

         
         
        uint256[] memory combinedCurrentUnits;
        uint256[] memory combinedNextSetUnits;
        (
            combinedCurrentUnits,
            combinedNextSetUnits
        ) = calculateCombinedUnitArrays(
            currentSet,
            nextSet,
            minimumBid,
            _auctionLibrary,
            combinedTokenArray
        );

         
        return RebalancingLibrary.BiddingParameters({
            minimumBid: minimumBid,
            remainingCurrentSets: _remainingCurrentSets,
            combinedCurrentUnits: combinedCurrentUnits,
            combinedNextSetUnits: combinedNextSetUnits,
            combinedTokenArray: combinedTokenArray
        });
    }

     
    function calculateMinimumBid(
        uint256 _currentSetNaturalUnit,
        uint256 _nextSetNaturalUnit,
        address _auctionLibrary
    )
        private
        view
        returns (uint256)
    {
         
        uint256 priceDivisor = IAuctionPriceCurve(_auctionLibrary).priceDivisor();

        return Math.max(
            _currentSetNaturalUnit.mul(priceDivisor),
            _nextSetNaturalUnit.mul(priceDivisor)
        );
    }

     
    function calculateCombinedUnitArrays(
        SetTokenLibrary.SetDetails memory _currentSet,
        SetTokenLibrary.SetDetails memory _nextSet,
        uint256 _minimumBid,
        address _auctionLibrary,
        address[] memory _combinedTokenArray
    )
        public
        returns (uint256[] memory, uint256[] memory)
    {
         
         
        uint256[] memory memoryCombinedCurrentUnits = new uint256[](_combinedTokenArray.length);
        uint256[] memory memoryCombinedNextSetUnits = new uint256[](_combinedTokenArray.length);

        for (uint256 i = 0; i < _combinedTokenArray.length; i++) {
            memoryCombinedCurrentUnits[i] = calculateCombinedUnit(
                _currentSet,
                _minimumBid,
                _auctionLibrary,
                _combinedTokenArray[i]
            );

            memoryCombinedNextSetUnits[i] = calculateCombinedUnit(
                _nextSet,
                _minimumBid,
                _auctionLibrary,
                _combinedTokenArray[i]
            );
        }

        return (memoryCombinedCurrentUnits, memoryCombinedNextSetUnits);
    }

     
    function calculateCombinedUnit(
        SetTokenLibrary.SetDetails memory _setToken,
        uint256 _minimumBid,
        address _auctionLibrary,
        address _currentComponent
    )
        private
        returns (uint256)
    {
         
        uint256 indexCurrent;
        bool isComponent;
        (indexCurrent, isComponent) = _setToken.components.indexOf(_currentComponent);

         
        if (isComponent) {
            return computeTransferValue(
                _setToken.units[indexCurrent],
                _setToken.naturalUnit,
                _minimumBid,
                _auctionLibrary
            );
        }

        return 0;
    }

     
    function redeemCurrentSet(
        address _currentSet,
        address _coreAddress,
        address _vaultAddress
    )
        public
        returns (uint256)
    {
         
        uint256 currentSetBalance = IVault(_vaultAddress).getOwnerBalance(
            _currentSet,
            address(this)
        );

         
        uint256 currentSetNaturalUnit = ISetToken(_currentSet).naturalUnit();

         
        uint256 remainingCurrentSets = currentSetBalance.div(currentSetNaturalUnit).mul(currentSetNaturalUnit);

        ICore(_coreAddress).redeemInVault(
            _currentSet,
            remainingCurrentSets
        );

        return remainingCurrentSets;
    }

    
    function computeTransferValue(
        uint256 _unit,
        uint256 _naturalUnit,
        uint256 _minimumBid,
        address _auctionLibrary
    )
        internal
        returns (uint256)
    {
        uint256 priceDivisor = IAuctionPriceCurve(_auctionLibrary).priceDivisor();
        return _minimumBid.mul(_unit).div(_naturalUnit).div(priceDivisor);
    }
}

 

 

pragma solidity 0.5.7;

















 
contract RebalancingSetToken is
    ERC20,
    ERC20Detailed
{
    using SafeMath for uint256;

     

     
    address public core;
    address public factory;
    address public vault;
    address public componentWhiteListAddress;

     
    ICore private coreInstance;
    IVault private vaultInstance;
    IWhiteList private componentWhiteListInstance;

    uint256 public naturalUnit;
    address public manager;
    RebalancingLibrary.State public rebalanceState;

     
    address public currentSet;
    uint256 public unitShares;
    uint256 public lastRebalanceTimestamp;

     
    uint256 public proposalPeriod;
    uint256 public rebalanceInterval;

     
    uint256 public proposalStartTime;

     
    address public nextSet;
    address public auctionLibrary;
    uint256 public startingCurrentSetAmount;
    RebalancingLibrary.AuctionPriceParameters public auctionPriceParameters;
    RebalancingLibrary.BiddingParameters public biddingParameters;

     
    address[] public failedAuctionWithdrawComponents;

     

    event NewManagerAdded(
        address newManager,
        address oldManager
    );

    event RebalanceProposed(
        address nextSet,
        address indexed auctionLibrary,
        uint256 indexed proposalPeriodEndTime
    );

    event RebalanceStarted(
        address oldSet,
        address newSet
    );

     

     

    constructor(
        address _factory,
        address _manager,
        address _initialSet,
        uint256 _initialUnitShares,
        uint256 _naturalUnit,
        uint256 _proposalPeriod,
        uint256 _rebalanceInterval,
        address _componentWhiteList,
        string memory _name,
        string memory _symbol
    )
        public
        ERC20Detailed(
            _name,
            _symbol,
            18
        )
    {
         
        require(
            _initialUnitShares > 0,
            "RebalancingSetToken.constructor: Unit shares must be positive"
        );

        IRebalancingSetFactory tokenFactory = IRebalancingSetFactory(_factory);

        require(
            _naturalUnit >= tokenFactory.minimumNaturalUnit(),
            "RebalancingSetToken.constructor: Natural Unit too low"
        );

        require(
            _naturalUnit <= tokenFactory.maximumNaturalUnit(),
            "RebalancingSetToken.constructor: Natural Unit too large"
        );

         
        require(
            _manager != address(0),
            "RebalancingSetToken.constructor: Invalid manager address"
        );

         
        require(
            _proposalPeriod >= tokenFactory.minimumProposalPeriod(),
            "RebalancingSetToken.constructor: Proposal period too short"
        );
        require(
            _rebalanceInterval >= tokenFactory.minimumRebalanceInterval(),
            "RebalancingSetToken.constructor: Rebalance interval too short"
        );

        core = IRebalancingSetFactory(_factory).core();
        coreInstance = ICore(core);
        vault = coreInstance.vault();
        vaultInstance = IVault(vault);
        componentWhiteListAddress = _componentWhiteList;
        componentWhiteListInstance = IWhiteList(_componentWhiteList);
        factory = _factory;
        manager = _manager;
        currentSet = _initialSet;
        unitShares = _initialUnitShares;
        naturalUnit = _naturalUnit;

        proposalPeriod = _proposalPeriod;
        rebalanceInterval = _rebalanceInterval;
        lastRebalanceTimestamp = block.timestamp;
        rebalanceState = RebalancingLibrary.State.Default;
    }

     

     
    function propose(
        address _nextSet,
        address _auctionLibrary,
        uint256 _auctionTimeToPivot,
        uint256 _auctionStartPrice,
        uint256 _auctionPivotPrice
    )
        external
    {
         
        RebalancingLibrary.AuctionPriceParameters memory auctionPriceParams =
            RebalancingLibrary.AuctionPriceParameters({
                auctionTimeToPivot: _auctionTimeToPivot,
                auctionStartPrice: _auctionStartPrice,
                auctionPivotPrice: _auctionPivotPrice,
                auctionStartTime: 0
            });

         
        ProposeLibrary.ProposalContext memory proposalContext =
            ProposeLibrary.ProposalContext({
                manager: manager,
                currentSet: currentSet,
                coreAddress: core,
                componentWhitelist: componentWhiteListAddress,
                factoryAddress: factory,
                lastRebalanceTimestamp: lastRebalanceTimestamp,
                rebalanceInterval: rebalanceInterval,
                rebalanceState: uint8(rebalanceState)
            });

         
        ProposeLibrary.validateProposal(
            _nextSet,
            _auctionLibrary,
            proposalContext,
            auctionPriceParams
        );

         
        auctionPriceParameters = auctionPriceParams;
        nextSet = _nextSet;
        auctionLibrary = _auctionLibrary;
        proposalStartTime = block.timestamp;
        rebalanceState = RebalancingLibrary.State.Proposal;

        emit RebalanceProposed(
            _nextSet,
            _auctionLibrary,
            proposalStartTime.add(proposalPeriod)
        );
    }

     
    function startRebalance()
        external
    {
         
        StartRebalanceLibrary.validateStartRebalance(
            proposalStartTime,
            proposalPeriod,
            uint8(rebalanceState)
        );

         
        biddingParameters = StartRebalanceLibrary.redeemCurrentSetAndGetBiddingParameters(
            currentSet,
            nextSet,
            auctionLibrary,
            core,
            vault
        );

         
        startingCurrentSetAmount = biddingParameters.remainingCurrentSets;
        auctionPriceParameters.auctionStartTime = block.timestamp;
        rebalanceState = RebalancingLibrary.State.Rebalance;

        emit RebalanceStarted(currentSet, nextSet);
    }

     
    function settleRebalance()
        external
    {
         
        unitShares = SettleRebalanceLibrary.settleRebalance(
            totalSupply(),
            biddingParameters.remainingCurrentSets,
            biddingParameters.minimumBid,
            naturalUnit,
            nextSet,
            core,
            vault,
            uint8(rebalanceState)
        );

         
        currentSet = nextSet;
        lastRebalanceTimestamp = block.timestamp;
        rebalanceState = RebalancingLibrary.State.Default;
        clearAuctionState();
    }

     
    function placeBid(
        uint256 _quantity
    )
        external
        returns (address[] memory, uint256[] memory, uint256[] memory)
    {
         
        PlaceBidLibrary.validatePlaceBid(
            _quantity,
            core,
            biddingParameters
        );

         
        uint256[] memory inflowUnitArray;
        uint256[] memory outflowUnitArray;
        (
            inflowUnitArray,
            outflowUnitArray
        ) = getBidPrice(_quantity);

         
        biddingParameters.remainingCurrentSets = biddingParameters.remainingCurrentSets.sub(_quantity);

        return (biddingParameters.combinedTokenArray, inflowUnitArray, outflowUnitArray);
    }

     
    function endFailedAuction()
        external
    {
        uint256 calculatedUnitShares;
        (
            ,
            calculatedUnitShares
        ) = SettleRebalanceLibrary.calculateNextSetIssueQuantity(
            totalSupply(),
            naturalUnit,
            nextSet,
            vault
        );

         
         
        uint8 integerRebalanceState = FailAuctionLibrary.endFailedAuction(
            startingCurrentSetAmount,
            calculatedUnitShares,
            currentSet,
            core,
            auctionPriceParameters,
            biddingParameters,
            uint8(rebalanceState)
        );
        rebalanceState = RebalancingLibrary.State(integerRebalanceState);

         
        lastRebalanceTimestamp = block.timestamp;

         
        failedAuctionWithdrawComponents = biddingParameters.combinedTokenArray;

         
        clearAuctionState();
    }

     
    function getBidPrice(
        uint256 _quantity
    )
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        return PlaceBidLibrary.getBidPrice(
            _quantity,
            auctionLibrary,
            biddingParameters,
            auctionPriceParameters,
            uint8(rebalanceState)
        );
    }

     
    function mint(
        address _issuer,
        uint256 _quantity
    )
        external
    {
         
        require(
            msg.sender == core,
            "RebalancingSetToken.mint: Sender must be core"
        );

         
        require(
            rebalanceState != RebalancingLibrary.State.Rebalance,
            "RebalancingSetToken.mint: Cannot mint during Rebalance"
        );

         
        require(
            rebalanceState != RebalancingLibrary.State.Drawdown,
            "RebalancingSetToken.mint: Cannot mint during Drawdown"
        );

         
        _mint(_issuer, _quantity);
    }

     
    function burn(
        address _from,
        uint256 _quantity
    )
        external
    {
         
        require(
            rebalanceState != RebalancingLibrary.State.Rebalance,
            "RebalancingSetToken.burn: Cannot burn during Rebalance"
        );

         
        if (rebalanceState == RebalancingLibrary.State.Drawdown) {
             
            require(
                coreInstance.validModules(msg.sender),
                "RebalancingSetToken.burn: Set cannot be redeemed during Drawdown"
            );
        } else {
             
             
            require(
                msg.sender == core,
                "RebalancingSetToken.burn: Sender must be core"
            );
        }

        _burn(_from, _quantity);
    }

     
    function setManager(
        address _newManager
    )
        external
    {
        require(
            msg.sender == manager,
            "RebalancingSetToken.setManager: Sender must be the manager"
        );

        emit NewManagerAdded(_newManager, manager);
        manager = _newManager;
    }

     

     
    function getComponents()
        external
        view
        returns (address[] memory)
    {
        address[] memory components = new address[](1);
        components[0] = currentSet;
        return components;
    }

     
    function getUnits()
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory units = new uint256[](1);
        units[0] = unitShares;
        return units;
    }

     
    function getBiddingParameters()
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory biddingParams = new uint256[](2);
        biddingParams[0] = biddingParameters.minimumBid;
        biddingParams[1] = biddingParameters.remainingCurrentSets;
        return biddingParams;
    }

     
    function getAuctionPriceParameters()
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory auctionParams = new uint256[](4);
        auctionParams[0] = auctionPriceParameters.auctionStartTime;
        auctionParams[1] = auctionPriceParameters.auctionTimeToPivot;
        auctionParams[2] = auctionPriceParameters.auctionStartPrice;
        auctionParams[3] = auctionPriceParameters.auctionPivotPrice;
        return auctionParams;
    }

     
    function tokenIsComponent(
        address _tokenAddress
    )
        external
        view
        returns (bool)
    {
        return _tokenAddress == currentSet;
    }

     
    function getCombinedTokenArrayLength()
        external
        view
        returns (uint256)
    {
        return biddingParameters.combinedTokenArray.length;
    }

     
    function getCombinedTokenArray()
        external
        view
        returns (address[] memory)
    {
        return biddingParameters.combinedTokenArray;
    }

     
    function getCombinedCurrentUnits()
        external
        view
        returns (uint256[] memory)
    {
        return biddingParameters.combinedCurrentUnits;
    }

     
    function getCombinedNextSetUnits()
        external
        view
        returns (uint256[] memory)
    {
        return biddingParameters.combinedNextSetUnits;
    }

     
    function getFailedAuctionWithdrawComponents()
        external
        view
        returns (address[] memory)
    {
        return failedAuctionWithdrawComponents;
    }

     

     
    function clearAuctionState()
        internal
    {
        nextSet = address(0);
        auctionLibrary = address(0);
        startingCurrentSetAmount = 0;
        delete auctionPriceParameters;
        delete biddingParameters;
    }
}