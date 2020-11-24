 

 

 

pragma solidity ^0.4.25;


interface EscrowBaseInterface {

	function hasCurrencySupport(bytes32 _symbol) public view returns (bool);

	function getServiceFeeInfo() external view returns (address, uint16, uint);
	function setServiceFee(uint16 _feeValue) external returns (uint);
	function setServiceFeeAddress(address _feeReceiver) external returns (uint);

	 
     
     
     
     
     
    function getBalanceOf(
        bytes32 _tradeRecordId,
        address _seller,
        address _buyer
    ) external view returns (bytes32, uint);

	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	function createEscrow(
		bytes32 _tradeRecordId,
		address _seller,
		address _buyer,
		bytes32 _symbol,
		uint _value,
		uint _transferImmediatelyToBuyerAmount,
		uint8 _feeStatus
	) external payable returns (uint);

	 
	 
	 
	 
	 
	 
	 
	 
	function deposit(
		bytes32 _tradeRecordId,
		address _seller,
		address _buyer,
		uint _value,
		uint _transferImmediatelyToBuyerAmount,  
		uint8 _feeStatus
	) external payable returns (uint);

	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	function releaseBuyerPayment(
		bytes32 _tradeRecordId,
		address _seller,
		address _buyer,
		uint _value,
		uint _expireAtBlock,
		uint _salt,
		bytes _sellerSignature,
		uint8 _feeStatus
	) external returns (uint);

	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	function sendSellerPayback(
		bytes32 _tradeRecordId,
		address _seller,
		address _buyer,
		uint _value,
		uint _expireAtBlock,
		uint _salt,
		bytes _buyerSignature
	) external returns (uint);

	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	function releaseNegotiatedPayment(
		bytes32 _tradeRecordId,
		address _seller,
		address _buyer,
		uint _sellerValue,
		uint _buyerValue,
		uint _expireAtBlock,
		uint _salt,
		bytes _signatures,
		uint8 _feeStatus
	) external returns (uint);

	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	function initiateDispute(
		bytes32 _tradeRecordId,
		address _seller,
		address _buyer,
		uint _expireAtBlock,
		uint _salt,
		bytes _signature
	) external returns (uint);

	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	function cancelDispute(
		bytes32 _tradeRecordId,
		address _seller,
		address _buyer,
		uint _expireAtBlock,
		uint _salt,
		bytes _signature
	) external returns (uint);

	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	function releaseDisputedPayment(
		bytes32 _tradeRecordId,
		address _seller,
		address _buyer,
		uint _buyerValue,
		uint _expireAtBlock,
		bytes _arbiterSignature
	) external returns (uint);

	 
     
     
     
     
    function deleteEscrow(
        bytes32 _tradeRecordId,
        address _seller,
        address _buyer
    ) external returns (uint);

	function getArbiter(bytes32 _tradeRecordId, address _seller, address _buyer) external view returns (address);

	 
	 
	 
	 
	 
	 
	 
	 
	 
	function setArbiter(
		bytes32 _tradeRecordId,
		address _seller,
		address _buyer,
		address _arbiter,
		uint _expireAtBlock,
		uint _salt,
		bytes _bothSignatures
	) external returns (uint);

	 
	 
	 
	 
	 
	 
	function retranslateToFeeRecipient(bytes32 _symbol, address _from, uint _amount) external payable returns (uint);
}

 

 

pragma solidity ^0.4.25;


library Signatures {

    bytes constant internal SIGNATURE_PREFIX = "\x19Ethereum Signed Message:\n32";
    uint constant internal SIGNATURE_LENGTH = 65;

    function getSignerFromSignature(bytes32 _message, bytes _signature)
    public
    pure
    returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (_signature.length != SIGNATURE_LENGTH) {
            return 0;
        }

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := and(mload(add(_signature, 65)), 255)
        }

        if (v < 27) {
            v += 27;
        }

        return ecrecover(
            keccak256(abi.encodePacked(SIGNATURE_PREFIX, _message)),
            v,
            r,
            s
        );
    }

     
     
     
     
    function getSignersFromSignatures(bytes32 _message, bytes _signatures)
    public
    pure
    returns (address[] memory _addresses)
    {
        require(validSignaturesLength(_signatures), "SIGNATURES_SHOULD_HAVE_CORRECT_LENGTH");
        _addresses = new address[](numSignatures(_signatures));
        for (uint i = 0; i < _addresses.length; i++) {
            _addresses[i] = getSignerFromSignature(_message, signatureAt(_signatures, i));
        }
    }

    function numSignatures(bytes _signatures)
    private
    pure
    returns (uint256)
    {
        return _signatures.length / SIGNATURE_LENGTH;
    }

    function validSignaturesLength(bytes _signatures)
    internal
    pure
    returns (bool)
    {
        return (_signatures.length % SIGNATURE_LENGTH) == 0;
    }

    function signatureAt(bytes _signatures, uint position)
    private
    pure
    returns (bytes)
    {
        return slice(_signatures, position * SIGNATURE_LENGTH, SIGNATURE_LENGTH);
    }

    function bytesToBytes4(bytes memory source)
    private
    pure
    returns (bytes4 output) {
        if (source.length == 0) {
            return 0x0;
        }
        assembly {
            output := mload(add(source, 4))
        }
    }

    function slice(bytes _bytes, uint _start, uint _length)
    private
    pure
    returns (bytes)
    {
        require(_bytes.length >= (_start + _length), "SIGNATURES_SLICE_SIZE_SHOULD_NOT_OVERTAKE_BYTES_LENGTH");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                 
                 
                tempBytes := mload(0x40)

                 
                 
                 
                 
                 
                 
                 
                 
                let lengthmod := and(_length, 31)

                 
                 
                 
                 
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                     
                     
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                 
                 
                mstore(0x40, and(add(mc, 31), not(31)))
            }
             
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

}

 

 

