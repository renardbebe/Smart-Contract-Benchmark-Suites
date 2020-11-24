 

pragma solidity ^0.4.21;

 
contract Custodian {

     
     
    struct Request {
        bytes32 lockId;
        bytes4 callbackSelector;  
        address callbackAddress;
        uint256 idx;
        uint256 timestamp;
        bool extended;
    }

     
     
    event Requested(
        bytes32 _lockId,
        address _callbackAddress,
        bytes4  _callbackSelector,
        uint256 _nonce,
        address _whitelistedAddress,
        bytes32 _requestMsgHash,
        uint256 _timeLockExpiry
    );

     
    event TimeLocked(
        uint256 _timeLockExpiry,
        bytes32 _requestMsgHash
    );

     
    event Completed(
        bytes32 _lockId,
        bytes32 _requestMsgHash,
        address _signer1,
        address _signer2
    );

     
    event Failed(
        bytes32 _lockId,
        bytes32 _requestMsgHash,
        address _signer1,
        address _signer2
    );

     
    event TimeLockExtended(
        uint256 _timeLockExpiry,
        bytes32 _requestMsgHash
    );

     
     
    uint256 public requestCount;

     
    mapping (address => bool) public signerSet;

     
    mapping (bytes32 => Request) public requestMap;

     
    mapping (address => mapping (bytes4 => uint256)) public lastCompletedIdxs;

     
    uint256 public defaultTimeLock;

     
    uint256 public extendedTimeLock;

     
    address public primary;

     
    function Custodian(
        address[] _signers,
        uint256 _defaultTimeLock,
        uint256 _extendedTimeLock,
        address _primary
    )
        public
    {
         
        require(_signers.length >= 2);

         
        require(_defaultTimeLock <= _extendedTimeLock);
        defaultTimeLock = _defaultTimeLock;
        extendedTimeLock = _extendedTimeLock;

        primary = _primary;

         
        requestCount = 0;
         
        for (uint i = 0; i < _signers.length; i++) {
             
            require(_signers[i] != address(0) && !signerSet[_signers[i]]);
            signerSet[_signers[i]] = true;
        }
    }

     
    modifier onlyPrimary {
        require(msg.sender == primary);
        _;
    }

     
     
    function requestUnlock(
        bytes32 _lockId,
        address _callbackAddress,
        bytes4 _callbackSelector,
        address _whitelistedAddress
    )
        public
        payable
        returns (bytes32 requestMsgHash)
    {
        require(msg.sender == primary || msg.value >= 1 ether);

         
        require(_callbackAddress != address(0));

        uint256 requestIdx = ++requestCount;
         
         
         
         
        uint256 nonce = uint256(keccak256(block.blockhash(block.number - 1), address(this), requestIdx));

        requestMsgHash = keccak256(nonce, _whitelistedAddress, uint256(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF));

        requestMap[requestMsgHash] = Request({
            lockId: _lockId,
            callbackSelector: _callbackSelector,
            callbackAddress: _callbackAddress,
            idx: requestIdx,
            timestamp: block.timestamp,
            extended: false
        });

         
        uint256 timeLockExpiry = block.timestamp;
        if (msg.sender == primary) {
            timeLockExpiry += defaultTimeLock;
        } else {
            timeLockExpiry += extendedTimeLock;

             
            requestMap[requestMsgHash].extended = true;
        }

        emit Requested(_lockId, _callbackAddress, _callbackSelector, nonce, _whitelistedAddress, requestMsgHash, timeLockExpiry);
    }

     
    function completeUnlock(
        bytes32 _requestMsgHash,
        uint8 _recoveryByte1, bytes32 _ecdsaR1, bytes32 _ecdsaS1,
        uint8 _recoveryByte2, bytes32 _ecdsaR2, bytes32 _ecdsaS2
    )
        public
        returns (bool success)
    {
        Request storage request = requestMap[_requestMsgHash];

         
        bytes32 lockId = request.lockId;
        address callbackAddress = request.callbackAddress;
        bytes4 callbackSelector = request.callbackSelector;

         
        require(callbackAddress != address(0));

         
        require(request.idx > lastCompletedIdxs[callbackAddress][callbackSelector]);

        address signer1 = ecrecover(_requestMsgHash, _recoveryByte1, _ecdsaR1, _ecdsaS1);
        require(signerSet[signer1]);

        address signer2 = ecrecover(_requestMsgHash, _recoveryByte2, _ecdsaR2, _ecdsaS2);
        require(signerSet[signer2]);
        require(signer1 != signer2);

        if (request.extended && ((block.timestamp - request.timestamp) < extendedTimeLock)) {
            emit TimeLocked(request.timestamp + extendedTimeLock, _requestMsgHash);
            return false;
        } else if ((block.timestamp - request.timestamp) < defaultTimeLock) {
            emit TimeLocked(request.timestamp + defaultTimeLock, _requestMsgHash);
            return false;
        } else {
            if (address(this).balance > 0) {
                 
                 
                success = msg.sender.send(address(this).balance);
            }

             
            lastCompletedIdxs[callbackAddress][callbackSelector] = request.idx;
             
            delete requestMap[_requestMsgHash];

             
            success = callbackAddress.call(callbackSelector, lockId);

            if (success) {
                emit Completed(lockId, _requestMsgHash, signer1, signer2);
            } else {
                emit Failed(lockId, _requestMsgHash, signer1, signer2);
            }
        }
    }

     
    function deleteUncompletableRequest(bytes32 _requestMsgHash) public {
        Request storage request = requestMap[_requestMsgHash];

        uint256 idx = request.idx;

        require(0 < idx && idx < lastCompletedIdxs[request.callbackAddress][request.callbackSelector]);

        delete requestMap[_requestMsgHash];
    }

     
    function extendRequestTimeLock(bytes32 _requestMsgHash) public onlyPrimary {
        Request storage request = requestMap[_requestMsgHash];

         
         
        require(request.callbackAddress != address(0));

         
        require(request.extended != true);

         
        request.extended = true;

        emit TimeLockExtended(request.timestamp + extendedTimeLock, _requestMsgHash);
    }
}