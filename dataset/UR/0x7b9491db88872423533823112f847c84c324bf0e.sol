 

pragma solidity ^0.4.24;

 

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


contract DistributeTokens {
    using SafeMath for uint;
    
    address public owner; 
    address[] investors; 
    uint[] public usage_count;
    uint  interest;
    uint public count; 
    uint public total_count; 
    uint public son = 2;
    uint public mon = 3;
    
   

    constructor() public {
        owner = msg.sender;
    }
    
    mapping(address=>uint)my_interest;
    mapping(address=>user_info) public userinfo; 
    mapping(address=>address)verification;
    mapping(address=>uint) public Dividing_times;
    mapping(uint=>address) number;
    mapping(address=>uint)public Amount_invested;
    mapping(address=>address)quite_user;
    
    event invest_act(address user, uint value, uint interest);
    event end( address user);
    
    struct user_info{
        uint amount;
        uint user_profit;  
        uint block_number;
        uint timestamp;
    }

     
    function invest() public payable {
        require(msg.sender != verification[msg.sender],"這組帳號使用過");
        require(msg.value != 0 ,"不能為零");
        verification[msg.sender]=msg.sender;
        
        Amount_invested[msg.sender]=msg.value;
        my_interest[msg.sender]=interest;
        
        investors.push(msg.sender);   
        usage_count.push(1);
        fee(); 
        
        userinfo[msg.sender]=user_info(msg.value,interest,block.number,block.timestamp);
        count=count.add(1);
        total_count=total_count.add(1);
        
        emit invest_act(msg.sender,msg.value,interest);
        
    }
    
    
    function fee()private{
        owner.transfer(msg.value.div(50));
    }
    
    function querybalance()public view returns (uint){
        return address(this).balance;
    }
    
     
    
    function distribute(uint a, uint b) public {
        require(msg.sender == owner); 
        owner.transfer(address(this).balance.div(200));
        
        for(uint i = a; i < b; i++) {
            investors[i].transfer(Amount_invested[investors[i]].div(my_interest[investors[i]]));
            number[i]=investors[i];
            Dividing_times[number[i]] = usage_count[i]++;
        } 
    }
    
     
     
    
    function getInterest() public view returns(uint){
        if(interest <= 2190 && interest >= 0)
         return interest;
        else
         return 0;
    }    
    
    
    function Set_Interest(uint key)public{
        require(msg.sender==owner);
        if(key<=2190){
            interest = key;
        }else{
            interest = interest;
        }
    }
    
     
    
    function Safe_trans() public {
        require(owner==msg.sender);
        owner.transfer(querybalance());
    } 
    
     
    
    function Set_quota(uint _son, uint _mon)public {
        require(owner == msg.sender);
        if(_son<_mon && _son<=100 && _mon<=100){
            son=_son;
            mon=_mon;
        }else{
            son=son;
            mon=mon;
        }
    }
    
    
    function quit()public {
        
        if(quite_user[msg.sender]==msg.sender){
            revert("你已經退出了");
        }else{
        msg.sender.transfer(Amount_invested[msg.sender].mul(son).div(mon));
        quite_user[msg.sender]=msg.sender;
        my_interest[msg.sender]=1000000;
        Amount_invested[msg.sender]=1;
        userinfo[msg.sender]=user_info(0,0,block.number,block.timestamp);
        count=count.sub(1);
        }
        
        emit end(msg.sender);
    }
    
    
}