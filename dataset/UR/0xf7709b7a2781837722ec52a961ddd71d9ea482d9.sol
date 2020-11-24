 

pragma solidity 0.4.21;

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract TokenPayment {

    uint8 private _recipientLimit = 7;

     
    function multiTransfer(address _token, address[] memory _recipients, uint256[] memory _tokenAmounts) public {
        require(_recipients.length == _tokenAmounts.length);
        require(_recipients.length <= _recipientLimit);

         
        uint256 total;
        for (uint256 i = 0; i < _recipients.length; i++) {
            total += _tokenAmounts[i];
        }

         
        IERC20(_token).transferFrom(msg.sender, address(this), total);

         
        for (uint256 j = 0; j < _recipients.length; j++) {
            IERC20(_token).transfer(_recipients[j], _tokenAmounts[j]);
        }
    }

}