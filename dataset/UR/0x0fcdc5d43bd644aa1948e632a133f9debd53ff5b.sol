 

 
 
 
 
 
 
 
 
 
 
 
 
 
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

 

pragma solidity 0.5.3;



 
contract HashedTimelock {

    using SafeMath for uint256;

    event LogHTLCNew(
        bytes32 indexed contractId,
        address indexed sender,
        address indexed receiver,
        uint amount,
        uint timelock
    );
    event LogHTLCWithdraw(bytes32 indexed contractId, bytes32 preimage);
    event LogHTLCRefund(bytes32 indexed contractId);

    struct LockContract {
        address payable sender;
        address payable receiver;
        uint amount;
        uint timelock;  
        bool withdrawn;
        bool refunded;
        bytes32 preimage;
    }

    modifier fundsSent() {
        require(msg.value > 0, "msg.value must be > 0");
        _;
    }
    modifier futureTimelock(uint _time) {
         
         
         
        require(_time > now + 1 hours, "timelock time must be in the future");
        _;
    }
    modifier contractExists(bytes32 _contractId) {
        require(haveContract(_contractId), "contractId does not exist");
        _;
    }
    modifier hashlockMatches(bytes32 _contractId, bytes32 _x) {
        require(
            _contractId == keccak256(abi.encodePacked(_x)),
            "hashlock hash does not match"
        );
        _;
    }
    modifier withdrawable(bytes32 _contractId) {
        require(contracts[_contractId].receiver == msg.sender, "withdrawable: not receiver");
        require(contracts[_contractId].withdrawn == false, "withdrawable: already withdrawn");
        _;
    }
    modifier refundable(bytes32 _contractId) {
        require(contracts[_contractId].sender == msg.sender, "refundable: not sender");
        require(contracts[_contractId].refunded == false, "refundable: already refunded");
        require(contracts[_contractId].withdrawn == false, "refundable: already withdrawn");
        require(contracts[_contractId].timelock <= now, "refundable: timelock not yet passed");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "you are not an owner");
        _;
    }

    mapping (bytes32 => LockContract) contracts;
    uint256 public feePercent;  
    uint oneHundredPercent = 10000;  
    address payable public owner;
    uint feeToWithdraw;

    constructor(address payable _owner, uint256 _feePercent) public {
        feePercent = _feePercent;
        owner = _owner;
    }

    function setFeePercent(uint256 _feePercent) external onlyOwner {
        require(_feePercent < oneHundredPercent.div(2), "should be less than 50%");
        feePercent = _feePercent;
    }
     
    function newContract(address payable _receiver, bytes32 _hashlock, uint _timelock)
        external
        payable
        fundsSent
        futureTimelock(_timelock)
    {
        uint256 swapValue = msg.value.mul(oneHundredPercent).div(oneHundredPercent.add(feePercent));
        uint feeValue = msg.value.sub(swapValue);
        feeToWithdraw = feeValue.add(feeToWithdraw);

         
         
         
        if (haveContract(_hashlock)) {
            revert("contract exist");
        }

        contracts[_hashlock] = LockContract(
            msg.sender,
            _receiver,
            swapValue,
            _timelock,
            false,
            false,
            0x0
        );

        emit LogHTLCNew(
            _hashlock,
            msg.sender,
            _receiver,
            swapValue,
            _timelock
        );
    }

     
    function withdraw(bytes32 _contractId, bytes32 _preimage)
        external
        contractExists(_contractId)
        hashlockMatches(_contractId, _preimage)
        withdrawable(_contractId)
        returns (bool)
    {
        LockContract storage c = contracts[_contractId];
        c.preimage = _preimage;
        c.withdrawn = true;
        c.receiver.transfer(c.amount);
        emit LogHTLCWithdraw(_contractId, _preimage);
        return true;
    }

     
    function refund(bytes32 _contractId)
        external
        contractExists(_contractId)
        refundable(_contractId)
        returns (bool)
    {
        LockContract storage c = contracts[_contractId];
        c.refunded = true;
        c.sender.transfer(c.amount);
        emit LogHTLCRefund(_contractId);
        return true;
    }

    function claimTokens(address _token) external onlyOwner {
        if (_token == address(0)) {
            owner.transfer(feeToWithdraw);
            return;
        }
        IERC20 erc20token = IERC20(_token);
        uint256 balance = erc20token.balanceOf(address(this));
        erc20token.transfer(owner, balance);
    }

     
    function getContract(bytes32 _contractId)
        public
        view
        returns (
            address sender,
            address receiver,
            uint amount,
            uint timelock,
            bool withdrawn,
            bool refunded,
            bytes32 preimage
        )
    {
        if (haveContract(_contractId) == false)
            return (address(0), address(0), 0, 0, false, false, 0);
        LockContract storage c = contracts[_contractId];
        return (c.sender, c.receiver, c.amount, c.timelock,
            c.withdrawn, c.refunded, c.preimage);
    }

     
    function haveContract(bytes32 _contractId)
        public
        view
        returns (bool exists)
    {
        exists = (contracts[_contractId].sender != address(0));
    }

}