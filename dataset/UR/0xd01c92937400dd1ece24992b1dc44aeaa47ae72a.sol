 

pragma solidity ^0.4.24;


 

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START  = 0xb8;
    uint8 constant LIST_SHORT_START   = 0xc0;
    uint8 constant LIST_LONG_START    = 0xf8;

    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint len;
        uint memPtr;
    }

     
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        if (item.length == 0)
            return RLPItem(0, 0);

        uint memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

     
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory result) {
        require(isList(item));

        uint items = numItems(item);
        result = new RLPItem[](items);

        uint memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint dataLen;
        for (uint i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }
    }

     

     
    function isList(RLPItem memory item) internal pure returns (bool) {
        uint8 byte0;
        uint memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START)
            return false;
        return true;
    }

     
    function numItems(RLPItem memory item) internal pure returns (uint) {
        uint count = 0;
        uint currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
            currPtr = currPtr + _itemLength(currPtr);  
            count++;
        }

        return count;
    }

     
    function _itemLength(uint memPtr) internal pure returns (uint len) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START)
            return 1;

        else if (byte0 < STRING_LONG_START)
            return byte0 - STRING_SHORT_START + 1;

        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7)  
                memPtr := add(memPtr, 1)  

             
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen)))  
                len := add(dataLen, add(byteLen, 1))
            }
        }

        else if (byte0 < LIST_LONG_START) {
            return byte0 - LIST_SHORT_START + 1;
        }

        else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen)))  
                len := add(dataLen, add(byteLen, 1))
            }
        }
    }

     
    function _payloadOffset(uint memPtr) internal pure returns (uint) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START)
            return 0;
        else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START))
            return 1;
        else if (byte0 < LIST_SHORT_START)   
            return byte0 - (STRING_LONG_START - 1) + 1;
        else
            return byte0 - (LIST_LONG_START - 1) + 1;
    }

     

    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1, "Invalid RLPItem. Booleans are encoded in 1 byte");
        uint result;
        uint memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        return result == 0 ? false : true;
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
         
        require(item.len == 21, "Invalid RLPItem. Addresses are encoded in 20 bytes");

        uint memPtr = item.memPtr + 1;  
        uint addr;
        assembly {
            addr := div(mload(memPtr), exp(256, 12))  
        }

        return address(addr);
    }

    function toUint(RLPItem memory item) internal pure returns (uint) {
        uint offset = _payloadOffset(item.memPtr);
        uint len = item.len - offset;
        uint memPtr = item.memPtr + offset;

        uint result;
        assembly {
            result := div(mload(memPtr), exp(256, sub(32, len)))  
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes) {
        uint offset = _payloadOffset(item.memPtr);
        uint len = item.len - offset;  
        bytes memory result = new bytes(len);

        uint destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(item.memPtr + offset, destPtr, len);
        return result;
    }


     
    function copy(uint src, uint dest, uint len) internal pure {
         
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

         
        uint mask = 256 ** (WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))  
            let destpart := and(mload(dest), mask)  
            mstore(dest, or(destpart, srcpart))
        }
    }
}