pragma solidity ^0.4.23;


 
contract ERC20Interface {
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);

    string public symbol;

    function decimals() public view returns (uint8);
    function totalSupply() public view returns (uint256 supply);

    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
}

 

 

pragma solidity ^0.4.23;



 
 
 
 
contract Owned {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address public contractOwner;
    address public pendingContractOwner;

    modifier onlyContractOwner {
        if (msg.sender == contractOwner) {
            _;
        }
    }

    constructor()
    public
    {
        contractOwner = msg.sender;
    }

     
     
     
     
    function changeContractOwnership(address _to)
    public
    onlyContractOwner
    returns (bool)
    {
        if (_to == 0x0) {
            return false;
        }
        pendingContractOwner = _to;
        return true;
    }

     
     
     
    function claimContractOwnership()
    public
    returns (bool)
    {
        if (msg.sender != pendingContractOwner) {
            return false;
        }

        emit OwnershipTransferred(contractOwner, pendingContractOwner);
        contractOwner = pendingContractOwner;
        delete pendingContractOwner;
        return true;
    }

     
     
    function transferOwnership(address newOwner)
    public
    onlyContractOwner
    returns (bool)
    {
        if (newOwner == 0x0) {
            return false;
        }

        emit OwnershipTransferred(contractOwner, newOwner);
        contractOwner = newOwner;
        delete pendingContractOwner;
        return true;
    }

     
     
     
    function transferContractOwnership(address newOwner)
    public
    returns (bool)
    {
        return transferOwnership(newOwner);
    }

     
     
    function withdrawTokens(address[] tokens)
    public
    onlyContractOwner
    {
        address _contractOwner = contractOwner;
        for (uint i = 0; i < tokens.length; i++) {
            ERC20Interface token = ERC20Interface(tokens[i]);
            uint balance = token.balanceOf(this);
            if (balance > 0) {
                token.transfer(_contractOwner, balance);
            }
        }
    }

     
     
    function withdrawEther()
    public
    onlyContractOwner
    {
        uint balance = address(this).balance;
        if (balance > 0)  {
            contractOwner.transfer(balance);
        }
    }

     
     
     
     
    function transferEther(address _to, uint256 _value)
    public
    onlyContractOwner
    {
        require(_to != 0x0, "INVALID_ETHER_RECEPIENT_ADDRESS");
        if (_value > address(this).balance) {
            revert("INVALID_VALUE_TO_TRANSFER_ETHER");
        }

        _to.transfer(_value);
    }
}

 

 

pragma solidity ^0.4.25;


 
contract Object is Owned {
     
    uint constant OK = 1;
}

 

pragma solidity ^0.4.25;

 
contract Context {
     
     
    constructor () internal { }
     

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;  
        return msg.data;
    }
}

 

pragma solidity ^0.4.25;

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

 

pragma solidity ^0.4.25;



 
contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

 

pragma solidity ^0.4.25;




 
contract WhitelistedRole is Context, WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(_msgSender()), "WhitelistedRole: caller does not have the Whitelisted role");
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(_msgSender());
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}

 

 

pragma solidity ^0.4.25;




contract Relayed is Object, WhitelistedRole {

    uint private whitelistedCount;

    event RelayTransferred(address indexed previousRelay, address indexed newRelay);

     
    modifier onlyRelay() {
        require(!isActivatedRelay() || isWhitelisted(msg.sender), "RELAY_ONLY");
        _;
    }

    function isActivatedRelay() public view returns (bool) {
        return whitelistedCount != 0;
    }

    function _addWhitelisted(address account) internal {
        super._addWhitelisted(account);
        whitelistedCount = whitelistedCount + 1;
    }

    function _removeWhitelisted(address account) internal {
        super._removeWhitelisted(account);
        whitelistedCount = whitelistedCount - 1;
    }
}

 

 

pragma solidity ^0.4.25;


contract EscrowBase {

    mapping(bytes32 => bool) internal _saltWithEscrow2flagMapping;

     
     
     
     
     
     
    function getBalanceOf(
        bytes32 _tradeRecordId,
        address _seller,
        address _buyer
    )
    external
    view
    returns (bytes32, uint)
    {
        bytes32 _escrowHash = _getEscrowHash(_tradeRecordId, _seller, _buyer);
        return (_getEscrowSymbol(_escrowHash), _getEscrowValue(_escrowHash));
    }

     
     
	 
	 
     
    function _getEscrowHash(
        bytes32 _tradeRecordId,
        address _seller,
        address _buyer
    )
    internal
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(_tradeRecordId, _seller, _buyer));
    }

    function _getEncodedSaltWithEscrowHash(uint _salt, bytes32 _escrowHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_salt, _escrowHash));
    }

    function _getEscrowExists(bytes32 _escrowHash) internal view returns (bool);

    function _getEscrowDisputed(bytes32 _escrowHash) internal view returns (bool);

    function _getEscrowSymbol(bytes32 _escrowHash) internal view returns (bytes32);

    function _getEscrowValue(bytes32 _escrowHash) internal view returns (uint);

    function _getEscrowArbiter(bytes32 _escrowHash) internal view returns (address);
}

 

 

