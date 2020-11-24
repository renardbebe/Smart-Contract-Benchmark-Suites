 

 

 

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
pragma experimental "ABIEncoderV2";

 

interface IRebalanceAuctionModule {
     
    function bidAndWithdraw(
        address _rebalancingSetToken,
        uint256 _quantity,
        bool _allowPartialFill
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

     
    function auctionLibrary()
        external
        view
        returns (address);

     
    function totalSupply()
        external
        view
        returns (uint256);

     
    function proposalStartTime()
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

     
    function startingCurrentSetAmount()
        external
        view
        returns (uint256);

     
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

     
    function nextSet()
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

     
    function getAuctionPriceParameters()
        external
        view
        returns (uint256[] memory);

     
    function getBiddingParameters()
        external
        view
        returns (uint256[] memory);

     
    function getBidPrice(
        uint256 _quantity
    )
        external
        view
        returns (uint256[] memory, uint256[] memory);

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


 
interface IWETH {
    function deposit()
        external
        payable;

    function withdraw(
        uint256 wad
    )
        external;
}

 

 

pragma solidity 0.5.7;


 
interface IERC20 {
    function balanceOf(
        address _owner
    )
        external
        view
        returns (uint256);

    function allowance(
        address _owner,
        address _spender
    )
        external
        view
        returns (uint256);

    function transfer(
        address _to,
        uint256 _quantity
    )
        external;

    function transferFrom(
        address _from,
        address _to,
        uint256 _quantity
    )
        external;

    function approve(
        address _spender,
        uint256 _quantity
    )
        external
        returns (bool);

    function totalSupply()
        external
        returns (uint256);
}

 

 

pragma solidity 0.5.7;




 
library ERC20Wrapper {

     

     
    function balanceOf(
        address _token,
        address _owner
    )
        external
        view
        returns (uint256)
    {
        return IERC20(_token).balanceOf(_owner);
    }

     
    function allowance(
        address _token,
        address _owner,
        address _spender
    )
        internal
        view
        returns (uint256)
    {
        return IERC20(_token).allowance(_owner, _spender);
    }

     
    function transfer(
        address _token,
        address _to,
        uint256 _quantity
    )
        external
    {
        IERC20(_token).transfer(_to, _quantity);

         
        require(
            checkSuccess(),
            "ERC20Wrapper.transfer: Bad return value"
        );
    }

     
    function transferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _quantity
    )
        external
    {
        IERC20(_token).transferFrom(_from, _to, _quantity);

         
        require(
            checkSuccess(),
            "ERC20Wrapper.transferFrom: Bad return value"
        );
    }

     
    function approve(
        address _token,
        address _spender,
        uint256 _quantity
    )
        internal
    {
        IERC20(_token).approve(_spender, _quantity);

         
        require(
            checkSuccess(),
            "ERC20Wrapper.approve: Bad return value"
        );
    }

     
    function ensureAllowance(
        address _token,
        address _owner,
        address _spender,
        uint256 _quantity
    )
        internal
    {
        uint256 currentAllowance = allowance(_token, _owner, _spender);
        if (currentAllowance < _quantity) {
            approve(
                _token,
                _spender,
                CommonMath.maxUInt256()
            );
        }
    }

     

     
    function checkSuccess(
    )
        private
        pure
        returns (bool)
    {
         
        uint256 returnValue = 0;

        assembly {
             
            switch returndatasize

             
            case 0x0 {
                returnValue := 1
            }

             
            case 0x20 {
                 
                returndatacopy(0x0, 0x0, 0x20)

                 
                returnValue := mload(0x0)
            }

             
            default { }
        }

         
        return returnValue == 1;
    }
}

 

 

pragma solidity 0.5.7;










 
contract RebalancingSetEthBidder is
    ReentrancyGuard
{
    using SafeMath for uint256;

     
    IRebalanceAuctionModule public rebalanceAuctionModule;

     
    ITransferProxy public transferProxy;

     
    IWETH public weth;

     

    event BidPlacedWithEth(
        address indexed rebalancingSetToken,
        address indexed bidder
    );

     

     
    constructor(
        IRebalanceAuctionModule _rebalanceAuctionModule,
        ITransferProxy _transferProxy,
        IWETH _weth
    )
        public
    {
         
        rebalanceAuctionModule = _rebalanceAuctionModule;

         
        transferProxy = _transferProxy;

         
        weth = _weth;

         
        ERC20Wrapper.approve(
            address(_weth),
            address(_transferProxy),
            CommonMath.maxUInt256()
        );
    }

     
    function ()
        external
        payable
    {
        require(
            msg.sender == address(weth),
            "RebalancingSetEthBidder.fallback: Cannot receive ETH directly unless unwrapping WETH"
        );
    }

     

     

    function bidAndWithdrawWithEther(
        IRebalancingSetToken _rebalancingSetToken,
        uint256 _quantity,
        bool _allowPartialFill
    )
        external
        payable
        nonReentrant
    {
         
        weth.deposit.value(msg.value)();

         
        address[] memory combinedTokenArray = _rebalancingSetToken.getCombinedTokenArray();

         
        uint256[] memory inflowArray;
        uint256[] memory outflowArray;
        (
            inflowArray,
            outflowArray
        ) = _rebalancingSetToken.getBidPrice(_quantity);

         
        depositNonWethComponents(
            combinedTokenArray,
            inflowArray
        );

         
        rebalanceAuctionModule.bidAndWithdraw(
            address(_rebalancingSetToken),
            _quantity,
            _allowPartialFill
        );

         
        withdrawNonWethComponentsToSender(
            combinedTokenArray
        );

         
        uint256 wethBalance = ERC20Wrapper.balanceOf(address(weth), address(this));
        if (wethBalance > 0) {
            weth.withdraw(wethBalance);
            msg.sender.transfer(wethBalance);
        }

         
        emit BidPlacedWithEth(
            address(_rebalancingSetToken),
            msg.sender
        );
    }

     

     
    function depositNonWethComponents(
        address[] memory _combinedTokenArray,
        uint256[] memory _inflowArray
    )
        private
    {
         
        for (uint256 i = 0; i < _combinedTokenArray.length; i++) {
            address currentComponent = _combinedTokenArray[i];
            uint256 currentComponentQuantity = _inflowArray[i];

             
            if (currentComponentQuantity > 0) {
                 
                ERC20Wrapper.ensureAllowance(
                    address(currentComponent),
                    address(this),
                    address(transferProxy),
                    currentComponentQuantity
                );

                 
                if (currentComponent != address(weth)) {
                     
                    ERC20Wrapper.transferFrom(
                        address(currentComponent),
                        msg.sender,
                        address(this),
                        currentComponentQuantity
                    );
                }
            }
        }
    }

      
    function withdrawNonWethComponentsToSender(
        address[] memory _combinedTokenArray
    )
        private
    {
         
        for (uint256 i = 0; i < _combinedTokenArray.length; i++) {
            address currentComponent = _combinedTokenArray[i];

             
            uint256 currentComponentBalance = ERC20Wrapper.balanceOf(
                currentComponent,
                address(this)
            );

             
            if (currentComponentBalance > 0 && currentComponent != address(weth)) {
                 
                ERC20Wrapper.transfer(
                    address(currentComponent),
                    msg.sender,
                    currentComponentBalance
                );
            }
        }
    }
}