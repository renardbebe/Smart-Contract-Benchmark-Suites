 

pragma solidity ^0.4.24;

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TokenSender {

    event TransferFail(uint256 index, address receiver, uint256 amount);

    function bulkTransfer(address[] receivers, uint256[] amounts, address token) external {
        address sender = msg.sender;
        uint256 length = receivers.length;
        for (uint256 i = 0; i < length; i++) {
            if (!ERC20(token).transferFrom(sender, receivers[i], amounts[i])) {
                emit TransferFail(i, receivers[i], amounts[i]);
                return;
            }
        }
    }

    function bulkTransferEther(address[] receivers, uint256[] amounts) external payable {
        uint256 length = receivers.length;
        uint256 totalSend = 0;
        for (uint256 i = 0; i < length; i++){
            if (!receivers[i].send(amounts[i])) {
                emit TransferFail(i, receivers[i], amounts[i]);
                return;
            }
            totalSend += amounts[i];
        }
        uint256 balances = msg.value - totalSend;
        if (balances > 0) {
            msg.sender.transfer(balances);
        }
        require(this.balance == 0);
    }
}