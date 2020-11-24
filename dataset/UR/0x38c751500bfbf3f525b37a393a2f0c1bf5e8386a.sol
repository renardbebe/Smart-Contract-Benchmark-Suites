 

 

pragma solidity ^0.5.1;
pragma experimental ABIEncoderV2;

 
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

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
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

contract LibOrder {
    struct Order {
        address makerAddress;
        address takerAddress;
        address feeRecipientAddress;
        address senderAddress;
        uint256 makerAssetAmount;
        uint256 takerAssetAmount;
        uint256 makerFee;
        uint256 takerFee;
        uint256 expirationTimeSeconds;
        uint256 salt;
        bytes makerAssetData;
        bytes takerAssetData;
    }
}

contract IPasser {

    function fillOrder (
        LibOrder.Order calldata order,
        uint256 takerAssetFillAmount,
        uint256 salt,
        bytes calldata orderSignature,
        bytes calldata takerSignature
    )
    external payable;
}

contract distributor is Ownable{
    using SafeMath for uint;

    event  UpdateAuthorizedAddress(address indexed passer);
    address public passer;

    constructor (address payable _passer) public {
        passer = _passer;
    }

    function fillOrder (
        LibOrder.Order calldata order,
        uint256 takerAssetFillAmount,
        uint256 salt,
        bytes calldata orderSignature,
        bytes calldata takerSignature,
        address payable[] calldata feeRecipientsAddresses,
        uint[] calldata feeAmounts
    ) external payable {
        require(feeRecipientsAddresses.length == feeAmounts.length);
        uint actualRecipientCutsTotal;
        for(uint i= 0; i < feeRecipientsAddresses.length; i++){
            actualRecipientCutsTotal += feeAmounts[i];
        }
        uint actualTakerAssetFillAmount = msg.value.sub(actualRecipientCutsTotal);
        require(takerAssetFillAmount == actualTakerAssetFillAmount, "INVALID_FEE_AMOUNT");

        IPasser(passer).fillOrder.value(actualTakerAssetFillAmount)(
            order,
            takerAssetFillAmount,
            salt,
            orderSignature,
            takerSignature
        );

        for(uint i= 0; i < feeRecipientsAddresses.length; i++){
            feeRecipientsAddresses[i].transfer(feeAmounts[i]);
        }
    }

    function updateAuthorizedAddress(
       address _passer
    )
        external
        onlyOwner
    {
        passer = _passer;
        emit UpdateAuthorizedAddress(_passer);
    }
}