library RLPWriter {
    function toRlp(bytes memory _value) internal pure returns (bytes memory _bytes) {
        uint _valuePtr;
        uint _rplPtr;
        uint _valueLength = _value.length;

        assembly {
            _valuePtr := add(_value, 0x20)
            _bytes := mload(0x40)                    
            _rplPtr := add(_bytes, 0x20)             
        }

         
        if (_valueLength == 1 && _value[0] <= 0x7f) {
            assembly {
                mstore(_bytes, 1)                    
                mstore(_rplPtr, mload(_valuePtr))   
                mstore(0x40, add(_rplPtr, 1))        
            }
            return;
        }

         
        if (_valueLength <= 55) {
            assembly {
                mstore(_bytes, add(1, _valueLength))             
                mstore8(_rplPtr, add(0x80, _valueLength))        
                mstore(0x40, add(add(_rplPtr, 1), _valueLength))  
            }

            copy(_valuePtr, _rplPtr + 1, _valueLength);
            return;
        }

         
        uint _lengthSize = uintMinimalSize(_valueLength);

        assembly {
            mstore(_bytes, add(add(1, _lengthSize), _valueLength))   
            mstore8(_rplPtr, add(0xb7, _lengthSize))                 
            mstore(add(_rplPtr, 1), mul(_valueLength, exp(256, sub(32, _lengthSize))))  
            mstore(0x40, add(add(add(_rplPtr, 1), _lengthSize), _valueLength))   
        }

        copy(_valuePtr, _rplPtr + 1 + _lengthSize, _valueLength);
        return;
    }

    function toRlp(uint _value) internal pure returns (bytes memory _bytes) {
        uint _size = uintMinimalSize(_value);

        bytes memory _valueBytes = new bytes(_size);

        assembly {
            mstore(add(_valueBytes, 0x20), mul(_value, exp(256, sub(32, _size))))
        }

        return toRlp(_valueBytes);
    }

    function toRlp(bytes[] memory _values) internal pure returns (bytes memory _bytes) {
        uint _ptr;
        uint _size;
        uint i;

         
        for(; i < _values.length; ++i)
            _size += _values[i].length;

         
        assembly {
            _bytes := mload(0x40)
            _ptr := add(_bytes, 0x20)
        }

        if (_size <= 55) {
            assembly {
                mstore8(_ptr, add(0xc0, _size))
                _ptr := add(_ptr, 1)
            }
        } else {
            uint _size2 = uintMinimalSize(_size);

            assembly {
                mstore8(_ptr, add(0xf7, _size2))
                _ptr := add(_ptr, 1)
                mstore(_ptr, mul(_size, exp(256, sub(32, _size2))))
                _ptr := add(_ptr, _size2)
            }
        }

         
        for(i = 0; i < _values.length; ++i) {
            bytes memory _val = _values[i];
            uint _valPtr;

            assembly {
                _valPtr := add(_val, 0x20)
            }

            copy(_valPtr, _ptr, _val.length);

            _ptr += _val.length;
        }

        assembly {
            mstore(0x40, _ptr)
            mstore(_bytes, sub(sub(_ptr, _bytes), 0x20))
        }
    }

    function uintMinimalSize(uint _value) internal pure returns (uint _size) {
        for (; _value != 0; _size++)
            _value /= 256;
    }

     
    function copy(uint src, uint dest, uint len) internal pure {
         
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }

            src += 32;
            dest += 32;
        }

         
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))  
            let destpart := and(mload(dest), mask)  
            mstore(dest, or(destpart, srcpart))
        }
    }
}