pragma solidity ^0.4.25;


contract DisputedEmitter {
    event DisputeRequested(bytes32 indexed tradeHash, address arbiter);
    event DisputeCanceled(bytes32 indexed tradeHash);
    event ArbiterTransferred(bytes32 indexed tradeHash, address arbiter);

    function _emitDisputeRequested(bytes32 _tradeHash, address _arbiter) internal {
        emit DisputeRequested(_tradeHash, _arbiter);
    }

    function _emitDisputeCanceled(bytes32 _tradeHash) internal {
        emit DisputeCanceled(_tradeHash);
    }

    function _emitArbiterTransferred(bytes32 _tradeHash, address _arbiter) internal {
        emit ArbiterTransferred(_tradeHash, _arbiter);
    }
}

 

 

pragma solidity ^0.4.25;





contract Disputed is
    Relayed,
    EscrowBase,
    DisputedEmitter
{
    mapping(bytes32 => address) internal _disputeInitiators;

     
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
    function initiateDispute(
        bytes32 _tradeRecordId,
        address _seller,
        address _buyer,
        uint _expireAtBlock,
        uint _salt,
        bytes _signature
    )
    external
    onlyRelay
    returns (uint)
    {
        bytes32 _escrowHash = _getEscrowHash(_tradeRecordId, _seller, _buyer);
        bytes32 _encodedSaltWithEscrow = _getEncodedSaltWithEscrowHash(_salt, _escrowHash);
        require(_getEscrowExists(_escrowHash), "DISPUTED_ESCROW_SHOULD_EXIST");
        require(!_getEscrowDisputed(_escrowHash), "DISPUTED_ESCROW_SHOULD_NOT_BE_DISPUTED");
        address _arbiter = _getEscrowArbiter(_escrowHash);
        require(_arbiter != address(0), "DISPUTED_ARBITER_SHOULD_NOT_BE_EMPTY");
        require(!_saltWithEscrow2flagMapping[_encodedSaltWithEscrow], "DISPUTED_SUCH_SALT_SHOULD_NOT_EXIST");
        bytes memory _message = abi.encodePacked(
            _escrowHash,
            address(this),
            msg.sig,
            _expireAtBlock,
            _salt
        );
        address _signer = Signatures.getSignerFromSignature(keccak256(_message), _signature);
        require(_signer == _seller || _signer == _buyer, "DISPUTED_SIGNER_SHOULD_BE_BUYER_OR_SELLER");
        require(block.number < _expireAtBlock, "DISPUTED_TX_SHOULD_NOT_BE_EXPIRED");

        _saltWithEscrow2flagMapping[_encodedSaltWithEscrow] = true;
        _disputeInitiators[_escrowHash] = _signer;
        _setEscrowDisputed(_escrowHash, true);
        _emitDisputeRequested(_escrowHash, _arbiter);

        return OK;
    }

     
	 
	 
	 
	 
	 
	 
	 
	 
	 
    function cancelDispute(
        bytes32 _tradeRecordId,
        address _seller,
        address _buyer,
        uint _expireAtBlock,
        uint _salt,
        bytes _signature
    )
    external
    onlyRelay
    returns (uint)
    {
        bytes32 _escrowHash = _getEscrowHash(_tradeRecordId, _seller, _buyer);
        bytes32 _encodedSaltWithEscrow = _getEncodedSaltWithEscrowHash(_salt, _escrowHash);
        require(_getEscrowExists(_escrowHash), "DISPUTED_ESCROW_SHOULD_EXIST");
        require(_getEscrowDisputed(_escrowHash), "DISPUTED_ESCROW_SHOULD_BE_DISPUTED");
        require(!_saltWithEscrow2flagMapping[_encodedSaltWithEscrow], "DISPUTED_SUCH_SALT_SHOULD_NOT_EXIST");
        bytes memory _message = abi.encodePacked(
            _escrowHash,
            address(this),
            msg.sig,
            _expireAtBlock,
            _salt
        );
        address _signer = Signatures.getSignerFromSignature(keccak256(_message), _signature);
        require(_signer == _disputeInitiators[_escrowHash], "DISPUTED_SIGNER_SHOULD_BE_DISPUTE_INITIATOR");
        require(block.number < _expireAtBlock, "DISPUTED_TX_SHOULD_NOT_BE_EXPIRED");

        _saltWithEscrow2flagMapping[_encodedSaltWithEscrow] = true;
        _setEscrowDisputed(_escrowHash, false);
        delete _disputeInitiators[_escrowHash];
        _emitDisputeCanceled(_escrowHash);

        return OK;
    }

     
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
    function releaseDisputedPayment(
        bytes32 _tradeRecordId,
        address _seller,
        address _buyer,
        uint _buyerValue,
        uint _expireAtBlock,
        bytes _arbiterSignature
        ) external returns (uint);

    function getArbiter(bytes32 _tradeRecordId, address _seller, address _buyer) external view returns (address) {
        bytes32 _escrowHash = _getEscrowHash(_tradeRecordId, _seller, _buyer);
        return _getEscrowArbiter(_escrowHash);
    }

     
	 
	 
	 
	 
	 
	 
	 
	 
    function setArbiter(
        bytes32 _tradeRecordId,
        address _seller,
        address _buyer,
        address _arbiter,
        uint _expireAtBlock,
        uint _salt,
        bytes _bothSignatures
    )
    external
    onlyRelay
    returns (uint)
    {
        bytes32 _escrowHash = _getEscrowHash(_tradeRecordId, _seller, _buyer);
        bytes32 _encodedSaltWithEscrow = _getEncodedSaltWithEscrowHash(_salt, _escrowHash);
        require(_getEscrowExists(_escrowHash), "DISPUTED_ESCROW_SHOULD_EXIST");
        require(!_saltWithEscrow2flagMapping[_encodedSaltWithEscrow], "DISPUTED_SUCH_SALT_SHOULD_NOT_EXIST");
        bytes memory _message = abi.encodePacked(
            _escrowHash,
            address(this),
            msg.sig,
            _arbiter,
            _expireAtBlock,
            _salt
        );
        address[] memory _signers = Signatures.getSignersFromSignatures(keccak256(_message), _bothSignatures);
        require(
            _signers.length == 2 &&
            (
                (_signers[0] == _seller && _signers[1] == _buyer) ||
                (_signers[0] == _buyer && _signers[1] == _seller)
            ),
            "DISPUTED_SIGNERS_SHOULD_BE_BUYER_AND_SELLER");
        require(block.number < _expireAtBlock, "DISPUTED_TX_SHOULD_NOT_BE_EXPIRED");

        _saltWithEscrow2flagMapping[_encodedSaltWithEscrow] = true;
        _setEscrowArbiter(_escrowHash, _arbiter);
        _emitArbiterTransferred(_escrowHash, _arbiter);

        return OK;
    }

    function _setEscrowDisputed(bytes32 _escrowHash, bool _disputeStatus) internal;

    function _setEscrowArbiter(bytes32 _escrowHash, address _arbiter) internal;
}

 

 

