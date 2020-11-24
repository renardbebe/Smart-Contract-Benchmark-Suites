 

 
pragma solidity^0.4.24;  
interface tokenTransfer {
    function transfer(address receiver, uint amount);
    function transferFrom(address _from, address _to, uint256 _value);
    function balanceOf(address receiver) returns(uint256);
}

contract Ownable {
  address public owner;
 
    function Ownable () public {
        owner = msg.sender;
    }
 
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }
 
     
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
        owner = newOwner;
      }
    }
}

contract airdrop is Ownable{
function airdrop(address _tokenAddress){
         bebTokenTransfer = tokenTransfer(_tokenAddress);
     }
    uint8 decimals = 18;
   struct airdropuser {
        uint256 Numberofdays;
        uint256 _lasttime;
    }
    uint256 airdropAmount;
    uint256 lastDate=now;
    uint256 depreciationTime=86400;
    tokenTransfer public bebTokenTransfer;  
    mapping(address=>airdropuser)public airdropusers;
    
    function airdropBEB()public{
        airdropuser storage _user=airdropusers[msg.sender];
       uint256 lasttime=_user._lasttime;
       if(lasttime==0){
         _user._lasttime=now;
         _user.Numberofdays+=1;
         airdropusers[msg.sender]._lasttime=now;
        bebTokenTransfer.transfer(msg.sender,airdropAmount);
         return;
       }
        uint256 depreciation=(now-lasttime)/depreciationTime;
        uint256 _lastDate=_user.Numberofdays+depreciation;
        require(depreciation>0,"Less than 1 day of earnings");
        require(_lastDate<11,"Must be less than 10 days");
        require(getTokenBalance()>airdropAmount);
        _user.Numberofdays+=depreciation;
         airdropusers[msg.sender]._lasttime=now;
        bebTokenTransfer.transfer(msg.sender,airdropAmount);
    }
    function getTokenBalance() public view returns(uint256){
         return bebTokenTransfer.balanceOf(address(this));
    }
    function getairdropAmount(uint256 _value)onlyOwner{
        airdropAmount=_value*10**18;
    }
    function getdays() public view returns(uint256){
         airdropuser storage _user=airdropusers[msg.sender];
        return (_user.Numberofdays);
    }
    function ()payable{
        
    }
}