library AuctionityLibraryDecodeRawTx {

    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    function decodeRawTxGetBiddingInfo(bytes memory _signedRawTxBidding, uint8 _chainId) internal pure returns (bytes32 _hashRawTxTokenTransfer, address _auctionContractAddress, uint256 _bidAmount, address _signerBid) {

        bytes memory _auctionBidlData;
        RLPReader.RLPItem[] memory _signedRawTxBiddingRLPItem = _signedRawTxBidding.toRlpItem().toList();

        _auctionContractAddress = _signedRawTxBiddingRLPItem[3].toAddress();
        _auctionBidlData = _signedRawTxBiddingRLPItem[5].toBytes();

        bytes4 _selector;
        assembly { _selector := mload(add(_auctionBidlData,0x20))}

        _signerBid = getSignerFromSignedRawTxRLPItemp(_signedRawTxBiddingRLPItem,_chainId);

         
        if(_selector == 0x1d03ae68 ) {

            assembly {
                _bidAmount := mload(add(_auctionBidlData,add(4,0x20)))
                _hashRawTxTokenTransfer := mload(add(_auctionBidlData,add(68,0x20)))
            }

        }

    }



    function decodeRawTxGetCreateAuctionInfo(bytes memory _signedRawTxCreateAuction, uint8 _chainId) internal pure returns (
        bytes32 _tokenHash,
        address _auctionFactoryContractAddress,
        address _signerCreate,
        address _tokenContractAddress,
        uint256 _tokenId,
        uint8 _rewardPercent
    ) {

        bytes memory _createAuctionlData;
        RLPReader.RLPItem[] memory _signedRawTxCreateAuctionRLPItem = _signedRawTxCreateAuction.toRlpItem().toList();


        _auctionFactoryContractAddress = _signedRawTxCreateAuctionRLPItem[3].toAddress();
        _createAuctionlData = _signedRawTxCreateAuctionRLPItem[5].toBytes();


        _signerCreate = getSignerFromSignedRawTxRLPItemp(_signedRawTxCreateAuctionRLPItem,_chainId);

        bytes memory _signedRawTxTokenTransfer;

        (_signedRawTxTokenTransfer, _tokenContractAddress,_tokenId,_rewardPercent) = decodeRawTxGetCreateAuctionInfoData( _createAuctionlData);



        _tokenHash = keccak256(_signedRawTxTokenTransfer);

    }

    function decodeRawTxGetCreateAuctionInfoData(bytes memory _createAuctionlData) internal pure returns(
        bytes memory _signedRawTxTokenTransfer,
        address _tokenContractAddress,
        uint256 _tokenId,
        uint8 _rewardPercent
    ) {
        bytes4 _selector;
        assembly { _selector := mload(add(_createAuctionlData,0x20))}

        uint _positionOfSignedRawTxTokenTransfer;
        uint _sizeOfSignedRawTxTokenTransfer;

         
        if(_selector == 0xffd6d828) {

            assembly {
                _positionOfSignedRawTxTokenTransfer := mload(add(_createAuctionlData,add(4,0x20)))
                _sizeOfSignedRawTxTokenTransfer := mload(add(_createAuctionlData,add(add(_positionOfSignedRawTxTokenTransfer,4),0x20)))

             
                _tokenContractAddress := mload(add(_createAuctionlData,add(add(mul(1,32),4),0x20)))
             
                _tokenId := mload(add(_createAuctionlData,add(add(mul(2,32),4),0x20)))
             
                _rewardPercent := mload(add(_createAuctionlData,add(add(mul(5,32),4),0x20)))

            }

            _signedRawTxTokenTransfer = new bytes(_sizeOfSignedRawTxTokenTransfer);

            for (uint i = 0; i < _sizeOfSignedRawTxTokenTransfer; i++) {
                _signedRawTxTokenTransfer[i] = _createAuctionlData[i + _positionOfSignedRawTxTokenTransfer + 4 + 32 ];
            }

        }

    }

    function ecrecoverSigner(
        bytes32 _hashTx,
        bytes _rsvTx,
        uint offset
    ) internal pure returns (address ecrecoverAddress){

        bytes32 r;
        bytes32 s;
        bytes1 v;

        assembly {
            r := mload(add(_rsvTx,add(offset,0x20)))
            s := mload(add(_rsvTx,add(offset,0x40)))
            v := mload(add(_rsvTx,add(offset,0x60)))
        }

        ecrecoverAddress = ecrecover(
            _hashTx,
            uint8(v),
            r,
            s
        );
    }



    function decodeRawTxGetWithdrawalInfo(bytes memory _signedRawTxWithdrawal, uint8 _chainId) internal pure returns (address withdrawalSigner, uint256 withdrawalAmount) {

        bytes4 _selector;
        bytes memory _withdrawalData;
        RLPReader.RLPItem[] memory _signedRawTxWithdrawalRLPItem = _signedRawTxWithdrawal.toRlpItem().toList();

        _withdrawalData = _signedRawTxWithdrawalRLPItem[5].toBytes();

        assembly { _selector := mload(add(_withdrawalData,0x20))}

        withdrawalSigner = getSignerFromSignedRawTxRLPItemp(_signedRawTxWithdrawalRLPItem,_chainId);

         
        if(_selector == 0x835fc6ca ) {

            assembly {
                withdrawalAmount := mload(add(_withdrawalData,add(4,0x20)))
            }

        }

    }



    function getSignerFromSignedRawTxRLPItemp(RLPReader.RLPItem[] memory _signedTxRLPItem, uint8 _chainId) internal pure returns (address ecrecoverAddress) {
        bytes memory _rawTx;
        bytes memory _rsvTx;

        (_rawTx, _rsvTx ) = explodeSignedRawTxRLPItem(_signedTxRLPItem, _chainId);
        return ecrecoverSigner(keccak256(_rawTx), _rsvTx,0);
    }

    function explodeSignedRawTxRLPItem(RLPReader.RLPItem[] memory _signedTxRLPItem, uint8 _chainId) internal pure returns (bytes memory _rawTx,bytes memory _rsvTx){

        bytes[] memory _signedTxRLPItemRaw = new bytes[](9);

        _signedTxRLPItemRaw[0] = RLPWriter.toRlp(_signedTxRLPItem[0].toBytes());
        _signedTxRLPItemRaw[1] = RLPWriter.toRlp(_signedTxRLPItem[1].toBytes());
        _signedTxRLPItemRaw[2] = RLPWriter.toRlp(_signedTxRLPItem[2].toBytes());
        _signedTxRLPItemRaw[3] = RLPWriter.toRlp(_signedTxRLPItem[3].toBytes());
        _signedTxRLPItemRaw[4] = RLPWriter.toRlp(_signedTxRLPItem[4].toBytes());
        _signedTxRLPItemRaw[5] = RLPWriter.toRlp(_signedTxRLPItem[5].toBytes());

        _signedTxRLPItemRaw[6] = RLPWriter.toRlp(_chainId);
        _signedTxRLPItemRaw[7] = RLPWriter.toRlp(0);
        _signedTxRLPItemRaw[8] = RLPWriter.toRlp(0);

        _rawTx = RLPWriter.toRlp(_signedTxRLPItemRaw);

        uint8 i;
        _rsvTx = new bytes(65);

        bytes32 tmp = bytes32(_signedTxRLPItem[7].toUint());
        for (i = 0; i < 32; i++) {
            _rsvTx[i] = tmp[i];
        }

        tmp = bytes32(_signedTxRLPItem[8].toUint());

        for (i = 0; i < 32; i++) {
            _rsvTx[i + 32] = tmp[i];
        }

        _rsvTx[64] = bytes1(_signedTxRLPItem[6].toUint() - uint(_chainId * 2) - 8);

    }

}
library AuctionityLibraryDeposit{

    function sendTransfer(address _tokenContractAddress, bytes memory _transfer, uint _offset) internal returns (bool){

        if(!isContract(_tokenContractAddress)){
            return false;
        }

        uint8 _numberOfTransfer = uint8(_transfer[_offset]);

        _offset += 1;

        bool _success;
        for (uint8 i = 0; i < _numberOfTransfer; i++){
            (_offset,_success) = decodeTransferCall(_tokenContractAddress, _transfer,_offset);
            
            if(!_success) {
                return false;
            }
        }

        return true;

    }

    function decodeTransferCall(address _tokenContractAddress, bytes memory _transfer, uint _offset) internal returns (uint, bool) {


        bytes memory _sizeOfCallBytes;
        bytes memory _callData;

        uint _sizeOfCallUint;

        if(_transfer[_offset] == 0xb8) {
            _sizeOfCallBytes = new bytes(1);
            _sizeOfCallBytes[0] = bytes1(_transfer[_offset + 1]);

            _offset+=2;
        }
        if(_transfer[_offset] == 0xb9) {

            _sizeOfCallBytes = new bytes(2);
            _sizeOfCallBytes[0] = bytes1(_transfer[_offset + 1]);
            _sizeOfCallBytes[1] = bytes1(_transfer[_offset + 2]);
            _offset+=3;
        }

        _sizeOfCallUint = bytesToUint(_sizeOfCallBytes);

        _callData = new bytes(_sizeOfCallUint);
        for (uint j = 0; j < _sizeOfCallUint; j++) {
            _callData[j] = _transfer[(j + _offset)];
        }

        _offset+=_sizeOfCallUint;

        return (_offset, sendCallData(_tokenContractAddress, _sizeOfCallUint, _callData));


    }

    function sendCallData(address _tokenContractAddress, uint _sizeOfCallUint, bytes memory _callData) internal returns (bool) {

        bool _success;
        bytes4 sig;

        assembly {

            let _ptr := mload(0x40)
            sig := mload(add(_callData,0x20))

            mstore(_ptr,sig)  
            for { let i := 0x04 } lt(i, _sizeOfCallUint) { i := add(i, 0x20) } {
                mstore(add(_ptr,i),mload(add(_callData,add(0x20,i))))  
            }


            _success := call(       
            sub (gas, 10000),  
            _tokenContractAddress,  
            0,     
            _ptr,     
            _sizeOfCallUint,  
            _ptr,     
            0x20)  

        }

        return _success;
    }

    
    function isContract(address _contractAddress) internal view returns (bool) {
        uint _size;
        assembly { _size := extcodesize(_contractAddress) }
        return _size > 0;
    }

    function bytesToUint(bytes b) internal pure returns (uint256){
        uint256 _number;
        for(uint i=0;i<b.length;i++){
            _number = _number + uint(b[i])*(2**(8*(b.length-(i+1))));
        }
        return _number;
    }

}

