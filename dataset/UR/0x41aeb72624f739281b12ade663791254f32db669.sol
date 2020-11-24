 

pragma solidity ^0.5.5;
library SafeMath{

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256){
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256){
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256){
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
contract EPlay {
    modifier isOwner() {
        require(msg.sender == _owner);
        _;
    }
struct User{
        address userAddress;
        uint investAmount;   
        address inviter;    
        address[] children; 
        uint invitersCount;   
        uint achieveTime;   
        uint annualRing;  
        uint64 referCode;   
uint birth;               
uint rebirth;             
bool gameOver;
    }
    address _owner;
    address[] public investors;
    mapping (address => User) public addressToUser;
    mapping (uint64 => address) public codeToAddress;

    uint256 minInvest;

    uint256 maxInvest;

    uint64 currentReferCode;


    uint256 public globalNodeNumber = 0;

    uint256 public totalInvestAmount;  

    uint256 public ethMissPool; 
    uint256 public racePool;   
     
    address fusePool;     
address guaranteePool;   
address foundingPool;    
address appFund;         
uint256 oneLoop = 24 hours;
uint256 roundOfLoop = 9;

    constructor() public{
        _owner = msg.sender;
        minInvest = 1 ether;
        maxInvest = 29 ether;
        currentReferCode = 168870;

        User memory creation = User(msg.sender, minInvest, address(0x0), new address[](0),0, 0,0,currentReferCode,now, now, false);
addressToUser[msg.sender] = creation;
codeToAddress[currentReferCode] = msg.sender;
currentReferCode = currentReferCode + 9;

fusePool = address(0x513E61aD45ABCe80c3306BDF535b8964129f675d);
guaranteePool = address(0xAfC22C4e544600675AA322608435ae6C65bccA05);
foundingPool = address(0xAD7565A73b145e7FC58fAc02eECa28a1591C551e);
appFund = address(0x6464FC7e76c1167608A2aa9d4238A792FD766013);

    }
	function transferOwnership(address newOwner) public isOwner {
		require(newOwner != address(0x0), "Ownable: new owner is the zero address");
		_owner = newOwner;
	}
	function isOrNotOwner() public view returns (bool){
	    return _owner == msg.sender;
	}
    function() payable external{
        ethMissPool = SafeMath.add(ethMissPool,msg.value);
    }


    function invest(uint64 referrNO)public payable{

        require(msg.value >= minInvest, "less than min");
        User memory o_user = addressToUser[msg.sender];

        require(SafeMath.add(msg.value, o_user.investAmount) <= maxInvest, "more than max");
        address r_address =  codeToAddress[referrNO];
        require (r_address != address(0x0), "invalid referrNO");
        o_user.investAmount = SafeMath.add(o_user.investAmount, msg.value);
        o_user.rebirth = now;
        o_user.annualRing = 0;
        o_user.gameOver = false;
         User  storage r_user = addressToUser[r_address];
        if (o_user.inviter == address(0x0)){

           
           
            r_user.children.push(msg.sender);
            o_user.birth = now;
            o_user.inviter = r_user.userAddress;
            o_user.userAddress = msg.sender;
            codeToAddress[currentReferCode] = msg.sender;
            o_user.referCode = currentReferCode;
            currentReferCode = currentReferCode + 9;
            investors.push(msg.sender);
            globalNodeNumber = globalNodeNumber + 1;
        }else{

        }
        r_user.invitersCount = SafeMath.add(r_user.invitersCount , msg.value);
        r_user.achieveTime = now;
        
    addressToUser[msg.sender] = o_user;
    totalInvestAmount = totalInvestAmount + msg.value;
    address payable payFoundingPool = address(uint160(foundingPool));
    payFoundingPool.transfer(SafeMath.div( msg.value, 100));
    address payable payAppFund = address(uint160(appFund));
    payAppFund.transfer(SafeMath.div( msg.value, 50));
    racePool = SafeMath.add(racePool, SafeMath.div(msg.value, 100));
    }
    function sendReward() public isOwner{

        for (uint i = 0; i < investors.length; i ++){
            address _add = investors[i];
            User memory _user = addressToUser[_add];
            if (_user.gameOver){
                autoReInvest(_add);
                _user.rebirth = now - (oneLoop / 2);
                addressToUser[_add] = _user;
            }else {
                if (SafeMath.sub(now , _user.rebirth) >=  oneLoop){
                
                  address payable needPay = address(uint160(_add));
      
                 uint staticAmount = getStatic(_add);
                      if (staticAmount > 0){
                     needPay.transfer(staticAmount);
                    }
                    uint dynamicAmount = getDynamic(_add);

                    if (dynamicAmount > 0){
                        needPay.transfer(dynamicAmount);
                        address payable safePool = address(uint160(fusePool));
                        safePool.transfer(SafeMath.div(dynamicAmount, 5));
                  }
                
                   if(SafeMath.sub(now, _user.rebirth) >=  (oneLoop * roundOfLoop)){
                        _user.annualRing = _user.annualRing + 1;
                        _user.rebirth = now - (oneLoop / 2);
                        _user.gameOver = true;
                      addressToUser[_add] = _user;
                     }
                
                 }
            }
        }
    }
    function autoReInvest(address _address) private {
        User memory _user = addressToUser[_address];
        require (_user.gameOver, "auto reInvest");
        _user.gameOver = false;
        addressToUser[_address] = _user;
        uint payAmount = _user.investAmount;
         address payable payFoundingPool = address(uint160(foundingPool));
    payFoundingPool.transfer(SafeMath.div( payAmount, 100));
    address payable payAppFund = address(uint160(appFund));
    payAppFund.transfer(SafeMath.div(payAmount, 50));
    }
    function reInvest() public{
      autoReInvest(msg.sender);
    }
    function canWithDraw() public view returns (bool){
         User memory _user = addressToUser[msg.sender];
        require (_user.gameOver, "can't withdraw");
        return true;
    }
    function withDrawForUser() public{
        User storage _user = addressToUser[msg.sender];
        require (_user.gameOver, "auto reInvest,can't withdraw");
        address payable needPay = address(uint160(_user.userAddress));
        
        uint payAmount = _user.investAmount;

        require (payAmount > 0, "no amount");
        _user.investAmount = 0;
        if (_user.annualRing > 3){
            needPay.transfer(SafeMath.mul(SafeMath.div(payAmount,100), 95));
            address payable pool = address(uint160(guaranteePool));
            pool.transfer(SafeMath.mul( SafeMath.div(payAmount,100),5));
        }else if (_user.annualRing > 2){
            needPay.transfer(SafeMath.mul(SafeMath.div(payAmount,100), 90));
            address payable pool = address(uint160(guaranteePool));
            pool.transfer(SafeMath.mul( SafeMath.div(payAmount,100),10));
        }else if (_user.annualRing > 1){
            needPay.transfer(SafeMath.mul(SafeMath.div(payAmount,100), 85));
            address payable pool = address(uint160(guaranteePool));
            pool.transfer(SafeMath.mul( SafeMath.div(payAmount,100),15));
        }else if (_user.annualRing > 0){
            needPay.transfer(SafeMath.mul(SafeMath.div(payAmount,100), 80));
            address payable pool = address(uint160(guaranteePool));
            pool.transfer(SafeMath.mul( SafeMath.div(payAmount,100),20));
        }
        
    }
    function getStatic(address _address) public view returns(uint){
if (getLevel(_address) == 1){
   User memory _user = addressToUser[_address];
   return SafeMath.mul(SafeMath.div(_user.investAmount, 1000),11 );  
}else if (getLevel(_address) == 2){
   User memory _user = addressToUser[_address];
   return SafeMath.mul(SafeMath.div(_user.investAmount, 1000),11 );  
}else if (getLevel(_address) == 3){
   User memory _user = addressToUser[_address];
   return SafeMath.mul(SafeMath.div(_user.investAmount, 1000),12 );  
}else if (getLevel(_address) == 4){
   User memory _user = addressToUser[_address];
   return SafeMath.mul(SafeMath.div(_user.investAmount, 1000),13 );  
}
return 0;
    }
    function getDynamic(address _address) public view returns(uint){
       if (getLevel(_address) == 0){
           return 0;
       }else  if (getLevel(_address) == 1){
            return getChildrenDynamic(_address, _address, 1, 1, 0);
       }else  if (getLevel(_address) == 2){
           return  getChildrenDynamic(_address, _address, 1, 2, 0);
       }else  if (getLevel(_address) == 3){
           return getChildrenDynamic(_address, _address, 1, 10, 0);
       }else  if (getLevel(_address) == 4){
           return getChildrenDynamic(_address, _address, 1, 99, 0);
       }
    }
    function getChildrenDynamic(address adam, address _par,uint8 generation,uint endGeneration, uint total) public view returns (uint){

    User memory _user = addressToUser[_par];
    address[] memory child = _user.children;
    uint myTotal = 0;

    for (uint i = 0; i < child.length; i ++){
        User memory _childUser = addressToUser[child[i]];
        uint rate = getDynamicRate(adam, generation);
        uint staticReward = 0;
        User memory adamUser = addressToUser[adam];
        if (adamUser.investAmount <= _childUser.investAmount){
            staticReward = getStatic(adam);
        }else {
            staticReward = getStatic(_childUser.userAddress);
        }
        if (generation < endGeneration){
            myTotal = getChildrenDynamic(adam, _childUser.userAddress, generation + 1, endGeneration, myTotal);
        }
        
        myTotal = myTotal + SafeMath.mul(SafeMath.div(staticReward , 100),rate);
    }
    return myTotal + total;
}
function getDynamicRate(address _address,uint generation)public view returns (uint){
if (getLevel(_address) == 1){
if (generation == 1){
    return 60;
}
}else if (getLevel(_address) == 2){
if (generation == 1){
    return 70;
}else if (generation == 2){
    return 30;
}
}else if (getLevel(_address) == 3){
    if (generation == 1){
    return 80;
}else if (generation == 2){
    return 30;
}else if (generation == 3){
    return 20;
}else if (generation <= 10){
    return 10;
}

}else if (getLevel(_address) == 4){
   if (generation == 1){
    return 100;
}else if (generation == 2){
    return 40;
}else if (generation == 3){
    return 30;
}else if (generation <= 10){
    return 10;
}else if (generation <= 15){
    return 5;
}else if (generation <= 99){
   return 1; 
}
}
return 0;
}
    

    function getLevel(address _address) public view returns(uint8){
User memory _user = addressToUser[_address];
if (_user.investAmount >= 16 ether){
return 4;
}else if (_user.investAmount >= 11 ether){
    return 3;
}else if (_user.investAmount >= 6 ether){
    return 2;
}else if (_user.investAmount >= 1 ether){
return 1;
}   
return 0;
 }
    function sendRace() public isOwner{

        address[] memory top10 = getTop10();
        uint256[9] memory rate = [uint256(40),20,10,5,5,5,5,5,5];
        uint256 sendedAmount = 0;
        for (uint i = 0; i < top10.length; i ++){
            address _add = top10[i];
            if (_add != address(0x0)){
                User memory _user = addressToUser[_add];
                if (_user.invitersCount != 0){
                    address payable needPay = address(uint160(_user.userAddress));
                    needPay.transfer(SafeMath.mul(SafeMath.div(racePool, 100), rate[i]));
                    sendedAmount = sendedAmount + SafeMath.mul(SafeMath.div(racePool, 100), rate[i]);
                }
            }
        }
        racePool = SafeMath.sub(racePool, sendedAmount);
        resetRace();


    }
    function getTop10() public view returns(address[] memory) {
              address[] memory allInvitors = investors;
         for (uint i = allInvitors.length - 1; i > 0; i--){
             address temp;
             for (uint j = i; j > 0; j--){
                 User memory _user = addressToUser[allInvitors[j]];
                 User memory _preUser = addressToUser[allInvitors[j - 1]];
                 if (_user.invitersCount > _preUser.invitersCount){
                     temp = allInvitors[j];
                     allInvitors[j] = allInvitors[j - 1];
                     allInvitors[j - 1] = temp;
                 }else if (_user.invitersCount == _preUser.invitersCount && _user.achieveTime < _preUser.achieveTime){
                    temp = allInvitors[j];
                     allInvitors[j] = allInvitors[j - 1];
                     allInvitors[j - 1] = temp;
                }
             }
         }
        address[] memory top9 = new address[](9);
        uint count = 9;
        if (allInvitors.length < 9){
            count = allInvitors.length;
        }
        for (uint i = 0; i < count; i++){
            top9[i] = allInvitors[i];
        }

         return top9;
    }
    function getTopInfo (uint rank)public view returns(address, uint, uint){
         address[] memory allInvitors = investors;
         for (uint i = allInvitors.length - 1; i > 0; i--){
             address temp;
             for (uint j = i; j > 0; j--){
                 User memory _user = addressToUser[allInvitors[j]];
                 User memory _preUser = addressToUser[allInvitors[j - 1]];
                 if (_user.invitersCount > _preUser.invitersCount){
                     temp = allInvitors[j];
                     allInvitors[j] = allInvitors[j - 1];
                     allInvitors[j - 1] = temp;
                 }else if (_user.invitersCount == _preUser.invitersCount && _user.achieveTime < _preUser.achieveTime){
                    temp = allInvitors[j];
                     allInvitors[j] = allInvitors[j - 1];
                     allInvitors[j - 1] = temp;
                }
             }
         }
         if (allInvitors.length > rank){
         User memory userRank = addressToUser[allInvitors[rank]];

         return (userRank.userAddress,userRank.children.length,userRank.invitersCount);
         }else{
        return(address(0x0),0,0);
    }
         
    }
    function resetRace() private isOwner{
        for (uint i = 0; i < investors.length; i ++){
            User storage _user = addressToUser[investors[i]];
            _user.invitersCount = 0;
        }
    }


}