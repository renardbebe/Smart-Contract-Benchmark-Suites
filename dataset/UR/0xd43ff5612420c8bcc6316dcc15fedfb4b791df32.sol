 

pragma solidity ^0.5.2;

 
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

 

pragma solidity ^0.5.7;

contract IController  {
    event SetContractInfo(bytes32 id, address contractAddress, bytes20 gitCommitHash);

    function setContractInfo(bytes32 _id, address _contractAddress, bytes20 _gitCommitHash) external;
    function updateController(bytes32 _id, address _controller) external;
    function getContract(bytes32 _id) public view returns (address);
}

 

pragma solidity ^0.5.1;

contract IBondingManager {

    function unbondingPeriod() public view returns (uint64);

}

 

pragma solidity ^0.5.1;

contract IRoundsManager {

    function roundLength() public view returns (uint256);

}

 

pragma solidity ^0.5.7;






contract LptOrderBook {

    using SafeMath for uint256;

    address private constant ZERO_ADDRESS = address(0);

    string internal constant ERROR_SELL_ORDER_COMMITTED_TO = "LPT_ORDER_SELL_ORDER_COMMITTED_TO";
    string internal constant ERROR_SELL_ORDER_NOT_COMMITTED_TO = "LPT_ORDER_SELL_ORDER_NOT_COMMITTED_TO";
    string internal constant ERROR_INITIALISED_ORDER = "LPT_ORDER_INITIALISED_ORDER";
    string internal constant ERROR_UNINITIALISED_ORDER = "LPT_ORDER_UNINITIALISED_ORDER";
    string internal constant ERROR_COMMITMENT_WITHIN_UNBONDING_PERIOD = "LPT_ORDER_COMMITMENT_WITHIN_UNBONDING_PERIOD";
    string internal constant ERROR_NOT_BUYER = "LPT_ORDER_NOT_BUYER";
    string internal constant ERROR_STILL_WITHIN_LOCK_PERIOD = "LPT_ORDER_STILL_WITHIN_LOCK_PERIOD";

    struct LptSellOrder {
        uint256 lptSellValue;
        uint256 daiPaymentValue;
        uint256 daiCollateralValue;
        uint256 deliveredByBlock;
        address buyerAddress;
    }

    IController livepeerController;
    IERC20 daiToken;
    mapping(address => LptSellOrder) public lptSellOrders;  

    constructor(address _livepeerController, address _daiToken) public {
        livepeerController = IController(_livepeerController);
        daiToken = IERC20(_daiToken);
    }

     
    function createLptSellOrder(uint256 _lptSellValue, uint256 _daiPaymentValue, uint256 _daiCollateralValue, uint256 _deliveredByBlock) public {
        LptSellOrder storage lptSellOrder = lptSellOrders[msg.sender];

        require(lptSellOrder.daiCollateralValue == 0, ERROR_INITIALISED_ORDER);

        daiToken.transferFrom(msg.sender, address(this), _daiCollateralValue);

        lptSellOrders[msg.sender] = LptSellOrder(_lptSellValue, _daiPaymentValue, _daiCollateralValue, _deliveredByBlock, ZERO_ADDRESS);
    }

     
    function cancelLptSellOrder() public {
        LptSellOrder storage lptSellOrder = lptSellOrders[msg.sender];

        require(lptSellOrder.buyerAddress == ZERO_ADDRESS, ERROR_SELL_ORDER_COMMITTED_TO);

        daiToken.transfer(msg.sender, lptSellOrder.daiCollateralValue);
        delete lptSellOrders[msg.sender];
    }

     
    function commitToBuyLpt(address _sellOrderCreator) public {
        LptSellOrder storage lptSellOrder = lptSellOrders[_sellOrderCreator];

        require(lptSellOrder.lptSellValue > 0, ERROR_UNINITIALISED_ORDER);
        require(lptSellOrder.buyerAddress == ZERO_ADDRESS, ERROR_SELL_ORDER_COMMITTED_TO);
        require(lptSellOrder.deliveredByBlock.sub(_getUnbondingPeriodLength()) > block.number, ERROR_COMMITMENT_WITHIN_UNBONDING_PERIOD);

        daiToken.transferFrom(msg.sender, address(this), lptSellOrder.daiPaymentValue);

        lptSellOrder.buyerAddress = msg.sender;
    }

     
    function claimCollateralAndPayment(address _sellOrderCreator) public {
        LptSellOrder storage lptSellOrder = lptSellOrders[_sellOrderCreator];

        require(lptSellOrder.buyerAddress == msg.sender, ERROR_NOT_BUYER);
        require(lptSellOrder.deliveredByBlock < block.number, ERROR_STILL_WITHIN_LOCK_PERIOD);

        uint256 totalValue = lptSellOrder.daiPaymentValue.add(lptSellOrder.daiCollateralValue);
        daiToken.transfer(msg.sender, totalValue);
    }

     
    function fulfillSellOrder() public {
        LptSellOrder storage lptSellOrder = lptSellOrders[msg.sender];

        require(lptSellOrder.buyerAddress != ZERO_ADDRESS, ERROR_SELL_ORDER_NOT_COMMITTED_TO);

        IERC20 livepeerToken = IERC20(_getLivepeerContractAddress("LivepeerToken"));livepeerToken.transferFrom(msg.sender, lptSellOrder.buyerAddress, lptSellOrder.lptSellValue);

        uint256 totalValue = lptSellOrder.daiPaymentValue.add(lptSellOrder.daiCollateralValue);
        daiToken.transfer(msg.sender, totalValue);

        delete lptSellOrders[msg.sender];
    }

    function _getLivepeerContractAddress(string memory _livepeerContract) internal view returns (address) {
        bytes32 contractId = keccak256(abi.encodePacked(_livepeerContract));
        return livepeerController.getContract(contractId);
    }

    function _getUnbondingPeriodLength() internal view returns (uint256) {
        IBondingManager bondingManager = IBondingManager(_getLivepeerContractAddress("BondingManager"));
        uint64 unbondingPeriodRounds = bondingManager.unbondingPeriod();

        IRoundsManager roundsManager = IRoundsManager(_getLivepeerContractAddress("RoundsManager"));
        uint256 roundLength = roundsManager.roundLength();

        return roundLength.mul(unbondingPeriodRounds);
    }
}