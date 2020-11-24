 

pragma solidity ^0.5.10;


interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TokenDistribution {
    constructor () public {
    }

    
    function batchSend (
        IERC20 _token, address[] calldata _addresses, uint256[] calldata _values) external returns (bool) {
        require(_addresses.length == _values.length, "Length mismatch");

        uint256 count = _addresses.length;
        for (uint256 i = 0; i < count; i++) {
            address to = _addresses[i];
            uint256 value = _values[i];
            if (!_token.transferFrom (msg.sender, to, value)) revert ();
        }

        return true;
    }

    
    function encodedBatchSend (
        IERC20 _token, uint160 _lotSize, uint256[] calldata _transfers) external returns (bool) {
        uint256 count = _transfers.length;
        for (uint256 i = 0; i < count; i++) {
            uint256 transfer = _transfers [i];
            uint256 value = (transfer >> 160) * _lotSize;
            address to = address (
                transfer & 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            if (!_token.transferFrom (msg.sender, to, value)) revert ();
        }

        return true;
    }
}