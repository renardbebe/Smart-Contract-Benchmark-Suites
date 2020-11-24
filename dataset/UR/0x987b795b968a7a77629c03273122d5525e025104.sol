 

pragma solidity ^0.4.15;

contract ERC20Interface {
     
    function transfer(address _to, uint256 _value) public returns (bool success);

}
contract BatchTransfer{
    address public owner;
    function BatchTransfer() public{
        owner=msg.sender;
    }
    
    function changeOwner(address _newOwner) onlyOwner{
        require(_newOwner!=0x0);
        owner=_newOwner;
    }
    
    function multiTransferToken(address _tokenAddr,address[] dests,uint256[] values) onlyOwner{
        ERC20Interface erc20 = ERC20Interface(_tokenAddr);
        
        require(dests.length == values.length);
        
        for(uint256 i=0;i<dests.length;i++){
            erc20.transfer(dests[i], values[i]);
        }
        
    }
    
    function multiTransferEther(address[] _addresses,uint256[] _amounts) onlyOwner{
        require(_addresses.length==_amounts.length);
        
        for(uint256 i=0;i<_addresses.length;i++){
            _addresses[i].transfer(_amounts[i]);
            
        }
    }
    function multiTransferEther(address[] _addresses,uint256 _amount) onlyOwner{
        require(_amount>0);
        require(_addresses.length>0&&_addresses.length<50);
        
        for(uint256 i=0;i<_addresses.length;i++){
            _addresses[i].transfer(_amount);
        }
    }
    
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function () public payable {
    }
}