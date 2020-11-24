 

pragma solidity ^0.4.11;

contract Burner {
    uint256 public totalBurned;
    
    function Purge() public {
         
         
        msg.sender.transfer(this.balance / 1000);
        assembly {
            mstore(0, 0x30ff)
             
             
            create(balance(address), 30, 2)
            pop
        }
    }
    
    function Burn() payable {
        totalBurned += msg.value;
    }
}