pragma solidity ^0.4.25;


contract FeeApplicable is Object {

    uint constant MAX_FEE = 100;  
    uint constant FEE_PRECISION = 10000;  

    address private _serviceFeeAddress;
    uint16 private _serviceFee;

    modifier onlyFeeAdmin {
        require(_isFeeAdmin(msg.sender), "AF_IC");  
        _;
    }

    function getServiceFeeInfo() public view returns (address, uint16, uint) {
        return (_serviceFeeAddress, _serviceFee, FEE_PRECISION);
    }

    function setServiceFee(uint16 _feeValue) external onlyFeeAdmin returns (uint) {
        require(_feeValue <= MAX_FEE, "AF_IV");  
        _serviceFee = _feeValue;
    }

    function setServiceFeeAddress(address _feeReceiver) external onlyFeeAdmin returns (uint) {
        _serviceFeeAddress = _feeReceiver;
    }

    function _isFeeAdmin(address _account) internal view returns (bool);
}

 

 

pragma solidity ^0.4.25;


contract EscrowEmitter {
    event Created(bytes32 indexed tradeHash, bytes32 symbol, uint value);
    event Deposited(bytes32 indexed tradeHash, bytes32 symbol, uint value);
    event ReleasedPayment(bytes32 indexed tradeHash, bytes32 symbol, uint value);
    event Payback(bytes32 indexed tradeHash, bytes32 symbol, uint value);

    function _emitCreated(bytes32 _tradeHash, bytes32 _symbol, uint _value) internal {
        emit Created(_tradeHash, _symbol, _value);
    }

    function _emitDeposited(bytes32 _tradeHash, bytes32 _symbol, uint _value) internal {
        emit Deposited(_tradeHash, _symbol, _value);
    }

    function _emitReleasedPayment(bytes32 _tradeHash, bytes32 _symbol, uint _value) internal {
        emit ReleasedPayment(_tradeHash, _symbol, _value);
    }

    function _emitPayback(bytes32 _tradeHash, bytes32 _symbol, uint _value) internal {
        emit Payback(_tradeHash, _symbol, _value);
    }
}

 

 

pragma solidity ^0.4.25;


