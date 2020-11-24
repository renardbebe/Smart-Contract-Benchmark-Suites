 

pragma solidity ^0.5.0;


contract FundSmart {
    address payable manager;


    uint256 private TOP_BORDER_LEVEL = 1000 ether;
    
    
    uint256 private MIN_DEPOSIT = 1 ether;
    
    uint256 public DEADLINE = 15;

    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }
    
    uint public count = 0;
    
    mapping(address => Invest[]) public invests;
    
    mapping (uint => address) public userCount;
    
    mapping(address => User) public users;
    
    mapping(address => profitBySystem) public profitOfUser;
    
    mapping(address =>  Ancestor[]) public ancestors;
    
    mapping(address => address[]) public children;

    mapping(address => uint) public level;
    

    address public owner;
     
    event LogDepositMade(address indexed accountAddress, uint amount);
    
    
    struct Ancestor {
        address payable add;
    }
    
    struct profitBySystem {
        bool exists;
        uint profitRef;
        uint profitReceive;
        uint profitOfRefReceive;
    }
    
    struct Invest {
        bool exists;
        bool requireWithdraw;
        uint lending;
        uint deadline;
        uint timeinvest;
        uint starttime;
    }

    struct User {
        bool exists;
        address payable parent;
        uint256 total;
        uint totalUser;
    }

    event AddNewUser(
        bool exists,
        address parent,
        uint256 total
    );
    
    event Withdraw (
        string msg
    );


    function Balance() public view returns (uint) {
        return address(this).balance;
    }
    
    constructor() public payable {
        owner = msg.sender;
        manager = msg.sender;
    }
    
    function() external payable {
        payForManager(msg.value);
    }
    
    function setDeadline(uint _deadline) public onlyOwner{
        require(_deadline>=15 && _deadline <=30);
        DEADLINE = _deadline;
    }
    
    function deposit() public payable {
         
        require(msg.value >= MIN_DEPOSIT);
         
        address payable _add = msg.sender;
       
        payForManager(msg.value);
         
        if(users[_add].exists) {
            users[_add].total +=  msg.value;
            users[_add].totalUser += msg.value;
            uint  _deadlines = now + DEADLINE * 1 days;
            profitOfUser[_add].exists = true;
            invests[_add].push(Invest({
                lending : msg.value,
                requireWithdraw: true,
                timeinvest : now,
                starttime : now,
                deadline : _deadlines,
                exists : true
            }));
            if(profitOfUser[users[_add].parent].exists){
                profitOfUser[users[_add].parent].profitRef += msg.value * 8 / 100;   
            }
            
            if(level[_add]==0){
                if(handlerlevelOne(_add)){
                    level[_add] = 1;
                }
            } 
            handlerAncestorTotal(_add,msg.value);

            emit LogDepositMade(_add, msg.value);
        } else {
            
        }
    }
    
    function getProfit(uint _level) private pure returns(uint){
        if(_level == 0){
            return 0;
        }
        
        if(_level == 1){
            return 3;
        }
        
        if(_level ==2){
            return 5;
        }
        
        if(_level==3){
            return 6;
        }
        
        return 0;
    }
    function handlerAncestorTotal(address _add, uint256 _total) private {
        Ancestor[] memory _ancestors = ancestors[_add];
        uint numberAncentors = _ancestors.length;
        if(numberAncentors>0){
            for(uint i=0; i< numberAncentors;i++){
                address addr = _ancestors[numberAncentors-1-i].add;
                updateTotalOfUser(addr,_total);
            }
        }
    }

    function payForManager(uint amount) private  {
        manager.transfer(amount / 10);
    }


    function addNewUser(string memory _parent) public payable{
        address payable parent;
        
        if (bytes(_parent).length > 0) {
             parent = parseAddr(_parent); 
        } else {
             parent = address(0x0);
        }
        
        if(!users[parent].exists){
            parent = address(0x0);
        }
        address payable _add = msg.sender;
        if(!users[msg.sender].exists && msg.sender != parent){
            count++;
            handlerAncestor(_add, parent);
             
            handlerChildren(_add, parent);

            User memory user = User({
                 exists: true, 
                 parent: parent, 
                 total: 0,
                 totalUser: 0
            });
    
            users[msg.sender] = user;
            userCount[count] = msg.sender;
            emit AddNewUser(true, parent, 0);
        }
    }
    
    
    function handlerAncestor(address payable _add, address payable _parents) private {       
        User storage user = users[_parents];
        if(user.exists) {
            ancestors[_add] = ancestors[_parents];
            ancestors[_add].push(Ancestor({add: _parents}));
        }
    }
    
    function handlerChildren(address _add, address payable _parents) private {
        User storage user = users[_parents];        
          if(user.exists) {
            children[_parents].push(_add);
        }
    }
    
    
    function updateTotalOfUser(address add, uint256 total) private {
        require(total > 0);
        User storage user = users[add];
        if(user.exists) {
            user.total += total;
            if(level[add]==0){
                if(handlerlevelOne(add)){
                    level[add] = 1;
                }
            } else {
                uint _percent = getProfit(level[add]);
                profitOfUser[add].profitRef += total * _percent /100;
                if(handlerLevel(add, level[add])){
                    level[add]++;
                    if(level[add]>=3){
                        level[add] == 3;
                    }
                }
                
            }
        } 
    }
    
    function handlerlevelOne(address _add) private view returns(bool){
        bool result = false;
        address[] memory _children = children[_add];
        if(users[_add].total>= TOP_BORDER_LEVEL && _children.length >=3 && profitOfUser[_add].exists){
            uint _currentChildTotal;
            uint threeMin = 0 ether;
            uint twoMin = 0 ether;
            for(uint i = 0; i< _children.length; i++){
                _currentChildTotal = users[_children[i]].total;
                if(_currentChildTotal >=200 ether && _currentChildTotal < 300 ether){
                   if(twoMin == 0 || _currentChildTotal < twoMin){
                       twoMin = _currentChildTotal;
                   } 
                }
                if(_currentChildTotal >= 300 ether){
                    if(threeMin == 0 || _currentChildTotal < threeMin){
                        threeMin = _currentChildTotal;
                    }
                }
            }
            
            if(threeMin >0 && threeMin > 0){
                if(users[_add].total - threeMin - twoMin >= 500 ether){
                    result = true;
                }
            }
        }
        
        return result;
    }
    
    function handlerLevel(address _add, uint _level) private view returns(bool){
        bool result = false;
         address[] memory _children = children[_add];
        if(users[_add].total>= TOP_BORDER_LEVEL && _children.length >=3){
            uint _subTotal = users[_add].total;
            uint _countLevel;
            for(uint i = 0; i< _children.length; i++){
                if(level[_children[i]] >= _level){
                    _countLevel++;
                    _subTotal = _subTotal - users[_children[i]].total;
                }
            }
            
           if(_countLevel ==2 ){
               if(_subTotal >= 500 ether){
                   result = true;
               }
           }
           
           if(_countLevel >=3){
               result = true;
           }
            
        }
        
        return result;
    }

    function downGradeLevel(address _add) private {
        if(level[_add]==3){
            if(!handlerLevel(_add,2)){
                level[_add] = 2;
            }
        }
        
        if(level[_add] == 2){
            if(!handlerLevel(_add,1)){
                level[_add] = 1;
            }
        }
        
        if(level[_add]==1){
            if(!handlerlevelOne(_add)){
                level[_add] = 0;
            }
        }
    }

    
    function parseAddr(string memory _a) private pure returns (address payable _parsedAddress) {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }
    
    
    function checkWithdraw(uint _index, uint _time, Invest[] storage _invests) private returns (bool) {

        uint i = _index+1;
        bool isCheck = false;
        while(i < _invests.length && !isCheck){
            if(_invests[i].starttime >= _time && _invests[i].requireWithdraw){
                if(_invests[i].lending >= _invests[_index].lending){
                     isCheck = true;
                    _invests[i].requireWithdraw = false;
                }
            }
            
            i +=1;
        }
    
        return isCheck;
    }
    
    
    function userWithdraw(address _add) private returns (uint) {
        Invest[] storage _invest = invests[_add];
        uint total = 0;
        
        for(uint i =0 ; i< _invest.length; i++){
            if(now >= _invest[i].deadline){
                if(_invest[i].exists){
                    if(checkWithdraw(i,_invest[i].deadline,_invest)){
                        total += _invest[i].lending;
                        _invest[i].exists = false;
                        _invest[i].timeinvest = now;
                    } 
                }
                
            }
        }
        
        return total;
    }

    event LogWithdraw(address indexed accountAddress, string msg);
    
    
    function downGradeLevelAncentor(address _add, uint _total) private {
        Ancestor[] memory _ancestors = ancestors[_add];
        for(uint i =0; i <_ancestors.length; i++){
            address _anc = _ancestors[_ancestors.length-1-i].add;
            users[_anc].total -= _total;
            downGradeLevel(_anc);
        }
    }
   
    function originalWithdraw () public payable{
        address payable add = msg.sender;
        if(profitOfUser[add].exists){
            uint _total = userWithdraw(add);
            if(_total > 0){
                uint amount = _total + _total * 8 / 100 ;
                users[add].total -= _total;
                users[add].totalUser -= _total;
                add.transfer(amount);
                downGradeLevel(add);
                downGradeLevelAncentor(add,_total);
                profitOfUser[add].profitReceive += amount;
                emit LogWithdraw(add, "Withdraw Succes");
            } else {
                emit LogWithdraw(add, "You Are Not Eligible To Withdraw");
            }
        } else {
            emit LogWithdraw(add, "You May Invest To Withdraw");
        }
    }
    
    function withdrawProfit() public payable {
        address payable add = msg.sender;
        if(profitOfUser[add].exists){
            uint _total = profitOfUser[add].profitRef + profitOfUser[add].profitOfRefReceive;
            if(_total >= users[add].totalUser){
                if(users[add].totalUser > profitOfUser[add].profitOfRefReceive){
                    add.transfer(users[add].totalUser-profitOfUser[add].profitOfRefReceive);
                    profitOfUser[add].profitRef = _total- users[add].totalUser;
                    profitOfUser[add].profitOfRefReceive = users[add].totalUser;
                }
            } else {
                add.transfer(profitOfUser[add].profitRef);
                profitOfUser[add].profitOfRefReceive += profitOfUser[add].profitRef;
                profitOfUser[add].profitRef = 0;
            }
            
            emit LogWithdraw(add, "Withdraw Succes");
        } else {
             emit LogWithdraw(add, "You May Invest To Withdraw ");
        }
    }

}