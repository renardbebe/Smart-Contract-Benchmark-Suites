 

 
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

contract Landlord is Ownable{
    struct user{
        uint256 amount;
        uint256 PlayerOf;
        uint256 LandlordOpen;
        uint256 bz;
    }
tokenTransfer public bebTokenTransfer;  
    string LandlordName;
    uint256 LandlordAmount;
    uint256 LandlordTime;
    address LandlordAddress;
    uint256 BETMIN;
    uint256 BETMAX;
    mapping(address=>user)public users;
    event bomus(address to,uint256 amountBouns,string lx);
    function Landlord(address _tokenAddress){
         bebTokenTransfer = tokenTransfer(_tokenAddress);
     }
     function BetLandlord(uint256 _value,uint256 _amount) public{
         require(tx.origin == msg.sender);
         user storage _user=users[msg.sender];
         uint256 amount=_amount* 10 ** 18; 
         uint256 _time=now; 
         uint256 Player=_value; 
         require(amount>=BETMIN && amount<=BETMAX); 
         require(LandlordAmount>=amount); 
         require(amount>0); 
         bebTokenTransfer.transferFrom(msg.sender,address(this),amount);
         uint256 _amoun=amount*96/100; 
         uint256 _amountt=amount*98/100; 
         uint256 random2 = random(block.difficulty+_time+amount*91/100);
         if(random2==1){ 
             if(Player==1){
                 _user.PlayerOf=Player; 
                 _user.amount=amount;
                 _user.LandlordOpen=random2;
                 _user.bz=2;
                  
                 bebTokenTransfer.transfer(msg.sender,amount);
             }
             if(Player==2){
                 _user.PlayerOf=Player; 
                 _user.amount=amount;
                 _user.LandlordOpen=random2;
                 _user.bz=1;
                  
                 LandlordAmount+=_amountt; 
             }
             if(Player==3){
                 _user.PlayerOf=Player; 
                 _user.amount=_amoun;
                 _user.LandlordOpen=random2;
                 _user.bz=0;
                  
                 LandlordAmount-=_amountt; 
                  
                 bebTokenTransfer.transfer(msg.sender,amount+_amoun);
             }
         }
         if(random2==2){ 
             if(Player==1){
                 _user.PlayerOf=Player; 
                 _user.amount=_amount;
                 _user.LandlordOpen=random2;
                 _user.bz=0;
                 LandlordAmount-=_amountt; 
                 bebTokenTransfer.transfer(msg.sender,amount+_amoun);
             }
             if(Player==2){
                 _user.PlayerOf=Player; 
                 _user.amount=amount;
                 _user.LandlordOpen=random2;
                 _user.bz=2;
                 bebTokenTransfer.transfer(msg.sender,amount);
             }
             if(Player==3){
                 _user.PlayerOf=Player;
                 _user.amount=amount;
                 _user.LandlordOpen=random2;
                 _user.bz=1;
                 LandlordAmount+=_amountt;
             }
         }
         if(random2==3){ 
             if(Player==1){
                 _user.PlayerOf=Player; 
                 _user.amount=amount;
                 _user.LandlordOpen=random2;
                 _user.bz=1;
                 LandlordAmount+=_amountt; 
             }
             if(Player==2){
                 _user.PlayerOf=Player; 
                 _user.amount=amount;
                 _user.LandlordOpen=random2;
                 _user.bz=0;
                 LandlordAmount-=_amountt; 
                 bebTokenTransfer.transfer(msg.sender,amount+_amoun);
             }
             if(Player==3){
                 _user.PlayerOf=Player; 
                 _user.amount=amount;
                 _user.LandlordOpen=random2;
                 _user.bz=2;
                 bebTokenTransfer.transfer(msg.sender,amount);
             }
         }
     }
     function setdizhu(uint256 _BETMIN,uint256 _BETMAX,string _name)onlyOwner{
         BETMIN=_BETMIN* 10 ** 18;
         BETMAX=_BETMAX* 10 ** 18;
         LandlordName=_name;
     }
     function QiangDiZhu(string name,uint256 amount,uint256 BETMAXs) public{
         require(tx.origin == msg.sender);
         uint256 _amount=amount* 10 ** 18;
         uint256 _BETMAX=BETMAXs* 10 ** 18;
         uint256 _time=now-LandlordTime;
         require(_amount>BETMAX && _BETMAX>BETMIN,"Must be greater than the maximum amount"); 
         require(LandlordAmount<BETMAX || _time >86400 || LandlordTime==0,"We can't rob landlords now"); 
         bebTokenTransfer.transferFrom(msg.sender,address(this),_amount); 
         if(LandlordAmount>0){
         bebTokenTransfer.transfer(LandlordAddress,LandlordAmount); 
         }
         BETMAX=_BETMAX; 
         LandlordAmount=_amount; 
         LandlordAddress=msg.sender; 
         LandlordTime=now; 
         LandlordName=name; 
         
     }
      
     function TuiDiZhu()public{
         require(tx.origin == msg.sender);
         require(LandlordAddress==msg.sender); 
          
         bebTokenTransfer.transfer(LandlordAddress,LandlordAmount); 
         LandlordAmount=0;
         LandlordAddress=0;
         LandlordTime=0;
         LandlordName="空闲";
     }
      
     function ChongZhi(uint256 _amount) public{
         require(tx.origin == msg.sender);
         require(LandlordAddress==msg.sender); 
         uint256 amount=_amount* 10 ** 18;
         bebTokenTransfer.transferFrom(msg.sender,address(this),amount); 
         LandlordAmount+=amount;
     }
     function withdrawAmount(uint256 amount) onlyOwner {
        uint256 _amount=amount* 10 ** 18;
        require(getTokenBalance()>=_amount,"Insufficient contract balance");
        bebTokenTransfer.transfer(owner,_amount); 
    }
    function getTokenBalance() public view returns(uint256){
         return bebTokenTransfer.balanceOf(address(this));
    }
     function getRandom()public view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256){
        user storage _user=users[msg.sender];
         
        return (_user.LandlordOpen,_user.PlayerOf,_user.amount,_user.bz,LandlordTime,BETMIN,BETMAX);
    }
     
    function LandlordNames()public view returns(string,address,uint256){
        return (LandlordName,LandlordAddress,LandlordAmount);
    }
      
     function random(uint256 randomyType)  internal returns(uint256 num){
        uint256 random = uint256(keccak256(randomyType,now));
         uint256 randomNum = random%4;
         if(randomNum<1){
             randomNum=1;
         }
         if(randomNum>3){
            randomNum=3; 
         }
         
         return randomNum;
    }
    function ()payable{
        
    }
}