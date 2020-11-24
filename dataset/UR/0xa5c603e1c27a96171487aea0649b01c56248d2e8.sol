 

pragma solidity ^0.4.24;

 
contract MultiSigWallet {

    uint constant public MAX_OWNER_COUNT = 10;

     
    uint256 public nonce;   
     
    uint256 public threshold; 
     
    uint256 public ownersCount;
     
    mapping (address => bool) public isOwner; 

     
    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);
    event ThresholdChanged(uint256 indexed newThreshold);
    event Executed(address indexed destination, uint256 indexed value, bytes data);
    event Received(uint256 indexed value, address indexed from);

     
    modifier onlyWallet() {
        require(msg.sender == address(this), "MSW: Calling account is not wallet");
        _;
    }

     
    constructor(uint256 _threshold, address[] _owners) public {
        require(_owners.length > 0 && _owners.length <= MAX_OWNER_COUNT, "MSW: Not enough or too many owners");
        require(_threshold > 0 && _threshold <= _owners.length, "MSW: Invalid threshold");
        ownersCount = _owners.length;
        threshold = _threshold;
        for(uint256 i = 0; i < _owners.length; i++) {
            isOwner[_owners[i]] = true;
            emit OwnerAdded(_owners[i]);
        }
        emit ThresholdChanged(_threshold);
    }

     
    function execute(address _to, uint _value, bytes _data, bytes _signatures) public {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 count = _signatures.length / 65;
        require(count >= threshold, "MSW: Not enough signatures");
        bytes32 txHash = keccak256(abi.encodePacked(byte(0x19), byte(0), address(this), _to, _value, _data, nonce));
        nonce += 1;
        uint256 valid;
        address lastSigner = 0;
        for(uint256 i = 0; i < count; i++) {
            (v,r,s) = splitSignature(_signatures, i);
            address recovered = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",txHash)), v, r, s);
            require(recovered > lastSigner, "MSW: Badly ordered signatures");  
            lastSigner = recovered;
            if(isOwner[recovered]) {
                valid += 1;
                if(valid >= threshold) {
                    require(_to.call.value(_value)(_data), "MSW: External call failed");
                    emit Executed(_to, _value, _data);
                    return;
                }
            }
        }
         
        revert("MSW: Not enough valid signatures");
    }

     
    function addOwner(address _owner) public onlyWallet {
        require(ownersCount < MAX_OWNER_COUNT, "MSW: MAX_OWNER_COUNT reached");
        require(isOwner[_owner] == false, "MSW: Already owner");
        ownersCount += 1;
        isOwner[_owner] = true;
        emit OwnerAdded(_owner);
    }

     
    function removeOwner(address _owner) public onlyWallet {
        require(ownersCount > threshold, "MSW: Too few owners left");
        require(isOwner[_owner] == true, "MSW: Not an owner");
        ownersCount -= 1;
        delete isOwner[_owner];
        emit OwnerRemoved(_owner);
    }

     
    function changeThreshold(uint256 _newThreshold) public onlyWallet {
        require(_newThreshold > 0 && _newThreshold <= ownersCount, "MSW: Invalid new threshold");
        threshold = _newThreshold;
        emit ThresholdChanged(_newThreshold);
    }

     
    function () external payable {
        emit Received(msg.value, msg.sender);        
    }

         
    function splitSignature(bytes _signatures, uint256 _index) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
         
         
         
        assembly {
            r := mload(add(_signatures, add(0x20,mul(0x41,_index))))
            s := mload(add(_signatures, add(0x40,mul(0x41,_index))))
            v := and(mload(add(_signatures, add(0x41,mul(0x41,_index)))), 0xff)
        }
        require(v == 27 || v == 28, "MSW: Invalid v"); 
    }

}