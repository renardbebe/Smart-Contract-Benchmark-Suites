 

pragma solidity ^0.5.0;

contract auid  {
   
   
    
    function getRecommendScaleBylevelandTim(uint level,uint times) public view returns(uint);
    function compareStr ( string memory  _str,string memory str) public view returns(bool);
    function getLineLevel(uint value) public view returns(uint);
    function getScBylevel(uint level) public view returns(uint);
    function getFireScBylevel(uint level) public view returns(uint);
    function getlevel(uint value) public view returns(uint);
}


contract Fairbet {
    uint startTime = 0;
    uint ethWei = 1 ether;
    uint oneDayCount = 0;
    uint totalMoney = 0;
    uint totalCount = 0;
	uint private beginTime = 1;
    uint lineCountTimes = 1;
	uint184 private currentIndex = 2;
	address private owner;
	uint private actStu = 0;
	uint counts=0;
	uint lotteryeth=0;
	uint184 lotindex=0;
	uint suneth=0;
	event Instructor(address _address,uint _amount,uint _type,string _usernumber);
	struct User{
        uint invitenumber;
        address userAddress;  
        uint freeAmount;
        uint freezeAmount;
        uint8 ft;
        uint inviteAmonut;
        uint bonusAmount;
        uint dayInviteAmonut;
        uint dayBonusAmount;
        uint level;
        uint resTime;
        uint lineAmount;
        uint lineLevel;
        string inviteCode;
        string beInvitedCode;
		uint isline;
		uint status;
		bool isVaild;
		uint8 _type; 
		uint outTime;
    }
    struct Invest{

        address userAddress;
        uint inputAmount;
        uint resTime;
        string  inviteCode;
        string beInvitedCode;
		uint isline;
		uint status; 
		uint times;
    }
    
    struct Amounts{
        uint sumAmount;
        uint sumzAmount;
        uint luckyAmount;
        uint luckyzAmount;
    }
    
    mapping (address=>Amounts) amountsMapping;
    mapping (address => User) userMapping;
    mapping (string => address) addressMapping;
    mapping (uint184 => address) indexMapping;
    
    Invest[] invests;
    auid  util = auid(0xff090ec478a1814e8b148804cF93d8306d1b030D);
    modifier onlyOwner {
        require (msg.sender == owner, "OnlyOwner methods called by non-owner.");
        _;
    }
    
    constructor() public {
        startTime=now;
        owner = msg.sender;
        User memory user = User(0,owner,0,0,0,0,0,0,0,4,now,0,4,"0000000", "000000" ,1,1,true,0,0);
        userMapping[owner] = user;
        indexMapping[0] =owner;
        addressMapping["0000000"]=owner;
        Invest memory invest = Invest(owner,0,now, "0000000", "000000" ,1,2,0);
        invests.push(invest);
        addAmounts(owner);
        user = User(0,0x0000000000000000000000000000000000000001,0,0,0,0,0,0,0,4,now,0,4,"1a90d0a3", "000000" ,1,1,true,1,0);
        userMapping[0x0000000000000000000000000000000000000001] = user;
        indexMapping[1] =0x0000000000000000000000000000000000000001;
        addressMapping["1a90d0a3"]=0x0000000000000000000000000000000000000001;
        invest = Invest(0x0000000000000000000000000000000000000001,0,now, "1a90d0a3", "000000" ,1,2,0);
        invests.push(invest);
        addAmounts(0x0000000000000000000000000000000000000001);
    }
    
    function addAmounts(address userAddress)private{	
          Amounts memory amounts = Amounts(0,0,0,0);
          amountsMapping[userAddress]=amounts;
    }
    

    
    function invest(address userAddress ,uint inputAmount,string memory  inviteCode,string memory  beInvitedCode) public payable{
        require(!util.compareStr(inviteCode,"000000"),"Code  exit");
        userAddress = msg.sender;
  		inputAmount = msg.value;
        uint lineAmount = inputAmount;
        if(!getUserByinviteCode(beInvitedCode)){
            
            require(getUserByinviteCode(beInvitedCode),"Code must exit");
        }
        execute2(beInvitedCode,inputAmount);
        User memory userTest = userMapping[userAddress];
        if(util.compareStr(beInvitedCode,"1a90d0a3")&&now-15 days<startTime){
            require(inputAmount == 50 * ethWei,"Amount error");
            require(!userTest.isVaild,"error");
        }else{
            if(inputAmount < 1* ethWei || inputAmount > 30* ethWei || util.compareStr(inviteCode,"")){
                 
                    require(inputAmount >= 1* ethWei && inputAmount <= 30* ethWei && !util.compareStr(inviteCode,""), "between 1 and 30");
            }
             address  userAddressCode = addressMapping[inviteCode];
             
            if(userTest.isVaild && userTest.status != 2){
                require(util.compareStr(userTest.beInvitedCode,beInvitedCode),"error");
                    if(userTest.ft==0){
                    userTest.freezeAmount = userTest.freezeAmount + inputAmount;
                    userTest.lineAmount = userTest.lineAmount + lineAmount;
                    userTest.level =util.getlevel(userTest.freezeAmount);
                    userTest.lineLevel = util.getLineLevel(userTest.freezeAmount + userTest.freeAmount +userTest.lineAmount);
                    userMapping[userAddress] = userTest;
                    require((userTest.freezeAmount) <= 30 * ethWei,"can not beyond 30 eth");
                    }else{
                    require(inputAmount==userTest.freezeAmount,"error");
                    require(now-userTest.outTime<2 days,"error");
                    userTest.freezeAmount = inputAmount;
                    userTest.bonusAmount=0;
                    userTest.inviteAmonut=0;
                    userTest.ft=0;
                    userTest.outTime=0;
                    userMapping[userAddress] = userTest;
                    }
                    require(util.compareStr(beInvitedCode,userTest.beInvitedCode),"");
            }else{
                 uint level =util.getlevel(inputAmount);
                 uint lineLevel = util.getLineLevel(lineAmount);
                require(userAddressCode == 0x0000000000000000000000000000000000000000||userAddressCode==userAddress,"error");
               
                    userTest = User(0,userAddress,0,inputAmount,0,0,0,0,0,level,now,lineAmount,lineLevel,inviteCode, beInvitedCode ,1,1,true,1,0);
                if(util.compareStr(beInvitedCode,"1a90d0a3")){
                    userTest = User(0,userAddress,0,inputAmount,0,0,0,0,0,level,now,lineAmount,lineLevel,inviteCode, beInvitedCode ,1,1,true,0,0);
                }
                addAmounts(userAddress);
                userMapping[userAddress] = userTest;
                indexMapping[currentIndex] = userAddress;
                currentIndex = currentIndex + 1;
            }
        }
        totalMoney = totalMoney + inputAmount;
        suneth=suneth+(inputAmount/100)*5;
        address  userAddressCode1 = addressMapping[beInvitedCode];
        
        if((userMapping[userAddressCode1].lineAmount+userMapping[userAddressCode1].freezeAmount+userMapping[userAddressCode1].freeAmount)<=inputAmount)
        userMapping[userAddressCode1].invitenumber=userMapping[userAddressCode1].invitenumber+1;
     
        totalCount = totalCount + 1;
        bool isLine = false;
      
         Invest memory invest;
        if(beginTime==1){
            lineAmount = 0;
            oneDayCount = oneDayCount + inputAmount;
            invest= Invest(userAddress,inputAmount,now, inviteCode, beInvitedCode ,1,1,0);
            invests.push(invest);
            sendFeetoAdmin(inputAmount);
          	emit Instructor(msg.sender,inputAmount,1,beInvitedCode);
            
        }else{
            isLine = true;
            invest = Invest(userAddress,inputAmount,now, inviteCode, beInvitedCode ,0,1,0);
            inputAmount = 0;
            invests.push(invest);
        }
       
        address  userAddressCode = addressMapping[inviteCode];
          
          
            if(userAddressCode == 0x0000000000000000000000000000000000000000){
                addressMapping[inviteCode] = userAddress;
            }
            counts=counts+1;
            
            if(counts==100)
            {
                counts=0;
                lottery(lotindex,lotteryeth);
                lotindex=currentIndex;
                lotteryeth=0;
            }
            lotteryeth=lotteryeth+inputAmount/100;
            
    }
    function lottery(uint184 c,uint money)  private   {
        uint single=money/5;
        for(uint8 i=0;i<5;i++){
        address   add=indexMapping[c+8+20*i] ;
        if(add != 0x0000000000000000000000000000000000000000){
            Amounts memory amounts = amountsMapping[add];
            amounts.luckyAmount=money;
            amounts.luckyzAmount+=money;
        }
      }
    }
    
    function sunshimeplan(uint184 startLength ,uint184 endLength) public{
        require (msg.sender == owner);
        uint l1=0;
        uint l2=0;
        uint l3=0;
        uint l4=0;
   for(uint184 i = startLength; i <= endLength&&(invests[i].resTime+7 days)>now; i++) {
        address  userAddressCode = addressMapping[invests[i].inviteCode];
        User memory user = userMapping[userAddressCode];
        if(user.lineLevel==1)
           l1++;
        else if(user.lineLevel==2)
           l2++;
        else if(user.lineLevel==3)
           l3++;
        else if(user.lineLevel==4)
           l4++;
    }
    sendSun(l1,l2,l3,l4,startLength,endLength);
   
    }
    function sendSun(uint l1,uint l2,uint l3,uint l4,uint184 startLength ,uint184 endLength) private {
        uint level_awardl1=0;
        uint level_awardl2=0;
        uint level_awardl3=0;
        uint level_awardl4=0;
        if(suneth>0){
        if(l1>0){
             level_awardl1=(suneth*10/100)/l1;
        }
        if(l2>0){
            level_awardl2=(suneth*20/100)/l2;
        }
        if(l3>0){
             level_awardl3=(suneth*30/100)/l3;
        }
        if(l4>0){
            level_awardl4 =(suneth*40/100)/l4;
        }
        
       
       
        for(uint184 i = startLength; i <= endLength&&(invests[i].resTime+7 days)>now; i++) {
        address  userAddress = addressMapping[invests[i].inviteCode];
        User memory user1 = userMapping[userAddress]; 
        Amounts memory amounts = amountsMapping[userAddress];
        if(user1.level==1){
            if(level_awardl1>0&&address (this).balance>level_awardl1&&userAddress!=0x0000000000000000000000000000000000000001){
                address(uint160(userAddress)).transfer(level_awardl1);
                 amounts.sumzAmount+=level_awardl1;
                 suneth=suneth-level_awardl1;
            }
           
        }else if(user1.level==2){
             if(level_awardl2>0&&address (this).balance>level_awardl2&&userAddress!=0x0000000000000000000000000000000000000001){
                address(uint160(userAddress)).transfer(level_awardl2);
                 amounts.sumzAmount+=level_awardl2;
                   suneth=suneth-level_awardl2;
            }
           
        } else if(user1.level==3){
             if(level_awardl3>0&&address (this).balance>level_awardl3&&userAddress!=0x0000000000000000000000000000000000000001){
                address(uint160(userAddress)).transfer(level_awardl3);
                 amounts.sumzAmount+=level_awardl3;
                   suneth=suneth-level_awardl3;
            }
           
            
        }else if(user1.level==4){
            if(level_awardl4>0&&address (this).balance>level_awardl4&&userAddress!=0x0000000000000000000000000000000000000001){
                address(uint160(userAddress)).transfer(level_awardl4);
                   amounts.sumzAmount+=level_awardl4;
                     suneth=suneth-level_awardl4;
            }
         
        }
         
     }
        }

    }
   
   
    function countShareAndRecommendedAward(uint184 startLength ,uint184 endLength) external onlyOwner {
        for(uint184 i = startLength; i <= endLength; i++) {
             address  userAddressCode = indexMapping[i];
            User memory user = userMapping[userAddressCode];
            if(user.ft==0){
                uint scale = util.getScBylevel(user.level);
                uint _bouns = scale*user.freezeAmount/1000;
                user.dayBonusAmount =user.dayBonusAmount + _bouns;
                user.bonusAmount = user.bonusAmount + _bouns;  
                if((user.bonusAmount+user.inviteAmonut)>=(user.freezeAmount*getFt(user.level)/10)&&user._type==1){
                    user.ft=1;
                    user.outTime=now;
                }else if(((user.bonusAmount+user.inviteAmonut)>=user.freezeAmount*4)&&user._type==0){
                    user.ft=1;
                    user.outTime=now;
                }
                  userMapping[userAddressCode] = user;
            }
            
           
        }
    }
    
    function countRecommend(uint184 startLength ,uint184 endLength,uint times) public {
        require (msg.sender == owner);
         for(uint184 i = startLength; i <= endLength; i++) {
            address userAddress = indexMapping[i];
            if(userAddress != 0x0000000000000000000000000000000000000000){
                User memory user =  userMapping[userAddress];
                if(user.status == 1 && user.freezeAmount >= 1 * ethWei&&user.ft==0){
                    uint scale = util.getScBylevel(user.level);
                    execute(user.beInvitedCode,1,user.freezeAmount,scale);
                }
            }
        }
    }
    function execute2(string memory inviteCode,uint money) private{
        address  userAddressCode = addressMapping[inviteCode];
        if(userAddressCode != 0x0000000000000000000000000000000000000000){
            User memory user = userMapping[userAddressCode];
            if(user.isVaild&&user._type==0){
                sendAmountTobeInvited(inviteCode,money);
            }else{
                execute2(user.beInvitedCode,money);
            }
        }
         
    }
    
    function execute(string  memory inviteCode,uint runtimes,uint money,uint shareSc) private  returns(string memory,uint,uint,uint) {
        string memory codeOne = "null";
        address  userAddressCode = addressMapping[inviteCode];
        User memory user = userMapping[userAddressCode];
        
        if (user.isVaild && runtimes <= 100){
            codeOne = user.beInvitedCode;
              if(user.status == 1&&user.ft==0){
                  
                  uint fireSc = util.getFireScBylevel(user.lineLevel);
                  uint recommendSc = util.getRecommendScaleBylevelandTim(user.lineLevel,runtimes);
                  uint moneyResult = 0;
                  
                  if(money <= (user.freezeAmount+user.lineAmount+user.freeAmount)){
                      moneyResult = money;
                      fireSc=10;
                  }else{
                      moneyResult = user.freezeAmount+user.lineAmount+user.freeAmount;
                  }
                  if(recommendSc != 0){
                      
                      user.dayInviteAmonut =user.dayInviteAmonut + (moneyResult*shareSc*fireSc*recommendSc/10000/10/100);
                      user.inviteAmonut = user.inviteAmonut + (moneyResult*shareSc*fireSc*recommendSc/10000/10/100);
                if((user.bonusAmount+user.inviteAmonut)>=(user.freezeAmount*getFt(user.level)/10)&&user._type==1){
                    user.ft=1;
                    user.outTime=now;
                }else if(((user.bonusAmount+user.inviteAmonut)>=user.freezeAmount*4)&&user._type==0){
                    user.ft=1;
                    user.outTime=now;
                }
            
                      userMapping[userAddressCode] = user;
                  }
              }
              return execute(codeOne,runtimes+1,money,shareSc);
        }
        return (codeOne,0,0,0);
    }
    
    function sendMoneyToUser(address userAddress, uint money) private {
        uint256 _eth = money;
        address(uint160(userAddress)).transfer(_eth);
    }
    function sendAward(uint184 startLength ,uint184 endLength,uint times)  external onlyOwner  {
         for(uint184 i = startLength; i <= endLength; i++) {
            address userAddress = indexMapping[i];
            if(userAddress != 0x0000000000000000000000000000000000000000&&userAddress != 0x0000000000000000000000000000000000000001){
                User memory user =  userMapping[userAddress];
                if(user.status == 1){
                   Amounts memory amounts = amountsMapping[userAddress];
                    uint sendMoney =user.dayInviteAmonut + user.dayBonusAmount;
                    uint limitmoney=user.invitenumber*(user.lineAmount+user.freeAmount+user.freezeAmount);
                    limitmoney=(user.lineAmount+user.freeAmount+user.freezeAmount)/2;
                    if(sendMoney>limitmoney){
                        sendMoney=limitmoney;
                    }
                    sendMoney=sendMoney+amounts.luckyAmount;
                    if(sendMoney >= (ethWei/10)){
                        sendMoney = sendMoney - (ethWei/1000);  
                        bool isEnough = false ;
                        uint resultMoney = 0;
                        (isEnough,resultMoney) = isEnoughBalance(sendMoney);
                        if(isEnough){
                            sendMoneyToUser(user.userAddress,resultMoney);
                            emit Instructor(user.userAddress,resultMoney,2,"0");
                            user.dayInviteAmonut = 0;
                            user.dayBonusAmount = 0;
                            amounts.luckyAmount=0;
                            userMapping[userAddress] = user;
                        }else{
                            userMapping[userAddress] = user;
                            if(resultMoney > 0 ){
                                sendMoneyToUser(user.userAddress,resultMoney);
                              	emit Instructor(user.userAddress,resultMoney,2,"0");
                                user.dayInviteAmonut = 0;
                                user.dayBonusAmount = 0;
                                amounts.luckyAmount=0;
                                userMapping[userAddress] = user;
                            }
                        }
                    }
                }
            }
        }
    }
    function isEnoughBalance(uint sendMoney) private view returns (bool,uint){
        if((address(this).balance-suneth) > 0 ){
            if(sendMoney >= (address(this).balance-suneth)){
                return (false,(address(this).balance-suneth)); 
            }else{
                return (true,sendMoney);
            }
        }else{
            return (false,0);
        }

    }
    function getUserByAddress(address userAddress) public view returns(uint,uint,uint,uint,uint,uint,uint,uint,uint,string memory,string memory,uint){
            User memory user = userMapping[userAddress];
            return (user.lineAmount,user.freeAmount,user.freezeAmount,user.inviteAmonut,
            user.bonusAmount,user.lineLevel,user.status,user.dayInviteAmonut,user.dayBonusAmount,user.inviteCode,user.beInvitedCode,user.level);
    } 
    
    function getUserByAddress2(address userAddress) public view returns(uint,bool,uint){
            User memory user = userMapping[userAddress];
            return (user.ft,user.isVaild,user.status);
    }
    
    function getUserByAddress1(address userAddress) public view returns(bool){
          User memory user = userMapping[userAddress];
           return(user.isVaild);
    }
        function getAmountByAddress(address userAddress) public view returns(uint,uint,uint,uint){
        Amounts memory amounts =  amountsMapping[userAddress];
        return (amounts.sumAmount,amounts.sumzAmount,amounts.luckyAmount,amounts.luckyzAmount);
    }
    function getUserByinviteCode(string memory inviteCode) public view returns (bool){
        address  userAddressCode = addressMapping[inviteCode];
        if(userAddressCode != 0x0000000000000000000000000000000000000000){
            User memory user = userMapping[userAddressCode];
        if (user.isVaild){
            return true;
        }
    }
        return false;
    }
    function getaddress(string memory inviteCode) public view returns (address) {
         address  userAddressCode = addressMapping[inviteCode];
         return userAddressCode;
    }
    function getSomeInfo() public view returns(uint,uint,uint,uint,uint){
        return(totalMoney,totalCount,beginTime,suneth,lotteryeth);
    }
    function test() public view returns(uint,uint,uint){
        return (invests.length-2,currentIndex,actStu);
    }
    function sendFeetoAdmin(uint amount) private {
        0x08447F9c60adc5C16670ea0D029f713d41B3EF94.transfer(amount/25);     
        0x9FEA1699aa52D6287eD24EF9718c083062C3000a.transfer(amount/50);     
        0x707e2685A3039673032E1b5BB978c2EF3C8B2b95.transfer(amount/50);     
    }

   
    function usadr(uint184 t)public view returns (address)
    {
        return indexMapping[t];
    }
    
    function getFt(uint level) private view returns(uint){
    if(level == 1){
            return 20;
        }if(level == 2){
            return 25;
        }if(level == 3) {
            return 30;
        }if(level==4)
        {
            return 35;
         }return 0;
    }
    function getContractBanla()public view returns (uint){
        return address (this).balance;
    }
    function sendAmountTobeInvited(string memory inviteCode,uint amount) private {
          address  userAddressCode = addressMapping[inviteCode];
          if(userAddressCode != 0x0000000000000000000000000000000000000000){
            User memory user = userMapping[userAddressCode];
            if(user.isVaild&&user._type==0){
                if(now -30 days  < user.resTime){
               amount=amount*7/100; 
               address(uint160(userAddressCode)).transfer(amount);
            }else if(now -30 days  > user.resTime && now -30 days*2  <= user.resTime){
               amount=amount*5/100; 
                address(uint160(userAddressCode)).transfer(amount);
            }else if(now -30 days  > user.resTime && now -30 days*3  <= user.resTime){
               amount=amount*3/100; 
                 address(uint160(userAddressCode)).transfer(amount);
            }else if(now -30 days  > user.resTime && now -30 days*4  <= user.resTime){
               amount=amount*2/100; 
                 address(uint160(userAddressCode)).transfer(amount);
            }
                
                
            }
          }
      
    }
}