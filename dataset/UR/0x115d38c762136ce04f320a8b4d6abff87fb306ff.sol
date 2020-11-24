 

pragma solidity 0.4.18;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract Test {
    IERC20 public token = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    
    function transfer(address _to, uint256 _value) public {
        token.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public {
        token.transferFrom(_from, _to, _value);
    }
}