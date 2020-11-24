 

pragma solidity ^0.4.17;

 
contract EthealSplit {
     
    function split(address[] _to) public payable {
        uint256 _val = msg.value / _to.length;
        for (uint256 i=0; i < _to.length; i++) {
            _to[i].send(_val);
        }

        if (address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }
    }
}