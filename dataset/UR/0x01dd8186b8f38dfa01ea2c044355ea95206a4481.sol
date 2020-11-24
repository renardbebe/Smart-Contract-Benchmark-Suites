 

pragma solidity ^0.4.19;

contract Snake {
    address public ownerAddress;
    uint256 public length;  

    mapping (uint256 => uint256) public snake;  
    mapping (uint256 => address) public owners;  
    mapping (uint256 => uint256) public stamps;  
    
    event Sale(address owner, uint256 profit, uint256 stamp);  
    
    function Snake() public {
        ownerAddress = msg.sender; 
        length = 0;  
        _extend(length);  
    }
    
     
    function buy(uint256 id) external payable {
        require(snake[id] > 0);  
        require(msg.value >= snake[id] / 100 * 150);  
        address owner = owners[id];
        uint256 amount = snake[id];

        snake[id] = amount / 100 * 150;  
        owners[id] = msg.sender;  
        stamps[id] = uint256(now);  

        owner.transfer(amount / 100 * 125);  
        Sale(owner, amount, uint256(now));  
         
        if (id == 0) { 
            length++;  
            _extend(length);  
        }
        ownerAddress.transfer(this.balance);  
    }
     
    function getToken(uint256 id) external view returns(uint256, uint256, address) {
        return (snake[id] / 100 * 150, stamps[id], owners[id]);
    }
     
    function _extend(uint256 id) internal {
        snake[id] = 1 * 10**16;
        owners[id] = msg.sender;
    }
}