library Bits {

    uint constant internal ONE = uint(1);
    uint constant internal ONES = uint(~0);

     
     
    function setBit(uint self, uint8 index) internal pure returns (uint) {
        return self | ONE << index;
    }

     
     
    function clearBit(uint self, uint8 index) internal pure returns (uint) {
        return self & ~(ONE << index);
    }

     
     
     
     
    function toggleBit(uint self, uint8 index) internal pure returns (uint) {
        return self ^ ONE << index;
    }

     
    function bit(uint self, uint8 index) internal pure returns (uint8) {
        return uint8(self >> index & 1);
    }

     
     
     
     
    function bitSet(uint self, uint8 index) internal pure returns (bool) {
        return self >> index & 1 == 1;
    }

     
     
     
     
     
    function bitEqual(uint self, uint other, uint8 index) internal pure returns (bool) {
        return (self ^ other) >> index & 1 == 0;
    }

     
    function bitNot(uint self, uint8 index) internal pure returns (uint8) {
        return uint8(1 - (self >> index & 1));
    }

     
     
    function bitAnd(uint self, uint other, uint8 index) internal pure returns (uint8) {
        return uint8((self & other) >> index & 1);
    }

     
     
    function bitOr(uint self, uint other, uint8 index) internal pure returns (uint8) {
        return uint8((self | other) >> index & 1);
    }

     
     
    function bitXor(uint self, uint other, uint8 index) internal pure returns (uint8) {
        return uint8((self ^ other) >> index & 1);
    }

     
     
     
     
     
     
    function bits(uint self, uint8 startIndex, uint16 numBits) internal pure returns (uint) {
        require(0 < numBits && startIndex < 256 && startIndex + numBits <= 256);
        return self >> startIndex & ONES >> 256 - numBits;
    }

     
     
     
    function highestBitSet(uint self) internal pure returns (uint8 highest) {
        require(self != 0);
        uint val = self;
        for (uint8 i = 128; i >= 1; i >>= 1) {
            if (val & (ONE << i) - 1 << i != 0) {
                highest += i;
                val >>= i;
            }
        }
    }

     
     
     
    function lowestBitSet(uint self) internal pure returns (uint8 lowest) {
        require(self != 0);
        uint val = self;
        for (uint8 i = 128; i >= 1; i >>= 1) {
            if (val & (ONE << i) - 1 == 0) {
                lowest += i;
                val >>= i;
            }
        }
    }

}

 

 

pragma solidity ^0.4.25;



contract FeeConstants {

    using Bits for uint8;

    uint8 constant SELLER_FLAG_BIT_IDX = 0;
    uint8 constant BUYER_FLAG_BIT_IDX = 1;

    function _getSellerFeeFlag() internal pure returns (uint8 _feeStatus) {
        return uint8(_feeStatus.setBit(SELLER_FLAG_BIT_IDX));
    }

    function _getBuyerFeeFlag() internal pure returns (uint8 _feeStatus) {
        return uint8(_feeStatus.setBit(BUYER_FLAG_BIT_IDX));
    }

    function _getAllFeeFlag() internal pure returns (uint8 _feeStatus) {
        return uint8(uint8(_feeStatus
            .setBit(SELLER_FLAG_BIT_IDX))
            .setBit(BUYER_FLAG_BIT_IDX));
    }

    function _getNoFeeFlag() internal pure returns (uint8 _feeStatus) {
        return 0;
    }

    function _isFeeFlagAppliedFor(uint8 _feeStatus, uint8 _userBit) internal pure returns (bool) {
        return _feeStatus.bitSet(_userBit);
    }
}

 

 

pragma solidity ^0.4.25;


 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b, "SAFE_MATH_MUL");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SAFE_MATH_SUB");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SAFE_MATH_ADD");
        return c;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }
}

 

 

pragma solidity ^0.4.25;



library PercentCalculator {

    using SafeMath for uint;

    function getPercent(
        uint _value,
        uint _percent,
        uint _precision
    )
    internal
    pure
    returns (uint)
    {
        return _value.mul(_percent).div(_precision);
    }

    function getValueWithPercent(
        uint _value,
        uint _percent,
        uint _precision
    )
    internal
    pure
    returns (uint)
    {
        return _value.add(getPercent(_value, _percent, _precision));
    }

    function getFullValueFromPercentedValue(
        uint _value,
        uint _percent,
        uint _precision
    )
    internal
    pure
    returns (uint)
    {
        return _value.mul(_precision).div(_percent);
    }
}

 

 

pragma solidity ^0.4.25;










