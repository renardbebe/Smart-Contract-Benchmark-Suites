 

pragma solidity 0.4.24;
pragma experimental "v0.5.0";

interface RTCoinInterface {
    

     
    function transfer(address _recipient, uint256 _amount) external returns (bool);

    function transferFrom(address _owner, address _recipient, uint256 _amount) external returns (bool);

    function approve(address _spender, uint256 _amount) external returns (bool approved);

     
    function totalSupply() external view returns (uint256);

    function balanceOf(address _holder) external view returns (uint256);

    function allowance(address _owner, address _spender) external view returns (uint256);

     
    function mint(address _recipient, uint256 _amount) external returns (bool);

    function stakeContractAddress() external view returns (address);

    function mergedMinerValidatorAddress() external view returns (address);
    
     
    function freezeTransfers() external returns (bool);

    function thawTransfers() external returns (bool);
}

library SafeMath {

   
   
    function mul(uint256 a, uint256 b) internal pure  returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

 
 
 
contract Payments {
    using SafeMath for uint256;    

     
    bytes constant private PREFIX = "\x19Ethereum Signed Message:\n32";
     
     
     
    address constant private SIGNER = 0xa80cD01dD37c29116549AA879c44C824b703828A;
    address constant private TOKENADDRESS = 0xecc043b92834c1ebDE65F2181B59597a6588D616;
    address constant private HOTWALLET = 0x3eC6481365c2c2b37d7b939B5854BFB7e5e83C10;
    RTCoinInterface constant private RTI = RTCoinInterface(TOKENADDRESS);
    string constant public VERSION = "production";

    address public admin;

     
    enum PaymentState{ nil, paid }
     
    enum PaymentMethod{ RTC, ETH }

    struct PaymentStruct {
        uint256 paymentNumber;
        uint256 chargeAmountInWei;
        PaymentMethod method;
        PaymentState state;
    }

    mapping (address => uint256) public numPayments;
    mapping (address => mapping(uint256 => PaymentStruct)) public payments;

    event PaymentMade(address _payer, uint256 _paymentNumber, uint8 _paymentMethod, uint256 _paymentAmount);

    modifier validPayment(uint256 _paymentNumber) {
        require(payments[msg.sender][_paymentNumber].state == PaymentState.nil, "payment already made");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "sender must be admin");
        _;
    }

    constructor() public {
        admin = msg.sender;
    }

     
    function makePayment(
        bytes32 _h,
        uint8   _v,
        bytes32 _r,
        bytes32 _s,
        uint256 _paymentNumber,
        uint8   _paymentMethod,
        uint256 _chargeAmountInWei,
        bool   _prefixed)  
        public
        payable
        validPayment(_paymentNumber)
        returns (bool)
    {
        require(_paymentMethod == 0 || _paymentMethod == 1, "invalid payment method");
        bytes32 image;
        if (_prefixed) {
            bytes32 preimage = generatePreimage(_paymentNumber, _chargeAmountInWei, _paymentMethod);
            image = generatePrefixedPreimage(preimage);
        } else {
            image = generatePreimage(_paymentNumber, _chargeAmountInWei, _paymentMethod);
        }
         
        require(image == _h, "reconstructed preimage does not match");
        address signer = ecrecover(_h, _v, _r, _s);
         
        require(signer == SIGNER, "recovered signer does not match");
        PaymentStruct memory ps = PaymentStruct({
            paymentNumber: _paymentNumber,
            chargeAmountInWei: _chargeAmountInWei,
            method: PaymentMethod(_paymentMethod),
            state: PaymentState.paid
        });
        payments[msg.sender][_paymentNumber] = ps;
        numPayments[msg.sender] = numPayments[msg.sender].add(1);
         
        if (PaymentMethod(_paymentMethod) == PaymentMethod.ETH) {
            require(msg.value == _chargeAmountInWei, "msg.value does not equal charge amount");
            emit PaymentMade(msg.sender, _paymentNumber, _paymentMethod, _chargeAmountInWei);
            HOTWALLET.transfer(msg.value);
            return true;
        }
        emit PaymentMade(msg.sender, _paymentNumber, _paymentMethod, _chargeAmountInWei);
        require(RTI.transferFrom(msg.sender, HOTWALLET, _chargeAmountInWei), "trasferFrom failed, most likely needs approval");
        return true;
    }

     
    function verifyImages(
        bytes32 _h,
        uint256 _paymentNumber,
        uint8   _paymentMethod,
        uint256 _chargeAmountInWei,
        bool   _prefixed)
        public
        view
        returns (bool)
    {
        require(_paymentMethod == 0 || _paymentMethod == 1, "invalid payment method");
        bytes32 image;
        if (_prefixed) {
            bytes32 preimage = generatePreimage(_paymentNumber, _chargeAmountInWei, _paymentMethod);
            image = generatePrefixedPreimage(preimage);
        } else {
            image = generatePreimage(_paymentNumber, _chargeAmountInWei, _paymentMethod);
        }
        return image == _h;
    }

     
    function verifySigner(
        bytes32 _h,
        uint8   _v,
        bytes32 _r,
        bytes32 _s,
        uint256 _paymentNumber,
        uint8   _paymentMethod,
        uint256 _chargeAmountInWei,
        bool   _prefixed)
        public
        view
        returns (bool)
    {
        require(_paymentMethod == 0 || _paymentMethod == 1, "invalid payment method");
        bytes32 image;
        if (_prefixed) {
            bytes32 preimage = generatePreimage(_paymentNumber, _chargeAmountInWei, _paymentMethod);
            image = generatePrefixedPreimage(preimage);
        } else {
            image = generatePreimage(_paymentNumber, _chargeAmountInWei, _paymentMethod);
        }
        require(image == _h, "failed to reconstruct preimages");
        return ecrecover(_h, _v, _r, _s) == SIGNER;
    }

     
    function generatePreimage(
        uint256 _paymentNumber,
        uint256 _chargeAmountInWei,
        uint8   _paymentMethod)
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(msg.sender, _paymentNumber, _paymentMethod, _chargeAmountInWei));
    }

     
    function generatePrefixedPreimage(bytes32 _preimage) internal pure returns (bytes32)  {
        return keccak256(abi.encodePacked(PREFIX, _preimage));
    }

     
    function goodNightSweetPrince() public onlyAdmin returns (bool) {
        selfdestruct(msg.sender);
        return true;
    }
}