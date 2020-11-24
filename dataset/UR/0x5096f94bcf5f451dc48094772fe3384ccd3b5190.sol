 

pragma solidity ^0.5.1;

contract LockRequestable {

         
         
        uint256 public lockRequestCount;

        constructor() public {
                lockRequestCount = 0;
        }

         
         
        function generateLockId() internal returns (bytes32 lockId) {
                return keccak256(
                abi.encodePacked(blockhash(block.number - 1), address(this), ++lockRequestCount)
                );
        }
}

contract CustodianUpgradeable is LockRequestable {

         
         
        struct CustodianChangeRequest {
                address proposedNew;
        }

         
         
        address public custodian;

         
        mapping (bytes32 => CustodianChangeRequest) public custodianChangeReqs;

        constructor(address _custodian) public LockRequestable() {
                custodian = _custodian;
        }

         
        modifier onlyCustodian {
                require(msg.sender == custodian);
                _;
        }

         
        function requestCustodianChange(address _proposedCustodian) public returns (bytes32 lockId) {
                require(_proposedCustodian != address(0));

                lockId = generateLockId();

                custodianChangeReqs[lockId] = CustodianChangeRequest({
                        proposedNew: _proposedCustodian
                });

                emit CustodianChangeRequested(lockId, msg.sender, _proposedCustodian);
        }

         
        function confirmCustodianChange(bytes32 _lockId) public onlyCustodian {
                custodian = getCustodianChangeReq(_lockId);

                delete custodianChangeReqs[_lockId];

                emit CustodianChangeConfirmed(_lockId, custodian);
        }

         
        function getCustodianChangeReq(bytes32 _lockId) private view returns (address _proposedNew) {
                CustodianChangeRequest storage changeRequest = custodianChangeReqs[_lockId];

                 
                 
                require(changeRequest.proposedNew != address(0));

                return changeRequest.proposedNew;
        }

         
        event CustodianChangeRequested(
                bytes32 _lockId,
                address _msgSender,
                address _proposedCustodian
        );

         
        event CustodianChangeConfirmed(bytes32 _lockId, address _newCustodian);
}

contract TokenSettingsInterface {

     
    function getTradeAllowed() public view returns (bool);
    function getMintAllowed() public view returns (bool);
    function getBurnAllowed() public view returns (bool);
    
     
    event TradeAllowedLocked(bytes32 _lockId, bool _newValue);
    event TradeAllowedConfirmed(bytes32 _lockId, bool _newValue);
    event MintAllowedLocked(bytes32 _lockId, bool _newValue);
    event MintAllowedConfirmed(bytes32 _lockId, bool _newValue);
    event BurnAllowedLocked(bytes32 _lockId, bool _newValue);
    event BurnAllowedConfirmed(bytes32 _lockId, bool _newValue);

     
    modifier onlyCustodian {
        _;
    }
}


contract _BurnAllowed is TokenSettingsInterface, LockRequestable {
     
     
     
     
     
     
     
    bool private burnAllowed = false;

    function getBurnAllowed() public view returns (bool) {
        return burnAllowed;
    }

     

    struct PendingBurnAllowed {
        bool burnAllowed;
        bool set;
    }

    mapping (bytes32 => PendingBurnAllowed) public pendingBurnAllowedMap;

    function requestBurnAllowedChange(bool _burnAllowed) public returns (bytes32 lockId) {
       require(_burnAllowed != burnAllowed);
       
       lockId = generateLockId();
       pendingBurnAllowedMap[lockId] = PendingBurnAllowed({
           burnAllowed: _burnAllowed,
           set: true
       });

       emit BurnAllowedLocked(lockId, _burnAllowed);
    }

    function confirmBurnAllowedChange(bytes32 _lockId) public onlyCustodian {
        PendingBurnAllowed storage value = pendingBurnAllowedMap[_lockId];
        require(value.set == true);
        burnAllowed = value.burnAllowed;
        emit BurnAllowedConfirmed(_lockId, value.burnAllowed);
        delete pendingBurnAllowedMap[_lockId];
    }
}


contract _MintAllowed is TokenSettingsInterface, LockRequestable {
     
     
     
     
     
     
     
    bool private mintAllowed = false;

    function getMintAllowed() public view returns (bool) {
        return mintAllowed;
    }

     

    struct PendingMintAllowed {
        bool mintAllowed;
        bool set;
    }

    mapping (bytes32 => PendingMintAllowed) public pendingMintAllowedMap;

    function requestMintAllowedChange(bool _mintAllowed) public returns (bytes32 lockId) {
       require(_mintAllowed != mintAllowed);
       
       lockId = generateLockId();
       pendingMintAllowedMap[lockId] = PendingMintAllowed({
           mintAllowed: _mintAllowed,
           set: true
       });

       emit MintAllowedLocked(lockId, _mintAllowed);
    }

    function confirmMintAllowedChange(bytes32 _lockId) public onlyCustodian {
        PendingMintAllowed storage value = pendingMintAllowedMap[_lockId];
        require(value.set == true);
        mintAllowed = value.mintAllowed;
        emit MintAllowedConfirmed(_lockId, value.mintAllowed);
        delete pendingMintAllowedMap[_lockId];
    }
}


contract _TradeAllowed is TokenSettingsInterface, LockRequestable {
     
     
     
     
     
     
     
    bool private tradeAllowed = false;

    function getTradeAllowed() public view returns (bool) {
        return tradeAllowed;
    }

     

    struct PendingTradeAllowed {
        bool tradeAllowed;
        bool set;
    }

    mapping (bytes32 => PendingTradeAllowed) public pendingTradeAllowedMap;

    function requestTradeAllowedChange(bool _tradeAllowed) public returns (bytes32 lockId) {
       require(_tradeAllowed != tradeAllowed);
       
       lockId = generateLockId();
       pendingTradeAllowedMap[lockId] = PendingTradeAllowed({
           tradeAllowed: _tradeAllowed,
           set: true
       });

       emit TradeAllowedLocked(lockId, _tradeAllowed);
    }

    function confirmTradeAllowedChange(bytes32 _lockId) public onlyCustodian {
        PendingTradeAllowed storage value = pendingTradeAllowedMap[_lockId];
        require(value.set == true);
        tradeAllowed = value.tradeAllowed;
        emit TradeAllowedConfirmed(_lockId, value.tradeAllowed);
        delete pendingTradeAllowedMap[_lockId];
    }
}

contract TokenSettings is TokenSettingsInterface, CustodianUpgradeable,
_TradeAllowed,
_MintAllowed,
_BurnAllowed
    {
    constructor(address _custodian) public CustodianUpgradeable(_custodian) {
    }
}