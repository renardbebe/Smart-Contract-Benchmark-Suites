 

pragma solidity^0.4.20;  
 
interface tokenTransfer {
    function transfer(address receiver, uint amount);
    function transferFrom(address _from, address _to, uint256 _value);
    function balanceOf(address receiver) returns(uint256);
}

contract Ownable {
  address public owner;
  bool lock = false;
 
 
     
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

contract BebPos is Ownable{

     
   struct BebUser {
        address customerAddr; 
        uint256 amount;  
        uint256 bebtime; 
         
    }
    uint256 Bebamount; 
    uint256 bebTotalAmount; 
    uint256 sumAmount = 0; 
    uint256 OneMinuteBEB; 
    tokenTransfer public bebTokenTransfer;  
    uint8 decimals = 18;
    uint256 OneMinute=1 minutes;  
     
    mapping(address=>BebUser)public BebUsers;
    address[] BebUserArray; 
     
    event messageBetsGame(address sender,bool isScuccess,string message);
     
    function BebPos(address _tokenAddress,uint256 _Bebamount,uint256 _bebTotalAmount,uint256 _OneMinuteBEB){
         bebTokenTransfer = tokenTransfer(_tokenAddress);
         Bebamount=_Bebamount*10**18; 
         bebTotalAmount=_bebTotalAmount*10**18; 
         OneMinuteBEB=_OneMinuteBEB*10**18; 
         BebUserArray.push(_tokenAddress);
     }
          
    function freeze(uint256 _value,address _addr) public{
         
       if(BebUsers[msg.sender].amount == 0){
            
           if(Bebamount > OneMinuteBEB){
           bebTokenTransfer.transferFrom(_addr,address(address(this)),_value); 
           BebUsers[_addr].customerAddr=_addr;
           BebUsers[_addr].amount=_value;
           BebUsers[_addr].bebtime=now;
           sumAmount+=_value; 
            
            
           messageBetsGame(msg.sender, true,"转入成功");
            return;   
           }
           else{
            messageBetsGame(msg.sender, true,"转入失败,BEB总量已经全部发行完毕");
            return;   
           }
       }else{
            messageBetsGame(msg.sender, true,"转入失败,请先取出合约中的余额");
            return;
       }
    }

     
    function unfreeze(address referral) public {
        address _address = msg.sender;
        BebUser storage user = BebUsers[_address];
        require(user.amount > 0);
         
        uint256 _time=user.bebtime; 
        uint256 _amuont=user.amount; 
           uint256 AA=(now-_time)/OneMinute*OneMinuteBEB; 
           uint256 BB=bebTotalAmount-Bebamount; 
           uint256 CC=_amuont*AA/BB; 
            
           if(Bebamount > OneMinuteBEB){
              Bebamount-=CC; 
              
             user.bebtime=now; 
           }
         
        if(Bebamount > OneMinuteBEB){
            Bebamount-=CC; 
            sumAmount-=_amuont;
            bebTokenTransfer.transfer(msg.sender,CC+user.amount); 
            
            BebUsers[_address].amount=0; 
            BebUsers[_address].bebtime=0; 
             
            messageBetsGame(_address, true,"本金和利息成功取款");
            return;
        }
        else{
            Bebamount-=CC; 
            sumAmount-=_amuont;
            bebTokenTransfer.transfer(msg.sender,_amuont); 
            
            BebUsers[_address].amount=0; 
            BebUsers[_address].bebtime=0; 
             
            messageBetsGame(_address, true,"BEB总量已经发行完毕，取回本金");
            return;  
        }
    }
    function getTokenBalance() public view returns(uint256){
         return bebTokenTransfer.balanceOf(address(this));
    }
    function getSumAmount() public view returns(uint256){
        return sumAmount;
    }
    function getBebAmount() public view returns(uint256){
        return Bebamount;
    }
    function getBebAmountzl() public view returns(uint256){
        uint256 _sumAmount=bebTotalAmount-Bebamount;
        return _sumAmount;
    }
    function myfrozentokens() public view returns (uint){
		return sumAmount;
	}

    function totalSupply() public view returns (uint){
        return Bebamount;
    }
    
    function earningrate() public view returns (uint){
        BebUser storage user = BebUsers[msg.sender];
       assert(user.amount > 0);
       uint256 A=(now-user.bebtime)/OneMinute*OneMinuteBEB;
       uint256 B=bebTotalAmount-Bebamount;
       uint256 C=user.amount*A/B + user.amount;
       return C;
    }
    
	function myBalance() public view returns (uint){
       BebUser storage user = BebUsers[msg.sender];
       return user.amount;
    }
    
    function checkinterests() public view returns(uint) {
       BebUser storage user = BebUsers[msg.sender];
       assert(user.amount > 0);
       uint256 A=(now-user.bebtime)/OneMinute*OneMinuteBEB;
       uint256 B=bebTotalAmount-Bebamount;
       uint256 C=user.amount*A/B;
       return C;
    }


    function getLength() public view returns(uint256){
        return (BebUserArray.length);
    }
     function getUserProfit(address _form) public view returns(address,uint256,uint256,uint256){
       address _address = _form;
       BebUser storage user = BebUsers[_address];
       assert(user.amount > 0);
       uint256 A=(now-user.bebtime)/OneMinute*OneMinuteBEB;
       uint256 B=bebTotalAmount-Bebamount;
       uint256 C=user.amount*A/B;
        return (_address,user.bebtime,user.amount,C);
    }
    function()payable{
        
    }
}