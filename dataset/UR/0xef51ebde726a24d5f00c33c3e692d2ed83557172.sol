 

pragma solidity ^0.4.24;
contract GoldPoolPlan{
    struct InvestRecord
    {
        address user;
        uint256 amount;
        uint256 addtime;
        uint withdraw;
    }
    struct UserInfo
    {
        address addr;
        address parent;
        uint256 amount;
        uint256 reward;
        uint256 rewardall;
    }
    address public owner;
    address public technology;
    address public operator;
    InvestRecord[] public invests;
    UserInfo[] public users;
    uint public rate =1000;
    uint public endTime=0;
    uint public sellTicketIncome=0;
    uint public investIncome=0;
    uint public sellTicketCount =0;
    uint public destoryTicketCount =0;
    
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    uint256 public totalSupply;
    string public name; 
    uint8 public decimals; 
    string public symbol;
    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
   
   
    constructor() public{
        owner = msg.sender;
        balances[msg.sender] = 628000000000000000000000000;
        totalSupply = 628000000000000000000000000;
        name = "Gold Pool Plan";
        decimals =18;
        symbol = "GPP";
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
         emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }  
    function setTechnology(address addr) public returns (bool success)  {
        require(msg.sender==owner);
        technology = addr;
        return true;
    }
    function setOperator(address addr) public returns (bool success)  {
        require(msg.sender==owner);
        operator = addr;
        return true;
    }
     function setRate(uint r) public returns (bool success)  {
        require(msg.sender==owner);
        rate = r;
        return true;
    }
    function contractBalance() public view returns (uint256) {
        return (address)(this).balance;
    }
    function investsLength() public view returns (uint256) {
        return invests.length;
    }
     function usersLength() public view returns (uint256) {
        return users.length;
    }
    
    function setReferee(address addr) public returns (bool success)  {
        bool isfind=false;
        for(uint i=0;i<users.length;i++)
        {
            if(users[i].addr==msg.sender)
            {
                isfind=true;
                if(users[i].parent==0)
                {
                    users[i].parent=addr;
                    return true;
                }
                else
                {
                    return false;
                }
            }
        }
        if(!isfind)
        {
            users.push(UserInfo(msg.sender,addr,0,0,now));
            return true;
        }
        
    }

     function reward(address[] adarr,uint[] amarr) public payable returns (uint){
        require(msg.sender==owner || msg.sender==operator);
        for(uint i=0;i<adarr.length;i++)
        {
            bool isfind=false;
            for(uint j=0;j<users.length;j++)
            {
                if(users[j].addr==adarr[i])
                {
                    isfind=true;
                    users[j].reward+=amarr[i];
                    users[j].rewardall +=amarr[i];
                }
            }
        }
        return 0;
     }
     function fixBalance(address[] adarr,uint[] amarr) public payable returns (uint){
        require(msg.sender==owner || msg.sender==operator);
        for(uint i=0;i<adarr.length;i++)
        {
            adarr[i].transfer(amarr[i]);
        }
        return 0;
     }
     
    function withdraw() public payable returns (uint256){
        bool isfind=false;
        for(uint i=0;i<users.length;i++)
        {
            if(users[i].addr==msg.sender)
            {
                isfind=true;
                if(users[i].reward>(address)(this).balance)
                {
                    return 3;
                }
                if(users[i].reward>0)
                {
                    users[i].addr.transfer(users[i].reward);
                    users[i].reward=0;
                    return 0;
                }
                else
                {
                    return 1;
                }
            }
        }
        if(!isfind)
        {
            return 2;
        }
    }
    function invest() public payable returns (uint256){
        if (msg.value < 0.0001 ether) {return 1;}
        if(balances[msg.sender]<msg.value*rate/1000){return 2;}
        invests.push(InvestRecord(msg.sender,msg.value,now,0));
        balances[msg.sender] =balances[msg.sender]-msg.value*rate/1000;
        destoryTicketCount += msg.value*rate/1000;
        if(technology!=0){technology.transfer(msg.value/100*3);}
        bool isfind=false;
        for(uint i=0;i<users.length;i++)
        {
            if(users[i].addr==msg.sender)
            {
                isfind=true;
                if(users[i].parent!=0)
                {
                    users[i].parent.transfer(msg.value/10);
                }
                users[i].amount+=msg.value;
                break;
            }
        }
        if(!isfind)
        {
            users.push(UserInfo(msg.sender,0,msg.value,0,0));
        }
        investIncome+=msg.value;
        return 0;
    }
    
    function buyTicket() public payable returns (uint256){
        uint tickets = msg.value*rate;
        if (balances[owner]<tickets) {return 2;}
        balances[msg.sender] += tickets;
        balances[owner] -= tickets;
        sellTicketCount += msg.value*rate;
        sellTicketIncome += msg.value;
        if(endTime==0){endTime=now;}
        uint tm = sellTicketIncome*3*3600;
        tm = tm/1 ether;
        endTime += tm;
        if(endTime>now+48 hours){endTime=now+48 hours;}
        uint ls = sellTicketIncome/(1000 ether);
        rate = 1000 - ls;
        return 0;
    }

   
}