contract EscrowETH is
    EscrowBaseInterface,
    Disputed,
    FeeApplicable,
    EscrowEmitter,
    FeeConstants
{

    using SafeMath for uint;

    bytes32 constant ETH_SYMBOL = "ETH";

    uint private accumulatedFee;

    mapping(bytes32 => Escrow) private escrows;

    struct Escrow {
        bool exists;
        bool disputed;
        uint value;
        address arbiter;
    }

    function() external payable {
        revert("ESCROW_ETH_DOES_NOT_SUPPORT_ETH");
    }

    function getFeeBalance() public view returns (uint) {
        return accumulatedFee;
    }

     
     
     
     
     
     
     
     
     
     
     
     
    function createEscrow(
        bytes32 _tradeRecordId,
        address _seller,
        address _buyer,
        bytes32 _symbol,
        uint _value,
        uint _transferImmediatelyToBuyerAmount,
        uint8 _feeStatus
    )
    external
    payable
    onlyRelay
    returns (uint)
    {
        bytes32 _escrowHash = _getEscrowHash(_tradeRecordId, _seller, _buyer);
        Escrow storage _escrow = escrows[_escrowHash];
        require(!_escrow.exists, "ESCROW_ETH_ESCROW_SHOULD_NOT_EXIST");
        require(hasCurrencySupport(_symbol), "ESCROW_ETH_CURRENCY_SHOULD_BE_SUPPORTED");

        uint _valueWithoutFee = _value;
        if (_value > 0) {
            require(_value == msg.value && _value >= _transferImmediatelyToBuyerAmount, "ESCROW_ETH_VALUE_SHOULD_BE_CORRECT");
            _valueWithoutFee = _takeDepositFee(_value, _feeStatus);
            if (_transferImmediatelyToBuyerAmount > 0) {
                 
                _valueWithoutFee = _valueWithoutFee.sub(_transferImmediatelyToBuyerAmount);
                uint _transferImmediatelyToBuyerAmountWithoutFee = _takeWithdrawalFee(_transferImmediatelyToBuyerAmount, _feeStatus);
                _buyer.transfer(_transferImmediatelyToBuyerAmountWithoutFee);
            }
        }
        escrows[_escrowHash] = Escrow(true, false, _valueWithoutFee, address(0));
        _emitCreated(_escrowHash, ETH_SYMBOL, _valueWithoutFee);

        return OK;
    }

     
     
     
     
     
     
     
     
    function deposit(
        bytes32 _tradeRecordId,
        address _seller,
        address _buyer,
        uint _value,
        uint _transferImmediatelyToBuyerAmount,  
        uint8 _feeStatus
    )
    external
    payable
    onlyRelay
    returns (uint)
    {
        bytes32 _escrowHash = _getEscrowHash(_tradeRecordId, _seller, _buyer);
        Escrow storage _escrow = escrows[_escrowHash];
        require(_escrow.exists, "ESCROW_ETH_ESCROW_SHOULD_EXIST");
        require(!_escrow.disputed, "ESCROW_ETH_ESCROW_SHOULD_NOT_BE_DISPUTED");
        require(msg.value == _value && msg.value > 0 && _value >= _transferImmediatelyToBuyerAmount, "ESCROW_ETH_VALUE_SHOULD_BE_CORRECT");

        uint _valueWithoutFee = _takeDepositFee(_value, _feeStatus);
        if (_transferImmediatelyToBuyerAmount > 0) {
             
            _valueWithoutFee = _valueWithoutFee.sub(_transferImmediatelyToBuyerAmount);
            uint _transferImmediatelyToBuyerAmountWithoutFee = _takeWithdrawalFee(_transferImmediatelyToBuyerAmount, _feeStatus);
            _buyer.transfer(_transferImmediatelyToBuyerAmountWithoutFee);
        }
        _escrow.value = _escrow.value.add(_valueWithoutFee);
        _emitDeposited(_escrowHash, ETH_SYMBOL, _valueWithoutFee);

        return OK;
    }

     
     
     
     
     
     
     
     
     
     
     
     
    function releaseBuyerPayment(
        bytes32 _tradeRecordId,
        address _seller,
        address _buyer,
        uint _value,
        uint _expireAtBlock,
        uint _salt,
        bytes _sellerSignature,
        uint8 _feeStatus
    )
    external
    onlyRelay
    returns (uint)
    {
        bytes32 _escrowHash = _getEscrowHash(_tradeRecordId, _seller, _buyer);
        Escrow storage _escrow = escrows[_escrowHash];
        bytes32 _encodedSaltWithEscrow = _getEncodedSaltWithEscrowHash(_salt, _escrowHash);
        require(_escrow.exists, "ESCROW_ETH_ESCROW_SHOULD_EXIST");
        require(!_escrow.disputed, "ESCROW_ETH_ESCROW_SHOULD_NOT_BE_DISPUTED");
        require(!_saltWithEscrow2flagMapping[_encodedSaltWithEscrow], "ESCROW_ETH_SUCH_SALT_SHOULD_NOT_EXIST");
        _assertSeller(_escrowHash, _seller, _value, _expireAtBlock, _salt, _sellerSignature);
        require(block.number < _expireAtBlock, "ESCROW_ETH_TX_SHOULD_NOT_BE_EXPIRED");
        require(_escrow.value >= _value && _value > 0, "ESCROW_ETH_VALUE_SHOULD_BE_CORRECT");

        _saltWithEscrow2flagMapping[_encodedSaltWithEscrow] = true;
        _escrow.value = _escrow.value.sub(_value);
        uint _valueWithoutFee = _takeWithdrawalFee(_value, _feeStatus);
        _buyer.transfer(_valueWithoutFee);
        _emitReleasedPayment(_escrowHash, ETH_SYMBOL, _valueWithoutFee);

        return OK;
    }

    function _assertSeller(
        bytes32 _escrowHash,
        address _seller,
        uint _value,
        uint _expireAtBlock,
        uint _salt,
        bytes _sellerSignature
    )
    private
    view
    {
        bytes memory _message = abi.encodePacked(
            _escrowHash,
            address(this),
            msg.sig,
            _value,
            _expireAtBlock,
            _salt
        );
        address _signer = Signatures.getSignerFromSignature(keccak256(_message), _sellerSignature);
        require(_signer == _seller, "ESCROW_ETH_SIGNER_SHOULD_BE_SELLER");
    }


     
     
     
     
     
     
     
     
     
     
     
    function sendSellerPayback(
        bytes32 _tradeRecordId,
        address _seller,
        address _buyer,
        uint _value,
        uint _expireAtBlock,
        uint _salt,
        bytes _buyerSignature
    )
    external
    onlyRelay
    returns (uint)
    {
        bytes32 _escrowHash = _getEscrowHash(_tradeRecordId, _seller, _buyer);
        Escrow storage _escrow = escrows[_escrowHash];
        bytes32 _encodedSaltWithEscrow = _getEncodedSaltWithEscrowHash(_salt, _escrowHash);
        require(_escrow.exists, "ESCROW_ETH_ESCROW_SHOULD_EXIST");
        require(!_escrow.disputed, "ESCROW_ETH_ESCROW_SHOULD_NOT_BE_DISPUTED");
        require(!_saltWithEscrow2flagMapping[_encodedSaltWithEscrow], "ESCROW_ETH_SUCH_SALT_SHOULD_NOT_EXIST");
        bytes memory _message = abi.encodePacked(
            _escrowHash,
            address(this),
            msg.sig,
            _value,
            _expireAtBlock,
            _salt
        );
        address _signer = Signatures.getSignerFromSignature(keccak256(_message), _buyerSignature);
        require(_signer == _buyer, "ESCROW_ETH_SIGNER_SHOULD_BE_BUYER");
        require(block.number < _expireAtBlock, "ESCROW_ETH_TX_SHOULD_NOT_BE_EXPIRED");
        require(_escrow.value >= _value && _value > 0, "ESCROW_ETH_VALUE_SHOULD_BE_CORRECT");

        _saltWithEscrow2flagMapping[_encodedSaltWithEscrow] = true;
        _escrow.value = _escrow.value.sub(_value);
        _seller.transfer(_value);
        _emitPayback(_escrowHash, ETH_SYMBOL, _value);

        return OK;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
    function releaseNegotiatedPayment(
        bytes32 _tradeRecordId,
        address _seller,
        address _buyer,
        uint _sellerValue,
        uint _buyerValue,
        uint _expireAtBlock,
        uint _salt,
        bytes _signatures,
        uint8 _feeStatus
    )
    external
    onlyRelay
    returns (uint)
    {
        bytes32 _escrowHash = _getEscrowHash(_tradeRecordId, _seller, _buyer);
        Escrow storage _escrow = escrows[_escrowHash];
        require(_escrow.exists, "ESCROW_ETH_ESCROW_SHOULD_EXIST");
        require(!_escrow.disputed, "ESCROW_ETH_ESCROW_SHOULD_NOT_BE_DISPUTED");
        require(!_saltWithEscrow2flagMapping[_getEncodedSaltWithEscrowHash(_salt, _escrowHash)], "ESCROW_ETH_SUCH_SALT_SHOULD_NOT_EXIST");
        _assertSellerAndBuyer(_escrowHash, _seller, _buyer, _sellerValue, _buyerValue, _expireAtBlock, _salt, _signatures);
        require(block.number < _expireAtBlock, "ESCROW_ETH_TX_SHOULD_NOT_BE_EXPIRED");
        require(_escrow.value >= _sellerValue.add(_buyerValue) && _sellerValue.add(_buyerValue) > 0, "ESCROW_ETH_VALUE_SHOULD_BE_CORRECT");

        _saltWithEscrow2flagMapping[_getEncodedSaltWithEscrowHash(_salt, _escrowHash)] = true;
        _escrow.value = _escrow.value.sub(_sellerValue.add(_buyerValue));
        _seller.transfer(_sellerValue);
        uint _buyerValueWithoutFee = _takeWithdrawalFee(_buyerValue, _feeStatus);
        _buyer.transfer(_buyerValueWithoutFee);
        _emitPayback(_escrowHash, ETH_SYMBOL, _sellerValue);
        _emitReleasedPayment(_escrowHash, ETH_SYMBOL, _buyerValueWithoutFee);

        return OK;
    }

    function _assertSellerAndBuyer(
        bytes32 _escrowHash,
        address _seller,
        address _buyer,
        uint _sellerValue,
        uint _buyerValue,
        uint _expireAtBlock,
        uint _salt,
        bytes _signatures
    )
    private
    view
    {
        bytes memory _message = abi.encodePacked(
            _escrowHash,
            address(this),
            msg.sig,
            _sellerValue,
            _buyerValue,
            _expireAtBlock,
            _salt
        );
        address[] memory _signers = Signatures.getSignersFromSignatures(keccak256(_message), _signatures);
        require(_signers.length == 2 && ((_signers[0] == _seller && _signers[1] == _buyer) ||
            (_signers[0] == _buyer && _signers[1] == _seller)), "ESCROW_ETH_SIGNERS_SHOULD_BE_BUYER_AND_SELLER");
    }

     
     
     
     
     
     
     
     
     
     
     
    function releaseDisputedPayment(
        bytes32 _tradeRecordId,
        address _seller,
        address _buyer,
        uint _buyerValue,
        uint _expireAtBlock,
        bytes _arbiterSignature
    )
    external
    onlyRelay
    returns (uint)
    {
        bytes32 _escrowHash = _getEscrowHash(_tradeRecordId, _seller, _buyer);
        Escrow storage _escrow = escrows[_escrowHash];
        require(_escrow.exists, "ESCROW_ETH_ESCROW_SHOULD_EXIST");
        require(_escrow.disputed, "ESCROW_ETH_ESCROW_SHOULD_BE_DISPUTED");
        bytes memory _message = abi.encodePacked(
            _escrowHash,
            address(this),
            msg.sig,
            _buyerValue,
            _expireAtBlock
        );
        address _signer = Signatures.getSignerFromSignature(keccak256(_message), _arbiterSignature);
        require(_signer == _escrow.arbiter, "ESCROW_ETH_SIGNER_SHOULD_BE_ARBITER");
        require(block.number < _expireAtBlock, "ESCROW_ETH_TX_SHOULD_NOT_BE_EXPIRED");
        require(_buyerValue <= _escrow.value, "ESCROW_ETH_VALUE_SHOULD_BE_CORRECT");

        if (_buyerValue < _escrow.value) {
            uint _sellerValue = _escrow.value.sub(_buyerValue);
            _seller.transfer(_sellerValue);
            _emitPayback(_escrowHash, ETH_SYMBOL, _sellerValue);
        }
        uint _buyerValueWithoutFee = _takeWithdrawalFee(_buyerValue);
        _buyer.transfer(_buyerValueWithoutFee);

        _deleteEscrow(_escrowHash);
        delete _disputeInitiators[_escrowHash];
        _emitReleasedPayment(_escrowHash, ETH_SYMBOL, _buyerValueWithoutFee);
        _emitDisputeCanceled(_escrowHash);

        return OK;
    }

     
     
     
     
     
    function deleteEscrow(
        bytes32 _tradeRecordId,
        address _seller,
        address _buyer
    ) external returns (uint) {
        bytes32 _escrowHash = _getEscrowHash(_tradeRecordId, _seller, _buyer);
        Escrow storage _escrow = escrows[_escrowHash];
        if (_escrow.exists && _escrow.value == 0) {
            _deleteEscrow(_escrowHash);
        }

        return OK;
    }

    function _deleteEscrow(bytes32 _escrowHash) private {
        delete escrows[_escrowHash];
    }

     
     
     
     
    function _takeDepositFee(uint _value, uint8 _feeStatus) private returns (uint _valueToDeposit) {
        _valueToDeposit = _value;
        bool _isActivatedRelay = isActivatedRelay();
        (, uint16 _serviceFeeValue, uint _feePrecision) = getServiceFeeInfo();
        if (_serviceFeeValue > 0 && (!_isActivatedRelay || (_isActivatedRelay && _isFeeFlagAppliedFor(_feeStatus, SELLER_FLAG_BIT_IDX)))) {
            _valueToDeposit = PercentCalculator.getFullValueFromPercentedValue(_value, _feePrecision.add(_serviceFeeValue), _feePrecision);
            uint _feeValue = _value.sub(_valueToDeposit);
            accumulatedFee = accumulatedFee.add(_feeValue);
        }
    }

     
     
     
     
    function _takeWithdrawalFee(uint _value, uint8 _feeStatus) private returns (uint) {
        bool _isActivatedRelay = isActivatedRelay();
        if (!_isActivatedRelay || (_isActivatedRelay && _isFeeFlagAppliedFor(_feeStatus, BUYER_FLAG_BIT_IDX))) {
            return _takeWithdrawalFee(_value);
        }
        return _value;
    }

    function _takeWithdrawalFee(uint _value) private returns (uint) {
        (, uint16 _serviceFeeValue, uint _feePrecision) = getServiceFeeInfo();
        if (_serviceFeeValue > 0) {
            uint _feeValue = PercentCalculator.getPercent(_value, _serviceFeeValue, _feePrecision);
            _value = _value.sub(_feeValue);
            accumulatedFee = accumulatedFee.add(_feeValue);
        }
        return _value;
    }

     
    function withdrawFee() external onlyContractOwner {
        (address _feeDestinationAddress,,) = getServiceFeeInfo();
        require(_feeDestinationAddress != 0x0, "ESCROW_ETH_INVALID_SERVICE_FEE_ADDRESS");

        if (accumulatedFee > 0) {
            uint _accumulatedFee = accumulatedFee;
            accumulatedFee = 0;
            _feeDestinationAddress.transfer(_accumulatedFee);
        }
    }

	function retranslateToFeeRecipient(bytes32 _symbol, address  , uint _amount) external payable returns (uint) {
        require(hasCurrencySupport(_symbol), "ESCROW_ETH_CURRENCY_SHOULD_BE_SUPPORTED");
        require(msg.value == _amount, "ESCROW_ETH_VALUE_SHOULD_BE_CORRECT");

        accumulatedFee = accumulatedFee.add(_amount);

        return OK;
    }

    function hasCurrencySupport(bytes32 _symbol) public view returns (bool) {
        return _symbol == ETH_SYMBOL;
    }

    function _isFeeAdmin(address _account) internal view returns (bool) {
        return contractOwner == _account;
    }

    function _getEscrowExists(bytes32 _escrowHash) internal view returns(bool) {
        Escrow storage _escrow = escrows[_escrowHash];
        return _escrow.exists;
    }

    function _getEscrowDisputed(bytes32 _escrowHash) internal view returns(bool) {
        Escrow storage _escrow = escrows[_escrowHash];
        return _escrow.disputed;
    }

    function _getEscrowSymbol(bytes32  ) internal view returns(bytes32) {
        return ETH_SYMBOL;
    }

    function _getEscrowValue(bytes32 _escrowHash) internal view returns(uint) {
        Escrow storage _escrow = escrows[_escrowHash];
        return _escrow.value;
    }

    function _getEscrowArbiter(bytes32 _escrowHash) internal view returns(address) {
        Escrow storage _escrow = escrows[_escrowHash];
        return _escrow.arbiter;
    }

    function _setEscrowDisputed(bytes32 _escrowHash, bool _disputeStatus) internal {
        Escrow storage _escrow = escrows[_escrowHash];
        _escrow.disputed = _disputeStatus;
    }

    function _setEscrowArbiter(bytes32 _escrowHash, address _arbiter) internal {
        Escrow storage _escrow = escrows[_escrowHash];
        _escrow.arbiter = _arbiter;
    }
}