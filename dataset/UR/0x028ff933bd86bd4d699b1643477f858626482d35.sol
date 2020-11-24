 

 
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

contract LUCKER is Ownable{
tokenTransfer public bebTokenTransfer;  
    uint8 decimals = 18;
    uint256 opentime=now+3600; 
    uint256 opensome; 
    uint256 _opensome; 
    uint256 BEBMAX;
    uint256 BEBtime;
    uint256 Numberofairdrops;
    address ownersto;
     
    struct luckuser{
        uint256 _time;
        uint256 _eth;
        uint256 _beb;
        uint256 _bz;
        uint256 _romd; 
        uint256 Bond;
        uint256 sumeth;
        uint256 sumbeb;
    }
    mapping(address=>luckuser)public luckusers;
    function LUCKER(address _tokenAddress,address _addr){
         bebTokenTransfer = tokenTransfer(_tokenAddress);
         ownersto=_addr;
     }
     function present()public{
         require(tx.origin == msg.sender);
         luckuser storage _user=luckusers[msg.sender];
         require(_user.Bond>0,"Please air drop authorization");
         if(_opensome>=opensome){
             _opensome=0;
         }
         uint256 _times=now;
         uint256 _usertime=now-_user._time;
         require(_usertime>BEBtime || _user._time==0,"You can't air drop again, please wait 24 hours");
          
         uint256 random2 = random(block.difficulty+_usertime+_times);
         if(random2==88){
                  _user._time=now;
                  _user._eth=1 ether;
                  _user._bz=1;
                  _user._beb=0;
                  _user._romd=random2;
                  _opensome+=1;
                  _user.sumbeb+=100*10**18;
                  _user.sumeth+=1 ether;
                  _user.Bond-=1;
                  require(this.balance>=1 ether,"Insufficient contract balance");
                  msg.sender.transfer(1 ether);
                  bebTokenTransfer.transfer(msg.sender,100*10**18);
         }else{
             if(random2==55){
                _user._time=now;
                  _user._eth=100000000000000000;
                  _user._bz=1;
                  _user._beb=0;
                  _user._romd=random2;
                  _opensome+=1;
                  _user.sumbeb+=88*10**18;
                  _user.sumeth+=100000000000000000;
                  _user.Bond-=1;
                  require(this.balance>=100000000000000000,"Insufficient contract balance");
                  msg.sender.transfer(100000000000000000);
                  bebTokenTransfer.transfer(msg.sender,88*10**18); 
             }else{
                 if(random2==22){
                    _user._time=now;
                  _user._eth=80000000000000000;
                  _user._bz=1;
                  _user._beb=0;
                  _user._romd=random2;
                  _opensome+=1;
                  _user.sumbeb+=58*10**18;
                  _user.sumeth+=80000000000000000;
                  _user.Bond-=1;
                  require(this.balance>=80000000000000000,"Insufficient contract balance");
                  msg.sender.transfer(80000000000000000);
                  bebTokenTransfer.transfer(msg.sender,58*10**18);  
                 }else{
                    _user._time=now;
                   
                  uint256 sstt=random2* 10 ** 18;
                  uint256 rrr=sstt/2000;
                 _user._eth=rrr;
                 uint256 beb=random2* 10 ** 18;
                 _user._beb=beb;
                 _user._romd=random2;
                  _user._bz=1;
                  _opensome+=1;
                  _user.sumbeb+=beb;
                  _user.sumeth+=rrr;
                  _user.Bond-=1;
                  require(this.balance>=rrr,"Insufficient contract balance");
                  msg.sender.transfer(rrr);
                 bebTokenTransfer.transfer(msg.sender,beb);  
                 }
             }
         }
     }

     function getLUCK()public view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256){
         luckuser storage _user=luckusers[msg.sender];
         return (_user._time,_user._eth,_user._beb,_user._bz,_user._romd,opentime,_user.Bond,_user.sumeth,_user.sumbeb);
     }
     
    function getTokenBalance() public view returns(uint256){
         return bebTokenTransfer.balanceOf(address(this));
    }
    function getTokenBalanceUser(address _addr) public view returns(uint256){
         return bebTokenTransfer.balanceOf(address(_addr));
    }
    function gettime() public view returns(uint256,uint256,uint256,uint256){
         return (opentime,Numberofairdrops,opensome,_opensome);
    }
    function querBalance()public view returns(uint256){
         return this.balance;
     }
     function ETHwithdrawal(uint256 amount) payable  onlyOwner {
        
       require(this.balance>=amount,"Insufficient contract balance");
       owner.transfer(amount);
    }
    function BEBwithdrawal(uint256 amount)onlyOwner {
       uint256 _amount=amount* 10 ** 18;
       bebTokenTransfer.transfer(owner,_amount);
    }
    function setLUCK(uint256 _opensome_,uint256 _time)onlyOwner{
        opensome=_opensome_;
        BEBtime=_time;
        
    }
    function setAirdrop(address _addr,uint256 _opensome_)onlyOwner{
        luckuser storage _user=luckusers[_addr];
        _user.Bond-=_opensome_;
        
    }
    function AirdropAuthorization(address _addr,uint256 _value)public{
        require(tx.origin == msg.sender);
        require(ownersto==msg.sender);
        luckuser storage _user=luckusers[_addr];
        _user.Bond+=_value;
    }
     
     function random(uint256 randomyType)  internal returns(uint256 num){
        uint256 random = uint256(keccak256(randomyType,now));
         uint256 randomNum = random%101;
         if(randomNum<1){
             randomNum=1;
         }
         if(randomNum>100){
            randomNum=100; 
         }
         
         return randomNum;
    }
    function eth()payable{
    }
    function ()payable{
    }
}