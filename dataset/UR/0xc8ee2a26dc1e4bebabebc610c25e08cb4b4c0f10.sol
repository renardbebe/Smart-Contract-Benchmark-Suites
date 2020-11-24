 

pragma solidity >=0.4.0 <0.6.0;

 
library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

 
contract Ownable {
     address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 
interface Token {

  function allowance(address _owner, address _spender) external returns (uint256 remaining);

  function transfer(address _to, uint256 _value) external;

  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

  function balanceOf(address _owner) external returns (uint256 balance);
}


 
contract NodeBallot is Ownable{
    
    using SafeMath for uint256;

    struct Node {
         
        uint256 originalAmount;
         
        uint256 totalBallotAmount;
         
        uint date;
         
        bool valid;
    }
    
    struct BallotInfo {
         
        address nodeAddress;
         
        uint256 amount;
         
        uint date;
    }

     
    uint256 public constant lockLimitTime = 3 * 30 ; 
    
     
    Token public token;
    
     
    uint256 public decimals = 10**18;
    
     
    mapping (address => Node) public nodes;
     
    mapping (address => BallotInfo) public userBallotInfoMap;
     
    bool public activityEnable = true;
     
    bool public withdrawEnable = false;
     
    uint256 public totalLockToken = 0; 
     
    uint256 public totalWithdrawToken = 0; 
     
    uint public startDate = 0;
    
    constructor(address tokenAddr) public{
        
        token = Token(tokenAddr);
        
        startDate = now;
    }
    
    
     
    event Ballot(address indexed _ballotAddress,address indexed _nodeAddress, uint256 _ballotAmount, uint _date);
    
      
    event GeneralNode(address indexed _nodeAddress,uint256 _oringinalAmount, uint _date);
    
     
    event Withdraw(address indexed _ballotAddress,uint256 _amount);

     
    function motifyActivityEnable(bool enable) public onlyOwner{
        activityEnable = enable;
    }
    
     
    function openWithdraw(bool enable) public onlyOwner {
        
        if(enable){
            require(activityEnable == false,"please make sure the activity is closed.");
        }
        else{
            require(activityEnable == true,"please make sure the activity is on.");
        }
        withdrawEnable = enable;
    }
   
   
   
     
    function generalSuperNode(uint256 originalAmount) public {

         
        require(activityEnable == true ,'The activity have been closed. Code<202>');
        
         
        require(originalAmount >= 100000 * decimals,'The amount of node token is too low. Code<201>');
        
         
        uint256 allowance = token.allowance(msg.sender,address(this));
        require(allowance>=originalAmount,'Insufficient authorization balance available in the contract. Code<204>');

         
        Node memory addOne = nodes[msg.sender];
        require(addOne.valid == false,'Node did exist. Code<208>');
        
         
        nodes[msg.sender] = Node(originalAmount,0,now,true);
        
        totalLockToken = SafeMath.add(totalLockToken,originalAmount);
        
         
        token.transferFrom(msg.sender,address(this),originalAmount);
        
        emit GeneralNode(msg.sender,originalAmount,now);
    }
    
     
    function ballot(address nodeAddress , uint256 ballotAmount) public returns (bool result){
        
         
        require(activityEnable == true ,'The activity have been closed. Code<202>');
        
         
        BallotInfo memory ballotInfo = userBallotInfoMap[msg.sender];
        require(ballotInfo.amount == 0,'The address has been voted. Code<200>');
        
         
        Node memory node = nodes[nodeAddress];
        require(node.valid == true,'Node does not exist. Code<203>');
            
         
        uint256 allowance = token.allowance(msg.sender,address(this));
        require(allowance>=ballotAmount,'Insufficient authorization balance available in the contract. Code<204>');

         
        nodes[nodeAddress].totalBallotAmount = SafeMath.add(node.totalBallotAmount,ballotAmount);
        
          
        BallotInfo memory info = BallotInfo(nodeAddress,ballotAmount,now);
        userBallotInfoMap[msg.sender]=info;
        
         
        totalLockToken = SafeMath.add(totalLockToken,ballotAmount);
        
         
        token.transferFrom(msg.sender,address(this),ballotAmount);
        
        emit Ballot(msg.sender,nodeAddress,ballotAmount,now);
        
        result = true;
    }
    
     
    function withdrawToken() public returns(bool res){
        
        return _withdrawToken(msg.sender);
    }
 
     
    function withdrawTokenToAddress(address ballotAddress) public onlyOwner returns(bool res){
        
        return _withdrawToken(ballotAddress);
    }
    
     
    function _withdrawToken(address destinationAddress) internal returns(bool){
        
        require(destinationAddress != address(0),'Invalid withdraw address. Code<205>');
        require(withdrawEnable,'Token withdrawal is not open. Code<207>');
        
        BallotInfo memory info = userBallotInfoMap[destinationAddress];
        Node memory node = nodes[destinationAddress];
        
        require(info.amount != 0 || node.originalAmount != 0,'This address is invalid. Code<209>');

        uint256 amount = 0;

        if(info.amount != 0){
            require(now >= info.date + lockLimitTime * 1 days,'The token is still in the lock period. Code<212>');
            amount = info.amount;

            userBallotInfoMap[destinationAddress]=BallotInfo(info.nodeAddress,0,info.date);
        }
        
        if(node.originalAmount != 0){
            
            require(now >= node.date + lockLimitTime * 1 days,'The token is still in the lock period. Code<212>');
            amount = SafeMath.add(amount,node.originalAmount);
            
            nodes[destinationAddress] = Node(node.originalAmount,node.totalBallotAmount,node.date,false);
        }
        
        totalWithdrawToken = SafeMath.add(totalWithdrawToken,amount);
        
         
        token.transfer(destinationAddress,amount);
        
        emit Withdraw(destinationAddress,amount);
        
        return true;
    }
    
    
     
    function transferToken() public onlyOwner {
        
        require(now >= startDate + 365 * 1 days,"transfer time limit.");
        token.transfer(_owner, token.balanceOf(address(this)));
    }

    
     
    function destruct() payable public onlyOwner {
        
         
        require(activityEnable == false,'Activities are not up to the deadline. Code<212>');
         
        require(token.balanceOf(address(this)) == 0 , 'please execute transferToken first. Code<213>');
        
        selfdestruct(msg.sender);  
    }
}