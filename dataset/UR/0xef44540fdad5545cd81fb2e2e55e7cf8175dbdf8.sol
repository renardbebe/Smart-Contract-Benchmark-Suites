 

contract ERC20TransferFrom {
    function transferFrom(address, address, uint256) external returns (bool);
}

contract Monica {
    function pay(address token, uint256 decimals, address[] calldata tos, uint256[] calldata amounts) external {
        require(tos.length == amounts.length);
        
        uint256 base = 10 ** decimals;
        uint256 length = tos.length;
        
        for (uint256 i = 0; i < length; i++) {
            require(ERC20TransferFrom(token).transferFrom(msg.sender, tos[i], amounts[i] * base));
        }
    }
}