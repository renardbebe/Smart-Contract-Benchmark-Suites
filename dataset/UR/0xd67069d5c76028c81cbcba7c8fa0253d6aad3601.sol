 

pragma solidity ^0.5.8;

 
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

library IterableMap {
    
    struct IMap {
        mapping(address => uint256) mapToData;
        mapping(address => uint256) mapToIndex;  
        address[] indexes;
    }
    
    function insert(IMap storage self, address _address, uint256 _value) internal returns (bool replaced) {
      
        require(_address != address(0));
        
        if(self.mapToIndex[_address] == 0){
            
             
            self.indexes.push(_address);
            self.mapToIndex[_address] = self.indexes.length;
            self.mapToData[_address] = _value;
            return false;
        }
        
         
        self.mapToData[_address] = _value;
        return true;
    }
    
    function remove(IMap storage self, address _address) internal returns (bool success) {
       
        require(_address != address(0));
        
         
        if(self.mapToIndex[_address] == 0){
            return false;   
        }
        
        uint256 deleteIndex = self.mapToIndex[_address];
        if(deleteIndex <= 0 || deleteIndex > self.indexes.length){
            return false;
        }
       
          
        if (deleteIndex < self.indexes.length) {
             
            self.indexes[deleteIndex-1] = self.indexes[self.indexes.length-1];
            self.mapToIndex[self.indexes[deleteIndex-1]] = deleteIndex;
        }
        self.indexes.length -= 1;
        delete self.mapToData[_address];
        delete self.mapToIndex[_address];
       
        return true;
    }
  
    function contains(IMap storage self, address _address) internal view returns (bool exists) {
        return self.mapToIndex[_address] > 0;
    }
      
    function size(IMap storage self) internal view returns (uint256) {
        return self.indexes.length;
    }
  
    function get(IMap storage self, address _address) internal view returns (uint256) {
        return self.mapToData[_address];
    }

     
    function getKey(IMap storage self, uint256 _index) internal view returns (address) {
        
        if(_index < self.indexes.length){
            return self.indexes[_index];
        }
        return address(0);
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

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
        owner = msg.sender;
    }
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ZmineVoteBurn is Ownable {
  
     
    using IterableMap for IterableMap.IMap;
    using SafeMath for uint256;
    
     
    IERC20 public token;
  
     
    IterableMap.IMap voteRecordMap;
     
    IterableMap.IMap reclaimTokenMap;
    
     
    uint256 public timestampStartVote;
     
    uint256 public timestampEndVote;
     
    uint256 public timestampReleaseToken;
    
     
    uint256 _totalVote;
    
    constructor(IERC20 _token) public {

        token = _token;
        
         
         
        timestampStartVote = 1558483200; 
        
         
         
        timestampEndVote = 1559001600; 
        
         
         
        timestampReleaseToken = 1559174400; 
    }
    
     
     
     
    modifier onlyVotable() {
        require(isVotable());
        _;
    }
    
     
    modifier onlyReclaimable() {
        require(isReclaimable());
        _;
    }
  
     
     
    function isVotable() public view returns (bool){
        return (timestampStartVote <= block.timestamp && block.timestamp <= timestampEndVote);
    }
    
    function isReclaimable() public view returns (bool){
        return (block.timestamp >= timestampReleaseToken);
    }
    
    function countVoteUser() public view returns (uint256){
        return voteRecordMap.size();
    }
    
    function countVoteScore() public view returns (uint256){
        return _totalVote;
    }
    
    function getVoteByAddress(address _address) public view returns (uint256){
        return voteRecordMap.get(_address);
    }
    
     
     
    function voteBurn(uint256 amount) public onlyVotable {

        require(token.balanceOf(msg.sender) >= amount);
        
         
        token.transferFrom(msg.sender, address(this), amount);
        
         
        uint256 newAmount = voteRecordMap.get(msg.sender).add(amount);
        
         
        reclaimTokenMap.insert(msg.sender, newAmount);
        voteRecordMap.insert(msg.sender, newAmount);
        
         
        _totalVote = _totalVote.add(amount);
    }
    
     
    function reclaimToken() public onlyReclaimable {
      
        uint256 amount = reclaimTokenMap.get(msg.sender);
        require(amount > 0);
        require(token.balanceOf(address(this)) >= amount);
          
         
        token.transfer(msg.sender, amount);
        
         
        reclaimTokenMap.remove(msg.sender);
    }
    
     
     
    function adminCountReclaimableUser() public view onlyOwner returns (uint256){
        return reclaimTokenMap.size();
    }
    
    function adminCheckReclaimableAddress(uint256 index) public view onlyOwner returns (address){
        
        require(index >= 0); 
        
        if(reclaimTokenMap.size() > index){
            return reclaimTokenMap.getKey(index);
        }else{
            return address(0);
        }
    }
    
    function adminCheckReclaimableToken(uint256 index) public view onlyOwner returns (uint256){
    
        require(index >= 0); 
    
        if(reclaimTokenMap.size() > index){
            return reclaimTokenMap.get(reclaimTokenMap.getKey(index));
        }else{
            return 0;
        }
    }
    
    function adminCheckVoteAddress(uint256 index) public view onlyOwner returns (address){
        
        require(index >= 0); 
        
        if(voteRecordMap.size() > index){
            return voteRecordMap.getKey(index);
        }else{
            return address(0);
        }
    }
    
    function adminCheckVoteToken(uint256 index) public view onlyOwner returns (uint256){
    
        require(index >= 0); 
    
        if(voteRecordMap.size() > index){
            return voteRecordMap.get(voteRecordMap.getKey(index));
        }else{
            return 0;
        }
    }
    
     
    function adminReclaimToken(address _address) public onlyOwner {
      
        uint256 amount = reclaimTokenMap.get(_address);
        require(amount > 0);
        require(token.balanceOf(address(this)) >= amount);
          
        token.transfer(_address, amount);
        
         
        reclaimTokenMap.remove(_address);
    }
    
     
     
     
     
    function adminSweepMistakeTransferToken() public onlyOwner {
        
        require(reclaimTokenMap.size() == 0);
        require(token.balanceOf(address(this)) > 0);
        token.transfer(owner, token.balanceOf(address(this)));
    }
}