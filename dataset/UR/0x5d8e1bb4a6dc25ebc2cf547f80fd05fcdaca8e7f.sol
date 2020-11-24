 

 

 
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

contract BEBmining is Ownable{
tokenTransfer public bebTokenTransfer;  
    uint8 decimals = 18;
   struct BebUser {
        address customerAddr;
        uint256 amount; 
        uint256 bebtime;
        uint256 interest;
        
    }
     
    struct miner{
        uint256 mining;
        uint256 _mining;
        uint256 lastDate;
        uint256 amountdays;
        uint256 ethbomus;
        uint256 amountTotal;
        uint256 ETHV1;
        uint256 ETHV2;
        uint256 ETHV3;
        uint256 ETHV4;
        uint256 ETHV5;
        uint256 IntegralMining;
        uint256 RateOfreturn;
    }
    struct bebvv{
        uint256 BEBV1;
        uint256 BEBV2;
        uint256 BEBV3;
        uint256 BEBV4;
        uint256 BEBV5;
    }
    mapping(address=>bebvv)public bebvvs;
    mapping(address=>miner)public miners;
    address[]public minersArray;
    uint256 ethExchuangeRate=130; 
    uint256 bebethexchuang=2500; 
    uint256 bebethex=2500; 
    uint256 bounstotal;
    uint256 TotalInvestment;
    uint256 sumethbos;
    uint256 depreciationTime=86400;
    uint256 SellBeb; 
    uint256 BuyBeb; 
    uint256 IncomePeriod=730; 
    address addressDraw;
    uint256 intotime=1579073112;
    event bomus(address to,uint256 amountBouns,string lx);
    function BEBmining(address _tokenAddress,address Draw){
         bebTokenTransfer = tokenTransfer(_tokenAddress);
         addressDraw=Draw;
     }
       
    function EthTomining(address _addr)payable public{
        require(tx.origin == msg.sender);
        uint256 amount=msg.value;
        uint256 usdt=amount;
        uint256 _udst=amount;
        miner storage user=miners[_addr];
        require(amount>800000000000000000);
        if(usdt>40000000000000000000){
           usdt=amount*150/100;
           user.ETHV5+=1;
           user.RateOfreturn=10;
        }else{
            if (usdt > 25000000000000000000){
                    usdt = amount* 130 / 100;
                    user.ETHV4+=1;
                    user.RateOfreturn=30;
                }
                else{
                    if (usdt > 9000000000000000000){
                        usdt = amount * 120 / 100;
                         user.ETHV3+=1;
                         user.RateOfreturn=50;
                    }
                    else{
                        if (usdt > 4000000000000000000){
                            usdt = amount * 110 / 100;
                             user.ETHV2+=1;
                             user.RateOfreturn=70;
                        }
                        else{
                          user.ETHV1+=1;
                          user.RateOfreturn=100;
                        }
                    }
                }
        }
        uint256 _transfer=amount*15/100;
        addressDraw.transfer(_transfer);
        TotalInvestment+=_udst;
        user.mining+=usdt;
        user._mining+=_udst;
         
        user.lastDate=now;
        bomus(msg.sender,usdt,"Purchase success!");
    }
     
    function BebTomining(uint256 _value,address _addr)public{
        require(tx.origin == msg.sender);
        uint256 usdt=_value* 10 ** 18;
        uint256 _udst=usdt/bebethex;
        uint256 bebudst=usdt/bebethex;
        miner storage user=miners[_addr];
        bebvv storage _user=bebvvs[_addr];
        require(usdt>40000000000000000000000);
        if(usdt>2000000000000000000000000){
           _udst=usdt/bebethexchuang*150/100;
           _user.BEBV5+=1; 
           user.RateOfreturn=10;
        }else{
            if (usdt > 400000000000000000000000){
                    _udst = usdt / bebethexchuang * 130 / 100;
                   _user.BEBV4+=1;
                   user.RateOfreturn=10;
                }
                else{
                    if (usdt > 200000000000000000000000){
                        _udst = usdt / bebethexchuang * 120 / 100;
                        _user.BEBV3+=1;
                        user.RateOfreturn=10;
                    }
                    else{
                        if (usdt > 120000000000000000000000){
                            _udst = usdt / bebethexchuang * 110 / 100;
                            _user.BEBV2+=1;
                            user.RateOfreturn=10;
                        }else{
                          _user.BEBV1+=1;
                          user.RateOfreturn=10;
                        }
                    }
                }
                
            }
        bebTokenTransfer.transferFrom(msg.sender,address(this),usdt);
        TotalInvestment+=bebudst;
        user.mining+=_udst;
        user._mining+=bebudst;
        user.lastDate=now;
        bomus(msg.sender,usdt,"Purchase success!");
    }
     
    function integralTomining(uint256 _value,address _addr)onlyOwner{
        uint256 _eth=_value* 10 ** 18;
         
        miner storage user=miners[_addr];
         
        TotalInvestment+=_eth;
        user.mining+=_eth;
        user._mining+=_eth;
        if(user.lastDate==0){
           user.lastDate=now; 
        }
         
        bomus(_addr,_eth,"Purchase success!");
    }
     
    function migrateTomining(uint256 _days,uint256 _value,uint256 _minin,uint256 _amountTotal,address _addr)onlyOwner{
         
        miner storage user=miners[_addr];
        user.amountTotal=_amountTotal; 
        user.mining=_value;
        user._mining=_minin;
        user.lastDate=now;
        user.RateOfreturn=_days;
    }
    function setTomining(uint256 _value,uint256 _minin,address _addr)onlyOwner{
         
        miner storage user=miners[_addr];
        user.mining-=_value; 
        user._mining-=_minin; 
    }
    function setToTomining(uint256 _value,uint256 _minin,address _addr)onlyOwner{
         
        miner storage user=miners[_addr];
        user.mining+=_value; 
        user._mining+=_minin; 
    }
     
    function setaddress(address _addr)onlyOwner{
        addressDraw=_addr;
    }
    function freeSettlement()public{
        require(tx.origin == msg.sender);
        miner storage user=miners[msg.sender];
        bebvv storage _user=bebvvs[msg.sender];
        uint256 amuont=user.mining;
        uint256 _sdhttts=user.RateOfreturn;
        require(amuont>0,"You don't have a mining machine");
        uint256 _ethbomus=user.ethbomus;
        uint256 _lastDate=user.lastDate;
        uint256 _amountTotal=user.amountTotal;
        uint256 sumincome=_amountTotal*100/amuont;
        uint256 depreciation=(now-_lastDate)/depreciationTime;
        require(depreciation>0,"Less than 1 day of earnings");
         
        uint256 Bebday=amuont*depreciation/100;
        uint256 profit=Bebday;
        require(profit>0,"Mining amount 0");
        if(sumincome>_sdhttts){
           uint256 _Bebday=amuont*depreciation*9/100;
           uint256 _daystre=amuont*depreciation/100;
           require(this.balance>_daystre,"Insufficient contract balance");
           user.mining-=_Bebday;
            user.lastDate=now;
            user.ethbomus+=_daystre;
            user.amountTotal+=_daystre;
            user.amountdays+=depreciation;
            bounstotal+=_daystre;
            user.ethbomus=0;
            sumethbos=0;
           msg.sender.transfer(_daystre);
           if(user.amountdays>730){
                
              
           user.mining=0;
           user.lastDate=0;
           user.ethbomus=0;
           sumethbos=0;
           user.amountTotal=0;
           user.amountdays=0;
           user.ETHV1=0;
           user.ETHV2=0;
           user.ETHV3=0;
           user.ETHV4=0;
           user.ETHV5=0;
           user.IntegralMining=0;
           user._mining=0;
           _user.BEBV1=0;
           _user.BEBV2=0;
           _user.BEBV3=0;
           _user.BEBV4=0;
           _user.BEBV5=0;
           }
        }else{
            require(this.balance>profit,"Insufficient contract balance");
            user.lastDate=now;
            user.ethbomus+=Bebday;
            user.amountTotal+=Bebday;
            user.amountdays+=depreciation;
            bounstotal+=profit;
            user.ethbomus=0;
            sumethbos=0;
           msg.sender.transfer(profit);  
        }
        
    }
    function getbebmining()public view returns(uint256,uint256,uint256,uint256,uint256){
         bebvv storage user=bebvvs[msg.sender];
        return (user.BEBV1,user.BEBV2,user.BEBV3,user.BEBV4,user.BEBV5);
     }
     function querBalance()public view returns(uint256){
         return this.balance;
     }
    function querYrevenue()public view returns(uint256,uint256,uint256,uint256,uint256,uint256){
        miner storage user=miners[msg.sender];
        uint256 _amuont=user.mining;
        uint256 _min=user._mining;
        uint256 _amountTotal=user.amountTotal;
        if(_amuont==0){
            percentage=0;
        }else{
        uint256 percentage=100-(_amountTotal*100/_amuont*100/730);    
        }
        uint256 _lastDate=user.lastDate;
        uint256 dayzmount=_amuont/100;
        uint256 depreciation=(now-_lastDate)/depreciationTime;
         
        uint256  Bebday=_amuont*depreciation/100;
                 sumethbos=Bebday;

        uint256 profit=sumethbos;
        return (percentage,dayzmount,_min,profit,user.amountTotal,user.lastDate);
    }
    function ethmining()public view returns(uint256,uint256,uint256,uint256,uint256,uint256){
        miner storage user=miners[msg.sender];
        return (user.ETHV1,user.ETHV2,user.ETHV3,user.ETHV4,user.ETHV5,user.IntegralMining);
    }
    function getquerYrevenue()public view returns(uint256,uint256,uint256){
        miner storage user=miners[msg.sender];
        return (user.mining,user.amountTotal,user.lastDate);
    }
    function RefundData()public view returns(uint256,uint256,uint256,uint256){
        miner storage user=miners[msg.sender];
        uint256 benjin=user._mining-user.amountTotal;
        uint256 dayts=user.amountdays;
        uint256 dayxi=benjin*1/1000*dayts;
        return (user._mining,user.amountTotal,dayxi,benjin+dayxi);
    }
    function ModifyexchangeRate(uint256 sellbeb,uint256 buybeb,uint256 _ethExchuangeRate,uint256 maxsell,uint256 maxbuy) onlyOwner{
        ethExchuangeRate=_ethExchuangeRate;
        bebethexchuang=sellbeb;
        bebethex=buybeb;
        SellBeb=maxsell* 10 ** 18;
        BuyBeb=maxbuy* 10 ** 18;
        
    }
     
    function sellBeb(uint256 _sellbeb)public {
        require(tx.origin == msg.sender);
        uint256 _sellbebt=_sellbeb* 10 ** 18;
         require(_sellbeb>0,"The exchange amount must be greater than 0");
         require(_sellbeb<SellBeb,"More than the daily redemption limit");
         uint256 bebex=_sellbebt/bebethexchuang;
         require(this.balance>bebex,"Insufficient contract balance");
         bebTokenTransfer.transferFrom(msg.sender,address(this),_sellbebt);
         msg.sender.transfer(bebex);
    }
     
    function buyBeb() payable public {
        require(tx.origin == msg.sender);
        uint256 amount = msg.value;
        uint256 bebamountub=amount*bebethex;
        uint256 _transfer=amount*15/100;
        require(getTokenBalance()>bebamountub);
        addressDraw.transfer(_transfer);
        bebTokenTransfer.transfer(msg.sender,bebamountub);  
    }
    function queryRate() public view returns(uint256,uint256,uint256,uint256,uint256){
        return (ethExchuangeRate,bebethexchuang,bebethex,SellBeb,BuyBeb);
    }
    function TotalRevenue()public view returns(uint256,uint256) {
     return (bounstotal,TotalInvestment);
    }
    function setioc(uint256 _value)onlyOwner{
        IncomePeriod=_value;
    }
    event messageBetsGame(address sender,bool isScuccess,string message);
    function getTokenBalance() public view returns(uint256){
         return bebTokenTransfer.balanceOf(address(this));
    }
    function BEBwithdrawAmount(uint256 amount) onlyOwner {
        uint256 _amountbeb=amount* 10 ** 18;
        require(getTokenBalance()>_amountbeb,"Insufficient contract balance");
       bebTokenTransfer.transfer(owner,_amountbeb);
    } 
    function ()payable{
        
    }
}