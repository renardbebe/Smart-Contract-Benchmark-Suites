 

pragma solidity 0.5.11;

contract Storage {
    mapping(address => mapping(uint256=>string)) stringStore;
    mapping(address => mapping(uint256=>bytes)) bytesStore;
    mapping(address => mapping(uint256=>uint256)) uint256Store;
    
    function setString(uint256 _id, string calldata _data) external {
        stringStore[msg.sender][_id] = _data;
    }
    
    function getString(address _addr, uint256 _id) external view returns (string memory) {
        return stringStore[_addr][_id];
    }
    
    function setBytes(uint256 _id, bytes calldata _data) external {
        bytesStore[msg.sender][_id] = _data;
    }
    
    function getBytes(address _addr, uint256 _id) external view returns (bytes memory) {
        return bytesStore[_addr][_id];
    }
    
    function setUint256(uint256 _id, uint256 _data) external {
        uint256Store[msg.sender][_id] = _data;
    }
    
    function getUint256(address _addr, uint256 _id) external view returns (uint256) {
        return uint256Store[_addr][_id];
    }
}