contract AuctionityDepositEth {
    using SafeMath for uint256;

    string public version = "deposit-eth-v1";

    address public owner;
    address public oracle;
    uint8 public ethereumChainId;
    uint8 public auctionityChainId;
    bool public migrationLock;
    bool public maintenanceLock;

    mapping (address => uint256) public depotEth;   

    bytes32[] public withdrawalVoucherList;                      
    mapping (bytes32 => bool) public withdrawalVoucherSubmitted;  

    bytes32[] public auctionEndVoucherList;                      
    mapping (bytes32 => bool) public auctionEndVoucherSubmitted;  

    struct InfoFromCreateAuction {
        bytes32 tokenHash;
        address tokenContractAddress;
        address auctionSeller;
        uint8 rewardPercent;
        uint256 tokenId;
    }

    struct InfoFromBidding {
        address auctionContractAddress;
        address signer;
        uint256 amount;
    }

     
    event LogDeposed(address user, uint256 amount);
    event LogWithdrawalVoucherSubmitted(address user, uint256 amount, bytes32 withdrawalVoucherHash);

    event LogAuctionEndVoucherSubmitted(
        bytes32 tokenHash,
        address tokenContractAddress,
        uint256 tokenId,
        address indexed seller,
        address indexed winner,
        uint256 amount,
        bytes32 auctionEndVoucherHash
    );
    event LogSentEthToWinner(address auction, address user, uint256 amount);
    event LogSentEthToAuctioneer(address auction, address user, uint256 amount);
    event LogSentDepotEth(address user, uint256 amount);
    event LogSentRewardsDepotEth(address[] user, uint256[] amount);

    event LogError(string version,string error);
    event LogErrorWithData(string version, string error, bytes32[] data);


    constructor(uint8 _ethereumChainId, uint8 _auctionityChainId) public {
        ethereumChainId = _ethereumChainId;
        auctionityChainId = _auctionityChainId;
        owner = msg.sender;
    }

     
    modifier isOwner() {
        require(msg.sender == owner, "Sender must be owner");
        _;
    }

    modifier isOracle() {
        require(msg.sender == oracle, "Sender must be oracle");
        _;
    }

    function setOracle(address _oracle) public isOwner {
        oracle = _oracle;
    }

    modifier migrationLockable() {
        require(!migrationLock || msg.sender == owner, "MIGRATION_LOCKED");
        _;
    }

    function setMigrationLock(bool _lock) public isOwner {
        migrationLock = _lock;
    }

    modifier maintenanceLockable() {
        require(!maintenanceLock || msg.sender == owner, "MAINTENANCE_LOCKED");
        _;
    } 

    function setMaintenanceLock(bool _lock) public isOwner {
        maintenanceLock = _lock;
    }

     
    function addDepotEth(address _user, uint256 _amount) private returns (bool) {
        depotEth[_user] = depotEth[_user].add(_amount);
        return true;
    }

     
    function subDepotEth(address _user, uint256 _amount) private returns (bool) {
        if(depotEth[_user] < _amount){
            return false;
        }

        depotEth[_user] = depotEth[_user].sub(_amount);
        return true;
    }

     
    function getDepotEth(address _user) public view returns(uint256 _amount) {
        return depotEth[_user];
    }

     
    function() public payable {
        return depositEth();
    }

     
    function depositEth() public payable migrationLockable maintenanceLockable {
        bytes32[] memory _errorData;
        uint256 _amount = uint256(msg.value);
        require(_amount > 0, "Amount must be greater than 0");

        if(!addDepotEth(msg.sender, _amount)) {
            _errorData = new bytes32[](1);
            _errorData[0] = bytes32(_amount);
            emit LogErrorWithData(version, "DEPOSED_ADD_DATA_FAILED", _errorData);
            return;
        }

        emit LogDeposed(msg.sender, _amount);
    }

     
    function withdrawalVoucher(
        bytes memory _data,
        bytes memory _signedRawTxWithdrawal
    ) public maintenanceLockable {
        bytes32 _withdrawalVoucherHash = keccak256(_signedRawTxWithdrawal);

         
        if(withdrawalVoucherSubmitted[_withdrawalVoucherHash] == true) {
            emit LogError(version, "WITHDRAWAL_VOUCHER_ALREADY_SUBMITED");
            return;
        }

        address _withdrawalSigner;
        uint _withdrawalAmount;

        (_withdrawalSigner, _withdrawalAmount) = AuctionityLibraryDecodeRawTx.decodeRawTxGetWithdrawalInfo(_signedRawTxWithdrawal, auctionityChainId);
        
        if(_withdrawalAmount == uint256(0)) {
            emit LogError(version,'WITHDRAWAL_VOUCHER_AMOUNT_INVALID');
            return;
        }

        if(_withdrawalSigner == address(0)) {
            emit LogError(version,'WITHDRAWAL_VOUCHER_SIGNER_INVALID');
            return;
        }

         
        if(depotEth[_withdrawalSigner] < _withdrawalAmount) {
            emit LogError(version,'WITHDRAWAL_VOUCHER_DEPOT_AMOUNT_TOO_LOW');
            return;
        }

        if(!withdrawalVoucherOracleSignatureVerification(_data, _withdrawalSigner, _withdrawalAmount, _withdrawalVoucherHash)) {
            emit LogError(version,'WITHDRAWAL_VOUCHER_ORACLE_INVALID_SIGNATURE');
            return;
        }

         
        if(!_withdrawalSigner.send(_withdrawalAmount)) {
            emit LogError(version, "WITHDRAWAL_VOUCHER_ETH_TRANSFER_FAILED");
            return;
        }

        subDepotEth(_withdrawalSigner,_withdrawalAmount);

        withdrawalVoucherList.push(_withdrawalVoucherHash);
        withdrawalVoucherSubmitted[_withdrawalVoucherHash] = true;

        emit LogWithdrawalVoucherSubmitted(_withdrawalSigner,_withdrawalAmount, _withdrawalVoucherHash);
    }

    function withdrawalVoucherOracleSignatureVerification(
        bytes memory _data,
        address _withdrawalSigner,
        uint256 _withdrawalAmount,
        bytes32 _withdrawalVoucherHash
    ) internal view returns (bool)
    {

         
        return oracle == AuctionityLibraryDecodeRawTx.ecrecoverSigner(
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(
                        abi.encodePacked(
                            address(this),
                            _withdrawalSigner,
                            _withdrawalAmount,
                            _withdrawalVoucherHash
                        )
                    )
                )
            ),
            _data,
            0
        );
    }

     

    function auctionEndVoucher(
        bytes memory _data,
        bytes memory _signedRawTxCreateAuction,
        bytes memory _signedRawTxBidding,
        bytes memory _send
    ) public maintenanceLockable {
        bytes32 _auctionEndVoucherHash = keccak256(_signedRawTxCreateAuction);
         
        if(auctionEndVoucherSubmitted[_auctionEndVoucherHash] == true) {
            emit LogError(version, "AUCTION_END_VOUCHER_ALREADY_SUBMITED");
            return;
        }

        InfoFromCreateAuction memory _infoFromCreateAuction = getInfoFromCreateAuction(_signedRawTxCreateAuction);

        address _auctionContractAddress;
        address _winnerSigner;
        uint256 _winnerAmount;

        InfoFromBidding memory _infoFromBidding;

        if(_signedRawTxBidding.length > 1) {
            _infoFromBidding = getInfoFromBidding(_signedRawTxBidding, _infoFromCreateAuction.tokenHash);

            if(!verifyWinnerDepot(_infoFromBidding)) {
                return;
            }
        }

        if(!auctionEndVoucherOracleSignatureVerification(
            _data,
            keccak256(_send),
            _infoFromCreateAuction,
            _infoFromBidding
        )) {
            emit LogError(version, "AUCTION_END_VOUCHER_ORACLE_INVALID_SIGNATURE");
            return;
        }

        if(!AuctionityLibraryDeposit.sendTransfer(_infoFromCreateAuction.tokenContractAddress, _data, 97)){
            if(_data[97] > 0x01) { 
                revert("More than one transfer function to call");
            } else {
                emit LogError(version, "AUCTION_END_VOUCHER_TRANSFER_FAILED");
                return;
            }
        }

        if(_signedRawTxBidding.length > 1) {
            if(!sendExchange(_send, _infoFromCreateAuction, _infoFromBidding)) {
                return;
            }
        }


        auctionEndVoucherList.push(_auctionEndVoucherHash);
        auctionEndVoucherSubmitted[_auctionEndVoucherHash] = true;
        emit LogAuctionEndVoucherSubmitted(
            _infoFromCreateAuction.tokenHash,
            _infoFromCreateAuction.tokenContractAddress,
            _infoFromCreateAuction.tokenId,
            _infoFromCreateAuction.auctionSeller,
            _infoFromBidding.signer,
            _infoFromBidding.amount,
            _auctionEndVoucherHash
        );
    }

    function getInfoFromCreateAuction(bytes _signedRawTxCreateAuction) internal view returns
        (InfoFromCreateAuction memory _infoFromCreateAuction)
    {
        (
            _infoFromCreateAuction.tokenHash,
            ,
            _infoFromCreateAuction.auctionSeller,
            _infoFromCreateAuction.tokenContractAddress,
            _infoFromCreateAuction.tokenId,
            _infoFromCreateAuction.rewardPercent
        ) = AuctionityLibraryDecodeRawTx.decodeRawTxGetCreateAuctionInfo(_signedRawTxCreateAuction,auctionityChainId);
    }

    function getInfoFromBidding(bytes _signedRawTxBidding, bytes32 _hashSignedRawTxTokenTransfer) internal returns (InfoFromBidding memory _infoFromBidding) {
        bytes32 _hashRawTxTokenTransferFromBid;

        (
            _hashRawTxTokenTransferFromBid,
            _infoFromBidding.auctionContractAddress,
            _infoFromBidding.amount,
            _infoFromBidding.signer
        ) = AuctionityLibraryDecodeRawTx.decodeRawTxGetBiddingInfo(_signedRawTxBidding,auctionityChainId);

        if(_hashRawTxTokenTransferFromBid != _hashSignedRawTxTokenTransfer) {
            emit LogError(version, "AUCTION_END_VOUCHER_hashRawTxTokenTransfer_INVALID");
            return;
        }

        if(_infoFromBidding.amount == uint256(0)){
            emit LogError(version, "AUCTION_END_VOUCHER_BIDDING_AMOUNT_INVALID");
            return;
        }

    }    

    function verifyWinnerDepot(InfoFromBidding memory _infoFromBidding) internal returns(bool) {
         
        if(depotEth[_infoFromBidding.signer] < _infoFromBidding.amount) {
            emit LogError(version, "AUCTION_END_VOUCHER_DEPOT_AMOUNT_TOO_LOW");
            return false;
        }

        return true;
    }

    function sendExchange(
        bytes memory _send,
        InfoFromCreateAuction memory _infoFromCreateAuction,
        InfoFromBidding memory _infoFromBidding
    ) internal returns(bool) {
        if(!subDepotEth(_infoFromBidding.signer, _infoFromBidding.amount)){
            emit LogError(version, "AUCTION_END_VOUCHER_DEPOT_AMOUNT_TOO_LOW");
            return false;
        }

        uint offset;
        address _sendAddress;
        uint256 _sendAmount;
        bytes12 _sendAmountGwei;
        uint256 _sentAmount;

        assembly {
            _sendAddress := mload(add(_send,add(offset,0x14)))
            _sendAmount := mload(add(_send,add(add(offset,20),0x20)))
        }

        if(_sendAddress != _infoFromCreateAuction.auctionSeller){
            emit LogError(version, "AUCTION_END_VOUCHER_SEND_TO_SELLER_INVALID");
            return false;
        }

        _sentAmount += _sendAmount;
        offset += 52;

        if(!_sendAddress.send(_sendAmount)) {
            revert("Failed to send funds");
        }

        emit LogSentEthToWinner(_infoFromBidding.auctionContractAddress, _sendAddress, _sendAmount);

        if(_infoFromCreateAuction.rewardPercent > 0) {
            assembly {
                _sendAddress := mload(add(_send,add(offset,0x14)))
                _sendAmount := mload(add(_send,add(add(offset,20),0x20)))
            }

            _sentAmount += _sendAmount;
            offset += 52;

            if(!_sendAddress.send(_sendAmount)) {
                revert("Failed to send funds");
            }

            emit LogSentEthToAuctioneer(_infoFromBidding.auctionContractAddress, _sendAddress, _sendAmount);

            bytes2 _numberOfSendDepositBytes2;
            assembly {
                _numberOfSendDepositBytes2 := mload(add(_send,add(offset,0x20)))
            }

            offset += 2;

            address[] memory _rewardsAddress = new address[](uint16(_numberOfSendDepositBytes2));
            uint256[] memory _rewardsAmount = new uint256[](uint16(_numberOfSendDepositBytes2));

            for (uint16 i = 0; i < uint16(_numberOfSendDepositBytes2); i++){

                assembly {
                    _sendAddress := mload(add(_send,add(offset,0x14)))
                    _sendAmountGwei := mload(add(_send,add(add(offset,20),0x20)))
                }

                _sendAmount = uint96(_sendAmountGwei) * 1000000000;
                _sentAmount += _sendAmount;
                offset += 32;

                if(!addDepotEth(_sendAddress, _sendAmount)) {
                    revert("Can't add deposit");
                }

                _rewardsAddress[i] = _sendAddress;
                _rewardsAmount[i] = uint256(_sendAmount);
            }

            emit LogSentRewardsDepotEth(_rewardsAddress, _rewardsAmount);
        }

        if(uint256(_infoFromBidding.amount) != _sentAmount) {
            revert("Bidding amount is not equal to sent amount");
        }

        return true;
    }

    function getTransferDataHash(bytes memory _data) internal returns (bytes32 _transferDataHash){
        bytes memory _transferData = new bytes(_data.length - 97);

        for (uint i = 0; i < (_data.length - 97); i++) {
            _transferData[i] = _data[i + 97];
        }
        return keccak256(_transferData);

    }

    function auctionEndVoucherOracleSignatureVerification(
        bytes memory _data,
        bytes32 _sendDataHash,
        InfoFromCreateAuction memory _infoFromCreateAuction,
        InfoFromBidding memory _infoFromBidding
    ) internal returns (bool) {
        bytes32 _biddingHashProof;
        assembly { _biddingHashProof := mload(add(_data,add(0,0x20))) }

        bytes32 _transferDataHash = getTransferDataHash(_data);

         
        return oracle == AuctionityLibraryDecodeRawTx.ecrecoverSigner(
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(
                        abi.encodePacked(
                            address(this),
                            _infoFromCreateAuction.tokenContractAddress,
                            _infoFromCreateAuction.tokenId,
                            _infoFromCreateAuction.auctionSeller,
                            _infoFromBidding.signer,
                            _infoFromBidding.amount,
                            _biddingHashProof,
                            _infoFromCreateAuction.rewardPercent,
                            _transferDataHash,
                            _sendDataHash
                        )
                    )
                )
            ),
            _data,
            32
        );

    }
}