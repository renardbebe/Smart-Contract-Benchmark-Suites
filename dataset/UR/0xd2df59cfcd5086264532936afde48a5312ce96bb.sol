 

pragma solidity ^0.4.25;


 
contract Ownable {
    address private _owner;
    
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
    );
    
     
    constructor() public {
        _owner = msg.sender;
    }
    
     
    function owner() public view returns(address) {
        return _owner;
    }
    
     
    modifier contract_onlyOwner() {
    require(isOwner());
    _;
    }
    
     
    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }
    
     
    function renounceOwnership() public contract_onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }
    
     
    function transferOwnership(address newOwner) public contract_onlyOwner {
        _transferOwnership(newOwner);
    }
    
     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
        return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);  
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}



contract Auction is Ownable {
    
    using SafeMath for uint256;
    
    event bidPlaced(uint bid, address _address);
    event etherTransfered(uint amount, address _address);
    
    string _itemName;
    
    address _highestBidder;
    uint _highestBid;
    uint _minStep;
    uint _end;
    uint _start;
    
    constructor() public {
        
        _itemName = 'Pumpkinhead 1';
        _highestBid = 0;
        _highestBidder = address(this);
        
    				 
         
         
         
         
        
        _end = 1540339140;
        _start = _end - 3 days;

        _minStep = 10000000000000000;

    }
    
    function queryBid() public view returns (string, uint, uint, address, uint, uint) {
        return (_itemName, _start, _highestBid, _highestBidder, _end, _highestBid+_minStep);
    }
    
    function placeBid() payable public returns (bool) {
        require(block.timestamp > _start, 'Auction not started');
        require(block.timestamp < _end, 'Auction ended');
        require(msg.value >= _highestBid.add(_minStep), 'Amount too low');

        uint _payout = _highestBid;
        _highestBid = msg.value;
        
        address _oldHighestBidder = _highestBidder;
        _highestBidder = msg.sender;
        
        if(_oldHighestBidder.send(_payout) == true) {
            emit etherTransfered(_payout, _oldHighestBidder);
        }
        
        emit bidPlaced(_highestBid, _highestBidder);
        
        return true;
    }
    
    function queryBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function weiToOwner(address _address) public contract_onlyOwner returns (bool success) {
        require(block.timestamp > _end, 'Auction not ended');

        _address.transfer(address(this).balance);
        
        return true;
    }
}