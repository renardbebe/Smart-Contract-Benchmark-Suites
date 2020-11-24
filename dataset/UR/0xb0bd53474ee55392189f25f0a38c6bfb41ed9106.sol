 

pragma solidity ^0.4.23;

contract simple_contract {
    mapping (bytes32 => uint8[]) public vMap;
    mapping (bytes32 => bytes32[]) public rMap;
    mapping (bytes32 => bytes32[]) public sMap;

    constructor() public {
    }

     
    function addSign(bytes32 hash, uint8[] vArray, bytes32[] rArray, bytes32[] sArray, address[] addrArray) public {
        require(vMap[hash].length == 0 && rMap[hash].length == 0 && sMap[hash].length == 0, "no map");
        require(vArray.length == rArray.length && rArray.length == sArray.length, "invalid map");
        require(addrArray.length > 0 && addrArray.length < 1000, "invalid address array length");
        require(_checkDistinctParties(addrArray), "invalid address array");
        vMap[hash] = new uint8[](vArray.length);
        rMap[hash] = new bytes32[](vArray.length);
        sMap[hash] = new bytes32[](vArray.length);
        for (uint256 i = 0; i < vArray.length; i++) {
            vMap[hash][i] = vArray[i];
            rMap[hash][i] = rArray[i];
            sMap[hash][i] = sArray[i];

            bytes memory prefix = "\x19Ethereum Signed Message:\n32";
            bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
            require(ecrecover(prefixedHash, vArray[i], rArray[i], sArray[i]) == addrArray[i], "ecrecover fail");
        }
    }

    function getAddresses(bytes32 hash) public view returns (address[]) {
        uint8[] storage vArray = vMap[hash];
        bytes32[] storage rArray = rMap[hash];
        bytes32[] storage sArray = sMap[hash];
        address[] memory addrArray = new address[](vArray.length);
        require(vArray.length > 0 && rArray.length > 0 && sArray.length > 0);
        for (uint256 i = 0; i < vArray.length; i++) {
            bytes memory prefix = "\x19Ethereum Signed Message:\n32";
            bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
            addrArray[i] = ecrecover(prefixedHash, vArray[i], rArray[i], sArray[i]);
        }
        return addrArray;
    }

    function getEcrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public pure returns (address) {
        return ecrecover(hash, v, r, s);
    }

    function _checkDistinctParties(address[] _parties) private pure returns (bool) {
        for (uint256 i = 0; i < _parties.length; i++) {
            for (uint256 j = i + 1; j < _parties.length; j++) {
                if (_parties[i] == _parties[j]) {
                    return false;
                }
            }
        }
        return true;
    }
}