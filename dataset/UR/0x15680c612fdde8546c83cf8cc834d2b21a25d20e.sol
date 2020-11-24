 

pragma solidity >=0.4.22 <0.6.0;
pragma experimental ABIEncoderV2;
contract store_values {
    int64 public my_int;
    int64[3] public my_int_array;
    string public my_string;
    string[3] public my_string_array;
    bool public my_bool;
    bool[3] public my_bool_array;
    address public my_address;
    address[3] public my_address_array;
    bytes32 public my_bytes32;
    bytes32[3] public my_bytes32_array;
    bytes16 public my_bytes16;
    bytes16[3] public my_bytes16_array;

    function setter_int(int64 my_new_value) public returns (int64) {
        my_int = my_new_value;
        return my_int;
    }
    
    function setter_int_array(int64[3] memory my_new_value) public returns (int64[3] memory) {
        my_int_array = my_new_value;
        return my_int_array;
    }
    
    function setter_string(string memory my_new_value) public returns (string memory) {
        my_string = my_new_value;
        return my_string;
    }
    
    function setter_string_array(string[3] memory my_new_value) public returns (string[3] memory) {
        my_string_array = my_new_value;
        return my_string_array;
    }    
    
    function setter_bool(bool my_new_value) public returns (bool) {
        my_bool = my_new_value;
        return my_bool;
    }
    
    function setter_bool_array(bool[3] memory my_new_value) public returns (bool[3] memory) {
        my_bool_array = my_new_value;
        return my_bool_array;
    }
    
    function setter_address(address my_new_value) public returns (address) {
        my_address = my_new_value;
        return my_address;
    }
    
    function setter_address_array(address[3] memory my_new_value) public returns (address[3] memory) {
        my_address_array = my_new_value;
        return my_address_array;
    }
    
    function setter_bytes32(bytes32 my_new_value) public returns (bytes32) {
        my_bytes32 = my_new_value;
        return my_bytes32;
    }
    
    function setter_bytes32_array(bytes32[3] memory my_new_value) public returns (bytes32[3] memory) {
        my_bytes32_array = my_new_value;
        return my_bytes32_array;
    }
    
    function setter_bytes16(bytes16 my_new_value) public returns (bytes16) {
        my_bytes16 = my_new_value;
        return my_bytes16;
    }
    
    function setter_bytes16_array(bytes16[3] memory my_new_value) public returns (bytes16[3] memory) {
        my_bytes16_array = my_new_value;
        return my_bytes16_array;
    }    
    
}