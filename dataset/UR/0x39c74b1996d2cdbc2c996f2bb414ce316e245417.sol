 

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.11;


 
 
 
 
contract SimplifiedDelegatedTrasfer {
    address internal owner;

    constructor(address _owner ) public {
        owner = _owner;
    }
    
    function transferERC20Token(address tokenContractAddress, address to)
     public returns (bool _success) {
        return 
            transferERC20Token(
                tokenContractAddress,
                to,
                IERC20(tokenContractAddress).balanceOf(address(this))
            );
    }

    function transferERC20Token(address tokenContractAddress, address to, 
        uint256 amount) public returns (bool _success) {
        require(msg.sender == owner);
        return IERC20(tokenContractAddress).transfer(to, amount);
    }

    function claimETH(address payable to) public returns (bool _success) {
        return claimETH(to, address(this).balance);
    }

    function claimETH(address payable to, uint256 amount) public returns (bool _success) {
        require(msg.sender == owner);
        return to.send(amount);
    }

     
    function () external payable {
    }
}